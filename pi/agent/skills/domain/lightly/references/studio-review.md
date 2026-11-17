# Asking for review in lightly-ai/lightly-studio

1. Comment `/review` on the PR. PR Bot posts it to #dev-all-pr (`C01KSD8EE65`)
   within seconds, stacked PRs included.
2. Reply in that bot post's thread, tagging the reviewer:

   ```bash
   slackcli messages send --recipient-id C01KSD8EE65 --thread-ts <ts> --message "<@SLACK_ID> please review when you have some time, <topic>"
   ```

   Keep it to that one line. `<topic>` is short and names the piece, for
   example "Embedding plot compute prompt spec". No "n of N" counter, no
   extra hints. slackcli prints nothing on success, so confirm the reply by
   reading the thread.

   Find `<ts>` by reading #dev-all-pr through the Slack MCP (reading is fine,
   posting is not). Find an unknown Slack ID with the Slack MCP user search.
3. For a stack: one `/review` and one thread reply per PR, bottom-up, wave by
   wave.

Known Slack IDs: Kondrat (`ikondrat`) `U06RKND2V1R`, Leonardo (`LeonardoRosaa`)
`U09MYNTGZL0`, Nauryzbay (`mrpositron`) `U0APQJLV1M5`.

The Fast Track bot auto-approves a PR whose guardrails all pass, for example
adding at most 215 lines. Such a PR needs no human ask.
