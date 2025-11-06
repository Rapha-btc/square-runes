;; test.clar
;; Absolute minimum test contract

;; Test with hardcoded pubkey hash
(define-public (test-address)
  ;; 0x0fdfdb51fdaae15933b28e0a732f71984f680b03 is from our Bitcoin test wallet
  (let ((test-addr (principal-construct? 0x16 0x0fdfdb51fdaae15933b28e0a732f71984f680b03)))
    (match test-addr
      success (ok success)
      error (err u1))
  )
)

;; Convert test address to Bitcoin
(define-public (convert-test)
  (let ((test-addr (unwrap! (principal-construct? 0x16 0x0fdfdb51fdaae15933b28e0a732f71984f680b03) (err u2))))
    (contract-call? .base58-v3 convert test-addr)
  )
)

;; Convert your address to Bitcoin
(define-public (convert-your)
  (contract-call? .base58-v3 convert 'SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B)
)
