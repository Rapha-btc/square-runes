You're absolutely right - I misunderstood. Let me clarify the exact flow for what you're trying to achieve:

## Trustless Mapping Between Bitcoin Multisig and Stacks Principal

1. **User creates a multisig** with your app's pubkey and their pubkey
2. **Anyone calls your contract** to register this multisig
3. **Contract verifies**:
   - The multisig is valid
   - It contains exactly 2 pubkeys: your app's known pubkey + user pubkey
   - The multisig scriptPubKey matches
4. **Contract extracts pubkey hash** from user's Stacks principal (tx-sender)
5. **Contract verifies** that the hash160 of one of the multisig pubkeys matches this pubkey hash
6. **If verified**, contract records mapping: `multisig_address → stacks_principal`

This creates a trustless, verified mapping where:

- You know the multisig contains your app's pubkey (security)
- You know the user who registered it controls the other key (verification)
- You've mapped the Bitcoin multisig to the correct Stacks principal

The key insight is using tx-sender's pubkey hash to verify ownership of one of the keys in the multisig, establishing a trustless connection between chains.

Here's what this would look like in code:

```clarity
;; Register a multisig and verify the caller is one of its owners
(define-public (register-multisig
    (multisig-script-pub-key (buff 34))  ;; The Bitcoin multisig scriptPubKey
    (pubkeys (list 2 (buff 33)))         ;; Should contain [app_pubkey, user_pubkey]
  )
  (let (
      ;; Verify this is a 2-of-2 multisig
      (is-valid-multisig (unwrap-panic (verify-multisig-address pubkeys u2 true (some multisig-script-pub-key))))

      ;; Verify the app's pubkey is included
      (app-pubkey APP-PUBKEY)  ;; Your app's constant pubkey
      (contains-app-key (is-eq (element-at pubkeys u0) app-pubkey))

      ;; Get caller's pubkey hash from their Stacks address
      (caller-pubkey-hash (get hash-bytes (unwrap-panic (principal-destruct? tx-sender))))

      ;; Verify the other pubkey hash matches the caller's pubkey hash
      (user-pubkey (element-at pubkeys u1))
      (matches-caller (is-eq (hash160 user-pubkey) caller-pubkey-hash))

      ;; All checks must pass
      (is-valid (and is-valid-multisig contains-app-key matches-caller))
    )
    (if is-valid
        ;; Store the mapping in a data-map
        (begin
          (map-set multisig-to-principal multisig-script-pub-key tx-sender)
          (ok true)
        )
        (err u1)
    )
  )
)

;; Data map for multisig to Stacks principal mapping
(define-map multisig-to-principal (buff 34) principal)
```

This achieves exactly what you described - a trustless mapping between Bitcoin multisigs and Stacks principals, verified cryptographically.
