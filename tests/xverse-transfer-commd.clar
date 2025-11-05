Here are the command lines to test your updated functions in the Clarinet console:

1. Test the basic Runestone tag identification:
```
(contract-call? .runes-decoder get-runestone-tag 0x6a5d160200f7a538c60a80e8922601)
```

2. Test the general decoder that shows all parameters:
```
(contract-call? .runes-decoder decode-any-runestone 0x6a5d160200f7a538c60a80e8922601)
```

3. Test the standard transfer parser with correct parameters:
```
(contract-call? .runes-decoder parse-runes-transfer 0x6a5d160200f7a538c60a80e8922601 u922359 u1350 u1)
```

4. Test the full Xverse transfer parser that gives you all the details:
```
(contract-call? .runes-decoder parse-xverse-transfer-full 0x6a5d160200f7a538c60a80e8922601)
```

5. Test just extracting the amount:
```
(contract-call? .runes-decoder decode-amount-from-tag22 0x6a5d160200f7a538c60a80e8922601)
```

6. Examine raw bytes if needed for debugging:
```
(contract-call? .runes-decoder extract-raw-bytes 0x6a5d160200f7a538c60a80e8922601 u7 u15)
```

These commands should help you confirm that your Runes decoder is correctly parsing Xverse transfers, identifying the Rune ID components (block and tx index), extracting the transfer amount, and validating the output index.

(parse-tag22-transfer script next-offset expected-rune-block expected-rune-tx expected-output)
```

This fixes the parameter mismatch since your `parse-tag22-transfer` function expects 5 arguments but you're only passing 4 in the `parse-runes-transfer` function.

No other changes are needed at this time. This single line fix will resolve the compilation error.

After making this change, you can use the following commands to test your code:

1. To test basic functionality:
```
(contract-call? .runes-decoder get-runestone-tag 0x6a5d160200f7a538c60a80e8922601)
```

2. To see the full data structure:
```
(contract-call? .runes-decoder parse-xverse-transfer-full 0x6a5d160200f7a538c60a80e8922601)
```

3. To validate a specific transaction:
```
(contract-call? .runes-decoder parse-runes-transfer 0x6a5d160200f7a538c60a80e8922601 u922359 u1350 u1)

(contract-call? .runes-decoder parse-runes-transfer 0x6a5d160200f7a538c60a80e8922601 u922359 u1350 u1)