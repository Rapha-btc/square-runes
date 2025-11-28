Good question. The original concern was memory exhaustion:

```
OP_DUP OP_CAT OP_DUP OP_CAT OP_DUP OP_CAT...
```

Each iteration doubles the data size. Start with 1 byte, after 30 iterations you have 1GB on the stack. This could crash nodes or be used for DoS attacks.

**Why it's not a concern anymore:**

Bitcoin now has a 520-byte stack element limit. This was added after OP_CAT was disabled. So even with OP_CAT re-enabled:

- You concatenate two elements
- If result exceeds 520 bytes, script fails immediately
- No exponential growth possible

The fear was valid in 2010 when there were no stack limits. With current limits, the attack vector doesn't exist.

**The real debate now isn't safety, it's scope:**

Some devs worry OP_CAT enables things Bitcoin "shouldn't" do - complex covenants, MEV, on-chain computation that could bloat the chain or change Bitcoin's character. Others argue these capabilities are net positive and inevitable anyway.

So it's less "is OP_CAT dangerous?" and more "do we want Bitcoin to be programmable in this way?"
