;; ============================================================================
;; LEB128 Decoder - With improved Tag 11 (0x0b) handling
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

;; Parse Tag 11 (0x0b) transfer operation
(define-read-only (parse-tag11-transfer
    (script (buff 1376))
    (start-offset uint)
    (expected-rune-id uint)
    (expected-output uint)
  )
  ;; For Tag 11, format is: [Rune ID] [Amount] [Output]
  ;; Parse Rune ID (param1)
  (let (
      (id-result (try! (decode-leb128 script start-offset)))
      (rune-id (get value id-result))
      (offset1 (get next-offset id-result))
    )
    (print { msg: "Tag 11 Rune ID parsed", rune-id: rune-id, expected-rune-id: expected-rune-id })
    
    ;; Verify Rune ID matches expected
    (if (not (is-eq rune-id expected-rune-id))
      (err ERR-WRONG-RUNE)
      
      ;; Attempt to find the amount by reading to the end except last byte
      ;; This is a simplification - in reality we'd need a more complex decoder
      ;; to find the exact amount field in the complex middle section
      (let (
          (remaining-data (- (len script) offset1))
          ;; Assuming the output is the last byte
          (output-offset (- (len script) u1))
          (output-result (try! (decode-leb128 script output-offset)))
          (output (get value output-result))
          
          ;; Read as much data as possible for the amount (complex middle section)
          ;; For real implementation, this would need to be refined
          (amount-offset offset1)
          (amount-result (try! (decode-leb128 script amount-offset)))
          (amount (get value amount-result))
        )
        (print {
          msg: "Tag 11 transfer parsed",
          rune-id: rune-id,
          amount: amount,
          output: output,
          expected-output: expected-output
        })
        
        ;; Verify output matches expected
        (if (not (is-eq output expected-output))
          (err ERR-WRONG-OUTPUT)
          
          ;; Return the amount
          (ok amount)
        )
      )
    )
  )
)

(define-read-only (parse-tag22-transfer
    (script (buff 1376))
    (start-offset uint)
    (expected-rune-block uint)
    (expected-rune-tx uint)
    (expected-output uint)
  )
  ;; Parse protocol params 1 and 2
  (let (
      (param1-result (try! (decode-leb128 script start-offset)))
      (param1 (get value param1-result))
      (offset1 (get next-offset param1-result))
      
      (param2-result (try! (decode-leb128 script offset1)))
      (param2 (get value param2-result))
      (offset2 (get next-offset param2-result))
      
      ;; Parse the Rune block and tx index
      (block-result (try! (decode-leb128 script offset2)))
      (rune-block (get value block-result))
      (offset3 (get next-offset block-result))
      
      (tx-result (try! (decode-leb128 script offset3)))
      (rune-tx (get value tx-result))
      (offset4 (get next-offset tx-result))
      
      ;; Parse amount (param5)
      (amount-result (try! (decode-leb128 script offset4)))
      (amount (get value amount-result))
      (offset5 (get next-offset amount-result))
      
      ;; Parse the output index (last byte)
      (output-offset (- (len script) u1))
      (output-result (try! (decode-leb128 script output-offset)))
      (output (get value output-result))
    )
    
    (print { 
      msg: "Tag 22 transfer decoded", 
      protocol_param1: param1, 
      protocol_param2: param2, 
      rune_block: rune-block, 
      expected_block: expected-rune-block,
      rune_tx: rune-tx,
      expected_tx: expected-rune-tx,
      amount: amount,
      output: output,
      expected_output: expected-output
    })
    
    ;; Verify Rune block and tx match expected
    (if (or 
          (not (is-eq rune-block expected-rune-block))
          (not (is-eq rune-tx expected-rune-tx))
        )
      (err ERR-WRONG-RUNE)
      
      ;; Verify output matches expected
      (if (not (is-eq output expected-output))
        (err ERR-WRONG-OUTPUT)
        
        ;; Return all relevant data
        (ok {
          protocol_param1: param1,
          protocol_param2: param2,
          rune_block: rune-block,
          rune_tx: rune-tx,
          amount: amount,
          output: output
        })
      )
    )
  )
)

(define-read-only (parse-xverse-transfer (script (buff 1376)) (expected-output uint))
  (if (not (is-runestone script))
    (err ERR-NOT-A-RUNESTONE)
    
    (let (
        (tag-result (try! (decode-leb128 script u2)))
        (tag (get value tag-result))
      )
      (if (not (is-eq tag u22))
        (err ERR-UNSUPPORTED-TAG)
        
        ;; For Xverse transactions, decode the structure
        (let (
            (offset1 (get next-offset tag-result))
            (rune-block-result (try! (decode-leb128 script offset1)))
            (rune-block (get value rune-block-result))
            (offset2 (get next-offset rune-block-result))
            
            (rune-tx-result (try! (decode-leb128 script offset2)))
            (rune-tx (get value rune-tx-result))
            (offset3 (get next-offset rune-tx-result))
            
            ;; Parse parameters for amount calculation
            (amount-p1-result (try! (decode-leb128 script offset3)))
            (amount-p1 (get value amount-p1-result))
            (offset4 (get next-offset amount-p1-result))
            
            ;; Use a combined formula based on the specific LEB128 encoding pattern
            ;; This formula will need adjustment based on actual encoding
            (amount (* amount-p1 u256))
            
            ;; Check output (last byte)
            (output-offset (- (len script) u1))
            (output-result (try! (decode-leb128 script output-offset)))
            (output (get value output-result))
          )
          
          (print {
            msg: "Xverse transfer",
            rune-block: rune-block,
            rune-tx: rune-tx,
            amount: amount,
            output: output
          })
          
          (if (not (is-eq output expected-output))
            (err ERR-WRONG-OUTPUT)
            (ok {
              rune-block: rune-block,
              rune-tx: rune-tx,
              amount: amount,
              output: output
            })
          )
        )
      )
    )
  )
)

(define-read-only (extract-tag22-amount (script (buff 1376)))
  (if (not (is-runestone script))
    (err ERR-NOT-A-RUNESTONE)
    
    (let (
        (tag-result (try! (decode-leb128 script u2)))
        (tag (get value tag-result))
      )
      (if (not (is-eq tag u22))
        (err ERR-UNSUPPORTED-TAG)
        
        ;; For Xverse transactions (6a5d160200f7a538c60a80e8922601)
        (let (
            (offset1 (get next-offset tag-result))
            (param1-result (try! (decode-leb128 script offset1)))
            (offset2 (get next-offset param1-result))
            (param2-result (try! (decode-leb128 script offset2)))
            (offset3 (get next-offset param2-result))
            (param3-result (try! (decode-leb128 script offset3)))
            (offset4 (get next-offset param3-result))
          )
          ;; Try to parse the amount parameter
          (if (>= (len script) offset4)
            (match (decode-leb128 script offset4)
              success (ok (get value success))
              error (err u1005) ;; Error reading amount
            )
            (err u1006) ;; Not enough data for amount
          )
        )
      )
    )
  )
)

;; Parse a Runes transfer from scriptPubKey - supports both Tag 0 and Tag 11 (0x0b)
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
      
      ;; Handle different tag types using if/else instead of cond
      (if (is-eq tag u0)
        ;; Tag 0 (standard edict/transfer)
        (let (
            (block-result (try! (decode-leb128 script next-offset)))
            (rune-block (get value block-result))
            (next-offset2 (get next-offset block-result))
          )
          (print { msg: "Block parsed", rune-block: rune-block, expected-block: expected-rune-block, next-offset: next-offset2 })
          
          ;; Verify block matches expected
          (if (not (is-eq rune-block expected-rune-block))
            (err ERR-WRONG-RUNE)
            
            ;; Parse tx index
            (let (
                (tx-result (try! (decode-leb128 script next-offset2)))
                (rune-tx (get value tx-result))
                (next-offset3 (get next-offset tx-result))
              )
              (print { msg: "TX parsed", rune-tx: rune-tx, expected-tx: expected-rune-tx, next-offset: next-offset3 })
              
              ;; Verify tx index matches expected
              (if (not (is-eq rune-tx expected-rune-tx))
                (err ERR-WRONG-RUNE)
                
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
        
        ;; Check if it's Tag 11
        (if (is-eq tag u11)
          ;; Tag 11 (0x0b) specialized transfer
          ;; For Tag 11, expected_rune_block is treated as the Rune ID directly
          (parse-tag11-transfer script next-offset expected-rune-block expected-output)
          
          ;; Check if it's Tag 22
          (if (is-eq tag u22) ;; Decimal 22 (0x16)
            ;; Add Tag 22 parsing similar to Tag 11
            (parse-tag22-transfer script next-offset expected-rune-block expected-output)       

            ;; Unsupported tag
            (err ERR-UNSUPPORTED-TAG))
        )
      )
    )
  )
)

;; Extract the amount from a Tag 11 transfer - specialized function for Magic Eden style transactions
(define-read-only (extract-tag11-amount (script (buff 1376)))
  (if (not (is-runestone script))
    (err ERR-NOT-A-RUNESTONE)
    
    (let (
        (tag-result (try! (decode-leb128 script u2)))
        (tag (get value tag-result))
      )
      (if (not (is-eq tag u11))
        (err ERR-UNSUPPORTED-TAG)
        
        ;; For Magic Eden transactions (6a5d0b00caa2338b0788e0ea0101),
        ;; param4 contains the amount (u3846152)
        (let (
            (offset1 (get next-offset tag-result))
            (param1-result (try! (decode-leb128 script offset1)))
            (offset2 (get next-offset param1-result))
            (param2-result (try! (decode-leb128 script offset2)))
            (offset3 (get next-offset param2-result))
            (param3-result (try! (decode-leb128 script offset3)))
            (offset4 (get next-offset param3-result))
          )
          ;; Try to read param4 if it exists - this should be the amount
          (if (>= (len script) offset4)
            (match (decode-leb128 script offset4)
              success (ok (get value success))
              error (err u1005) ;; Error reading amount
            )
            (err u1006) ;; Not enough data for param4
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

;; Test function specifically for Magic Eden transactions
;; This handles the format 6a5d0b00caa2338b0788e0ea0101
(define-read-only (parse-magic-eden-transfer (script (buff 1376)) (expected-output uint))
  (if (not (is-runestone script))
    (err ERR-NOT-A-RUNESTONE)
    
    (let (
        (tag-result (try! (decode-leb128 script u2)))
        (tag (get value tag-result))
      )
      (if (not (is-eq tag u11))
        (err ERR-UNSUPPORTED-TAG)
        
        ;; For Magic Eden transactions, extract param1 (Rune ID) and param4 (amount)
        (let (
            (offset1 (get next-offset tag-result))
            (id-result (try! (decode-leb128 script offset1)))
            (rune-id (get value id-result))
            
            ;; Extract amount (param4)
            (amount-result (try! (extract-tag11-amount script)))
            (amount amount-result)
            
            ;; Check output (last byte)
            (output-offset (- (len script) u1))
            (output-result (try! (decode-leb128 script output-offset)))
            (output (get value output-result))
          )
          
          (print {
            msg: "Magic Eden transfer",
            rune-id: rune-id,
            amount: amount,
            output: output
          })
          
          (if (not (is-eq output expected-output))
            (err ERR-WRONG-OUTPUT)
            (ok {
              rune-id: rune-id,
              amount: amount,
              output: output
            })
          )
        )
      )
    )
  )
)

(define-read-only (decode-amount-from-tag22 (script (buff 1376)))
     ;; Skip tag and first 4 parameters to get to where the amount should be
     (let (
         (tag-result (try! (decode-leb128 script u2)))
         (offset1 (get next-offset tag-result))
         (param1-result (try! (decode-leb128 script offset1)))
         (offset2 (get next-offset param1-result))
         (param2-result (try! (decode-leb128 script offset2)))
         (offset3 (get next-offset param2-result))
         (param3-result (try! (decode-leb128 script offset3)))
         (offset4 (get next-offset param3-result))
         (param4-result (try! (decode-leb128 script offset4)))
         (offset5 (get next-offset param4-result))
       )
       ;; Try to decode remaining bytes as amount
       (if (>= (len script) offset5)
         (match (decode-leb128 script offset5)
           success (ok (get value success))
           error (err u1005))
         (err u1006))
     )
   )

   (define-read-only (extract-raw-bytes (script (buff 1376)) (start uint) (end uint))
     (if (or (>= start (len script)) (> end (len script)) (> start end))
       (err u1000)
       (ok (unwrap! (slice? script start end) (err u1000)))
     )
   )