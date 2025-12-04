Yes, from your PIZZA contract.

**Breakdown:**

```clarity
(principal-destruct? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
;; → (ok { version: 0x1a, hash-bytes: 0x..., name: none })

(principal-destruct? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.my-contract)
;; → (ok { version: 0x1a, hash-bytes: 0x..., name: (some "my-contract") })
```

**The key:** `name` is `none` for wallets, `(some "contract-name")` for contracts.

```clarity
(is-some (get name (unwrap-panic (principal-destruct? addr))))
;;   ↓         ↓              ↓
;;   │         │              └── returns { version, hash-bytes, name }
;;   │         └── extracts `name` field (optional)
;;   └── true if name exists (contract), false if none (wallet)
```

**Result:**

- Wallet → `false`
- Contract → `true`
