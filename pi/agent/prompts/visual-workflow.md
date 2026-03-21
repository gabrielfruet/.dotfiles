---
description: Visual-driven workflow for design and frontend work
---

# Visual Workflow - Design & Frontend Tasks

**Use this for:** UI changes, CSS, styling, responsiveness, visual debugging, design iterations

---

## Core Loop

```
Make Change → Screenshot → Verify → Feedback → Repeat
```

**Key principle:** Always verify visually after every change. Text descriptions are ambiguous.

---

## Skills to Load

Load these skills before starting:
- `playwright-cli` - for screenshots and browser automation
- `groq-vlm` - for analyzing screenshots when needed

---

## Workflow

### 1. View Before Acting

Always check the current state first:

```bash
playwright-cli open <url>
```

Take a screenshot to establish a baseline:
```bash
playwright-cli screenshot --filename=before.png
```

### 2. Make One Change at a Time

Make small, focused changes. Don't batch multiple changes together.

**Bad:** "I'll change the font, colors, spacing, and layout all at once"

**Good:** Change one thing → verify → next thing

### 3. Screenshot After Every Change

After every edit, verify visually:

```bash
playwright-cli screenshot --filename=after-edit.png
```

### 4. Use Mobile View for Responsiveness

Test responsive designs:

```bash
playwright-cli resize 375 812
playwright-cli screenshot --filename=mobile.png
```

### 5. Read the Screenshot

Read the screenshot yourself. Look for:
- Is the change applied correctly?
- Did anything else break?
- Is the spacing/alignment correct?

### 6. Iterate Based on Feedback

If user says "looks wrong" or "not what I wanted":
1. Screenshot current state
2. Show it to user
3. Ask specifically what's wrong
4. Don't assume you know what to fix

### 7. Show, Then Ask

After making a change:
> "Here's what it looks like now. Should I continue with the other changes, or adjust something?"

---

## Git Workflow

Commit after each logical unit:

```bash
git add -A && git commit -m "descriptive commit message"
```

Keep screenshots out of commits:
```bash
git rm *.png
```

---

## When Stuck

- **Unclear if change worked?** → Screenshot it
- **Not sure what user wants?** → Show current state + ask
- **Something broke?** → Screenshot the error state
- **Mobile looks wrong?** → Resize viewport and screenshot

---

## What the User Wants to Do

$@

