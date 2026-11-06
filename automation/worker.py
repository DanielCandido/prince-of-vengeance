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
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            data = json.load(response)
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"Gemini API HTTP {error.code}; check key, quota and model") from error
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
    if command(["git","status","--porcelain"])["stdout"].strip():
        raise RuntimeError("Start with a clean working tree.")
    if command(["git","branch","--show-current"])["stdout"].strip() != "main":
        raise RuntimeError("Start from main.")
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
        context = (ROOT/"AGENTS.md").read_text(encoding="utf-8")
        for path in ("docs/GDD.md","DEVELOPMENT_PLAN.md"):
            file = ROOT/path
            if file.exists():
                context += "\n" + file.read_text(encoding="utf-8")[:9000]
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
