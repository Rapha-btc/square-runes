https://www.hiro.so/blog/how-every-stacks-address-has-a-corresponding-bitcoin-address

https://gist.github.com/LNow/6c8509dbb540815c622f8fb40232f869#file-base58-v3-clar

Perfect! Now that we have both LNow's and Eamon's implementations, I understand your goal better. Here's how to integrate this into your workflow:

## How to Use This

1. **Deploy a Combination Contract**: Create a contract that combines:

   - The base58 conversion code (from LNow/Eamon)
   - Your existing multisig verification code

2. **Flow for Users**:

   - User creates a Bitcoin multisig with your service's Bitcoin public key
   - User calls your Stacks contract using their Stacks wallet/address
   - Your contract:
     1. Gets the user's Stacks address from `tx-sender`
     2. Converts the Stacks address to its corresponding Bitcoin address
     3. Verifies this Bitcoin address is one of the signers in the multisig
     4. Performs whatever action is needed if verified

3. **Address Conversion**:
   - Yes, the addresses produced are the same ones shown in Leather/Xverse
   - The Stacks address and Bitcoin address share the same underlying pubkey hash

## Implementation Example

```clarity
(define-public (verify-user-in-multisig
    (multisig-script-pub-key (buff 34))
    ;; No need to pass in their Stacks address - we get it from tx-sender
  )
  (let (
      ;; Get Bitcoin pubkey hash from Stacks address
      (btc-address (unwrap-panic (convert tx-sender)))
      ;; Get our service's pubkey
      (service-pubkey 0x02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead)

      ;; Verify the multisig contains both addresses
      (is-valid-multisig (verify-multisig-address
        (list
          service-pubkey
          (extract-pubkey-from-btc-address btc-address) ;; You'd need to add this function
        )
        u2  ;; 2-of-2
        true  ;; Is SegWit
        (some multisig-script-pub-key)
      ))
    )
    (ok is-valid-multisig)
  )
)
```

The key missing piece is the `extract-pubkey-from-btc-address` function, which would need to be implemented by:

1. Converting the address string back to binary form
2. Extracting the pubkey hash from the address
3. Converting that to the appropriate pubkey format

This creates a system where a user can prove their Stacks address corresponds to one of the keys in a Bitcoin multisig.

> > (contract-call? .base58-v3 convert 'SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B)

(ok "1EPLzonPUextZfrb8SyybxVZGEmvCPQeug")

> > (contract-call? .base58-v3 convert 'SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B)

(ok "1EPLzonPUextZfrb8SyybxVZGEmvCPQeug")

> > (contract-call? .base58-decode base58-to-address "1EPLzonPUextZfrb8SyybxVZGEmvCPQeug")

(ok 'ST39QN3DAMX8DG11EHQT09Y6KGAK04JJJWPGHDGDF)

> > (contract-call? .address-converter stacks-to-bitcoin 'SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B)

<stdin>:1:2: error: use of unresolved contract 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.address-converter'

(contract-call? .address-converter stacks-to-bitcoin 'SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B)

^~~~~~~~~~~~~~

(contract-call? .address-converter stacks-to-bitcoin 'SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B)

                ^~~~~~~~~~~~~~~~~~

(contract-call? .address-converter stacks-to-bitcoin 'SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B)

                                   ^~~~~~~~~~~~~~~~~

(contract-call? .address-converter stacks-to-bitcoin 'SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B)

                                                     ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

> > (contract-call? .add-converter stacks-to-bitcoin 'SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B)

(ok "1EPLzonPUextZfrb8SyybxVZGEmvCPQeug")

> > (contract-call? .add-converter verify-address-match 'SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B)

error: Runtime Error: Runtime error while interpreting ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.contract-8: Runtime(UnwrapFailure, Some([FunctionIdentifier { identifier: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.add-converter:verify-address-match" }, FunctionIdentifier { identifier: "_native_:special_let" }, FunctionIdentifier { identifier: "_native_:native_unwrap" }]))

> >

weird a bitcoin address that starts with 1? leather displays bc1qrx2ghj5aegvu5dccwqmkqu88w5qznj7g8xdqam for this stacks address

also it converts to a testnet address that is not the testnet address of SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B which is ST29D6YMDNAKN1P045T6Z817RTE1AC0JAAAG2EQZZno

we dont need the reverse for now... users start from stacks addresses i guess?

therefore we create a multi-sig using their associated bitcoin pubkey to their stacks add

we dont need the reverse for now... users start from stacks addresses i guess?

therefore we create a multi-sig using their associated bitcoin pubkey to their stacks add

this means we dont need eamon or debug this

we just need to verify what lnow is giving is correct... how to? maybe using our test wallet from bitcoin node?

then if it's correct we can then extend our multi sig verif to stacks add tx sender is owner of this multi sig you see?

lay out the steps next, and focus on only the very next one now
