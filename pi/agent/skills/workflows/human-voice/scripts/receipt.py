#!/usr/bin/env python3
"""Print the human-voice receipt for a draft, then the channel's rules.

Usage: receipt.py <channel> < draft.md
"""

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


def rule_sections(channel_text: str) -> str:
    sections = re.split(r"^(?=## )", channel_text, flags=re.MULTILINE)
    keep = [s for s in sections[1:] if s.split("\n", 1)[0][3:].strip() not in SKIPPED_SECTIONS]
    return "".join(keep).strip()


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    channel = sys.argv[1]
    path = CHANNELS / f"{channel}.md"
    if not path.exists():
        names = ", ".join(sorted(p.stem for p in CHANNELS.glob("*.md")))
        sys.exit(f"unknown channel {channel!r}; one of: {names}")

    draft = sys.stdin.read()
    channel_text = path.read_text()
    words = len(draft.split())
    mixed = sum(is_mixed(s) for s in sentences(draft))

    print(f"channel: {channel} | {words}/{max_words(channel_text)} words | mixed {mixed}")
    print()
    print(rule_sections(channel_text))


if __name__ == "__main__":
    main()
