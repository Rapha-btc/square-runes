Yes, I see exactly what you're getting at now. Let me think through this carefully.

**The asymmetry you're identifying:**

**Bitcoin → Stacks (peg-in):** Trustless today. User deposits to multisig, Clarity reads Bitcoin state via `at-block`, confirms deposit after 6 blocks, mints FT. No signatures needed beyond user's initial Bitcoin tx. The chain itself is the oracle.

**Stacks → Bitcoin (peg-out):** Requires operator signatures. User burns FT on Clarity, but Bitcoin doesn't know this happened. Someone has to sign a Bitcoin tx to release funds. This is where trust enters.

**The ideal trustless scenario:**

What you'd want is Bitcoin natively reading Stacks state the way Stacks reads Bitcoin state. Then:

1. User burns FT on Clarity
2. Bitcoin script somehow verifies "this burn happened"
3. User unlocks their BTC unilaterally

But Bitcoin can't do this. Bitcoin script is intentionally limited - it can't verify external chain state, can't make HTTP calls, can't parse Clarity events.

**So what's the DLC angle here?**

A DLC is essentially a way to make Bitcoin conditionally spendable based on external data, but it requires that external data to be _signed_ by an oracle. The signature is what Bitcoin can verify.

Your insight is: "The burn event on Clarity IS the attestation. Why do we need anything else?"

The answer is: Bitcoin can't read Clarity. The burn event exists, is finalized, is cryptographically secured by Stacks consensus... but Bitcoin doesn't speak that language.

**What would bridge this gap?**

You'd need one of:

**Option A: Bitcoin soft fork for cross-chain verification**
Bitcoin script gains opcodes to verify Stacks block headers and Clarity state proofs. Not happening.

**Option B: BitVM-style verification**
A fraud proof system where the "happy path" assumes the burn happened, and anyone can challenge with a proof if it didn't. Complex, but theoretically possible. The user would lock BTC in a BitVM contract that says "I can withdraw after N blocks unless someone proves I didn't burn the FT."

**Option C: Threshold signature that's programmatically bound**
This is closer to what exists. The sBTC signers don't _choose_ to sign - they're programmatically obligated to sign when Clarity state meets conditions. The trust assumption becomes "the signer software is correct and enough signers run it honestly."

**Option D: ZK proof of Stacks state transition**
User generates a zero-knowledge proof that:

- Block X was finalized on Stacks
- In block X, contract Y emitted burn event for user Z amount W
- This proof is verifiable by Bitcoin script (via something like OP_CAT + Lamport signatures, or future opcodes)

This is the "infinite resources" answer. You'd essentially compress all of Stacks consensus verification into a succinct proof that Bitcoin can check.

**The DLC framing revisited:**

A simple DLC where "nothing happens OR 100% to user when burned on Stacks" still requires an oracle signature attesting to the burn. The DLC structure doesn't eliminate the oracle - it just makes the Bitcoin script cleaner.

Unless... the "oracle" is a ZK proof. Then:

- User creates DLC: "I can spend this with proof P"
- User burns FT on Stacks
- User generates ZK proof P that burn occurred
- User submits P to Bitcoin, unlocks funds

No operator. No threshold signers. Just math.

**Is this buildable today?**

Not quite. You'd need:

- A ZK circuit that verifies Stacks block finality
- Bitcoin script that can verify ZK proofs (requires OP_CAT or similar, being discussed but not activated)
- Reasonable proof generation time/cost

This is active research area (see ZeroSync for Bitcoin, various L2 proving systems).

**Practical middle ground:**

The closest thing today is making the operator set as trust-minimized as possible:

- Large threshold (say 7-of-10)
- Geographically and jurisdictionally diverse
- Programmatically bound (signers run deterministic software that signs iff Clarity burn verified)
- Slashing conditions (operators lose stake if they sign incorrectly)
- User signature mandatory (your N-of-N approach)

This isn't _trustless_ but it's _trust-minimized_ with economic security.

**So to directly answer your question:**

The ideal trustless scenario is ZK-verified Stacks state on Bitcoin. The burn event becomes a proof that Bitcoin script can verify. No oracles, no operators, no multisig. Pure cryptographic verification.

It's not buildable today, but it's the direction things are heading. Your capsule design with mandatory user signature is the best practical approximation until Bitcoin gets the primitives to verify external proofs.

Does this clarify the gap you were intuiting?
