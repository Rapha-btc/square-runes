;; Test 1: Decode a single byte value (0x64 = 100 decimal)
(contract-call? .leb128-decoder decode-leb128 0x64 u0)

;; Test 2: Decode a two-byte value (0x8101 = 129 decimal)
(contract-call? .leb128-decoder decode-leb128 0x8101 u0)

;; Test 3: Decode a three-byte value (0x828001 = 16384 decimal)
(contract-call? .leb128-decoder decode-leb128 0x828001 u0)

;; Test 4: Test the Runes transfer parser with a simple example
;; This is a simulated Runes transfer with:
;; - OP_RETURN 0x6a
;; - OP_13 0x5d
;; - Tag 0 (edicts)
;; - Block delta 2585442
;; - TX index 1183
;; - Amount 100
;; - Output 1
(contract-call? .leb128-decoder parse-simple-runes-transfer 0x6a5d0082b49d01640164 u2585442 u1183 u1)

;; With print statements to debug
(contract-call? .leb128-decoder parse-simple-runes-transfer 0x6a5d0082b49d01640164 u2578946 u100 u100)

;; Send 1 unit of Rune 2578946:100 to output #100 of this transaction"

;; Direct decoding test to see all parsed values
(contract-call? .leb128-decoder test-decode-runestone-parts 0x6a5d0082b49d01640164)


;; ===

To test the updated Runes decoder in the Clarinet console, you'll want to use the following commands:

1. First, make sure your contract is deployed in the Clarinet environment:
   ```
   (contract-call? .runes-decoder decode-any-runestone 0x6a5d0b00caa2338b0788e0ea0101)
   ```

2. To test specifically with your Magic Eden transaction:
   ```
   (contract-call? .runes-decoder decode-any-runestone 0x6a5d0b00caa2338b0788e0ea0101)
   ```

3. To check if it's a valid runestone and determine the tag:
   ```
   (contract-call? .runes-decoder get-runestone-tag 0x6a5d0b00caa2338b0788e0ea0101)
   ```

4. To test parsing with specific expected values:
   ```
   (contract-call? .runes-decoder parse-runes-transfer 0x6a5d0b00caa2338b0788e0ea0101 u0 u0 u1)
   ```
   This checks if the transaction is transferring Rune ID 0:0 to output 1.

5. If you want to compare with the previous implementation, you can still use:
   ```
   (contract-call? .leb128-decoder test-decode-runestone-parts 0x6a5d0b00caa2338b0788e0ea0101)
   ```

The most informative test will be the first one using `decode-any-runestone`, as it makes the fewest assumptions about the structure and will show you all the decoded LEB128 values in the transaction.