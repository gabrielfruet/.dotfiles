# Patterns

Constructions rather than words, each with the rewrite. `blocklist.md` is the
phrase list; this is what to do once you spot one. The last two sections are the
important half: they stop the rewrite gutting prose that was fine.

Fragments and em dashes are deliberately absent. Both are decided per channel,
in `channels/*.md`, because the answer differs by register.

## Copula avoidance

Elaborate constructions substituted for a plain "is" or "has".

> Gallery 825 serves as LAAA's exhibition space. The gallery features four
> separate spaces and boasts over 3,000 square feet.

> Gallery 825 is LAAA's exhibition space. It has four rooms totaling 3,000
> square feet.

## Negative parallelism and tailing negation

"Not only... but...", "It's not just about... it's...", plus clipped negations
tacked onto the end instead of written as a real clause.

> It's not just about the beat riding under the vocals; it's part of the
> aggression. The options come from the selected item, no guessing.

> The heavy beat adds to the aggressive tone. The options come from the selected
> item, so the user doesn't have to guess.

## Rule of three

Ideas forced into groups of three to look comprehensive. Use two. Use five. Use
one and stop.

> The event features keynote sessions, panel discussions, and networking
> opportunities. Attendees can expect innovation, inspiration, and insight.

> The event includes talks and panels, with time for informal networking between
> sessions.

## Elegant variation

Repetition penalties produce synonym cycling.

> The protagonist faces many challenges. The main character must overcome
> obstacles. The central figure eventually triumphs. The hero returns home.

> The protagonist faces many challenges but eventually triumphs and returns home.

## False ranges

"From X to Y" where X and Y aren't on a shared scale.

> Our journey has taken us from the singularity of the Big Bang to the grand
> cosmic web, from the birth of stars to the dance of dark matter.

> The book covers the Big Bang, star formation, and current theories about dark
> matter.

## Inline-header vertical lists

Every bullet opening with a bolded header and a colon.

> - **User Experience:** significantly improved with a new interface.
> - **Performance:** enhanced through optimized algorithms.
> - **Security:** strengthened with end-to-end encryption.

> The update improves the interface, speeds up load times, and adds end-to-end
> encryption.

## Fragmented headers

A heading, then a one-line paragraph restating the heading, then the real content.

> ## Performance
>
> Speed matters.
>
> When users hit a slow page, they leave.

> ## Performance
>
> When users hit a slow page, they leave.

## Manufactured punchlines

Every sentence landing like a quotable closer, short fragments stacked to
manufacture drama. One short sentence for emphasis is fine; a run of them sounds
engineered.

> Then AlphaEvolve arrived. It had no preference for symmetry. No aesthetic
> prior. No nostalgia for human taste. The old rules were gone.

> AlphaEvolve changed the search because it did not favor symmetry or
> human-looking designs. That made some older assumptions less useful.

## Aphorism formulas

Ordinary claims turned into reusable aphorisms that sound profound without adding
precision. Replace the formula with the concrete claim it gestures at.

> Symmetry is the language of trust. Efficiency becomes a trap when teams forget
> the human layer.

> Symmetric layouts often feel more predictable to users. Teams can over-optimize
> workflows and miss how people actually use them.

## Speculative gap-filling

When a model can't find a source it writes a paragraph about not finding one,
then invents plausible filler to cover the gap.

> Information about her early life is not publicly available, suggesting she
> maintains a low profile. She likely grew up in a middle-class household, which
> shaped her later interest in education reform.

> Her early life is not documented in the available sources. (Or omit the section.)

## Diff-anchored writing

Docs or comments narrating a change rather than describing the thing as it is.
Unless the document is version-scoped, it should read coherently without knowing
what changed last commit.

> This function was added to replace the previous approach of iterating through
> all items, which caused O(n²) performance.

> This function uses a hash map for O(1) lookups, avoiding the O(n²) cost of
> naive iteration.

## Surface tells

Cheap to fix, only meaningful in clusters: Title Case In Headings, emoji as
section markers, curly quotes where the rest of the document uses straight ones,
boldface applied mechanically to phrases mid-sentence.

## What NOT to flag

A clean human writer hits several of the patterns above with no AI involved.
None of these is a reliable indicator on its own:

- **Perfect grammar and consistent style.** Polish is not AI. Many writers are
  professionals, or have been edited.
- **Mixed casual and formal registers.** Usually signals someone technical, or a
  young writer, not a chatbot.
- **Bland or robotic prose.** AI prose has *specific* tells. Generic dryness
  without them is just dry writing.
- **Formal or academic vocabulary.** AI overuses specific fancy words, not all
  fancy words. Don't flatten "ostensibly" because it sounds brainy.
- **Common transitions in isolation.** One "however" is not a tell.
- **Curly quotes alone.** macOS, Word and most editors auto-curl by default.
- **Em dashes alone.** Journalists use them constantly. Evidence only when paired
  with formulaic sales-y rhythm.
- **One short emphatic sentence.** Flag staccato drama only when several land in
  a row and inflate the tone.
- **Unsourced claims.** Most writing is unsourced.
- **Secondhand text.** Never rewrite a watched phrase inside a quotation, title,
  proper name, or an example where the phrase is being discussed rather than used.

## Signs of human writing

Leave these alone. Over-editing destroys exactly what makes a piece sound human:

- **Specific, hard-to-fabricate detail.** A real address, a weird quote, "the
  lawyer who used to work upstairs from my dentist." Models round off specifics;
  people hoard them.
- **Mixed feelings and unresolved tension.** "I think this is mostly good, but it
  bothers me and I can't say why." Models default to clean takes.
- **Dated, era-bound references.** Slang and in-jokes that map to a specific year.
- **Editorial choices the writer can defend.** If there's a reason for the cut,
  that's a strong human signal.
- **Variety in sentence length.**
- **Genuine asides and self-corrections.** "(I keep wanting to say 'almost' here,
  but it really was certain.)" Models rarely interrupt themselves.

---

Adapted from [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing),
maintained by WikiProject AI Cleanup. Original skill packaging MIT licensed.
