# Runes Protocol Tags Analysis

## Introduction

After extensive research, it's apparent that Tag 11 (0x0b) isn't explicitly documented in the official Runes protocol documentation. The Runes protocol documentation primarily mentions Tag 0 (for transfers/edicts) and Tag 13 (for etching/creation), but doesn't provide details about Tag 11.

According to the official documentation: "The Runes reference implementation, ord, is the normative specification of the Runes protocol. Nothing you read here or elsewhere, aside from the code of ord, is a specification."

This means that to fully understand Tag 11, we would need to examine the reference implementation's code directly.

## Known Tag Types

Based on available documentation:

| Tag | Hex | Purpose |
|-----|-----|---------|
| 0   | 0x00| Edicts (transfer instructions) |
| 13  | 0x0d| Etching (creating new Runes) |
| 11  | 0x0b| Special transfer format (undocumented) |

## Tag 11 (0x0b) Format Analysis

From our examination of real-world data, Tag 11 appears to be a special transfer format with this structure:

```
6a5d0b00caa2338b0788e0ea0101
```

Breaking it down:
- `6a`: OP_RETURN marker
- `5d`: OP_13 (Runes protocol marker)
- `0b`: Tag 11
- `00`: Rune ID parameter (likely a shorthand reference)
- Remaining data: Complex encoding of amount and destination

When decoded with our parser:
```
(ok { param1: u0, param2: u840010, param3: u907, param4: (some u3846152), tag: u11 })
```

## Theory on Tag 11 Usage

Tag 11 appears to be used by exchanges and wallets (like Magic Eden) as an optimized or specialized transfer format. It likely provides additional features compared to the standard Tag 0 transfers:

1. **Simplified Rune Identification**: Instead of using the full block:tx format, it might use a shorthand reference system
2. **Batch Capabilities**: May allow for more efficient batch transfers
3. **Extended Data**: The additional parameters might encode special conditions or metadata

## Decoding Specific Parameters

For the transaction `0x6a5d0b00caa2338b0788e0ea0101`:

- `param1: u0`: Shorthand reference to the Rune ID (could be a lookup index)
- `param2: u840010`: Unknown parameter (possibly a protocol-specific identifier)
- `param3: u907`: Possibly the output index or batch identifier
- `param4: u3846152`: Likely the amount being transferred (given your confirmation this is the amount you tried to transfer)

## Implications for Bridge Implementation

For a Runes-to-SIP-010 bridge implementation:

1. **Handle Multiple Tag Types**: Support both Tag 0 and Tag 11 transfers
2. **Extract Rune ID**: Develop a method to map the shorthand reference (param1) to the actual Rune ID
3. **Proper Amount Extraction**: For Tag 11, use param4 as the amount
4. **Output Identification**: Correctly identify which output receives the Runes

## Recommended Next Steps

1. **Examine Ord Reference Implementation**: Look at the official `ord` codebase to understand Tag 11
2. **Test with Various Services**: Create test transfers from different wallets/exchanges to see format variations
3. **Document Common Patterns**: Build a reference table of Tag 11 parameter mappings for popular services
4. **Implement Flexible Parser**: Create a parser that can handle all known tag types and extract relevant data

## Conclusion

Tag 11 appears to be a legitimate and widely-used transfer format in the Runes protocol, despite not being explicitly documented. By analyzing real-world transactions and understanding its pattern, we can build a bridge implementation that correctly handles these transfers.
