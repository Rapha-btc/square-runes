;; ============================================================================
;; Documentation & Examples
;; ============================================================================

;; Example: DOG Rune (DOG•GO•TO•THE•MOON)
;; Rune ID: 2585442:1183
;; Block: 2585442 (0x82B49D01 in LEB128)
;; TX Index: 1183 (0x9F09 in LEB128)
;;
;; A transfer of 100 DOG to output 1 encodes as:
;; 0x6a 0x5d 0x00 0x82b49d01 0x9f09 0x64 0x01
;; │    │    │    │          │      │    └─ Output index: 1
;; │    │    │    │          │      └────── Amount: 100
;; │    │    │    │          └───────────── TX index: 1183
;; │    │    │    └──────────────────────── Block: 2585442
;; │    │    └───────────────────────────── Tag: 0 (edicts)
;; │    └────────────────────────────────── OP_13 (Runes magic)
;; └─────────────────────────────────────── OP_RETURN


(contract-call? .leb128-decoder parse-simple-runes-transfer 0x6a5d0082b49d01640164 u2578946 u100 u100)
(ok u1)
```

This represents:

1. **Input Data** (`0x6a5d0082b49d01640164`):
   - `0x6a`: OP_RETURN marker
   - `0x5d`: OP_13 marker (Runes protocol indicator)
   - `0x00`: Tag 0 (edicts - transfer instruction)
   - `0x82 0xb4 0x9d 0x01`: Block delta (LEB128 encoded as 2578946)
   - `0x64`: TX index (LEB128 encoded as 100)
   - `0x01`: Amount (LEB128 encoded as 1)
   - `0x64`: Output index (LEB128 encoded as 100)

2. **Expected Values**:
   - Block: `u2578946` (matches the encoded value)
   - TX: `u100` (matches the encoded value)
   - Output: `u100` (matches the encoded value)

3. **Result**:
   - `(ok u1)`: Successfully parsed and returned the amount (1) of the Rune being transferred

This command successfully decoded a Runes protocol transfer message, verified that it matches the expected Rune ID (block+tx) and destination output, and extracted the transfer amount.

## 3. Testing with Real-World Data

We can absolutely try with real-world data. Let me help you find and analyze a real Runes transfer.

Here's how we would approach this:

1. Find a Bitcoin transaction with a Runes transfer on mempool.space or another explorer
2. Extract the OP_RETURN data from the transaction
3. Format it for testing with our decoder
4. Run the test and verify the results

To find a real transaction, you would look for Bitcoin transactions with OP_RETURN outputs containing the Runes protocol marker (0x6a 0x5d). Once we have that data, we can run a command like:
```
(contract-call? .leb128-decoder parse-simple-runes-transfer 
  [OP_RETURN_DATA] 
  [EXPECTED_BLOCK]
  [EXPECTED_TX]
  [EXPECTED_OUTPUT])