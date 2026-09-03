# Impact traps — additive-looking changes that still break

`codebase-exploration` finds the touched surface. This is the add-on it does not
do: spotting changes that read as safe or additive but break a consumer. Check
each site against this list before you call it "safe".

| Change | Reads as | Actually breaks |
|---|---|---|
| New `NOT NULL` column, no default | additive | every existing INSERT that omits it; needs a backfill |
| New required field on a request / DTO | additive | every caller that does not send it |
| New enum / union variant | additive | exhaustive `switch`/`match`, strict deserializers |
| Widening a return type / adding a field | additive | `SELECT *` consumers, strict schema validators (Avro / Protobuf / Parquet), snapshot tests |
| New optional param with a default | additive | positional callers, overload resolution, serialized signatures |
| Relaxing a validation / making a field optional | additive | consumers that relied on the invariant holding |
| New event / message field | additive | strict-schema subscribers, contract tests, replay of old events |
| Rename with an alias kept | additive | reflection, string-keyed lookups, config referencing the old name |
| New index / constraint | additive | write latency; existing rows that violate the new constraint |

Rule of thumb: a change is only truly additive if every existing reader ignores
what it did not ask for. The moment a reader is strict — schema validation,
exhaustive matching, positional binding — "additive" is a breaking change wearing
a disguise.
