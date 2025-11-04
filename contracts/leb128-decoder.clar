;; ============================================================================
;; LEB128 Decoder for Runes Protocol
;; ============================================================================

(define-constant ERR-LEB128-OUT-OF-BOUNDS (err u1000))
(define-constant ERR-LEB128-OVERFLOW (err u1001))

;; Decode a single LEB128-encoded integer
;; Returns: (ok { value: uint, next-offset: uint })
(define-read-only (decode-leb128 (data (buff 4096)) (start-offset uint))
  ;; Bounds check
  (if (>= start-offset (len data))
    (err ERR-LEB128-OUT-OF-BOUNDS)
    
    ;; Read first byte
    (let (
        (byte1 (unwrap! (element-at data start-offset) (err ERR-LEB128-OUT-OF-BOUNDS)))
        ;; Assuming we could convert byte1 to uint:
        (data-bits1 (bit-and byte1 0x7f))
        (has-more1 (> (bit-and byte1 0x80) u0))
      )
      (if (not has-more1)
        ;; Single byte value
        (ok { value: data-bits1, next-offset: (+ start-offset u1) })
        
        ;; Multiple bytes
        (if (>= (+ start-offset u1) (len data))
          (err ERR-LEB128-OUT-OF-BOUNDS)
          (let (
              (byte2 (unwrap! (element-at data (+ start-offset u1)) (err ERR-LEB128-OUT-OF-BOUNDS)))
              (data-bits2 (bit-and byte2 0x7f))
              (has-more2 (> (bit-and byte2 0x80) u0))
              (value12 (+ data-bits1 (* data-bits2 (pow u2 u7))))
            )
            (if (not has-more2)
              ;; Two byte value
              (ok { value: value12, next-offset: (+ start-offset u2) })
              
              ;; Three or more bytes
              (if (>= (+ start-offset u2) (len data))
                (err ERR-LEB128-OUT-OF-BOUNDS)
                (let (
                    (byte3 (unwrap! (element-at data (+ start-offset u2)) (err ERR-LEB128-OUT-OF-BOUNDS)))
                    (data-bits3 (bit-and byte3 0x7f))
                    (has-more3 (> (bit-and byte3 0x80) u0))
                    (value123 (+ value12 (* data-bits3 (pow u2 u14))))
                  )
                  (if (not has-more3)
                    ;; Three byte value
                    (ok { value: value123, next-offset: (+ start-offset u3) })
                    
                    ;; Four byte value
                    (if (>= (+ start-offset u3) (len data))
                      (err ERR-LEB128-OUT-OF-BOUNDS)
                      (let (
                          (byte4 (unwrap! (element-at data (+ start-offset u3)) (err ERR-LEB128-OUT-OF-BOUNDS)))
                          (data-bits4 (bit-and byte4 0x7f))
                          (value1234 (+ value123 (* data-bits4 (pow u2 u21))))
                        )
                        (ok { value: value1234, next-offset: (+ start-offset u4) })
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
      (if (not (is-eq tag u0))
        (err u102) ;; Not an edict
        
        ;; Parse rune ID (block delta)
        (let (
            (block-result (try! (decode-leb128 script next-offset)))
            (rune-block (get value block-result))
            (next-offset2 (get next-offset block-result))
          )
          ;; Verify rune block matches expected
          (if (not (is-eq rune-block expected-rune-block))
            (err u103) ;; Wrong rune
            
            ;; Parse rune ID (tx index)
            (let (
                (tx-result (try! (decode-leb128 script next-offset2)))
                (rune-tx (get value tx-result))
                (next-offset3 (get next-offset tx-result))
              )
              ;; Verify rune tx matches expected
              (if (not (is-eq rune-tx expected-rune-tx))
                (err u103) ;; Wrong rune
                
                ;; Parse amount
                (let (
                    (amount-result (try! (decode-leb128 script next-offset3)))
                    (amount (get value amount-result))
                    (next-offset4 (get next-offset amount-result))
                  )
                  ;; Parse output
                  (let (
                      (output-result (try! (decode-leb128 script next-offset4)))
                      (output (get value output-result))
                    )
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