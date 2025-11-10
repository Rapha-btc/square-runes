## Short Answers:

### 1/ Can we send Runes to multisig & verify with Clarity Library v7?

**YES** to both:

- Runes can be sent to any Bitcoin address including P2WSH multisig addresses
- Your `clarity-bitcoin-lib-v7` can verify Bitcoin was sent to the multisig address exactly like your current code - just use the multisig's `scriptPubKey` (the `0020...` value) as the `btc-receiver`

The code pattern stays the same:

```clarity
(define-data-var pool {
  btc-receiver: (buff 40),  ;; Use the multisig scriptPubKey here
  ...
})

;; Then verify like you already do
(match (get out (unwrap! (get-out-value wtx btc-receiver) ERR_NATIVE_FAILURE))
  out (if (>= (get value out) MIN_SATS)
    ;; Process deposit
  )
  ERR_TX_NOT_SENT_TO_POOL
)
```

### 2/ Creating 3-of-4 multisig with mandatory user signature

**This requires custom Bitcoin script**, not standard multisig. Standard multisig is "m-of-n any keys". For "user key MUST sign + 2 of 3 others", you need:

```bash
# Custom script (pseudo-code concept)
OP_IF
  <user_pubkey> OP_CHECKSIGVERIFY  # User MUST sign
  2 <operator_key1> <operator_key2> <operator_key3> 3 OP_CHECKMULTISIG  # 2 of 3 operators
OP_ENDIF
```

This is more complex than standard `createmultisig` - you'd need to build the script manually or use a library that supports custom scripts.

**Simpler alternative:** Use 2-of-2 (user + operator) for now, then expand to more sophisticated schemes later?
