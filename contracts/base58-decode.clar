;; base58-decode.clar
;; from eamon penland's winning entry / Hiro
;; Constants
(define-constant BASE58_CHARS "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
(define-constant ALL_HEX 0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff)

;; Base58 conversion helpers
(define-read-only (get-base58-value (char (string-ascii 1)))
    (unwrap-panic (index-of? BASE58_CHARS char))
)

(define-read-only (string-to-base58-array (str (string-ascii 40)))
    (map get-base58-value str)
)

;; Base256 conversion helpers
(define-read-only (process-byte-with-carry (existing-byte uint) (state {carry: uint, new-bytes: (list 35 uint)}))
    (let (
        (total (+ (* existing-byte u58) (get carry state)))
        (new-carry (/ total u256))
        (new-byte (mod total u256))
    )
        {
            carry: new-carry,
            new-bytes: (unwrap-panic (as-max-len? (append (get new-bytes state) new-byte) u35))
        }
    )
)

(define-read-only (process-base58-value (b58 uint) (bytes (list 35 uint)))
    (let (
        (result (fold process-byte-with-carry bytes {carry: b58, new-bytes: (list)}))
        (final-carry (get carry result))
        (final-bytes (get new-bytes result))
    )
        (if (> final-carry u0)
            (unwrap-panic (as-max-len? (concat final-bytes (list final-carry)) u35))
            final-bytes
        )
    )
)

(define-read-only (base58-to-base256 (base58-array (list 40 uint)))
    (let (
        (array-len (len base58-array))
        (reversed-array (fold process-base58-value 
            (unwrap-panic (slice? base58-array u0 array-len))
            (list u0)
        ))
    )
        (fold process-reverse reversed-array (list))
    )
)

;; Hex conversion helpers
(define-read-only (uint-to-hex (val uint))
    (unwrap-panic (as-max-len? 
        (unwrap-panic (slice? ALL_HEX val (+ val u1)))
        u1
    ))
)

(define-read-only (concat-byte (byte (buff 1)) (acc (buff 35)))
    (unwrap-panic (as-max-len? (concat acc byte) u35))
)

(define-read-only (bytes-to-hex (bytes (list 35 uint)))
    (fold concat-byte 
        (map uint-to-hex bytes)
        0x
    )
)

;; Utility functions
(define-read-only (is-one (i uint)) (is-eq i u0))

(define-read-only (process-reverse (byte uint) (acc (list 35 uint)))
    (unwrap-panic (as-max-len? (concat (list byte) acc) u35))
)

(define-read-only (add-zero-bytes (bytes (list 35 uint)) (count uint))
    (let (
        (zeros (unwrap-panic (slice? (list u0 u0 u0 u0 u0 u0 u0 u0 u0 u0) u0 count)))
    )
        (unwrap-panic (as-max-len? (concat bytes zeros) u35))
    )
)

;; Main conversion function
(define-read-only (base58-to-address (addr (string-ascii 35)))
    (let (
        (base58-array (string-to-base58-array addr))
        (leading-ones (unwrap-panic (slice? base58-array u0 (default-to u0 (index-of? (map is-one base58-array) false)))))
        (base256 (add-zero-bytes (base58-to-base256 base58-array) (len leading-ones)))
        (version (unwrap-panic (element-at? base256 u0)))
        (payload-length (- (len base256) u4))
        (payload (unwrap-panic (slice? base256 u1 payload-length)))
    )
    (principal-construct? (if is-in-mainnet 0x16 0x1a) (unwrap-panic (as-max-len? (bytes-to-hex payload) u20)))
))