# The chain

```
awesome-brainstorming ──(Pass A rigor)──► awesome-writing-plans ──(Pass B loop)──►
  superpowers:executing-plans ──► finishing-with-review ──►
    [superpowers:requesting-code-review + receiving-code-review ×1–2] ──►
      end-of-session-reflection ──► superpowers:finishing-a-development-branch
```

`autonomous-chunk-execution` sits beside this chain: for large multi-file work it
decomposes the job into chunks, and each chunk runs through plan → execute →
finishing-with-review.

| Transition | Carries |
|---|---|
| brainstorming → writing-plans | an approved, rigor-strengthened spec |
| writing-plans → executing-plans | a plan with a Deferred Risks section |
| executing-plans → finishing-with-review | a branch with completed tasks |
| finishing-with-review → reflection | a reviewed, fix-applied branch |
| reflection → finishing-a-development-branch | committed session artifacts |
