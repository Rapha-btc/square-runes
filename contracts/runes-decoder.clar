;; ============================================================================
;; LEB128 Decoder - With support for Tag 11 (0x0b) transfers
;; ============================================================================

(define-constant ERR-LEB128-OUT-OF-BOUNDS u1000)
(define-constant ERR-NOT-A-RUNESTONE u101)
(define-constant ERR-UNSUPPORTED-TAG u102)
(define-constant ERR-WRONG-RUNE u103)
(define-constant ERR-WRONG-OUTPUT u104)

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

;; Check if a buffer starts with OP_RETURN (0x6a) + OP_13 (0x5d)
(define-read-only (is-runestone (script (buff 1376)))
  (and
    (>= (len script) u2)
    (is-eq (unwrap! (element-at script u0) false) 0x6a)
    (is-eq (unwrap! (element-at script u1) false) 0x5d)
  )
)

;; Parse a Runes transfer from scriptPubKey - supports both Tag 0 (edict) and Tag 11 (0x0b) transfers
(define-read-only (parse-runes-transfer 
    (script (buff 1376))
    (expected-rune-block uint)
    (expected-rune-tx uint)
    (expected-output uint)
  )
  ;; Check for OP_RETURN (0x6a) + OP_13 (0x5d)
  (if (not (is-runestone script))
    (err ERR-NOT-A-RUNESTONE) ;; Not a runestone
    
    ;; Parse the tag
    (let (
        (tag-result (try! (decode-leb128 script u2)))
        (tag (get value tag-result))
        (next-offset (get next-offset tag-result))
      )
      (print { msg: "Tag parsed", tag: tag, next-offset: next-offset })
      
      ;; Check if this is a supported tag (Tag 0 = edict or Tag 11 = 0x0b)
      (if (and (not (is-eq tag u0)) (not (is-eq tag u11)))
        (err ERR-UNSUPPORTED-TAG) ;; Unsupported tag type
        
        ;; Parse rune ID (block delta or direct ID)
        (let (
            (rune-id-result (try! (decode-leb128 script next-offset)))
            (rune-id (get value rune-id-result))
            (next-offset2 (get next-offset rune-id-result))
          )
          (print { msg: "Rune ID parsed", rune-id: rune-id, next-offset: next-offset2 })
          
          ;; For Tag 0, we expect block + tx. For Tag 11, we may have a different structure
          (if (is-eq tag u0)
            ;; Standard Tag 0 edict - continue with tx index
            (let (
                (tx-result (try! (decode-leb128 script next-offset2)))
                (rune-tx (get value tx-result))
                (next-offset3 (get next-offset tx-result))
              )
              (print { msg: "TX parsed", rune-tx: rune-tx, expected-tx: expected-rune-tx, next-offset: next-offset3 })
              
              ;; Verify rune block and tx match expected values
              (if (or (not (is-eq rune-id expected-rune-block)) 
                      (not (is-eq rune-tx expected-rune-tx)))
                (err ERR-WRONG-RUNE) ;; Wrong rune
                
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
                      (err ERR-WRONG-OUTPUT) ;; Wrong output
                      
                      ;; Return the amount
                      (ok amount)
                    )
                  )
                )
              )
            )
            
            ;; Tag 11 transfer - different format, likely with direct Rune ID
            ;; For now, we just decode remaining data to get amount and output
            (let (
                ;; Decode amount (which may be encoded differently in Tag 11)
                ;; This is an estimation - may need adjustment based on actual protocol
                (amount-result (try! (decode-leb128 script next-offset2)))
                (amount (get value amount-result))
                (next-offset3 (get next-offset amount-result))
                
                ;; Try to decode output
                (output-result (try! (decode-leb128 script next-offset3)))
                (output (get value output-result))
              )
              (print {
                msg: "Tag 11 transfer parsed",
                rune-id: rune-id,
                amount: amount,
                output: output
              })
              
              ;; For Tag 11, we check if the rune-id matches expected rune-block
              ;; This is a simplification - in reality we'd need to know how rune IDs are represented
              (if (not (is-eq rune-id expected-rune-block))
                (err ERR-WRONG-RUNE)
                
                ;; Check output matches expected
                (if (not (is-eq output expected-output))
                  (err ERR-WRONG-OUTPUT)
                  
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

;; Test function to decode any runestone regardless of tag
(define-read-only (decode-any-runestone (script (buff 1376)))
  (if (not (is-runestone script))
    (err ERR-NOT-A-RUNESTONE)
    
    (let (
        ;; Parse tag
        (tag-result (try! (decode-leb128 script u2)))
        (tag (get value tag-result))
        (next-offset1 (get next-offset tag-result))
        
        ;; Parse first parameter (rune ID or block delta)
        (param1-result (try! (decode-leb128 script next-offset1)))
        (param1 (get value param1-result))
        (next-offset2 (get next-offset param1-result))
        
        ;; Parse second parameter (tx index or amount)
        (param2-result (try! (decode-leb128 script next-offset2)))
        (param2 (get value param2-result))
        (next-offset3 (get next-offset param2-result))
        
        ;; Parse third parameter (amount or output)
        (param3-result (try! (decode-leb128 script next-offset3)))
        (param3 (get value param3-result))
        (next-offset4 (get next-offset param3-result))
        
        ;; Try to parse fourth parameter if it exists
        (param4 (if (>= (len script) next-offset4)
                   (match (decode-leb128 script next-offset4)
                     success (some (get value success))
                     error none)
                   none))
      )
      
      (ok {
        tag: tag,
        param1: param1,
        param2: param2,
        param3: param3,
        param4: param4
      })
    )
  )
)

;; Check if a script is a valid runestone and determine its tag
(define-read-only (get-runestone-tag (script (buff 1376)))
  (if (not (is-runestone script))
    (err ERR-NOT-A-RUNESTONE)
    
    (match (decode-leb128 script u2)
      success (ok (get value success))
      error (err error)
    )
  )
)
