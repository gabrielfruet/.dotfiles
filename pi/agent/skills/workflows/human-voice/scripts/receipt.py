#!/usr/bin/env python3
"""Print the human-voice receipt for a draft, then the channel's rules.

Usage: receipt.py <channel> [--before old.md] [--voice samples.md] < draft.md

samples.md holds 2-3 of the user's own messages from the target channel or
thread, separated by lines containing only `---`. Channels whose config block
says `voice: required` exit 1 without it.
"""

import argparse
import re
import sys
from pathlib import Path

CHANNELS = Path(__file__).resolve().parent.parent / "references" / "channels"
SKIPPED_SECTIONS = {"Example", "Allowed here"}


def is_mixed(sentence: str) -> bool:
    """True when a sentence weaves code into prose (rule in ai-facing.md)."""
    spans = re.findall(r"`([^`]+)`", sentence)
    return (
        len(spans) >= 3
        or any(len(span) > 30 for span in spans)
        or any(c in span for span in spans for c in "/(→")
    )


def max_words(channel_text: str) -> str:
    match = re.search(r"^max_words:\s*(\S+)", channel_text, re.MULTILINE)
    return match.group(1) if match else "none"


def sentences(draft: str) -> list[str]:
    prose = re.sub(r"^```.*?^```", "", draft, flags=re.MULTILINE | re.DOTALL)
    parts = re.split(r"(?<=[.!?])\s+|\n\s*\n|\n\s*[-*\d]+[.)]?\s", prose)
    return [p.strip() for p in parts if p.strip()]


def voice_required(channel_text: str) -> bool:
    return re.search(r"^voice:\s*required", channel_text, re.MULTILINE) is not None


def short(text: str, limit: int = 80) -> str:
    text = " ".join(text.split())
    return text if len(text) <= limit else text[: limit - 1] + "…"


def ends(text: str) -> tuple[str, str]:
    parts = sentences(text)
    return (short(parts[0]), short(parts[-1])) if parts else ("", "")


def voice_report(samples_text: str, draft: str) -> tuple[str, str]:
    """Return the receipt's voice field and the opener/closer comparison."""
    samples = [s.strip() for s in re.split(r"^---\s*$", samples_text, flags=re.MULTILINE)]
    samples = [s for s in samples if s]
    if not samples:
        return 'voice: MISSING', ""
    draft_open, draft_close = ends(draft)
    lines = []
    for label, index, draft_end in (("opener", 0, draft_open), ("closer", 1, draft_close)):
        for n, sample in enumerate(samples):
            lines.append(f"{label if n == 0 else '':7} you:   {ends(sample)[index]}")
        lines.append(f"{'':7} draft: {draft_end}")
    return f'voice: "{ends(samples[0])[0]}"', "\n".join(lines)


def rule_sections(channel_text: str) -> str:
    sections = re.split(r"^(?=## )", channel_text, flags=re.MULTILINE)
    keep = [s for s in sections[1:] if s.split("\n", 1)[0][3:].strip() not in SKIPPED_SECTIONS]
    return "".join(keep).strip()


def main() -> None:
    parser = argparse.ArgumentParser(usage=__doc__)
    parser.add_argument("channel")
    parser.add_argument("--before", type=Path)
    parser.add_argument("--voice", type=Path)
    args = parser.parse_args()
    channel = args.channel
    path = CHANNELS / f"{channel}.md"
    if not path.exists():
        names = ", ".join(sorted(p.stem for p in CHANNELS.glob("*.md")))
        sys.exit(f"unknown channel {channel!r}; one of: {names}")

    draft = sys.stdin.read()
    channel_text = path.read_text()
    words = str(len(draft.split()))
    if args.before is not None:
        words = f"{len(args.before.read_text().split())} → {words}"
    mixed = sum(is_mixed(s) for s in sentences(draft))

    receipt = f"channel: {channel} | {words}/{max_words(channel_text)} words | mixed {mixed}"
    comparison = ""
    missing = False
    if args.voice is not None:
        field, comparison = voice_report(args.voice.read_text(), draft)
        receipt += f" | {field}"
        missing = field == "voice: MISSING"
    elif voice_required(channel_text):
        receipt += " | voice: MISSING"
        missing = True

    print(receipt)
    if comparison:
        print()
        print(comparison)
        print("\nRewrite until each draft line could have come from the same person.")
    if missing:
        print("\nFetch 2-3 of the user's own messages in the target channel or thread,")
        print("save them to a file separated by --- lines, and rerun with --voice.")
    print()
    print(rule_sections(channel_text))
    if missing:
        sys.exit(1)


if __name__ == "__main__":
    main()
