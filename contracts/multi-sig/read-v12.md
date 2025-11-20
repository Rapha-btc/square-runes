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

okay so i have a bitcoin address which i assume would have the same pubkey as leather shows me that bitcoin add and my stacks add in the same account

BTC:

bc1qrx2ghj5aegvu5dccwqmkqu88w5qznj7g8xdqam

Runes:

bc1pmhm6rgn7esqtmrezmn3k6zyyapwn7q8jvczkcv3mvntx4yd62zfsjmlhv5

Stacks:

SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B

and pubkey:02a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f7170

Great! Let me clarify what you have:

## Your Addresses & Keys:

1. **Stacks Address**: `SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B`
2. **Public Key**: `02a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f7170`
3. **BTC Native SegWit**: `bc1qrx2ghj5aegvu5dccwqmkqu88w5qznj7g8xdqam` (P2WPKH)
4. **BTC Taproot/Runes**: `bc1pmhm6rgn7esqtmrezmn3k6zyyapwn7q8jvczkcv3mvntx4yd62zfsjmlhv5` (P2TR)

## Important Clarification:

**These addresses use the SAME private key but DIFFERENT derivations:**

- **Stacks & BTC P2WPKH** (`bc1q...`): Both derive from the same secp256k1 keypair
  - ✅ Your pubkey `02a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f7170` works for both
- **Taproot/Runes** (`bc1p...`): Uses **Taproot** (BIP340) which has a different pubkey format
  - ❌ Your compressed pubkey doesn't directly work here
  - Taproot uses x-only (32-byte) pubkeys, not compressed (33-byte)

## For Runes Capsule:

**Use your P2WPKH address (`bc1q...`) and the pubkey you extracted** for creating the multisig vault:

```bash
# Create 2-of-2 multisig with your Stacks/BTC pubkey
bitcoin-cli createmultisig 2 '["038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe","02a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f7170"]' "bech32"
```

This creates a P2WSH multisig address where:

- You can sign with your Leather wallet (using your Stacks keypair)
- Runes can be sent to this address
- Your signature is required for any withdrawal

**Note:** If you specifically need Taproot for Runes, that's more complex and requires different scripting.

**YES, exactly correct!** 🎯

## Breakdown:

**Your extracted pubkey** (`02a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f7170`):

- ✅ Can sign for P2WPKH address `bc1qrx2ghj5aegvu5dccwqmkqu88w5qznj7g8xdqam`
- ✅ Can sign for Stacks address `SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B`
- ✅ Can sign for the P2WSH multisig you create with this pubkey
- ❌ **Cannot** sign for Taproot address `bc1pmhm6rgn7esqtmrezmn3k6zyyapwn7q8jvczkcv3mvntx4yd62zfsjmlhv5`

## Why Taproot is different:

- **Your pubkey format**: 33 bytes (compressed) - `02...` or `03...` prefix
- **Taproot pubkey format**: 32 bytes (x-only) - no prefix, just the x-coordinate

They're derived from the same private key but use different elliptic curve signature schemes:

- P2WPKH/P2WSH: ECDSA signatures
- Taproot (P2TR): Schnorr signatures

## For Runes Capsule:

Since Runes work on ANY Bitcoin address type, you can:

1. **Send Runes** to your P2WSH multisig address (created with your extracted pubkey)
2. **Sign withdrawals** using your Stacks wallet (Leather/Xverse)
3. Everything works as expected ✅

The Taproot address is just a different address type in your wallet - you don't need it for this use case.

From the document you shared earlier, here's the multisig address that was created:

## Multisig Address:

```
bc1q63hzljy4mvhz3jn42adz046722hdyugkyc92q279sz6kemqhhdyq5r73u0
```

## Full Details:

- **Address**: `bc1q63hzljy4mvhz3jn42adz046722hdyugkyc92q279sz6kemqhhdyq5r73u0`
- **Type**: P2WSH (Pay-to-Witness-Script-Hash) 2-of-2 multisig
- **Public Keys**:
  1. `038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe` (Bitcoin node key)
  2. `02a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f7170` (Your Stacks key)
- **Redeem Script**: `5221038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe2102a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f717052ae`
- **ScriptPubKey**: `0020d46e2fc895db2e28ca75575a27d75e52aed27116260aa02bc580b56cec17bb48`

**You can send Runes to this address** and they'll be secured by the 2-of-2 multisig requiring both:

- Your Stacks wallet signature
- The Bitcoin node operator signature

This is your vault address for the Runes Capsule! 🎯
