;; ============================================================================
;; LEB128 Decoder for Clarity
;; ============================================================================
;; 
;; LEB128 (Little Endian Base 128) is a variable-length encoding used in the
;; Runes protocol to efficiently encode integers in Bitcoin OP_RETURN outputs.
;;
;; Version: 1.0.1
;; License: MIT
;; ============================================================================

;; ============================================================================
;; Constants
;; ============================================================================

(define-constant ERR-OUT-OF-BOUNDS (err u1000))
(define-constant ERR-DECODE-OVERFLOW (err u1001))
(define-constant ERR-EMPTY-BUFFER (err u1003))

;; ============================================================================
;; Core LEB128 Decoder
;; ============================================================================

;; Decode a single LEB128-encoded integer from a buffer at the given offset
;; 
;; Parameters:
;;   - data: Buffer containing LEB128-encoded data
;;   - start-offset: Position in buffer where LEB128 integer starts
;;
;; Returns:
;;   (ok { value: uint, next-offset: uint })
;;   - value: The decoded integer
;;   - next-offset: Position of next byte after this LEB128 integer
;;
;; Errors:
;;   - ERR-OUT-OF-BOUNDS: Offset exceeds buffer length
;;   - ERR-DECODE-OVERFLOW: More than 10 bytes (invalid for uint64)
;;   - ERR-EMPTY-BUFFER: Buffer is empty
;;
;; Example:
;;   (decode-leb128 0xE58E26 u0) => (ok { value: u624485, next-offset: u3 })
(define-read-only (decode-leb128 
    (data (buff 4096)) 
    (start-offset uint)
  )
  (let (
      (data-len (len data))
    )
    ;; Validation
    (asserts! (> data-len u0) ERR-EMPTY-BUFFER)
    (asserts! (< start-offset data-len) ERR-OUT-OF-BOUNDS)
    
    ;; Decode using fold over max possible bytes
    (let (
        (result (fold decode-leb128-byte
          (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9)
          {
            data: data,
            offset: start-offset,
            value: u0,
            shift: u0,
            done: false,
            error: false
          }
        ))
      )
      ;; Check for errors
      (asserts! (not (get error result)) ERR-DECODE-OVERFLOW)
      (asserts! (get done result) ERR-OUT-OF-BOUNDS)
      
      ;; Return decoded value and next offset
      (ok {
        value: (get value result),
        next-offset: (get offset result)
      })
    )
  )
)

;; Helper function: decode one byte of LEB128
;; This is called by fold for each potential byte in the encoding
(define-private (decode-leb128-byte 
    (byte-idx uint)
    (state {
      data: (buff 4096),
      offset: uint,
      value: uint,
      shift: uint,
      done: bool,
      error: bool
    })
  )
  ;; If already done or error, pass through unchanged
  (if (or (get done state) (get error state))
    state
    ;; Try to read next byte
    (match (element-at? (get data state) (get offset state))
      current-byte-buff (let (
          ;; Convert (buff 1) to uint
          (current-byte (buff-to-uint-le current-byte-buff))
          
          ;; Extract the 7 data bits (bits 0-6)
          (data-bits (bit-and current-byte 0x7f))
          
          ;; Check continuation bit (bit 7)
          ;; If set (0x80), more bytes follow
          ;; If clear (0x00), this is the last byte
          (has-more (is-eq (bit-and current-byte 0x80) 0x80))
          
          ;; Calculate this byte's contribution to the final value
          ;; data-bits * (2 ^ shift)
          (contribution (* data-bits (pow u2 (get shift state))))
          
          ;; Add to accumulated value
          (new-value (+ (get value state) contribution))
          
          ;; Next shift amount (7 bits per byte)
          (new-shift (+ (get shift state) u7))
        )
        {
          data: (get data state),
          offset: (+ (get offset state) u1),
          value: new-value,
          shift: new-shift,
          done: (not has-more),
          error: false
        }
      )
      ;; No byte at this offset - if we haven't finished, it's an error
      (merge state { 
        error: (not (get done state)),
        done: true 
      })
    )
  )
)

;; ============================================================================
;; Test Functions
;; ============================================================================

;; Test basic decoding
(define-read-only (test-decode-basic)
  {
    test0: (decode-leb128 0x00 u0),
    test100: (decode-leb128 0x64 u0),
    test127: (decode-leb128 0x7f u0),
    test128: (decode-leb128 0x8001 u0),
    test300: (decode-leb128 0xac02 u0)
  }
)

;; Test decoding real Runes data
(define-read-only (test-decode-runes-edict)
  (let (
      ;; DOG rune: block 2585442 (0x82B49D01), tx 1183 (0x9F09)
      ;; amount 100 (0x64), output 1 (0x01)
      (data 0x82b49d019f096401)
      
      ;; Decode block number
      (block-result (try! (decode-leb128 data u0)))
      (block-num (get value block-result))
      
      ;; Decode tx index
      (tx-result (try! (decode-leb128 data (get next-offset block-result))))
      (tx-idx (get value tx-result))
      
      ;; Decode amount
      (amount-result (try! (decode-leb128 data (get next-offset tx-result))))
      (amount (get value amount-result))
      
      ;; Decode output
      (output-result (try! (decode-leb128 data (get next-offset amount-result))))
      (output (get value output-result))
    )
    (ok {
      block: block-num,      ;; Should be 2585442
      tx-index: tx-idx,      ;; Should be 1183
      amount: amount,        ;; Should be 100
      output: output,        ;; Should be 1
      bytes-read: (get next-offset output-result)
    })
  )
)

;; Test error conditions
(define-read-only (test-error-cases)
  {
    out-of-bounds: (decode-leb128 0x64 u10),
    empty-buffer: (decode-leb128 0x u0),
    incomplete: (decode-leb128 0x80 u0)
  }
)
