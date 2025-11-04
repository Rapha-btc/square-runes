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

;; Direct decoding test to see all parsed values
(contract-call? .leb128-decoder test-decode-runestone-parts 0x6a5d0082b49d01640164)