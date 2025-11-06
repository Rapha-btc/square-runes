;; address-converter.clar
;; A simple test contract for converting between Stacks and Bitcoin addresses

;; Constants for base58 conversion
(define-constant ALL_HEX 0x000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF)
(define-constant BASE58_CHARS "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")

;; Constants for version bytes
;; mainnet p2pkh: P -> 22 -> 0x16 == 0x00
;; mainnet p2sh:  M -> 20 -> 0x14 == 0x05
;; testnet p2pkh: T -> 26 -> 0x1a == 0x6f
;; testnet p2sh:  N -> 21 -> 0x15 == 0xc4
(define-constant STX_VER 0x16141a15)
(define-constant BTC_VER 0x00056fc4)

(define-constant LST (list))
(define-constant ERR_INVALID_ADDR (err u1))

;; PART 1: STACKS TO BITCOIN CONVERSION (From base58-v3.clar)
;; --------------------------------------------------------

;; Main function to convert a Stacks address to a Bitcoin address
(define-public (stacks-to-bitcoin (addr principal))
    (convert addr)
)

;; Implementation from LNow
(define-read-only (convert (addr principal))
    (match (principal-destruct? addr) 
        ;; if version byte match the network (ie. mainnet principal on mainnet, or testnet principal on testnet)
        network-match-data (convert-inner network-match-data)
        ;; if version byte does not match the network
        network-not-match-data (convert-inner network-not-match-data)
    )
)

(define-private (convert-inner (data {hash-bytes: (buff 20), name: (optional (string-ascii 40)), version:(buff 1)}))
    (let (
        ;; exit early if contract principal
        (t1 (asserts! (is-none (get name data)) ERR_INVALID_ADDR))
        ;; convert STX version byte to BTC version
        (version (unwrap-panic (element-at? BTC_VER (unwrap-panic (index-of? STX_VER (get version data))))))
        ;; concat BTC version & hash160 
        (versioned-hash-bytes (concat version (get hash-bytes data)))
        ;; concat hash-bytes & 4 bytes checksum, and convert hex to uint
        (to-encode (map hex-to-uint (concat 
            versioned-hash-bytes 
            ;; checksum = encode versionded-hash-bytes 2x with sha256, and then extract first 4 bytes
            (unwrap-panic (as-max-len? (unwrap-panic (slice? (sha256 (sha256 versioned-hash-bytes)) u0 u4)) u4))
        )))
        ;; "cut" leading zeros leveraging index-of? property
        (leading-zeros (unwrap-panic (slice? to-encode u0 (default-to u0 (index-of? (map is-zero to-encode) false)))))
    )
        (ok 
            (fold 
                convert-to-base58-string 
                (concat (fold outer-loop (unwrap-panic (slice? to-encode (len leading-zeros) u25)) LST) leading-zeros) 
                ""
            )
        )
    )
)

(define-read-only (outer-loop (x uint) (out (list 44 uint)))
    (let (
        (new-out (fold update-out out (list x)))
        (push (fold carry-push 0x0000 (list (unwrap-panic (element-at? new-out u0)))))
    )
        (concat 
            (default-to LST (slice? new-out u1 (len new-out)))
            (default-to LST (slice? push u1 (len push)))
        )
    )
)

(define-read-only (update-out (x uint) (out (list 35 uint)))
    (let (
        (carry (+ (unwrap-panic (element-at? out u0)) (* x u256)))
    )
        (unwrap-panic (as-max-len? (concat  
            (list (/ carry u58)) ;; new carry
            (concat 
                (default-to LST (slice? out u1 (len out))) ;; existing list
                (list (mod carry u58)) ;; new value we want to append
            )
        ) u35))
    )
)

(define-read-only (carry-push (x (buff 1)) (out (list 9 uint)))
    (let (
        (carry (unwrap-panic (element-at? out u0)))
    )
        (if (> carry u0)
            (unwrap-panic (as-max-len? (concat 
                (list (/ carry u58)) ;; new carry
                (concat
                    (default-to LST (slice? out u1 (len out))) ;; existing list
                    (list (mod carry u58)) ;; new value we want to append
                )
            ) u9))
            out
        )
    )
)

(define-read-only (convert-to-base58-string (x uint) (out (string-ascii 44)))
    (unwrap-panic (as-max-len? (concat (unwrap-panic (element-at? BASE58_CHARS x)) out) u44))
)

(define-read-only (hex-to-uint (x (buff 1))) (unwrap-panic (index-of? ALL_HEX x)))
(define-read-only (is-zero (i uint)) (<= i u0))

;; PART 2: BITCOIN TO STACKS CONVERSION (From base58-decode.clar)
;; --------------------------------------------------------

;; Main function to convert a Bitcoin address to a Stacks address
(define-public (bitcoin-to-stacks (input (string-ascii 60)))
    (btc-to-stx input)
)

;; Implementation from Eamon Penland
(define-read-only (btc-to-stx (input (string-ascii 60)))
    (let ( 
        (b58-numbers (map unwrap-uint (filter is-some-uint (map b58-to-uint input))))
        (t1 (asserts! (>= (len b58-numbers) (len input)) ERR_INVALID_ADDR)) 
        (leading-ones-count (default-to (len input) (index-of? (map is-zero b58-numbers) false)))
        (leading-zeros (map force-zero (unwrap-panic (slice? b58-numbers u0 leading-ones-count)))) 
        (to-decode (default-to LST (slice? b58-numbers leading-ones-count (len b58-numbers))))
        (decoded (concat (fold decode-outer to-decode LST) leading-zeros))
        (decoded-hex (fold to-hex-rev decoded 0x))
        (decoded-hex-len (len decoded-hex))
        (t2 (asserts! (< u4 decoded-hex-len) ERR_INVALID_ADDR))
        (actual-checksum (unwrap-panic (slice? (sha256 (sha256 (unwrap-panic (slice? decoded-hex u0 (- decoded-hex-len u4))))) u0 u4)))
        (expected-checksum (unwrap-panic (slice? decoded-hex (- decoded-hex-len u4) decoded-hex-len)))
        (t3 (asserts! (is-eq actual-checksum expected-checksum) ERR_INVALID_ADDR))
        (version (unwrap-panic (element-at? STX_VER (unwrap! (index-of? BTC_VER (unwrap-panic (element-at? decoded-hex u0))) ERR_INVALID_ADDR))))
    ) 
        (ok (unwrap! (principal-construct? version (unwrap-panic (as-max-len? (unwrap-panic (slice? decoded-hex u1 (- decoded-hex-len u4))) u20))) ERR_INVALID_ADDR))
    ) 
)

;; Helper functions for Bitcoin to Stacks conversion
(define-read-only (b58-to-uint (x (string-ascii 1))) (index-of? BASE58_CHARS x))
(define-read-only (is-some-uint (x (optional uint))) (is-some x))
(define-read-only (unwrap-uint (x (optional uint))) (unwrap-panic x))
(define-read-only (force-zero (x uint)) u0)

(define-read-only (to-hex-rev (x uint) (out (buff 33)))
    (unwrap-panic (as-max-len? (concat (unwrap-panic (element-at? ALL_HEX x)) out) u33))
)

(define-read-only (decode-outer (x uint) (out (list 33 uint)))
    (let (
        (new-out (fold update-out-btc out (list x)))
        (carry-to-push (fold carry-push-btc 0x0000 (list (unwrap-panic (element-at? new-out u0)))))
        )   
        (concat 
            (default-to LST (slice? new-out u1 (len new-out)))
            (default-to LST (slice? carry-to-push u1 (len carry-to-push)))
        )
    )
)

(define-read-only (update-out-btc (x uint) (out (list 30 uint)))
    (let ((carry (+ (unwrap-panic (element-at? out u0)) (* x u58))))
        (unwrap-panic (as-max-len? (concat 
            (list (/ carry u256)) ;; new carry
            (concat
                (default-to LST (slice? out u1 (len out))) ;; existing list
                (list (mod carry u256)) ;; new element
            )
        ) u30))
    )
)

(define-read-only (carry-push-btc (x (buff 1)) (out (list 3 uint)))
    (let ((carry (unwrap-panic (element-at? out u0))))      
        (if (> carry u0)
            (unwrap-panic (as-max-len? (concat
                (list (/ carry u256)) ;; new carry
                (concat
                    (default-to LST (slice? out u1 (len out))) ;; existing list
                    (list (mod carry u256)) ;; new element
                )
            ) u3))
            out
        )
    )
)

;; Test helper function to verify conversions match
(define-public (verify-address-match (stx-address principal))
    (let (
        (btc-address (unwrap-panic (stacks-to-bitcoin stx-address)))
        (back-to-stx (unwrap-panic (bitcoin-to-stacks btc-address)))
    )
        (ok (is-eq stx-address back-to-stx))
    )
)

(define-read-only (verify-pubkey-hash (address principal))
  (match (principal-destruct? address)
    success-data (ok (get hash-bytes success-data))
    error-data (err u1)
  )
)

;; ;; Convert the pubkey hash hex to a buffer
;; (define-constant TEST-PUBKEY-HASH 0x0fdfdb51fdaae15933b28e0a732f71984f680b03)

;; ;; Verify if a specific Stacks address contains this pubkey hash
;; (define-public (verify)
;; (ok (verify-pubkey-hash 'SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B TEST-PUBKEY-HASH)))

;; ;; Convert a Stacks address to Bitcoin and compare with expected Bitcoin address
;; (define-read-only (compare) 
;; (ok (is-eq (contract-call? .base58-v3 convert 'SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B) (ok "12SwJiUMQTG98ueX61ZXrXXXR75hEGbzbz")))
;; )

;; (define-public (extract-stacks-pubkey-hash (stx-addr principal))
;;   (match (principal-destruct? stx-addr)
;;     success-data (ok (get hash-bytes success-data))
;;     error-data (err u1)
;;   )
;; )

;; (define-public (verify-conversion (stx-addr principal))
;;   (let
;;     (
;;       ;; Get the pubkey hash from the Stacks address
;;       (pubkey-hash (unwrap-panic (extract-stacks-pubkey-hash stx-addr)))
      
;;       ;; Convert the Stacks address to Bitcoin using LNow's code
;;       (btc-addr (unwrap-panic (convert stx-addr)))
      
;;       ;; Manually construct the expected Bitcoin address from the pubkey hash
;;       ;; This would require implementing base58check encoding
;;     )
;;     (ok (list pubkey-hash btc-addr))
;;   )
;; )