;; ============================================================================
;; LEB128 Decoder - With decimal literals instead of hex
;; ============================================================================

(define-constant ERR-LEB128-OUT-OF-BOUNDS u1000)

;; Read a single byte as uint8, returning the value and updated offset
(define-read-only (read-byte (data (buff 4096)) (offset uint))
  (if (>= offset (len data))
    (err ERR-LEB128-OUT-OF-BOUNDS)
    (ok {
      byte: (buff-to-uint-le (unwrap-panic (as-max-len?
        (unwrap! (slice? data offset (+ offset u1)) (err ERR-LEB128-OUT-OF-BOUNDS))
        u1
      ))),
      next-offset: (+ offset u1)
    })
  )
)

;; Decode a LEB128 integer
(define-read-only (decode-leb128 (data (buff 4096)) (start-offset uint))
  ;; Read first byte
  (let (
      (byte1-result (try! (read-byte data start-offset)))
      (byte1 (get byte byte1-result))
      (offset1 (get next-offset byte1-result))
      ;; Using decimal literals instead of hex
      (data-bits1 (bit-and byte1 u127))  ;; u127 instead of 0x7f
      (has-more1 (> (bit-and byte1 u128) u0))  ;; u128 instead of 0x80
    )
    (if (not has-more1)
      ;; Single byte value
      (ok { value: data-bits1, next-offset: offset1 })
      
      ;; Read second byte
      (let (
          (byte2-result (try! (read-byte data offset1)))
          (byte2 (get byte byte2-result))
          (offset2 (get next-offset byte2-result))
          (data-bits2 (bit-and byte2 u127))
          (has-more2 (> (bit-and byte2 u128) u0))
          (value12 (+ data-bits1 (* data-bits2 (pow u2 u7))))
        )
        (if (not has-more2)
          ;; Two byte value
          (ok { value: value12, next-offset: offset2 })
          
          ;; Read third byte
          (let (
              (byte3-result (try! (read-byte data offset2)))
              (byte3 (get byte byte3-result))
              (offset3 (get next-offset byte3-result))
              (data-bits3 (bit-and byte3 u127))
              (has-more3 (> (bit-and byte3 u128) u0))
              (value123 (+ value12 (* data-bits3 (pow u2 u14))))
            )
            (if (not has-more3)
              ;; Three byte value
              (ok { value: value123, next-offset: offset3 })
              
              ;; Read fourth byte
              (let (
                  (byte4-result (try! (read-byte data offset3)))
                  (byte4 (get byte byte4-result))
                  (offset4 (get next-offset byte4-result))
                  (data-bits4 (bit-and byte4 u127))
                  (value1234 (+ value123 (* data-bits4 (pow u2 u21))))
                )
                ;; Four byte value
                (ok { value: value1234, next-offset: offset4 })
              )
            )
          )
        )
      )
    )
  )
)

;; Simple function to parse a Runes edict from a scriptPubKey
(define-read-only (parse-simple-runes-transfer 
    (script (buff 1376))
    (expected-rune-block uint)
    (expected-rune-tx uint)
    (expected-output uint)
  )
  ;; Check for OP_RETURN (0x6a) + OP_13 (0x5d)
  (if (or (< (len script) u2) 
          (not (is-eq (unwrap! (element-at script u0) (err u100)) 0x6a))
          (not (is-eq (unwrap! (element-at script u1) (err u100)) 0x5d)))
    (err u101) ;; Not a runestone
    
    ;; Parse the tag (should be 0 for edicts)
    (let (
        (tag-result (try! (decode-leb128 script u2)))
        (tag (get value tag-result))
        (next-offset (get next-offset tag-result))
      )
      (print { msg: "Tag parsed", tag: tag, next-offset: next-offset })
      (if (not (is-eq tag u0))
        (err u102) ;; Not an edict
        
        ;; Parse rune ID (block delta)
        (let (
            (block-result (try! (decode-leb128 script next-offset)))
            (rune-block (get value block-result))
            (next-offset2 (get next-offset block-result))
          )
          (print { msg: "Block parsed", rune-block: rune-block, expected-block: expected-rune-block, next-offset: next-offset2 })
          ;; Verify rune block matches expected
          (if (not (is-eq rune-block expected-rune-block))
            (err u103) ;; Wrong rune
            
            ;; Parse rune ID (tx index)
            (let (
                (tx-result (try! (decode-leb128 script next-offset2)))
                (rune-tx (get value tx-result))
                (next-offset3 (get next-offset tx-result))
              )
              (print { msg: "TX parsed", rune-tx: rune-tx, expected-tx: expected-rune-tx, next-offset: next-offset3 })
              ;; Verify rune tx matches expected
              (if (not (is-eq rune-tx expected-rune-tx))
                (err u103) ;; Wrong rune
                
                ;; Parse amount
                (let (
                    (amount-result (try! (decode-leb128 script next-offset3)))
                    (amount (get value amount-result))
                    (next-offset4 (get next-offset amount-result))
                  )
                  (print { msg: "Amount parsed", amount: amount, next-offset: next-offset4 })
                  ;; Parse output
                  (let (
                      (output-result (try! (decode-leb128 script next-offset4)))
                      (output (get value output-result))
                    )
                    (print { msg: "Output parsed", output: output, expected-output: expected-output })
                    ;; Verify output matches expected
                    (if (not (is-eq output expected-output))
                      (err u104) ;; Wrong output
                      
                      ;; Return the amount
                      (ok amount)
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

;; Test function to decode specific parts of the runestone
(define-read-only (test-decode-runestone-parts (script (buff 1376)))
  (let (
      ;; Skip OP_RETURN and OP_13 (0x6a 0x5d)
      (tag-result (try! (decode-leb128 script u2)))
      (tag (get value tag-result))
      (next-offset1 (get next-offset tag-result))
      
      ;; Decode block delta
      (block-result (try! (decode-leb128 script next-offset1)))
      (block (get value block-result))
      (next-offset2 (get next-offset block-result))
      
      ;; Decode tx index
      (tx-result (try! (decode-leb128 script next-offset2)))
      (tx (get value tx-result))
      (next-offset3 (get next-offset tx-result))
      
      ;; Decode amount
      (amount-result (try! (decode-leb128 script next-offset3)))
      (amount (get value amount-result))
      (next-offset4 (get next-offset tx-result))
      
      ;; Decode output
      (output-result (try! (decode-leb128 script next-offset4)))
      (output (get value output-result))
    )
    (ok {
      tag: tag,
      block: block,
      tx: tx,
      amount: amount,
      output: output
    })
  )
)