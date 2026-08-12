# Blocklist

The phrase-level list. Read it during the rewrite pass; append to it as new tics
show up.

A phrase being here doesn't make it wrong in isolation. It makes it load-bearing
evidence that a machine wrote the sentence, because these appear at rates far
above baseline human usage. When one shows up, rewrite the sentence rather than
swapping the word. Look for clusters: a single em dash means nothing, but em
dashes plus rule-of-three plus "vibrant tapestry" plus a Conclusion section is a
confession.

`patterns.md` covers what *not* to flag. Check it before acting on anything here.

## Constructions

Highest signal. These are patterns, not words, and they survive vocabulary
substitution.

- "It's not just X, it's Y", and every variant: "isn't merely", "goes beyond",
  "more than just"
- "X isn't about A. It's about B." Negation-then-affirmation generally.
- "Not only... but also"
- "Think of it as...", "Imagine a world where..."
- "At its core, X is...", "Fundamentally, this comes down to...", "In reality",
  "What really matters", "The deeper issue", "The heart of the matter"
- "The key insight here is...", "The real question is...", "Here's the thing:"
- "That said," as a paragraph opener
- "Whether you're a X or a Y..."
- "In today's fast-paced world", and all "in today's ___" openers
- Rhetorical question followed immediately by its answer
- Em dash used for dramatic reveal more than once per piece
- Aphorism formulas: "X is the Y of Z", "X becomes a trap", "X is not a tool but
  a mirror", "the language of", "the currency of", "the architecture of"

## Words

Corporate and AI vocabulary that clusters in generated text:

leverage (verb), delve, dive into, deep dive, unpack, robust, seamless,
seamlessly, landscape (metaphorical), realm, tapestry, journey (metaphorical),
navigate (metaphorical), foster, fostering, harness, elevate, unlock, empower,
streamline, holistic, nuanced, multifaceted, myriad, plethora, pivotal, crucial,
vital, paramount, testament, cornerstone, game-changer, transformative,
cutting-edge, state-of-the-art, best-in-class, ecosystem (non-biological),
synergy, actionable, granular, bespoke, curated, meticulously, intricate,
intricacies, underscore, illuminate, resonate, embark, garner, interplay,
enduring, enhance, align with, highlight (verb), showcase, key (adjective),
valuable, additionally

Promotional and significance inflation:

boasts a, vibrant, rich (figurative), profound, enhancing its, exemplifies,
commitment to, natural beauty, nestled, in the heart of, groundbreaking
(figurative), renowned, breathtaking, must-visit, stunning, stands as, serves as,
is a testament to, a vital/crucial/pivotal role, underscores its importance,
reflects broader, symbolizing its ongoing, contributing to the, setting the stage
for, marks a shift, key turning point, evolving landscape, focal point, indelible
mark, deeply rooted

Intensifier-hedges that add nothing:

truly, incredibly, remarkably, notably, significantly, fundamentally, essentially,
arguably, quite possibly, it's worth noting that, it's important to remember that

## Openers and closers

- "Great question!", "Absolutely!", "Certainly!", "Of course!", "You're
  absolutely right!"
- "I hope this helps", "Let me know if you have any questions", "Feel free to
  reach out", "Would you like...", "Want me to...?", "Should I continue?"
- "Let's break this down", "Let's explore", "Let's dive in", "Here's what you
  need to know", "Now let's look at", "Without further ado"
- "Honestly?", "Look,", "Here's the thing", "The thing is", "Let's be honest",
  "Real talk" — as standalone theatrical hooks. Mid-sentence they are ordinary.
- "In conclusion", "To sum up", "Ultimately", "At the end of the day", "The
  bottom line is..."
- Any final paragraph beginning "Overall," or "In summary,"

## Vague attribution

Industry reports, Observers have cited, Experts argue, Some critics argue,
several sources/publications when few are cited. If a real source exists, name
it. Never invent one; an unsupported claim gets cut, not decorated.

## Gap-filling and cutoff disclaimers

as of [date], up to my last training update, while specific details are
limited/scarce, based on available information, not publicly available, maintains
a low profile, keeps personal details private, likely [grew up/studied/began], it
is believed that

Two tells in one: the model writes a paragraph *about* not finding a source, then
invents plausible filler to cover the gap. Say what isn't known, or cut the
sentence.

## Hyphenated pairs

third-party, cross-functional, client-facing, data-driven, decision-making,
well-known, high-quality, real-time, long-term, end-to-end

Not banned, but hyphenated uniformly is a tell. Keep the hyphen when the compound
is attributive (`a high-quality report`), drop it when it follows the noun (`the
report is high quality`).

## Structural markers

- Bold lead-in on every bullet: `**Item:**` then explanation, repeated down the list
- Every bullet the same length
- Emoji as section markers, unless the register genuinely calls for it
- Header on a section shorter than two paragraphs
- Numbered list where the numbers don't mean sequence
- Title Case In Headings

## Softeners to delete outright

- "somewhat", "fairly", "rather", "a bit" when hedging a claim the writer is
  confident about
- "I think" / "in my view" stacked on an already-qualified statement
- "may or may not", "can vary depending on", "there are pros and cons to both"
- Any sentence whose only function is to acknowledge that other views exist

## Additions

Append below with a date. Keep the reason short; future-you needs to know why it
was flagged.
