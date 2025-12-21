# Runes Protocol Parser for Stacks

This repository contains a Clarity implementation for parsing Bitcoin Runes protocol data, allowing Stacks smart contracts to understand and react to Runes transactions on the Bitcoin chain.

## Overview

The Runes protocol is a Bitcoin-native token standard that uses OP_RETURN outputs to encode token transfer information. This implementation provides:

1. A robust LEB128 decoder for parsing variable-length integers
2. A runestone parser that extracts Runes protocol data from Bitcoin transactions
3. Support for cross-chain bridging between Bitcoin Runes and Stacks SIP-010 tokens

## How It Works

### LEB128 Decoder

The core of the implementation is a LEB128 (Little Endian Base 128) decoder that can parse the variable-length integers used in the Runes protocol. LEB128 is an efficient encoding that:

- Uses 7 bits per byte for data
- Uses bit 7 as a continuation flag (1 = more bytes follow)
- Can represent arbitrary-sized integers in a space-efficient manner

Our decoder handles LEB128 values up to 4 bytes in length, which is sufficient for most Runes protocol values.

### Runes Protocol Parser

The parser extracts information from Bitcoin transactions containing Runes protocol data:

1. Verifies the OP_RETURN + OP_13 marker bytes
2. Extracts the tag (0 for edicts)
3. Extracts the rune ID (block height + transaction index)
4. Extracts the amount being transferred
5. Extracts the destination output index

## Usage

```clarity
;; Decode a single LEB128 value
(decode-leb128 0x64 u0) ;; Returns (ok { value: u100, next-offset: u1 })

;; Parse a Runes protocol transfer
(parse-simple-runes-transfer 
  0x6a5d0082b49d01640164  ;; Bitcoin scriptPubKey data
  u2578946                ;; Expected rune block height
  u100                    ;; Expected rune transaction index
  u100                    ;; Expected output index
) ;; Returns (ok u1) - the amount being transferred
```

## Technical Notes

- Uses `buff-to-uint-le` for buffer to uint conversion
- Handles bit operations with explicit uint literals (u127, u128) to avoid type issues
- Follows a pattern similar to clarity-bitcoin-lib for buffer parsing

## Testing

The implementation has been tested with various LEB128 values:
- Single byte values (0-127)
- Multi-byte values (128+)
- Complete Runes protocol transfers

## License

[Insert your license information here]
