"""Supervised Windows worker: GitHub Issue -> Gemini plan -> Codex -> Godot -> Gemini QA."""
import argparse
import json
import os
import re
import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RUNS = ROOT / ".automation-runs"

def command(argv, timeout=900, check=True):
    result = subprocess.run(argv, cwd=ROOT, text=True, capture_output=True,
                            encoding="utf-8", errors="replace", timeout=timeout, shell=False)
    output = {"code": result.returncode, "stdout": result.stdout[-30000:],
              "stderr": result.stderr[-10000:]}
    if check and result.returncode:
        raise RuntimeError(f"{argv[0]} failed ({result.returncode}): {result.stderr[-2000:]}")
    return output

def repository_context():
    """Ground planning in tracked project files, with explicit truncation limits."""
    tracked = command(["git", "ls-files", "--cached"])["stdout"].splitlines()
    allowed = (".gd", ".tscn", ".tres", ".godot", ".md", ".txt")
    excluded = (".automation-runs/", "automation/", "assets/", "addons/")
    paths = sorted(p for p in tracked if p and not p.startswith(excluded))
    relevant = [p for p in paths if p.endswith(allowed)]
    inventory = "\\n".join(relevant)
    if len(inventory) > 18000:
        inventory = inventory[:18000] + "\\n[INVENTORY TRUNCATED]"
    sections = ["TRACKED FILE INVENTORY (paths only; not proof of behavior):\\n" + inventory]
    budget = 42000
    priority = ("AGENTS.md", "docs/GDD.md", "DEVELOPMENT_PLAN.md",
                "project.godot", "scenes/vertical_slice.tscn")
    ordered = list(dict.fromkeys(
        [p for p in priority if p in relevant] +
        [p for p in relevant if p.startswith(("scripts/", "tests/", "scenes/", "planning/", "docs/"))]
    ))
    for name in ordered:
        if budget <= 0:
            break
        file = ROOT / name
        try:
            body = file.read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            continue
        if len(body) > 6500:
            body = body[:6500] + "\\n[FILE TRUNCATED]"
        section = f"\\n--- FILE: {name} ---\\n{body}\\n"
        if len(section) > budget:
            sections.append(f"\\n[CONTEXT BUDGET REACHED; remaining files not inspected]")
            break
        sections.append(section)
        budget -= len(section)
    return "\\n".join(sections)

def planner(issue, context):
    key = os.getenv("GEMINI_API_KEY")
    if not key:
        raise RuntimeError("Set GEMINI_API_KEY in PowerShell.")
    model = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    prompt = ("Act as Planner for Prince of Vengeance, a Godot 2D-only game. "
              "Respect AGENTS.md, audit existing systems, and return a Markdown specification "
              "with acceptance criteria, affected files, tests, risks and dependencies. "
              "Do not request 3D work.\nCONTEXT:\n" + context[:18000] +
              "\nISSUE:\n" + issue[:10000])
    request = urllib.request.Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent",
        data=json.dumps({"contents":[{"parts":[{"text":prompt}]}]}).encode(),
        headers={"x-goog-api-key":key,"content-type":"application/json"}, method="POST")
    # Transient model overloads should not abort the entire planning run.
    retryable = {429, 500, 502, 503, 504}
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                data = json.load(response)
            break
        except urllib.error.HTTPError as error:
            details = error.read().decode("utf-8", errors="replace")[:1500]
            if error.code not in retryable or attempt == 3:
                raise RuntimeError(
                    f"Gemini API HTTP {error.code}: {details}"
                ) from error
            delay = min(2 ** (attempt + 1), 16)
            print(f"Gemini API HTTP {error.code}; retrying in {delay}s "
                  f"(attempt {attempt + 2}/4)")
            time.sleep(delay)
        except (urllib.error.URLError, TimeoutError) as error:
            if attempt == 3:
                raise RuntimeError(f"Gemini API unavailable after 4 attempts: {error}") from error
            delay = min(2 ** (attempt + 1), 16)
            print(f"Gemini network error; retrying in {delay}s "
                  f"(attempt {attempt + 2}/4)")
            time.sleep(delay)
    parts = [p.get("text","") for c in data.get("candidates",[])
             for p in c.get("content",{}).get("parts",[])]
    result = "\n".join(parts).strip()
    if not result:
        raise RuntimeError("Gemini returned an empty plan.")
    return result

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--issue", type=int, required=True)
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--approved-spec", type=Path,
                        help="Previously reviewed spec; required for --execute")
    parser.add_argument("--skip-godot", action="store_true")
    args = parser.parse_args()
    # Planning is read-only: allow existing local edits and any current branch.
    # Execution changes files, so keep strict guards before launching Codex.
    if args.execute:
        if command(["git","status","--porcelain"])["stdout"].strip():
            raise RuntimeError("Execution requires a clean working tree.")
        current_branch = command(["git","branch","--show-current"])["stdout"].strip()
        if not current_branch:
            raise RuntimeError("Execution requires a named branch (not detached HEAD).")
    issue = json.loads(command(["gh","issue","view",str(args.issue),
                                 "--json","title,body,url"])["stdout"])
    RUNS.mkdir(exist_ok=True)
    folder = RUNS / f"issue-{args.issue}-{int(time.time())}"
    folder.mkdir()
    if args.execute:
        if not args.approved_spec or not args.approved_spec.is_file():
            raise RuntimeError("--execute requires --approved-spec PATH to a reviewed plan.")
        spec = args.approved_spec.read_text(encoding="utf-8")
    else:
        context = repository_context()
        (folder/"context.md").write_text(context, encoding="utf-8")
        spec = planner(issue["title"]+"\n"+(issue.get("body") or ""), context)
        path = folder/"spec.md"
        path.write_text(spec,encoding="utf-8")
        print(f"Review the plan: {path}")
        print(f"Then run: python automation/worker.py --issue {args.issue} --execute --approved-spec \"{path}\"")
        return
    branch = f"agents/issue-{args.issue}-{int(time.time())}"
    command(["git","switch","-c",branch])
    prompt = ("Implement the approved spec in the existing Godot 2D project. "
              "Follow AGENTS.md; do not introduce 3D or delete assets. "
              "Do not commit or push.\n"+spec)
    command(["codex","exec","--full-auto",prompt],timeout=3600)
    evidence = []
    if not args.skip_godot:
        evidence.append({"name":"import",**command(
            ["godot","--headless","--path",".","--editor","--quit"],timeout=180,check=False)})
        for scene in sorted((ROOT/"tests").glob("*_test.tscn")):
            evidence.append({"name":str(scene.relative_to(ROOT)),**command(
                ["godot","--headless","--path",".","--scene",
                 "res://"+scene.relative_to(ROOT).as_posix()],timeout=90,check=False)})
    (folder/"godot.json").write_text(json.dumps(evidence,indent=2),encoding="utf-8")
    diff = command(["git","diff","--no-ext-diff"])["stdout"]
    status = command(["git","status","--porcelain"])["stdout"]
    qa_prompt = ("Independent QA for Godot 2D. Return verdict exactly 'VERDICT: PASS' "
                 "or 'VERDICT: FAIL' on its own line, followed by findings. "
                 "Check spec, diff, test evidence, and identify missing coverage. "
                 "Do not modify files.\nSPEC:\n"+spec+"\nDIFF:\n"+diff[:50000]+
                 "\nSTATUS:\n"+status+"\nTESTS:\n"+json.dumps(evidence)[:20000])
    qa = command(["gemini","-p",qa_prompt],timeout=600,check=False)
    (folder/"qa.md").write_text(qa["stdout"]+"\n"+qa["stderr"],encoding="utf-8")
    passed = bool(re.search(r"(?m)^VERDICT: PASS\s*$",qa["stdout"]))
    if qa["code"] or not passed or any(item["code"] for item in evidence) or args.skip_godot:
        print(f"QA requires manual attention; no PR. Report: {folder/'qa.md'}")
        return
    print(f"QA passed. Inspect git diff/status, then commit and push {branch} manually.")
    print(f"After pushing: gh pr create --draft --base main --head {branch}")

if __name__ == "__main__":
    main()
