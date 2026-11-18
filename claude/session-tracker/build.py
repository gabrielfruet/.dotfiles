#!/usr/bin/env python3
"""Session juggling report: how many Claude Code tasks were in flight at once.

Reads ~/.claude/projects/*/*.jsonl transcripts, turns each human prompt into
an "engagement" interval (reading the last reply + writing the prompt), and
writes a self-contained HTML page next to the data.

Usage:
  build.py                 build the HTML page
  build.py --unclassified  print sessions with no thread yet, as JSON
  build.py --threads       print the current thread list, as JSON

Personal data (thread labels, the built page) lives in DATA_DIR, never in the
dotfiles repo, which is public.
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECTS = Path.home() / ".claude" / "projects"
DATA_DIR = Path(os.environ.get("SESSION_TRACKER_DIR", Path.home() / ".local/share/session-tracker"))
THREADS_FILE = DATA_DIR / "threads.json"
OUT_FILE = DATA_DIR / "session-tracker.html"

DAYS = 40
READ_CAP_MIN = 10  # a gap longer than this between reply and prompt counts as "away"
MIN_ENGAGE_MIN = 0.5  # every prompt costs at least 30 s of attention
FIRST_PROMPT_CHARS_PER_MIN = 300  # writing the opening prompt of a session
FIRST_PROMPT_MIN, FIRST_PROMPT_MAX = 1.0, 5.0

TICKET_RE = re.compile(r"\b([A-Z]{2,6})-(\d+)\b")  # issue-tracker IDs like ABC-123


def ts(s: str) -> float:
    return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()


def prompt_text(content) -> str:
    """Visible text of a user message, minus injected system reminders."""
    if isinstance(content, str):
        parts = [content]
    elif isinstance(content, list):
        parts = [b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text"]
    else:
        return ""
    keep = [p for p in parts if not p.lstrip().startswith("<system-reminder>")]
    text = " ".join(keep)
    text = re.sub(r"<pasted_content[^>]*>", "", text).replace("</pasted_content>", "")
    text = re.sub(r"<[^>]+>", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def is_human(d: dict) -> bool:
    origin = d.get("origin")
    if isinstance(origin, dict):
        return origin.get("kind") == "human"
    return d.get("turnOrigin") == "human"


def repo_of(cwd: str) -> str:
    cwd = (cwd or "").split("/.claude/worktrees/")[0]
    return Path(cwd).name or "~"


def parse_session(path: str, cutoff: float) -> dict | None:
    title = None
    cwd = branch = None
    prompts: list[tuple[float, str]] = []
    replies: list[float] = []
    prs: set[str] = set()
    with open(path, errors="replace") as fh:
        for line in fh:
            t = line[:40]
            if '"custom-title"' in line[:60] or '"agent-name"' in line[:60]:
                try:
                    d = json.loads(line)
                    title = d.get("customTitle") or d.get("agentName") or title
                except json.JSONDecodeError:
                    pass
                continue
            if '"pr-link"' in line[:40]:
                try:
                    prs.add(json.loads(line)["prUrl"])
                except (json.JSONDecodeError, KeyError):
                    pass
                continue
            if '"isSidechain":false' not in line and '"isSidechain": false' not in line:
                continue
            try:
                d = json.loads(line)
            except json.JSONDecodeError:
                continue
            kind = d.get("type")
            if kind not in ("user", "assistant"):
                continue
            stamp = d.get("timestamp")
            if not stamp:
                continue
            when = ts(stamp)
            cwd = cwd or d.get("cwd")
            branch = d.get("gitBranch") or branch
            if kind == "assistant":
                replies.append(when)
            elif is_human(d) and not d.get("isMeta"):
                text = prompt_text(d.get("message", {}).get("content"))
                if text:
                    prompts.append((when, text))
    prompts = [p for p in prompts if p[0] >= cutoff]
    if not prompts:
        return None
    return {
        "id": Path(path).stem,
        "title": title,
        "cwd": cwd or "",
        "repo": repo_of(cwd or ""),
        "branch": branch or "",
        "prs": sorted(prs),
        "prompts": prompts,
        "replies": sorted(replies),
    }


def engagements(s: dict) -> list[list]:
    """One [start_ms, end_ms, snippet] per human prompt."""
    out = []
    replies = s["replies"]
    prev_prompt = None
    ri = 0
    for when, text in sorted(s["prompts"]):
        while ri < len(replies) and replies[ri] < when:
            ri += 1
        last_reply = replies[ri - 1] if ri else None
        if last_reply is None or (prev_prompt is None and last_reply < when - READ_CAP_MIN * 60):
            mins = min(max(len(text) / FIRST_PROMPT_CHARS_PER_MIN, FIRST_PROMPT_MIN), FIRST_PROMPT_MAX)
            start = when - mins * 60
        else:
            start = max(last_reply, when - READ_CAP_MIN * 60)
        if prev_prompt is not None:
            start = max(start, prev_prompt)
        start = min(start, when - MIN_ENGAGE_MIN * 60)
        out.append([int(start * 1000), int(when * 1000), text[:140]])
        prev_prompt = when
    return out


def load_sessions() -> list[dict]:
    cutoff = time.time() - DAYS * 86400
    sessions = []
    for path in glob.glob(str(PROJECTS / "*" / "*.jsonl")):
        if os.path.getmtime(path) < cutoff:
            continue
        s = parse_session(path, cutoff)
        if s:
            sessions.append(s)
    return dedupe_forks(sessions)


def dedupe_forks(sessions: list[dict]) -> list[dict]:
    """A forked or /btw session copies its parent's prompts. Keep each prompt
    once, in the session with the most prompts (the parent, almost always)."""
    owner: dict[tuple, dict] = {}
    for s in sorted(sessions, key=lambda s: -len(s["prompts"])):
        for p in s["prompts"]:
            owner.setdefault((round(p[0], 3), p[1][:200]), s)
    for s in sessions:
        s["shared"] = len(s["prompts"])
        s["prompts"] = [p for p in s["prompts"] if owner[(round(p[0], 3), p[1][:200])] is s]
        s["shared"] -= len(s["prompts"])
    return [s for s in sessions if s["prompts"]]


def load_threads() -> dict:
    if THREADS_FILE.exists():
        return json.loads(THREADS_FILE.read_text())
    return {"threads": {}, "sessions": {}}


def fallback_thread(s: dict) -> tuple[str, str]:
    """Deterministic grouping when Claude has not labelled a session yet."""
    m = TICKET_RE.search(f"{s['title'] or ''} {s['branch']}")
    if m:
        key = f"{m.group(1).upper()}-{m.group(2)}"
        return f"ticket:{key}", s["title"] or key
    return f"session:{s['id']}", s["title"] or s["prompts"][0][1][:60]


def cmd_unclassified(sessions: list[dict], threads: dict) -> None:
    rows = []
    for s in sorted(sessions, key=lambda s: s["prompts"][0][0]):
        if s["id"] in threads["sessions"]:
            continue
        rows.append({
            "id": s["id"],
            "title": s["title"],
            "repo": s["repo"],
            "branch": s["branch"],
            "start": datetime.fromtimestamp(s["prompts"][0][0]).strftime("%m-%d %H:%M"),
            "prompts": len(s["prompts"]),
            "first": s["prompts"][0][1][:160],
        })
    json.dump(rows, sys.stdout, indent=1, ensure_ascii=False)
    print()


def build(sessions: list[dict], threads: dict) -> None:
    out_threads: dict[str, dict] = {}
    out_sessions = []
    for s in sessions:
        tid = threads["sessions"].get(s["id"])
        if tid and tid in threads["threads"]:
            name = threads["threads"][tid]["name"]
            kind = threads["threads"][tid].get("kind", "")
            labelled = True
        else:
            tid, name = fallback_thread(s)
            kind, labelled = "", False
        out_threads.setdefault(tid, {"id": tid, "name": name, "kind": kind, "repo": s["repo"], "labelled": labelled})
        out_sessions.append({
            "id": s["id"],
            "thread": tid,
            "title": s["title"] or s["prompts"][0][1][:60],
            "repo": s["repo"],
            "branch": s["branch"],
            "prs": s["prs"],
            "engage": engagements(s),
        })
    data = {
        "generatedAt": int(time.time() * 1000),
        "days": DAYS,
        "readCapMin": READ_CAP_MIN,
        "threads": list(out_threads.values()),
        "sessions": out_sessions,
    }
    template = (HERE / "template.html").read_text()
    blob = json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    html = template.replace("/*__DATA__*/null", blob)
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    OUT_FILE.write_text(html)
    unl = sum(1 for t in out_threads.values() if not t["labelled"])
    n_prompts = sum(len(s["engage"]) for s in out_sessions)
    print(f"wrote {OUT_FILE}: {len(out_sessions)} sessions, {len(out_threads)} threads "
          f"({unl} unlabelled), {n_prompts} prompts")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--unclassified", action="store_true")
    ap.add_argument("--threads", action="store_true")
    args = ap.parse_args()
    threads = load_threads()
    if args.threads:
        json.dump(threads["threads"], sys.stdout, indent=1, ensure_ascii=False)
        print()
        return
    sessions = load_sessions()
    if args.unclassified:
        cmd_unclassified(sessions, threads)
    else:
        build(sessions, threads)


if __name__ == "__main__":
    main()
