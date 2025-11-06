# Bitcoin Multisig Address Verification

This Clarity smart contract verifies that a Bitcoin multisig address was created from specific public keys. It supports both P2SH (legacy) and P2WSH (SegWit) multisig formats.

## Overview

The contract allows you to verify that a given Bitcoin multisig address corresponds to a specific set of public keys and an M-of-N signing threshold. This enables trustless interoperability between Bitcoin multisig wallets and Clarity contracts.

## Features

- Supports P2SH (addresses starting with '3') and P2WSH (addresses starting with 'bc1q') verification
- Leverages the sBTC bootstrap signers contract for compatibility with Bitcoin standards
- Handles 2-of-2, 2-of-3, and other M-of-N multisig configurations
- Provides generation and verification functions

## How It Works

The contract implements Bitcoin's address derivation logic:

1. For P2SH multisig:

   - Takes public keys and an M value
   - Creates the redeem script
   - Hashes it with HASH160 (SHA256 + RIPEMD160)
   - Formats it as `OP_HASH160 <20-byte-hash> OP_EQUAL`

2. For P2WSH multisig:
   - Takes public keys and an M value
   - Creates the redeem script
   - Hashes it with SHA256 only
   - Formats it as `0 <32-byte-hash>`

## Usage

```clarity
;; Verify a multisig address with known public keys
(contract-call? .multisig-verify verify-multisig-address
  (list
    0x038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe
    0x02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead
  )
  u2  ;; 2-of-2 multisig
  true  ;; Is SegWit (P2WSH)
  (some 0x0020eddadf5b9c9c859a4dd18d6874c986b573a9d194bc954660c86b9618d4acd5da)
)

;; Generate a P2WSH scriptPubKey for given public keys
(contract-call? .multisig-verify generate-and-verify-p2wsh
  (list
    0x038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe
    0x02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead
  )
  u2
)
```

## Testing

The contract has been tested with real Bitcoin addresses created using a Bitcoin Core node:

1. Created a test wallet and generated two addresses
2. Extracted the public keys for these addresses
3. Created a 2-of-2 multisig address from those public keys
4. Verified that our contract correctly:
   - Identified the matching public keys and threshold
   - Rejected incorrect public keys (by changing a single byte)
   - Rejected incorrect thresholds (by changing from 2-of-2 to 1-of-2)

All tests passed successfully, confirming that the contract correctly implements Bitcoin's multisig address derivation logic.

## Dependencies

This contract depends on:

- `SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-bootstrap-signers`

## Use Cases

- Verifying Bitcoin multisig deposit addresses in cross-chain applications
- Validating Bitcoin transaction outputs
- Building trustless bridges between Stacks and Bitcoin
- Implementing threshold signature schemes across chains
- Enabling conditional execution based on Bitcoin multisig ownership

## License

[Insert your preferred license here]
