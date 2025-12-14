**Correct, you don't need legacy.**

Here's the breakdown:

| Address   | Type                        | Has Witness Data | `was-segwit-tx-mined-compact` works? |
| --------- | --------------------------- | ---------------- | ------------------------------------ |
| `bc1p...` | Taproot                     | ✅ Yes           | ✅ Yes                               |
| `bc1q...` | Native SegWit               | ✅ Yes           | ✅ Yes                               |
| `3...`    | Nested SegWit (P2SH-P2WPKH) | ✅ Yes           | ✅ Yes                               |
| `1...`    | Pure Legacy                 | ❌ No            | ❌ No                                |

Xverse's `3...` is **nested segwit** - it wraps segwit inside P2SH for compatibility. The transaction still contains witness data, so `was-segwit-tx-mined-compact` handles it fine.

**For Runes specifically:**

- Runes live in Taproot (`bc1p...`) addresses
- Nobody stores Runes in pure legacy `1...` addresses
- Your users are Leather/Xverse users → all segwit-compatible

**Conclusion:** Your contract is good as-is. Skip legacy support entirely for the mainnet demo. You can always add it later if some bizarre edge case appears, but it won't.

```clarity
;; This is all you need:
process-deposit          ;; segwit (covers bc1p, bc1q, and 3... nested)

;; Don't bother with:
process-deposit-legacy   ;; only for pure 1... addresses, irrelevant for Runes
```

Ship it.
