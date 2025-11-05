Here are the Clarinet console commands to test your Runes decoder with the Xverse transfer transaction:

```
;; First, check if it's a valid runestone and get the tag
(contract-call? .runes-decoder get-runestone-tag 0x6a5d160200f7a538c60a80e8922601)

;; Decode the entire runestone structure regardless of tag
(contract-call? .runes-decoder decode-any-runestone 0x6a5d160200f7a538c60a80e8922601)

;; Try to extract just the amount from the Tag 22 transfer
(contract-call? .runes-decoder extract-tag22-amount 0x6a5d160200f7a538c60a80e8922601)

;; Test the Xverse-specific parser function (use output index 1)
(contract-call? .runes-decoder parse-xverse-transfer 0x6a5d160200f7a538c60a80e8922601 u1)

;; Test the general runes transfer parser
;; For your Rune ID 922359:1350
;; First parameter is the full transaction, second is the block number (922359),
;; third is the tx index (1350), fourth is the expected output index (1)
(contract-call? .runes-decoder parse-runes-transfer 0x6a5d160200f7a538c60a80e8922601 u922359 u1350 u1)
```

If your Rune ID isn't directly encoded as separate block and tx parameters in the transfer transaction, you might need to use the combined ID when testing:

```
;; For testing when the Rune ID is a single value
;; Assuming your Rune ID 922359:1350 is encoded as some integer value
;; You might need to calculate this value based on the encoding scheme
(contract-call? .runes-decoder parse-tag22-transfer 0x6a5d160200f7a538c60a80e8922601 u2 u[YOUR_ENCODED_RUNE_ID] u1)
```

Start with the `decode-any-runestone` function, as it gives you a detailed breakdown of all parameters without validating them. This will help you understand how the data is structured and what values to expect when testing the other functions.

Also, you can trace the execution with the print statements we included to see the parsed values at each step:

```
(contract-call? .runes-decoder parse-runes-transfer 0x6a5d160200f7a538c60a80e8922601 u922359 u1350 u1)
```

If you need to adjust the amount calculation based on what you learn from the decoded parameters, you can update the formula in the `parse-xverse-transfer` function accordingly.