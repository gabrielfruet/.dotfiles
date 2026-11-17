# Lightly Linear

How Gabriel plans LightlyStudio work in Linear. This file holds the rules; the `linear-cli` skill holds the commands.

## Where things live

- Team: Studio Product, key `STU`. Older Studio issues still sit in `LIG` (Engineering-All).
- Cycles run two weeks. Each has a doc "Preplanning Cycle Studio Product N", attached to the STU cycle. Gabriel's input is the `**Gabriel**` section under Team Input.
- Backlog: the doc "Gabriel's Studio backlog" (`e16c361ae161`), under the STU team. Linear has no private docs; it is unlisted, not hidden.
- Customers: Linear customer requests on the issue.
- Never assign issues to Gabriel to track them. Tracking happens in the backlog doc.

## Customer requests

- An issue that comes from a customer gets a customer request on creation,
  including issues the Linear Slack bot creates. Add it right after the bot replies.
- Body: one line on what the customer hit. Source: the Slack thread or call link.
- Mark it important when the customer is blocked.
- Find the customer with `list_customers`. If it's missing, ask Gabriel, then create it.
- Link the parent only; sub-issues inherit through it.
- Internal work for a customer (instance updates, demo prep) gets none.

## Preplanning section

- First line states capacity and the listed total. Capacity comes from the doc's Capacity line.
- Group by budget, then theme. Take the budgets from the doc's Pre-planning list for that cycle; they change between cycles. Each budget header carries its total.
- Themes follow the issues, not a fixed list. Reuse the headings already in the section, add one when an issue fits none, and drop one that empties.
- One line per issue: P level, link, ED, optional note. See the formats below.
- A customer is a note on the line (`customer: First Solar`), never a budget. Enterprise means enterprise-product work, not customer requests.
- Only issues Gabriel owns or tracks go here.

```markdown
Capacity 8ED. Listed 47ED.

* Roadmap \[33ED\]
  * Embeddings and embedding plot
    * P0 [LIG-11567](https://linear.app/lightly/issue/LIG-11567) 1ED, customer: First Solar
    * P1 [LIG-11482](https://linear.app/lightly/issue/LIG-11482) 2ED, covers LIG-10637 and LIG-11132
  * Getting data in
    * P2 [STU-12](https://linear.app/lightly/issue/STU-12) 4.5ED (STU-14 1, STU-15 2, STU-16 1, STU-17 0.5)
```

## Backlog doc

- Sections: Now, Next, Later, Dropped. Gabriel decides the order; never move an issue between sections without asking.
- Inside a section, group by theme. Line format as in preplanning, then `: note`.
- Notes are Gabriel's opinions. Add only verified facts (likely fixed, rescoped, merged), never a judgement.
- An issue added to the preplanning section also goes into Next.
- Dropped lists the ID and why: a date, or the issue it merged into.

## Estimates

- Unit: ED (engineer day). Docs keep halves, like 0.5ED.
- Linear takes whole points on STU and LIG. Round 0.5 up to 1.
- A parent whose sub-issues have estimates gets 0. The doc shows the sum with the breakdown, as STU-12 above.
- Propose each estimate with a one-line basis. Write nothing until Gabriel approves; for a batch, show an editable widget.
- Before estimating a bug, check git log for a fix that landed after the report.

## Priority

- The doc's P level wins. Linear follows: P0 Urgent, P1 High, P2 Medium, P3 Low.

## Merging duplicates

1. Keep the issue that has the design or the owner.
2. Mark the others `duplicate` of it. Linear moves them to Duplicate and notifies their owners.
3. Move their blocking links to the kept issue. Linear keeps one link per pair, so a new link replaces an old one.
4. Append a "Merged issues" section to the kept issue: each duplicate, what covers it, the gaps, and its acceptance criteria. Append; never rewrite the owner's text.
5. In docs, one line for the kept issue that names the duplicates, as LIG-11482 above.

## Writing to Linear docs

- The API replaces the whole doc. Re-read the live content right before writing, and build the new version from it.
- Change only Gabriel's section. Diff everything outside it against the live copy; it must be identical.
- Ask Gabriel to close the doc first. An open editor can write its older copy back.
- Re-read about 20 seconds after writing.
- Save a local copy in the repo's preplanning folder under .experimental before the first edit of a session.
- Every doc needs a parent, and the CLI cannot create one under a team. Call the `documentCreate` mutation with the team ID through `linear api`.

## Ask first

- Any change to someone else's issue: assignee, priority, description. Name the owner when asking.
