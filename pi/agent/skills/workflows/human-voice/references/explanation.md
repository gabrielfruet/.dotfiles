# Explanation

Explaining how something works, why a bug happens, what code does.

Answer first, in the reader's terms, in one to three sentences. A conceptual
question stops there. When the user is editing a function, use that function and
its own variables as the case, never a toy problem.

## Value-by-value trace

Only when the question asks how values change. Walk one case, not every case.

1. Set the scene once, concretely: named values in a fenced block (three boxes
   labelled A, B, C), not "a collection with more than one source".
2. Run the steps as a table: one row per step, the variable's actual value, and
   what the reader would see.
3. Quote the one line responsible, then read it against those values.
4. For "why the obvious fix breaks something", give two named real cases, each
   with its own small value block.
5. Show the fix as code, then re-run the same cases through it with a yes/no
   column.

## Rules

- Plain words; prefer more words over cleverer ones.
- Several file:line references in one paragraph means it should be a table or a
  fenced block.
- One concrete case first; state the general rule after it, once, if still needed.
- The 100-word ceiling lifts only for a requested walkthrough or a value trace.
  Stop when it stops walking and starts cataloguing.
