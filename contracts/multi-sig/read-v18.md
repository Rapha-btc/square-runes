**Flow:**

```
OP_RETURN says: "Send Runes to output 1"
                           ↓
             edict-output = u1
                           ↓
        get-output-at-index(tx, u1) → scriptPubKey
                           ↓
        get-capsule-owner(scriptPubKey) → owner
                           ↓
              Mint to owner ✅
```

**Code trace:**

```clarity
;; 1. Decode OP_RETURN → get edict-output (e.g., u1)
(edict-output (unwrap! (get edict-output parsed) ERR-PARSE-FAILED))

;; 2. Get scriptPubKey at that output index
(multisig-output (unwrap! (get-output-at-index tx-buff edict-output) ERR-MULTISIG-NOT-FOUND))
(output-script (get scriptPubKey multisig-output))

;; 3. Look up who owns that capsule
(capsule-owner-info (unwrap! (get-capsule-owner output-script) ERR-CAPSULE-NOT-FOUND))

;; 4. Mint to them
(try! (contract-call? sq-rune mint amount owner))
```

**Security:**

- Runes protocol: `edict-output` in OP_RETURN = "Runes go to this UTXO"
- Your contract: "Is that UTXO a registered capsule? If yes → mint to capsule owner"
- If someone sends Runes to a random address, `get-capsule-owner` returns `none` → fails

The multisig _must_ be at `edict-output` position or the deposit fails.
