This is a fascinating design question, and your analysis is largely correct. Let me work through the tradeoffs systematically.

**Your understanding is accurate on the core constraints:**

1. **DLC per deposit** - Yes, each DLC is a discrete contract with a fixed outcome set. You can't "add to" an existing DLC the way you can with the capsule pattern where Clarity reads cumulative deposits.

2. **All-or-nothing unlocks** - Standard DLCs resolve to one of N predefined outcomes. Partial withdrawals would require either (a) multiple outcome paths with different percentages, or (b) multiple smaller DLCs, both of which add complexity.

3. **User sovereignty vs operator risk** - You're right that a self-custodial DLC where the user can independently produce the oracle attestation eliminates operator dependency entirely. If the oracle is "Clarity contract emits event on FT burn," the user just needs to prove that event occurred.

**The hybrid you're describing:**

What you're really asking is: can a Clarity contract _act as_ a DLC oracle? The answer is yes in principle. The flow would be:

- User locks BTC in a DLC with two paths: (1) user + oracle signature, or (2) timelock refund
- The "oracle" is a signature derived from proving a Clarity contract state transition (the FT burn)
- User burns FT on Stacks, obtains proof, uses it to unlock the DLC unilaterally

**The technical challenge:**

The gap is in step 2. Standard DLC oracles (like Suredbits) sign _attestations_ that Bitcoin scripts can verify. To make Clarity-as-oracle work, you'd need either:

- A Clarity contract that can produce a signature Bitcoin can verify (possible via the new Stacks signer infrastructure, but complex)
- An adapter that watches Clarity events and produces oracle attestations (reintroduces a trust assumption, though it could be a threshold of signers)

**Compared to your current capsule:**

| Aspect               | Capsule (2-of-2 mandatory user sig)     | Self-DLC with Clarity oracle                    |
| -------------------- | --------------------------------------- | ----------------------------------------------- |
| Operator disappears  | User funds locked (but L2 still backed) | User can still unlock if oracle works           |
| Partial withdrawals  | Native                                  | Requires multiple DLCs or complex outcome trees |
| Incremental deposits | Native                                  | New DLC per deposit                             |
| Trust model          | User must trust operator won't collude  | User trusts oracle infrastructure               |
| Complexity           | Lower                                   | Higher                                          |

**My take:**

The DLC approach is theoretically purer for trustlessness, but the practical overhead (new DLC per deposit, all-or-nothing unlocks) makes it less composable than your capsule design. The capsule's weakness (operator liveness) could be mitigated by:

- Moving to 3-of-4 multisig with multiple operators
- Adding a timelock escape hatch where user can reclaim after N blocks if operator is unresponsive
- Using the DLC pattern _only_ for the escape hatch (operator disappears → user burns FT → DLC oracle attests → user recovers)

That last hybrid might give you the best of both worlds: capsule flexibility for normal operations, DLC-style unilateral exit for catastrophic operator failure.

Want me to search for what Mike Cohen's team built in 2023? That might give us concrete implementation patterns to reference.
