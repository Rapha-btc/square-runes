# Bitcoin Runes Decoder - Technical Documentation

## Overview

We've successfully built a Runes protocol decoder for Stacks blockchain interoperability that can parse different transaction formats:

1. **Standard transfers (Tag 0)**
2. **Magic Eden transfers (Tag 11/0x0b)**
3. **Xverse transfers (Tag 22/0x16)**

## Xverse Transfer Structure (Tag 22)

From our analysis of `0x6a5d160200f7a538c60a80e8922601`:

```
0x6a        - OP_RETURN
0x5d        - OP_13 (Runes protocol marker)
0x16        - Tag 22 (Xverse transfer format)
0x02        - param1 = 2 (protocol identifier?)
0x00        - param2 = 0 (flags?)
0xf7a538c6  - param3 = 922359 (rune_block) in LEB128
0x0a80e892  - param4 = 1350 (rune_tx) in LEB128
0x26        - param5 = 80000000 (amount) in LEB128
0x01        - output = 1
```

## Magic Eden Transfer Structure (Tag 11)

Different format than Xverse, uses a combined rune ID approach.

## Current Implementation

- LEB128 decoder for interpreting Runes protocol messages
- Tag detection and parsing for multiple transfer formats
- Parameter extraction for rune ID components, amount, and output index
- Comprehensive validation against expected values

## Open Questions

- What do the protocol_param1 (u2) and protocol_param2 (u0) values represent in Xverse transfers?
- Are there official specifications for the different tag formats?
- Do consolidated UTXO transfers use different tags?

## Resources for Further Research

- [Ordinals Documentation](https://docs.ordinals.com/runes.html)
- [Xverse Wallet Documentation](https://docs.xverse.app/)
- [Luminex GitHub](https://github.com/luminexord/runes)

## Community Inquiry

You might want to post in these communities for more specific information:

- [Bitcoin Dev Mailing List](https://lists.linuxfoundation.org/mailman/listinfo/bitcoin-dev)
- [Xverse Discord](https://discord.gg/xverse)
- [Stacks Discord](https://discord.gg/stacks)
- [Ordinals Discord](https://discord.gg/ordinals)

The protocol is still relatively new (launched April 2024), so detailed technical documentation about implementation-specific tags might be limited. Direct contact with developers at Xverse or Magic Eden may be your best option for definitive answers.
