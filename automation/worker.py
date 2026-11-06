"""Supervised Windows worker: GitHub Issue -> Gemini plan -> Codex -> Godot -> Gemini QA."""
import argparse
import json
import os
import re
import subprocess
import threading
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RUNS = ROOT / ".automation-runs"


def utc_timestamp():
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


def command(argv, timeout=900, check=True):
    try:
        result = subprocess.run(argv, cwd=ROOT, text=True, capture_output=True,
                                encoding="utf-8", errors="replace", timeout=timeout, shell=False)
        output = {"code": result.returncode, "stdout": result.stdout[-30000:],
                  "stderr": result.stderr[-10000:]}
    except subprocess.TimeoutExpired as error:
        def decode(value):
            if isinstance(value, bytes):
                return value.decode("utf-8", errors="replace")
            return value or ""
        output = {"code": 124, "stdout": decode(error.stdout)[-30000:],
                  "stderr": decode(error.stderr)[-10000:] +
                  f"\nTIMEOUT: command exceeded {timeout}s"}
        if check:
            raise RuntimeError(f"{argv[0]} timed out after {timeout}s") from error
        return output
    if check and result.returncode:
        raise RuntimeError(f"{argv[0]} failed ({result.returncode}): {result.stderr[-2000:]}")
    return output


def terminate_process_tree(process):
    """Best-effort termination, including descendants created by Godot on Windows."""
    if process.poll() is not None:
        return
    if os.name == "nt":
        try:
            subprocess.run(
                ["taskkill", "/PID", str(process.pid), "/T", "/F"],
                capture_output=True, text=True, timeout=15, check=False,
                creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
            )
        except (OSError, subprocess.SubprocessError):
            pass
    if process.poll() is None:
        try:
            process.kill()
        except OSError:
            pass



def run_logged_process(argv, log_path, timeout, target, stdin_text=None):
    """Run a process with durable incremental output and a structured outcome."""
    started_at = utc_timestamp()
    started = time.monotonic()
    log_path = Path(log_path)
    log_path.parent.mkdir(parents=True, exist_ok=True)

    stdout_parts = []
    stderr_parts = []
    timed_out = False
    exit_code = None
    start_error = ""

    creationflags = 0
    if os.name == "nt":
        creationflags = getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0)

    with log_path.open("w", encoding="utf-8", newline="") as log_file:
        log_file.write(
            json.dumps(
                {
                    "timestamp": started_at,
                    "command": list(argv),
                    "stdin_supplied": stdin_text is not None,
                },
                ensure_ascii=False,
            ) + "\n"
        )
        log_file.flush()

        try:
            process = subprocess.Popen(
                argv,
                cwd=ROOT,
                text=True,
                stdin=(
                    subprocess.PIPE
                    if stdin_text is not None
                    else subprocess.DEVNULL
                ),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                encoding="utf-8",
                errors="replace",
                bufsize=1,
                shell=False,
                creationflags=creationflags,
            )
        except OSError as error:
            start_error = f"Unable to start process: {error}"
            log_file.write(f"[worker] {start_error}\n")
            log_file.flush()

        else:
            lock = threading.Lock()
            stdin_errors = []

            def copy_stream(stream, label, destination):
                try:
                    for line in iter(stream.readline, ""):
                        destination.append(line)
                        with lock:
                            log_file.write(f"[{label}] {line}")
                            log_file.flush()
                finally:
                    stream.close()

            def write_stdin():
                try:
                    process.stdin.write(stdin_text)
                    process.stdin.flush()
                except (BrokenPipeError, OSError, ValueError) as error:
                    stdin_errors.append(str(error))
                finally:
                    try:
                        process.stdin.close()
                    except OSError:
                        pass

            readers = [
                threading.Thread(
                    target=copy_stream,
                    args=(process.stdout, "stdout", stdout_parts),
                    daemon=True,
                ),
                threading.Thread(
                    target=copy_stream,
                    args=(process.stderr, "stderr", stderr_parts),
                    daemon=True,
                ),
            ]

            for reader in readers:
                reader.start()

            writer = None
            if stdin_text is not None:
                writer = threading.Thread(
                    target=write_stdin,
                    daemon=True,
                )
                writer.start()

            try:
                exit_code = process.wait(timeout=timeout)

            except subprocess.TimeoutExpired:
                timed_out = True

                with lock:
                    log_file.write(
                        f"[worker] TIMEOUT: command exceeded {timeout}s\n"
                    )
                    log_file.flush()

                terminate_process_tree(process)

                try:
                    exit_code = process.wait(timeout=15)
                except subprocess.TimeoutExpired:
                    exit_code = None

            if writer is not None:
                writer.join(timeout=5)

            for reader in readers:
                reader.join(timeout=5)

            if stdin_errors:
                message = "; ".join(stdin_errors)
                stderr_parts.append(f"[worker] stdin error: {message}\n")

                with lock:
                    log_file.write(f"[worker] stdin error: {message}\n")
                    log_file.flush()

    if timed_out:
        status = "TIMEOUT"
    elif start_error or exit_code != 0:
        status = "FAIL"
    else:
        status = "PASS"

    stderr = "".join(stderr_parts)

    if start_error:
        stderr = start_error + ("\n" + stderr if stderr else "")

    return {
        "target": target,
        "command": list(argv),
        "exit_code": exit_code,
        "duration_seconds": round(time.monotonic() - started, 3),
        "status": status,
        "timestamp": started_at,
        "log_path": str(log_path.resolve()),
        "stdout": "".join(stdout_parts)[-30000:],
        "stderr": stderr[-10000:],
    }


def create_run_folder(issue):
    RUNS.mkdir(exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    folder = RUNS / f"issue-{issue}-{stamp}"
    folder.mkdir()
    return folder


def write_report(folder, report):
    """Atomically persist progress so completed steps survive later failures."""
    path = folder / "report.json"
    temporary = folder / "report.json.tmp"
    temporary.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    temporary.replace(path)
    return path


def repository_context(issue_text=""):
    """Build an issue-aware, bounded context from actual tracked files."""
    tracked = command(["git", "ls-files", "--cached"])["stdout"].splitlines()
    allowed = (".gd", ".tscn", ".tres", ".godot", ".md", ".txt")
    excluded = (".automation-runs/", "automation/", "assets/", "addons/")
    paths = sorted(p for p in tracked if p and not p.startswith(excluded))
    relevant = [p for p in paths if p.endswith(allowed)]
    inventory = "\n".join(relevant)
    if len(inventory) > 14000:
        inventory = inventory[:14000] + "\n[INVENTORY TRUNCATED]"
    sections = ["TRACKED FILE INVENTORY (paths only; not proof of behavior):\n" + inventory]
    requested = [p for p in relevant if p in issue_text]
    baseline = ["AGENTS.md", "docs/GDD.md", "project.godot",
                "planning/M01_BACKLOG.md", "DEVELOPMENT_PLAN.md"]
    gameplay = ["scripts/player/kaelen_controller_2d.gd",
                "scripts/components/hitbox_2d.gd",
                "scripts/components/hurtbox_2d.gd",
                "scripts/components/health_component.gd"]
    tests = [p for p in relevant if p.startswith("tests/") and p.endswith(".gd")]
    other_scripts = [p for p in relevant if p.startswith("scripts/") and p.endswith(".gd")]
    scenes = [p for p in relevant if p.startswith("scenes/") and p.endswith(".tscn")]
    ordered = list(dict.fromkeys(requested + baseline[:3] + gameplay + tests +
                                 baseline[3:] + other_scripts + scenes))
    budget = 48000
    for name in ordered:
        if name not in relevant or budget <= 0:
            continue
        try:
            body = (ROOT / name).read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            continue
        limit = 2000 if name.endswith(".md") and name != "AGENTS.md" else 5000
        if name == "AGENTS.md":
            limit = 3800
        if name == "project.godot":
            limit = 5500
        if name in requested:
            limit = 8500
        if len(body) > limit:
            body = body[:limit] + "\n[FILE TRUNCATED]"
        section = f"\n--- FILE: {name} ---\n{body}\n"
        if len(section) > budget:
            sections.append("\n[CONTEXT BUDGET REACHED; remaining files not inspected]")
            break
        sections.append(section)
        budget -= len(section)
    return "\n".join(sections)


def planner(issue, context):
    key = os.getenv("GEMINI_API_KEY")
    if not key:
        raise RuntimeError("Set GEMINI_API_KEY in PowerShell.")
    model = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    prompt = ("You are Planner for Prince of Vengeance, strictly Godot 2D. "
              "Treat AGENTS.md and docs/GDD.md as authoritative over outdated 3D plans. "
              "Use only the supplied file excerpts as evidence; distinguish VERIFIED, "
              "INFERRED and NOT INSPECTED. Cite exact paths and symbols. "
              "Never claim tests executed, never invent paths or GUT installation. "
              "Prefer the existing Godot test scenes. Give minimal, measurable tasks, "
              "acceptance criteria, risks and dependencies. "
              "For documentation-only issues, do not propose gameplay edits. "
              "Explicitly report any truncated files and missing evidence.\n"
              "ISSUE:\n" + issue[:10000] +
              "\nREPOSITORY CONTEXT:\n" + context[:65000])
    request = urllib.request.Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent",
        data=json.dumps({"contents": [{"parts": [{"text": prompt}]}]}).encode(),
        headers={"x-goog-api-key": key, "content-type": "application/json"}, method="POST")
    retryable = {429, 500, 502, 503, 504}
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                data = json.load(response)
            break
        except urllib.error.HTTPError as error:
            details = error.read().decode("utf-8", errors="replace")[:1500]
            if error.code not in retryable or attempt == 3:
                raise RuntimeError(f"Gemini API HTTP {error.code}: {details}") from error
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
    parts = [p.get("text", "") for c in data.get("candidates", [])
             for p in c.get("content", {}).get("parts", [])]
    result = "\n".join(parts).strip()
    if not result:
        raise RuntimeError("Gemini returned an empty plan.")
    return result


def collect_diff():
    diff = command(["git", "diff", "--no-ext-diff"])["stdout"]
    untracked = command(["git", "ls-files", "--others", "--exclude-standard"])["stdout"].splitlines()
    for name in untracked:
        if name.endswith(".md") and (ROOT / name).is_file():
            diff += f"\n--- UNTRACKED FILE: {name} ---\n"
            diff += (ROOT / name).read_text(encoding="utf-8")[:40000] + "\n"
    return diff


def run_qa_pipeline(issue, spec, folder, mode, branch, skip_godot=False):
    report = {
        "issue": issue,
        "mode": mode,
        "branch": branch,
        "started_at": utc_timestamp(),
        "report_path": str((folder / "report.json").resolve()),
        "godot_steps": [],
        "qa": None,
    }
    write_report(folder, report)

    if not skip_godot:
        steps = [("import", ["godot", "--headless", "--path", ".", "--editor", "--quit"], 180)]
        steps.extend(
            (str(scene.relative_to(ROOT)),
             ["godot", "--headless", "--path", ".", "--scene",
              "res://" + scene.relative_to(ROOT).as_posix()], 90)
            for scene in sorted((ROOT / "tests").glob("*_test.tscn"))
        )
        for index, (target, argv, timeout) in enumerate(steps, start=1):
            safe_name = re.sub(r"[^A-Za-z0-9_.-]+", "_", target)
            result = run_logged_process(argv, folder / "logs" / f"{index:02d}-{safe_name}.log",
                                        timeout=timeout, target=target)
            report["godot_steps"].append(result)
            write_report(folder, report)

    diff = collect_diff()
    status = command(["git", "status", "--porcelain"])["stdout"]
    qa_prompt = ("Independent QA for Godot 2D. Return verdict exactly 'VERDICT: PASS' "
                 "or 'VERDICT: FAIL' on its own line, followed by findings. "
                 "Check spec, diff, test evidence, and identify missing coverage. "
                 "Do not modify files.\nSPEC:\n" + spec + "\nDIFF:\n" + diff[:50000] +
                 "\nSTATUS:\n" + status + "\nTESTS:\n" +
                 json.dumps(report["godot_steps"], ensure_ascii=False)[:20000])

    qa_process = run_logged_process(
        ["gemini.cmd" if os.name == "nt" else "gemini", "-p", ""],
        folder / "logs" / "qa.log",
        timeout=600,
        target="Gemini QA",
        stdin_text=qa_prompt,
    )
    verdict_pass = bool(re.search(r"(?m)^VERDICT: PASS\s*$", qa_process["stdout"]))
    qa_result = dict(qa_process)
    qa_result["verdict"] = "PASS" if verdict_pass else "FAIL"
    qa_result["status"] = (
        "TIMEOUT" if qa_process["status"] == "TIMEOUT"
        else "PASS" if qa_process["status"] == "PASS" and verdict_pass
        else "FAIL"
    )
    report["qa"] = qa_result
    report["completed_at"] = utc_timestamp()
    report_path = write_report(folder, report)
    (folder / "qa.md").write_text(
        qa_process["stdout"] + ("\n" + qa_process["stderr"] if qa_process["stderr"] else ""),
        encoding="utf-8",
    )

    counts = {name: 0 for name in ("PASS", "FAIL", "TIMEOUT")}
    print("Godot steps:")
    for item in report["godot_steps"]:
        counts[item["status"]] += 1
        print(f"  {item['status']:<7} exit={item['exit_code']} "
              f"target={item['target']} log={item['log_path']}")
    print("Godot summary: " + ", ".join(f"{name}={counts[name]}" for name in counts))
    print(f"Gemini QA: {qa_result['status']} exit={qa_result['exit_code']} "
          f"log={qa_result['log_path']}")
    print(f"Evidence report: {report_path}")

    godot_failed = skip_godot or any(
        item["status"] != "PASS" for item in report["godot_steps"]
    )
    return 1 if godot_failed or qa_result["status"] != "PASS" else 0


def parse_args(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--issue", type=int, required=True)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--execute", action="store_true")
    modes.add_argument("--resume-qa", action="store_true")
    parser.add_argument("--approved-spec", type=Path,
                        help="Previously reviewed spec; required for --execute and --resume-qa")
    parser.add_argument("--skip-godot", action="store_true")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    if args.execute:
        if command(["git", "status", "--porcelain"])["stdout"].strip():
            raise RuntimeError("Execution requires a clean working tree.")
        current_branch = command(["git", "branch", "--show-current"])["stdout"].strip()
        if not current_branch:
            raise RuntimeError("Execution requires a named branch (not detached HEAD).")

    if args.execute or args.resume_qa:
        if not args.approved_spec or not args.approved_spec.is_file():
            raise RuntimeError(
                "--execute and --resume-qa require --approved-spec PATH to a reviewed plan."
            )
        spec = args.approved_spec.read_text(encoding="utf-8")
        folder = create_run_folder(args.issue)
        if args.resume_qa:
            branch = command(["git", "branch", "--show-current"])["stdout"].strip() or "DETACHED"
            return run_qa_pipeline(args.issue, spec, folder, "resume-qa", branch,
                                   skip_godot=args.skip_godot)

        branch = f"agents/issue-{args.issue}-{int(time.time())}"
        command(["git", "switch", "-c", branch])
        prompt = ("Implement the approved spec in the existing Godot 2D project. "
                  "Follow AGENTS.md; do not introduce 3D or delete assets. "
                  "Do not commit or push.\n" + spec)
        command(["codex", "exec", "--sandbox", "workspace-write", prompt], timeout=3600)
        result = run_qa_pipeline(args.issue, spec, folder, "execute", branch,
                                 skip_godot=args.skip_godot)
        if result:
            print(f"QA requires manual attention; no PR. Report: {folder / 'report.json'}")
            return result
        print(f"QA passed. Inspect git diff/status, then commit and push {branch} manually.")
        print(f"After pushing: gh pr create --draft --base main --head {branch}")
        return 0

    issue = json.loads(command(["gh", "issue", "view", str(args.issue),
                                "--json", "title,body,url"])["stdout"])
    folder = create_run_folder(args.issue)
    context = repository_context(issue["title"] + "\n" + (issue.get("body") or ""))
    (folder / "context.md").write_text(context, encoding="utf-8")
    spec = planner(issue["title"] + "\n" + (issue.get("body") or ""), context)
    path = folder / "spec.md"
    path.write_text(spec, encoding="utf-8")
    print(f"Review the plan: {path}")
    print(f"Then run: python automation/worker.py --issue {args.issue} "
          f"--execute --approved-spec \"{path}\"")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
