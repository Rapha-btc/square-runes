# Runes Capsule

**Trustless Bitcoin-to-Stacks Bridge for Runes Tokens**

## What is Runes Capsule?

A trust-minimized bridge that verifies Bitcoin Runes deposits on-chain using Clarity and mints wrapped SIP-10 tokens.

## The Core Innovation

Each user controls their own Bitcoin "Capsule" – an m-of-n multisig address where their signature is always required. The bridge operator cannot move funds without the user's explicit consent.

- **User sovereignty:** Nothing leaves your Capsule without your signature
- **No central honeypot:** Funds distributed across individual Capsules
- **Cryptographic mapping:** Stacks address ↔ Bitcoin Capsule linked via pubkey verification
- **Cryptographic parsing:** Stacks Clarity reads your Bitcoin Runes deposit and parses amount/asset/ownership transfer
- **Merkle proof verification:** Clarity verifies BTC transactions were actually mined

---

## The Powerful Unlock: Code Walkthrough

Here's what makes this trustless – the `verify-user-in-multisig` function that proves a Stacks user owns a Bitcoin Capsule:

```clarity
;; THE CORE UNLOCK: Trustless Stacks ↔ Bitcoin identity binding
(define-public (verify-user-in-multisig
    (multisig-script-pub-key (buff 34))
    (pubkeys (list 128 (buff 33)))
    (m uint))
  (let (
      ;; Check if ANY pubkey hashes to tx-sender's address
      (user-is-signer (fold check-pubkey pubkeys false))
      ;; Verify the multisig scriptPubKey is valid
      (multisig-valid (unwrap-panic
        (verify-multisig-address pubkeys m true (some multisig-script-pub-key))))
    )
    ;; BOTH conditions must be true: user controls key + multisig is valid
    (ok (and user-is-signer multisig-valid))))

;; The magic: hash160(pubkey) must equal tx-sender's hash-bytes
(define-private (check-pubkey (pubkey (buff 33)) (found bool))
  (let ((user-pubkey-hash
          (get hash-bytes (unwrap-panic (principal-destruct? tx-sender)))))
    (if found true
        (is-eq (hash160 pubkey) user-pubkey-hash))))
```

> 💡 **KEY INSIGHT:** The `hash160(pubkey) == tx-sender.hash-bytes` check is what makes this trustless. It cryptographically proves the caller's Stacks address derives from a pubkey in the Bitcoin multisig. No oracle needed – the math proves identity.

---

## The Bridge Flow

### Deposit

#### Step 1: Decode the Runestone

Runes encode transfer data in Bitcoin's OP_RETURN. Our decoder extracts amount, destination, and Rune ID:

```clarity
(contract-call? .runes-decoder decode-any-runestone
  0x6a5d0c160200f7a538c60acd9b0401)

=> (ok {
     amount: u69069,
     edict-output: (some u1),   ;; Which BTC output got the Runes
     rune-block: u922359,       ;; Rune ID (block + tx)
     rune-tx: u1350 })
```

#### Step 2: Verify & Register the Capsule

The multisig-verify contract cryptographically links Stacks address to Bitcoin Capsule:

```clarity
(contract-call? .multisig-verify verify-multisig-address
  (list
    0x038b39a74...  ;; Operator pubkey
    0x02a8dbe8f...  ;; User pubkey
  )
  u2              ;; 2-of-2 threshold
  true            ;; SegWit (P2WSH)
  (some 0x0020d46e2fc895db2e28...))  ;; Expected scriptPubKey

=> (ok true)
```

**How it works:** The contract rebuilds the expected P2WSH scriptPubKey from pubkeys using the sBTC bootstrap-signers library. If it matches, the mapping is proven mathematically.

**Capsule Registration:**

```clarity
(contract-call? .runes-capsule register-capsule
  'STVRQS3H4W9...  ;; Stacks address to receive minted tokens
  0x021deb4b0d... ;; User's compressed pubkey
  0x002032207a... ;; Capsule scriptPubKey (P2WSH)
  true)           ;; SegWit flag
```

#### Step 3: Process Deposit & Mint

When Runes arrive at the Capsule, anyone can submit the BTC tx for minting. The contract:

1. Verifies BTC tx was mined (merkle proof via clarity-bitcoin-lib-v7)
2. Parses OP_RETURN to decode Rune transfer details
3. Confirms destination output matches a registered Capsule
4. Mints SIP-10 "Square Runes" tokens to the Capsule owner
5. Records deposit to prevent double-minting

---

### Withdrawal (Unwrap)

Withdrawal is the reverse of deposit – user burns L2 tokens to unlock their L1 Runes.

#### Withdrawal Process

1. **User burns L2 tokens:** Call the burn function on the Square Runes (sqMOM) contract, specifying the amount to unwrap
2. **Wait 6 Bitcoin blocks:** Signers wait for 6 block confirmations (~1 hour) to ensure finality and prevent reorg attacks
3. **User co-signs withdrawal:** User signs a PSBT (Partially Signed Bitcoin Transaction) to authorize the Runes transfer back to their L1 address
4. **Operator co-signs & broadcasts:** Operator adds their signature to complete the m-of-n requirement and broadcasts the transaction
5. **Runes return to user:** The same Bitcoin taproot transaction structure used for deposit is reused – Runes go back to user's L1 wallet

> 💡 **KEY INSIGHT:** The withdrawal uses the same taproot transaction structure as the original deposit. This means Runes return via the same cryptographic path they came from – no new address generation needed, and the provenance chain is maintained on-chain.

#### Why 6 Blocks?

The 6-block wait serves two purposes: it ensures the burn transaction on Stacks has finality (cannot be reverted), and it gives the system time to detect any anomalies before releasing L1 assets. This is the same confirmation standard used by most Bitcoin services.

#### User Signature Required

**Critical:** Even during withdrawal, the user must co-sign. The operator cannot unilaterally release Runes – this is the same security guarantee as deposit. Your keys, your Runes, in both directions.

---

## Security Properties

| Property              | How Capsule Achieves It                                             |
| --------------------- | ------------------------------------------------------------------- |
| No arbitrary minting  | Tokens only minted when merkle proof confirms real BTC deposit      |
| No theft of L1 assets | m-of-n multisig requires user signature for any withdrawal          |
| No central honeypot   | Funds distributed across individual Capsules, not pooled            |
| No oracle dependency  | Cryptographic verification in Clarity – pubkey math proves identity |
| Two-way arbitrage     | Bidirectional bridging enables price parity through market forces   |

---

## ⚠️ Risks & Trade-offs

Every bridge has risks. Here's an honest assessment of what can go wrong:

### Risk 1: Collusion (Release Without Burning)

|                        |                                                                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **What can happen**    | Operator and user could collude to release L1 Runes without burning the L2 tokens. This would create unbacked L2 tokens.                              |
| **Why it's mitigated** | No honeypot for operator – collusion would need to happen user-by-user. Operator has reputational/business risk. Economic incentives discourage this. |
| **Residual risk**      | **MEDIUM** – Collusion is possible if operator is malicious and finds willing users                                                                   |

### Risk 2: Operator Key Compromise

|                                              |                                                                                                                                                                                                                |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **What can happen**                          | If operator's private keys are compromised, attackers could co-sign with users to unlock L1 runes without burning L2 tokens.                                                                                   |
| **Why it's better than traditional bridges** | Attacker still can't arbitrarily mint – they need real L1 assets. Exploitation is slow (10-min BTC blocks). Kill switch can suspend minting. Users keep access to their L1 + can sell L2 for partial recovery. |
| **Future mitigation**                        | 7-of-15 operator multisig (requires extension of sBTC bootstrap library to ensure user signature is required vs n-of-n). Timelocks for large withdrawals. Multiple independent signers.                        |
| **Residual risk**                            | **MEDIUM-HIGH** – Single operator key is a critical point of failure in pilot phase                                                                                                                            |

### Risk 3: Operator Unavailability (Liveness)

|                        |                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **What can happen**    | If operator goes offline/disappears, users cannot withdraw their L1 Runes (m-of-n requires operator signatures).                             |
| **Why it's mitigated** | Users can still trade L2 tokens. L1 assets are not lost – just temporarily locked.                                                           |
| **Future mitigation**  | Timelock recovery path (user-only withdrawal after X weeks). Multiple independent operators. Upgrade to m-of-n with user signature required. |
| **Residual risk**      | **MEDIUM** – Temporary lock possible, but no permanent loss                                                                                  |

### Risk 4: Smart Contract Bugs

|                        |                                                                                                                                          |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **What can happen**    | Bug in runes-decoder, multisig-verify, or capsule-core could enable invalid minting, fail to verify deposits, or lock funds.             |
| **Why it's mitigated** | Uses battle-tested clarity-bitcoin-lib-v7 and sBTC bootstrap-signers. Core logic is ~200 lines, auditable. Testnet pilot before mainnet. |
| **Residual risk**      | **MEDIUM** – New code always carries risk; formal audit recommended before mainnet                                                       |

### Risk 5: L2 Token Price Decoupling

|                        |                                                                                                                                                                            |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **What can happen**    | If any of the above risks materialize, L2 token (Square Runes) could trade below L1 value as market prices in the risk.                                                    |
| **Why it's mitigated** | Two-way bridging enables arbitrage to restore peg. Unlike traditional hacks, attacker can't drain everything instantly – slow BTC blocks + kill switch allow intervention. |
| **Residual risk**      | **LOW-MEDIUM** – Market forces + arbitrage naturally maintain peg if bridge functions correctly                                                                            |

### Risk Summary Matrix

| Risk                | Level    | Primary Mitigation             |
| ------------------- | -------- | ------------------------------ |
| Collusion           | MEDIUM   | No honeypot, reputational risk |
| Key Compromise      | MED-HIGH | Kill switch, slow exploitation |
| Operator Liveness   | MEDIUM   | Timelock recovery (future)     |
| Smart Contract Bugs | MEDIUM   | Testnet pilot, audit planned   |
| Price Decoupling    | LOW-MED  | Two-way arbitrage              |

---

## How Capsule Compares

| Aspect        | Federated Bridges              | Runes Capsule                         |
| ------------- | ------------------------------ | ------------------------------------- |
| Trust model   | 9-of-15 signers (e.g., Pontis) | 9-of-15 with user mandatory           |
| Honeypot risk | HIGH – central pool            | LOW – distributed Capsules            |
| User control  | None – trust the federation    | Full – user signature required        |
| Hack impact   | Instant drain of all funds     | Slow (10-min blocks), can kill switch |

---

## Future: Fully Trustless Withdrawals via BitVM

What if Runes bridging could be fully trustless? No operators. No multisig. No "trust us." Just math. Here's the path.

### The Problem with Today's Bridges

Today's bridge options all have trust assumptions:

- **Federated multisig** — trust the signers
- **MPC** — trust the key shards
- **Centralized** — trust the company

Even "decentralized" bridges are really "distributed trust."

### BitVM Changes This

BitVM enables verifying arbitrary computation on Bitcoin via fraud proofs + SNARKs.

[BOB](https://gobob.xyz/) built it for BTC. Their model: L1 → L2. "Did BTC lock on Bitcoin?"

That's the easy direction — and Clarity reads Bitcoin state already.

### The Hard Direction: L2 → L1

"Did a burn happen on Stacks? Release the L1 asset."

This requires proving Stacks state on Bitcoin. Same problem whether you're bridging sovereign wrapped BTC or Square Runes — both are SIP-10 tokens on Stacks.

### What the SNARK Circuit Needs

The circuit must:

1. Verify Stacks block validity (consensus, signer sigs, Bitcoin anchor)
2. Parse the burn tx
3. Confirm amount + authorization
4. Trigger L1 release

Nobody's built a Stacks state verifier in ZK yet.

### The Forkable Future

If Stacks core builds this for sovereign wrapped BTC (myBTC? iBTC?), the infrastructure becomes forkable.

Runes Capsule swaps one line:

```clarity
ft-burn? wrapped-btc  →  ft-burn? square-runes
```

Same circuit. Same verifier. Different token.

### Where Runes Gets Harder

| Asset | State Model                                     | Complexity |
| ----- | ----------------------------------------------- | ---------- |
| BTC   | UTXO = truth                                    | Simple     |
| Runes | UTXO + OP_RETURN = truth lives in indexed state | Complex    |

The L1 release isn't just "send BTC" — it's "send Runes" which means parsing the runestone protocol.

Can a SNARK include Runes indexing? Theoretically yes — it's deterministic computation. But the circuit is massive: full indexer logic, state history, OP_RETURN parsing. Possible, but a whole R&D effort on top of the Stacks verifier.

### Why We Ship with User Signatures Now

This is why Runes Capsule ships with mandatory user signatures.

> "Nothing leaves your vault without your key."

Best trust model possible now — while ZK infrastructure matures.

### The Roadmap to Trustless

| Phase       | Description                      | Status                                 |
| ----------- | -------------------------------- | -------------------------------------- |
| **Phase 1** | User-signature vaults (Capsules) | 🔨 Building now                        |
| **Phase 2** | Stacks ZK state proofs           | ⏳ Waiting on infra                    |
| **Phase 3** | Trustless BitVM withdrawals      | 🔬 If Runes indexing can be SNARKified |

### Our Philosophy

Runes liquidity deserves better than "trust our multisig" — even with a trustworthy decentralized set of companies.

For BTC, the math exists today. For Runes — a meta-protocol — it's harder. Maybe possible. The path is forming.

**We're not waiting. We're building with what's real now.**

---

## Current Status & Roadmap

- ✅ Mainnet pilot App: Runes Capsule deployed with MOM's token
- ✅ Core contracts: runes-decoder, multisig-verify, runes-capsule-core
- ✅ Wallet integrations: Leather, Xverse PSBT signing
- 📋 Next: Mainnet deployment, formal audit, m-of-n upgrade

---

## Resources

- **GitHub:** [github.com/uasu-finance/runes-capsule](https://github.com/Rapha-btc/square-runes)
- **Fak.fun:** [fak.fun/btc](https://fak.fun/capsule)
- **Contact:** [@RaphaStacks on X](https://x.com/RaphaStacks)
