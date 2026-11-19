#!/usr/bin/env python3
"""Session juggling report: how many Claude Code tasks were in flight at once.

Reads ~/.claude/projects/*/*.jsonl transcripts, turns each human prompt into
an "engagement" interval (reading the last reply + writing the prompt), and
writes a self-contained HTML page next to the data.

Usage:
  build.py                   build the HTML page (embeds DATA_DIR/summary.json)
  build.py --unclassified    print sessions with no thread yet, as JSON
  build.py --threads         print the current thread list, as JSON
  build.py --stats [DAY]     print one day's numbers for Claude to judge, as JSON
  build.py --notes [DAY]     print the Scratchpad and Tomorrow sections of that
                             day's daily note and the one before it
  build.py --checkin TEXT    add Claude's check-in question to today's daily note

DAY is YYYY-MM-DD and defaults to the latest day with sessions.

Personal data (thread labels, the summary, the built page) lives in DATA_DIR,
never in the dotfiles repo, which is public.
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
SUMMARY_FILE = DATA_DIR / "summary.json"  # written by Claude at each check-in
VAULT = Path(os.environ.get("SESSION_TRACKER_VAULT", Path.home() / "docs/zettelkasten"))
DAILY_NOTE = "60 - Planning/{day}.md"
NOTE_SECTIONS = ("Scratchpad", "Tomorrow")
CHECKIN_MARK = "🤖 Check-in:"

DAYS = 40
READ_CAP_MIN = 10  # a gap longer than this between reply and prompt counts as "away"
MIN_ENGAGE_MIN = 0.5  # every prompt costs at least 30 s of attention
FIRST_PROMPT_CHARS_PER_MIN = 300  # writing the opening prompt of a session
FIRST_PROMPT_MIN, FIRST_PROMPT_MAX = 1.0, 5.0

WINDOW_MIN, LIMIT = 30, 3  # what the Summary tab and --stats use

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


def area_by_repo(repo: str, threads: dict) -> str:
    """"work" when the repo matches a prefix in threads.json's workRepoPrefixes.
    A thread's own "area" overrides this for work done outside those repos."""
    prefixes = threads.get("workRepoPrefixes", [])
    return "work" if any(repo.startswith(p) for p in prefixes) else "other"


def resolve(sessions: list[dict], threads: dict) -> tuple[dict, list[dict]]:
    """Attach a thread to every session: Claude's label, or the fallback."""
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
        area = threads["threads"].get(tid, {}).get("area") or area_by_repo(s["repo"], threads)
        out_threads.setdefault(tid, {"id": tid, "name": name, "kind": kind, "area": area,
                                     "repo": s["repo"], "labelled": labelled})
        out_sessions.append({
            "id": s["id"],
            "thread": tid,
            "title": s["title"] or s["prompts"][0][1][:60],
            "repo": s["repo"],
            "branch": s["branch"],
            "prs": s["prs"],
            "engage": engagements(s),
        })
    return out_threads, out_sessions


def build(sessions: list[dict], threads: dict) -> None:
    out_threads, out_sessions = resolve(sessions, threads)
    summary = json.loads(SUMMARY_FILE.read_text()) if SUMMARY_FILE.exists() else None
    data = {
        "generatedAt": int(time.time() * 1000),
        "days": DAYS,
        "readCapMin": READ_CAP_MIN,
        "threads": list(out_threads.values()),
        "sessions": out_sessions,
        "summary": summary,
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


def by_day(out_sessions: list[dict]) -> dict[str, list[tuple[float, float, str]]]:
    """Engagements as (start_min, end_min, thread) per local day, in prompt order."""
    days: dict[str, list] = {}
    for s in out_sessions:
        for a, b, _ in s["engage"]:
            end = datetime.fromtimestamp(b / 1000)
            t0 = end.replace(hour=0, minute=0, second=0, microsecond=0).timestamp() * 1000
            days.setdefault(end.strftime("%Y-%m-%d"), []).append(((a - t0) / 60000, (b - t0) / 60000, s["thread"]))
    for evs in days.values():
        evs.sort(key=lambda e: e[1])
    return days


def day_stats(evs: list, names: dict, areas: dict, win: int = WINDOW_MIN, limit: int = LIMIT) -> dict:
    """Mirror of computeDay() in template.html, plus what Claude needs to write."""
    n = 1440
    order: list[str] = []
    cov: dict[str, bytearray] = {}
    end: dict[str, int] = {}  # last minute of the task's last prompt that day: no window tail after it
    for a, b, t in evs:
        if t not in cov:
            cov[t] = bytearray(n)
            order.append(t)
        m0, m1 = max(0, int(a // 1)), min(n, -int(-b // 1))
        m_end = max(m1, m0 + 1)
        for m in range(m0, m_end):
            cov[t][m] = 1
        end[t] = max(end.get(t, 0), m_end - 1)
    count, engaged, last = [0] * n, [0] * n, {}
    minutes = dict.fromkeys(order, 0.0)
    for m in range(n):
        here = [t for t in order if cov[t][m]]
        for t in here:
            last[t] = m
        count[m] = sum(1 for t in order if t in last and m - last[t] < win and m <= end[t])
        engaged[m] = 1 if here else 0
        for t in here:
            minutes[t] += 1 / len(here)
    eng = [m for m in range(n) if engaged[m]]
    levels = [0] * 5
    for m in eng:
        levels[min(max(count[m], 1), 5) - 1] += 1
    over = sum(1 for m in eng if count[m] > limit)
    runs, start = [], None  # stretches of engaged-day time above the limit
    for m in range((eng[0] if eng else 0), (eng[-1] + 2 if eng else 0)):
        above = count[m] > limit if m < n else False
        if above and start is None:
            start = m
        elif not above and start is not None:
            if m - start >= 5:
                runs.append({"from": f"{start // 60:02d}:{start % 60:02d}", "to": f"{m // 60:02d}:{m % 60:02d}",
                             "peak": max(count[start:m]),
                             "tasks": sorted({names[t] for a, b, t in evs if b >= start - win and a <= m and end[t] >= start})})
            start = None
    visits = dict.fromkeys(order, 0)
    hops, prev, last_end, returns = 0, None, {}, []
    for i, (a, b, t) in enumerate(evs):
        if t != prev:
            visits[t] += 1
            if prev is not None:
                hops += 1
            if t in last_end:
                j, end = last_end[t]
                returns.append((a - end, len({x[2] for x in evs[j + 1:i]})))
        last_end[t] = (i, b)
        prev = t
    area_min: dict[str, float] = {"work": 0.0, "other": 0.0}
    for t in order:
        area_min[areas[t]] += minutes[t]
    share = over / len(eng) if eng else 0
    verdict = "Within your limit" if share < 0.15 else "Some extra juggling" if share < 0.35 else "Hopped too much"
    med = lambda xs: sorted(xs)[len(xs) // 2] if xs else None
    return {
        "engagedMin": len(eng), "tasks": len(order), "hops": hops, "peak": max(count) if eng else 0,
        "overMin": over, "overShare": round(share, 3), "verdict": verdict,
        "areaMin": {k: round(v) for k, v in area_min.items()},
        "levelsMin": {f"{i + 1}{'+' if i == 4 else ''}": v for i, v in enumerate(levels)},
        "firstPrompt": f"{eng[0] // 60:02d}:{eng[0] % 60:02d}" if eng else None,
        "lastPrompt": f"{eng[-1] // 60:02d}:{eng[-1] % 60:02d}" if eng else None,
        "overRuns": runs,
        "returns": {"count": len(returns), "medianGapMin": med([round(g) for g, _ in returns]),
                    "medianOtherTasksBetween": med([k for _, k in returns])},
        "perTask": sorted(({"name": names[t], "area": areas[t], "min": round(minutes[t]), "visits": visits[t],
                            "from": f"{int(min(a for a, _, x in evs if x == t)) // 60:02d}:{int(min(a for a, _, x in evs if x == t)) % 60:02d}"}
                           for t in order), key=lambda r: -r["min"]),
    }


def cmd_stats(sessions: list[dict], threads: dict, day: str | None) -> None:
    out_threads, out_sessions = resolve(sessions, threads)
    names = {t: v["name"] for t, v in out_threads.items()}
    areas = {t: v["area"] for t, v in out_threads.items()}
    days = by_day(out_sessions)
    day = day or max(days)
    recent = sorted(k for k in days if k < day)[-6:]
    out = {"day": day, "window": WINDOW_MIN, "limit": LIMIT, **day_stats(days.get(day, []), names, areas),
           "previousDays": [{"day": k, "overShare": (st := day_stats(days[k], names, areas))["overShare"],
                             "engagedMin": st["engagedMin"], "hops": st["hops"]} for k in recent]}
    json.dump(out, sys.stdout, indent=1, ensure_ascii=False)
    print()


def note_path(day: str) -> Path:
    return VAULT / DAILY_NOTE.format(day=day)


def note_sections(text: str) -> dict[str, str]:
    """The level-2 sections named in NOTE_SECTIONS, keyed by that name."""
    out, cur = {}, None
    for line in text.splitlines():
        if line.startswith("## "):
            cur = next((s for s in NOTE_SECTIONS if s.lower() in line.lower()), None)
            if cur:
                out[cur] = ""
            continue
        if cur:
            out[cur] += line + "\n"
    return {k: v.strip() for k, v in out.items()}


def cmd_notes(day: str | None) -> None:
    day = day or datetime.now().strftime("%Y-%m-%d")
    notes = sorted(p.stem for p in note_path("x").parent.glob("*.md") if p.stem <= day)[-2:]
    out = {n: note_sections(note_path(n).read_text()) for n in notes}
    json.dump(out, sys.stdout, indent=1, ensure_ascii=False)
    print()


def insert_checkin(note: str, line: str) -> str:
    """Return the note with Claude's check-in line placed in it.

    `line` already starts with CHECKIN_MARK. It goes under "## Tomorrow", which
    is what the user reads when planning the next morning. A second run
    replaces the earlier check-in instead of stacking another one.
    """
    bullet = f"- {line}"
    lines = note.splitlines()
    trail = "\n" if note.endswith("\n") else ""
    for i, ln in enumerate(lines):
        if CHECKIN_MARK in ln:
            lines[i] = bullet
            return "\n".join(lines) + trail
    head = next((i for i, ln in enumerate(lines) if ln.startswith("## ") and "tomorrow" in ln.lower()), None)
    if head is None:
        return note.rstrip("\n") + f"\n\n## Tomorrow\n\n{bullet}\n"
    end = next((i for i in range(head + 1, len(lines)) if lines[i].startswith("## ")), len(lines))
    empty = next((i for i in range(head + 1, end) if lines[i].strip() == "-"), None)
    if empty is not None:  # the template's placeholder bullet
        lines[empty] = bullet
    else:
        last = max((i for i in range(head + 1, end) if lines[i].strip()), default=head)
        lines.insert(last + 1, bullet)
    return "\n".join(lines) + trail


def cmd_checkin(text: str) -> None:
    path = note_path(datetime.now().strftime("%Y-%m-%d"))
    if not path.exists():
        sys.exit(f"no daily note at {path}; skipping check-in")
    path.write_text(insert_checkin(path.read_text(), f"{CHECKIN_MARK} {text.strip()}"))
    print(f"check-in written to {path}")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--unclassified", action="store_true")
    ap.add_argument("--threads", action="store_true")
    ap.add_argument("--stats", nargs="?", const="", metavar="DAY")
    ap.add_argument("--notes", nargs="?", const="", metavar="DAY")
    ap.add_argument("--checkin", metavar="TEXT")
    args = ap.parse_args()
    if args.notes is not None:
        cmd_notes(args.notes or None)
        return
    if args.checkin:
        cmd_checkin(args.checkin)
        return
    threads = load_threads()
    if args.threads:
        json.dump(threads["threads"], sys.stdout, indent=1, ensure_ascii=False)
        print()
        return
    sessions = load_sessions()
    if args.unclassified:
        cmd_unclassified(sessions, threads)
    elif args.stats is not None:
        cmd_stats(sessions, threads, args.stats or None)
    else:
        build(sessions, threads)


if __name__ == "__main__":
    main()
