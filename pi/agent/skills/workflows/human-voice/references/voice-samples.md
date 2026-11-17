# Voice samples

Real text Gabriel wrote or sent. Append new samples when he rewrites a draft;
never edit or paraphrase existing ones.

## Slack

> I think the button and the filter removal are a bit awkward. Idea: no button, a hint in the plot chip on hover. Could be a follow-up, we merge this first with some small issues fixed that I'm going to comment.
>
> I think we can merge yours and I ask my agent to implement this new design. wdyt?

> I've asked my agent to prototype this

## PR review comments

> We can embed images, what we can't is "image bytes". This shows a wrong error,
> "cannot embed {query_kind}" -> "cannot embed images". Maybe
> `query_kind="image bytes"`? The new test matches on "cannot embed images" too,
> so it needs the same change.

> Nit: b"image bytes" reads a bit like a text value at first look. Not blocking,
> the older tests here use it too.

> Maybe we should use the MAX_INSTANCES constant here.

> I don't think we need this check. With an unknown id nothing gets deleted and
> delete() returns False anyway, so we could raise NotFoundError there instead of
> the HTTPException.

## Approval (agent draft Gabriel accepted)

> Thanks for adding a test for each of these. The per-annotation eye carrying the
> whole source over works for me. LGTM

## How he gives feedback (tone reference)

> You don't need to be that cold, remember, don't cut the words/sentences, cut information.

> in general, when writting issues, they should be written without needing much context. more contxt of the product, no like finer-swan caltech etc... even for me is not clear.

> trim the message, say about pacmap is slow. make it more causal.

> 3 that's a problem we should think of, put it like that.
