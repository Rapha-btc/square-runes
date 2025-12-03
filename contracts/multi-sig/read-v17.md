**`principal-of?`** — pubkey → principal (forward direction)

```clarity
(principal-of? 0x03adb8de4b...) ;; → (ok ST1AW6E...)
```

**`principal-destruct?`** — principal → {version, hash-bytes, name} (deconstruct, but hash-bytes is `hash160(pubkey)`, NOT the pubkey)

**The insight:** Use `principal-of?` to verify!

```clarity
(asserts! (is-eq (principal-of? user-pubkey) (ok tx-sender)) ERR-PUBKEY-MISMATCH)
```

Cleaner than hashing manually. User provides pubkey, you verify it derives to `tx-sender`.

===

`principal-of?` computes: **pubkey → principal**

It does this internally:

1. `sha256(pubkey)`
2. `ripemd160(result)` → gives hash160
3. Add version byte → gives principal (ST1... or SP1...)

**So to verify user's pubkey:**

```clarity
;; User claims this is their pubkey
(principal-of? user-pubkey)  ;; → (ok ST1ABC...)

;; Check it matches who's calling
(is-eq (principal-of? user-pubkey) (ok tx-sender))  ;; → true/false
```

If true, the pubkey is legit — it mathematically derives to the caller's address.
