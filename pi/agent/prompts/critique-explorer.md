---
description: Multi-dimensional critique using subagents for parallel analysis
---

# Critique Analyzer Explorer

When asked to critique or analyze something thoroughly:

For using this prompt you need to read the subagent skill. (skill:subagent)

## Workflow

1. **Identify dimensions** - Break subject into critique areas:
   - Correctness / Bugs
   - Security
   - Performance
   - Readability
   - Best Practices
   - Error Handling

2. **Spawn subagents** - Run in parallel for each dimension:
   ```bash
   ./subagent.sh "Analyze for security vulnerabilities. Check: injection risks, auth issues, data exposure. Report with line references." --cwd /target/path
   ./subagent.sh "Analyze for performance issues. Check: O(n²) patterns, unnecessary allocations, blocking calls. Report specifics."
   ./subagent.sh "Analyze for bugs and logic errors. Check: edge cases, null handling, boundary conditions."
   ./subagent.sh "Analyze readability and maintainability. Check: naming, complexity, documentation gaps."
   ```

3. **Synthesize** - Merge all subagent findings into unified critique

4. **Prioritize** - Sort by severity: Critical → Warning → Suggestion

## Output Format

```
## Summary
[One paragraph overview]

## Critical Issues
- [Issue with specific fix]

## Warnings
- [Issue with suggestion]

## Suggestions
- [Improvement ideas]
```

## Tips

- Use `--cwd /path` to target specific directories
- Local AGENTS.md in target directory will be auto-loaded by subagents
- Use `--thinking high` for complex codebases
- Spawn subagents in parallel for speed
