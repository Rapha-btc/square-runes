**Yes, this is exactly how it works.**

---

**The Script Logic:**

```
OP_IF
  // BEFORE EXPIRY PATH: User + m-of-n signers required
  <user_pubkey> OP_CHECKSIGVERIFY
  <m> <signer1_pubkey> <signer2_pubkey> ... <signern_pubkey> <n> OP_CHECKMULTISIG

OP_ELSE
  // AFTER EXPIRY PATH: Only m-of-n signers required (no user)
  <expiry_block_height> OP_CHECKLOCKTIMEVERIFY OP_DROP
  <m> <signer1_pubkey> <signer2_pubkey> ... <signern_pubkey> <n> OP_CHECKMULTISIG

OP_ENDIF
```

---

**What this enforces:**

| Timing        | Who can spend  | What's needed                |
| ------------- | -------------- | ---------------------------- |
| Before expiry | User + signers | User sig + m-of-n sigs       |
| After expiry  | Signers only   | m-of-n sigs (no user needed) |

---

**Why it works:**

1. **`OP_CHECKLOCKTIMEVERIFY` (CLTV)** — Bitcoin native opcode. If you try to use the "after expiry" path before the block height, the transaction is **invalid**. Not rejected by miners — literally cannot be constructed.

2. **`OP_CHECKSIGVERIFY`** on user key — In the "before expiry" path, user signature is **mandatory**. m-of-n signers alone cannot move funds.

3. **Two spending paths** — The `OP_IF/OP_ELSE` creates two mutually exclusive ways to spend. Bitcoin validates which path you're using based on the witness data you provide.

---

**With Taproot (cleaner, cheaper):**

```
Taproot Output:
├── Key Path: disabled (use NUMS point)
└── Script Tree:
    ├── Leaf A: <user_pk> CHECKSIGVERIFY <m> <signers...> <n> CHECKMULTISIG
    └── Leaf B: <expiry> CLTV DROP <m> <signers...> <n> CHECKMULTISIG
```

- Leaf A = user + m-of-n (anytime, but user required)
- Leaf B = m-of-n only (but timelocked)

Before expiry: Only Leaf A is spendable
After expiry: Both leaves are spendable, but protocol uses Leaf B

---

**The 1-block deposit:**

Deposit confirmation is just watching for the tx in a Bitcoin block. Clarity on Stacks can read Bitcoin block headers and verify merkle proofs. Once the deposit tx is in 1 confirmed block, you mint funBTC.

sBTC needs 2 blocks because of their finality model with the shared pool. Your Capsule is sovereign — you only need 1 confirmation to mint against YOUR locked BTC.

---

**So to answer directly:**

> before expiry can't withdraw without 1 determined user

✅ Correct — user signature is required via `OP_CHECKSIGVERIFY`

> after possible to withdraw without user's signature

✅ Correct — the CLTV path only requires m-of-n signers

> in both cases it needs m of n?

✅ Yes — both paths require m-of-n, but only the first path also requires the user

---

This is native Bitcoin. No soft fork needed. Works today.
