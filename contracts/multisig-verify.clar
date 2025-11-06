;; multisig-verify.clar
;; A minimal contract for verifying Bitcoin P2SH multisig addresses
;; by calling the existing sbtc-bootstrap-signers contract

;; For P2SH format verification
(define-constant OP-HASH160 0xa9)
(define-constant OP-EQUAL 0x87)
(define-constant PUSH-20 0x14)  ;; Push 20 bytes onto the stack

;; Create P2SH scriptPubKey from a script hash
(define-read-only (script-hash-to-p2sh (script-hash (buff 20)))
  (concat 
    (concat 
      (concat 
        0xa9  ;; OP_HASH160
        0x14  ;; PUSH_20
      )
      script-hash
    )
    0x87  ;; OP_EQUAL
  )
)

;; The main verification function - checks if a Bitcoin P2SH scriptPubKey
;; was created from the given pubkeys and m value
(define-public (verify-multisig-address
    (pubkeys (list 128 (buff 33)))
    (m uint)
    (script-pub-key (buff 23))  ;; The P2SH scriptPubKey (23 bytes)
  )
  (let (
      ;; Call the existing contract to get the script hash
      (script-hash (contract-call? 'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-bootstrap-signers pubkeys-to-hash pubkeys m))
      (expected-script-pub-key (script-hash-to-p2sh script-hash))
    )
    ;; Verify the address matches what we expect
    (ok (is-eq script-pub-key expected-script-pub-key))
  )
)
