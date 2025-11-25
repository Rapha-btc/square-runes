;; log-opreturn.clar
;; Minimal contract to log OP_RETURN and verify multisig output from Bitcoin PSBT
;; Multisig: bc1qxgs852k3ee87h33ycw3qdr8zdsrqy3td83qqja8f3986llt66z2qcnk2zp

(define-constant ERR-ELEMENT-EXPECTED (err u129))
(define-constant ERR-TRANSACTION (err u131))
(define-constant ERR-MULTISIG-NOT-FOUND (err u132))

;; Multisig scriptPubKey from tx output 1 (P2WSH format: 0x0020 + 32-byte witness program)
;; TODO: Verify this matches bc1qxgs852k3ee87h33ycw3qdr8zdsrqy3td83qqja8f3986llt66z2qcnk2zp
(define-constant MULTISIG_SCRIPTPUBKEY 0x002032207a2ad1ce4febc624c3a2068ce26c0602456d3c400974e9894faffd7ad094)

;; Expected value: 546 sats (dust limit for Runes)
(define-constant EXPECTED_SATS u546)

;; ============================================
;; Helper: read uint64 little-endian from buffer
;; ============================================
(define-read-only (read-uint64-le (value-buff (buff 8)))
  (buff-to-uint-le value-buff)
)

;; ============================================
;; Get output at index from parsed segwit tx
;; ============================================
(define-read-only (get-output-segwit (tx (buff 4096)) (index uint))
  (let ((parsed-tx (contract-call?
      'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.clarity-bitcoin-lib-v7
      parse-wtx tx false
    )))
    (match parsed-tx
      result (let (
          (outs (get outs (unwrap-panic parsed-tx)))
          (out (unwrap! (element-at? outs index) ERR-TRANSACTION))
        )
        (ok {
          scriptPubKey: (get scriptPubKey out),
          value: (get value out)
        })
      )
      missing ERR-TRANSACTION
    )
  )
)

;; ============================================
;; Extract raw OP_RETURN payload from output 0
;; ============================================
(define-read-only (get-opreturn-payload (tx (buff 4096)))
  (match (get-output-segwit tx u0)
    result (let (
        (script (get scriptPubKey result))
        (script-len (len script))
        ;; OP_RETURN: 6a <len> <data> or 6a 4c <len> <data>
        (offset (if (is-eq (unwrap! (element-at? script u1) ERR-ELEMENT-EXPECTED) 0x4c)
          u3
          u2
        ))
        (payload (unwrap! (slice? script offset script-len) ERR-ELEMENT-EXPECTED))
      )
      (ok {
        full-script: script,
        payload: payload,
        payload-len: (len payload)
      })
    )
    error ERR-ELEMENT-EXPECTED
  )
)

;; ============================================
;; Find multisig output (searches outputs 1-4)
;; ============================================
(define-read-only (find-multisig-output (tx (buff 4096)))
  (let (
      (out1 (get-output-segwit tx u1))
      (out2 (get-output-segwit tx u2))
    )
    ;; Check output 1 first
    (match out1
      o1 (if (is-eq (get scriptPubKey o1) MULTISIG_SCRIPTPUBKEY)
        (ok {
          index: u1,
          scriptPubKey: (get scriptPubKey o1),
          value: (get value o1)
        })
        ;; Check output 2
        (match out2
          o2 (if (is-eq (get scriptPubKey o2) MULTISIG_SCRIPTPUBKEY)
            (ok {
              index: u2,
              scriptPubKey: (get scriptPubKey o2),
              value: (get value o2)
            })
            ERR-MULTISIG-NOT-FOUND
          )
          e2 ERR-MULTISIG-NOT-FOUND
        )
      )
      e1 ERR-MULTISIG-NOT-FOUND
    )
  )
)

;; ============================================
;; MAIN: Log OP_RETURN and multisig output with mining proof verification
;; ============================================
(define-public (log-opreturn
    (height uint)
    (wtx {
      version: (buff 4),
      ins: (list 50 { outpoint: { hash: (buff 32), index: (buff 4) }, scriptSig: (buff 1376), sequence: (buff 4) }),
      outs: (list 50 { value: (buff 8), scriptPubKey: (buff 1376) }),
      locktime: (buff 4),
    })
    (witness-data (buff 1650))
    (header (buff 80))
    (tx-index uint)
    (tree-depth uint)
    (wproof (list 14 (buff 32)))
    (witness-merkle-root (buff 32))
    (witness-reserved-value (buff 32))
    (ctx (buff 4096))
    (cproof (list 14 (buff 32)))
  )
  (let (
      ;; Concatenate wtx + witness to get full tx buffer
      (tx-buff (contract-call?
        'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.bitcoin-helper-wtx-v2
        concat-wtx wtx witness-data
      ))
    )
    ;; Verify tx was mined
    (match (contract-call?
      'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.clarity-bitcoin-lib-v7
      was-segwit-tx-mined-compact height tx-buff header tx-index tree-depth
      wproof witness-merkle-root witness-reserved-value ctx cproof
    )
      btc-tx-id (let (
          (opreturn-data (get-opreturn-payload tx-buff))
          (multisig-output (find-multisig-output tx-buff))
        )
        ;; Print everything!
        (print {
          type: "log-opreturn",
          btc-tx-id: btc-tx-id,
          height: height,
          opreturn: opreturn-data,
          multisig-output: multisig-output,
          expected-multisig: MULTISIG_SCRIPTPUBKEY,
          expected-sats: EXPECTED_SATS,
        })
        (ok {
          btc-tx-id: btc-tx-id,
          opreturn: opreturn-data,
          multisig-output: multisig-output,
        })
      )
      error (err (* error u1000))
    )
  )
)

;; ============================================
;; READ-ONLY: Test parsing without mining proof
;; ============================================
(define-read-only (test-parse-opreturn (tx-buff (buff 4096)))
  {
    opreturn: (get-opreturn-payload tx-buff),
    multisig-output: (find-multisig-output tx-buff),
    output-0: (get-output-segwit tx-buff u0),
    output-1: (get-output-segwit tx-buff u1),
    output-2: (get-output-segwit tx-buff u2),
  }
)
