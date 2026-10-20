---
name: bucket-review
description: Use when the user runs /bucket-review or asks for a code review grouped by severity. Runs the code-review skill and reports its findings under five buckets — urgent, major, minor, pre-existing, code style — instead of one flat list.
argument-hint: "[target] [effort]"
---

# Bucket review

1. Run the `code-review` skill on the target and effort the user gave, and pass
   the buckets as args:

   ```text
   <user args> separate into urgent, major, minor, pre-existing, code style
   ```

   Where the runtime has no `code-review` skill, review the diff yourself.
2. Report findings under these headings, in this order, and skip empty ones:
   - **Urgent**: breaks production, loses data or opens a security hole.
   - **Major**: a real bug this change introduces.
   - **Minor**: a bug in a rare case, or a small correctness gap.
   - **Pre-existing**: a defect on the base branch that this change didn't
     cause. Report it, never fix it here.
   - **Code style**: naming, reuse, simplification. Never mixed in with bugs.
3. Set each finding's category to its bucket name when the findings go through
   a reporting tool.
