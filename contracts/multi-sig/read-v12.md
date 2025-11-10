**NO, you cannot directly use sBTC's `sbtc-bootstrap-signers` library for this.**

Here's why:

## What sBTC's library does:

```clarity
;; Generate the p2sh redeem script for a multisig
(define-read-only (pubkeys-to-spend-script
    (pubkeys (list 128 (buff 33)))
    (m uint)
  )
  (concat (uint-to-byte (+ u80 m)) ;; "m" in m-of-n
  (concat (pubkeys-to-bytes pubkeys) ;; list of pubkeys with length prefix
  (concat (uint-to-byte (+ u80 (len pubkeys))) ;; "n" in m-of-n
  0xae ;; CHECKMULTISIG
  )))
)
```

This creates **STANDARD m-of-n multisig**: `OP_m <pubkey1> <pubkey2> ... <pubkeyn> OP_n OP_CHECKMULTISIG`

## What you need:

**CUSTOM script with mandatory signer**: `<user_pubkey> OP_CHECKSIGVERIFY OP_2 <op1> <op2> <op3> OP_3 OP_CHECKMULTISIG`

This is a completely different script structure.

## What you CAN do:

**Adapt their approach** for your custom script:

```clarity
;; Build custom script: user MUST sign + 2-of-3 operators
(define-read-only (build-mandatory-user-multisig-script
    (user-pubkey (buff 33))
    (operator-pubkeys (list 3 (buff 33)))
  )
  (concat 0x21 ;; push 33 bytes
  (concat user-pubkey
  (concat 0xad ;; OP_CHECKSIGVERIFY (user MUST sign)
  (concat 0x52 ;; OP_2 (need 2 signatures)
  (concat (pubkeys-to-bytes operator-pubkeys)
  (concat 0x53 ;; OP_3 (from 3 operators)
  0xae ;; OP_CHECKMULTISIG
  ))))))
)
```

Then use their hash/principal generation pattern:

```clarity
(hash160 (build-mandatory-user-multisig-script user-pubkey operator-pubkeys))
```

**Bottom line:** You need to write your own custom script builder, but can reuse their hash160/principal generation logic.
