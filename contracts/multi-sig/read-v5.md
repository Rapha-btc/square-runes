ssh myusername@ipAdd

raphastacks@raphastacks-System-Product-Name:~$ bitcoin-cli createwallet "test_wallet"
{
"name": "test_wallet"
}
raphastacks@raphastacks-System-Product-Name:~$

raphastacks@raphastacks-System-Product-Name:~$ addr1=$(bitcoin-cli -rpcwallet=test_wallet getnewaddress "addr1" "bech32")
addr2=$(bitcoin-cli -rpcwallet=test_wallet getnewaddress "addr2" "bech32")

pubkey1=$(bitcoin-cli -rpcwallet=test_wallet getaddressinfo $addr1 | grep -o '"pubkey": "[^"]*"' | cut -d'"' -f4)
pubkey2=$(bitcoin-cli -rpcwallet=test_wallet getaddressinfo $addr2 | grep -o '"pubkey": "[^"]\*"' | cut -d'"' -f4)

echo "Public Key 1: $pubkey1"
echo "Public Key 2: $pubkey2"
Public Key 1: 038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe
Public Key 2: 02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead

multisig*info=$(bitcoin-cli -rpcwallet=test_wallet createmultisig 2 "[\"038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe\",\"02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead\"]" "bech32")
echo "Multisig Info: $multisig_info"
echo "Multisig Address: $(echo $multisig_info | grep -o '"address": "[^"]*"' | cut -d'"' -f4)"
echo "ScriptPubKey: $(echo $multisig*info | grep -o '"redeemScript": "[^"]*"' | cut -d'"' -f4)"

Public Key 2: 02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead
raphastacks@raphastacks-System-Product-Name:~$ multisig_info=$(bitcoin-cli -rpcwallet=test_wallet createmultisig 2 "[\"038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe\",\"02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead\"]" "bech32")
echo "Multisig Info: $multisig_info"
echo "Multisig Address: $(echo $multisig_info | grep -o '"address": "[^"]*"' | cut -d'"' -f4)"
echo "ScriptPubKey: $(echo $multisig_info | grep -o '"redeemScript": "[^"]*"' | cut -d'"' -f4)"
Multisig Info: {
  "address": "bc1qahdd7kuunjze5nw33458fjvxk4e6n5v5hj25vcxgdwtp349v6hdq07pc00",
  "redeemScript": "5221038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe2102378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead52ae",
  "descriptor": "wsh(multi(2,038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe,02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead))#vxpmxj9n"
}
Multisig Address: bc1qahdd7kuunjze5nw33458fjvxk4e6n5v5hj25vcxgdwtp349v6hdq07pc00
ScriptPubKey: 5221038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe2102378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead52ae
raphastacks@raphastacks-System-Product-Name:~$

Perfect! Now we have all the information we need:

1. **Public Key 1**: `038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe`
2. **Public Key 2**: `02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead`
3. **Multisig Address**: `bc1qahdd7kuunjze5nw33458fjvxk4e6n5v5hj25vcxgdwtp349v6hdq07pc00`
4. **Redeem Script**: `5221038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe2102378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead52ae`

We need one more piece of information - the actual scriptPubKey of the multisig address. Let's get that:

```bash
bitcoin-cli -rpcwallet=test_wallet getaddressinfo bc1qahdd7kuunjze5nw33458fjvxk4e6n5v5hj25vcxgdwtp349v6hdq07pc00
```

This should show the actual scriptPubKey. Look for a field named `scriptPubKey` in the output.

Alternatively, you can use:

```bash
bitcoin-cli decodescript 5221038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe2102378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead52ae
```

The output should include the P2WSH scriptPubKey, which will start with `0020`.

Let me know what you get from either of those commands, and we'll proceed to testing the contract.

raphastacks@raphastacks-System-Product-Name:~$ bitcoin-cli -rpcwallet=test_wallet getaddressinfo bc1qahdd7kuunjze5nw33458fjvxk4e6n5v5hj25vcxgdwtp349v6hdq07pc00
{
"address": "bc1qahdd7kuunjze5nw33458fjvxk4e6n5v5hj25vcxgdwtp349v6hdq07pc00",
"scriptPubKey": "0020eddadf5b9c9c859a4dd18d6874c986b573a9d194bc954660c86b9618d4acd5da",
"ismine": false,
"solvable": false,
"iswatchonly": false,
"isscript": true,
"iswitness": true,
"witness_version": 0,
"witness_program": "eddadf5b9c9c859a4dd18d6874c986b573a9d194bc954660c86b9618d4acd5da",
"ischange": false,
"labels": [
]
}
raphastacks@raphastacks-System-Product-Name:~$

Perfect! Now we have all the information we need:

1. **Public Key 1**: `038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe`
2. **Public Key 2**: `02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead`
3. **Multisig Address**: `bc1qahdd7kuunjze5nw33458fjvxk4e6n5v5hj25vcxgdwtp349v6hdq07pc00`
4. **Redeem Script**: `5221038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe2102378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead52ae`

We need one more piece of information - the actual scriptPubKey of the multisig address. Let's get that:

```bash
bitcoin-cli -rpcwallet=test_wallet getaddressinfo bc1qahdd7kuunjze5nw33458fjvxk4e6n5v5hj25vcxgdwtp349v6hdq07pc00
```

This should show the actual scriptPubKey. Look for a field named `scriptPubKey` in the output.

Alternatively, you can use:

```bash
bitcoin-cli decodescript 5221038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe2102378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead52ae
```

The output should include the P2WSH scriptPubKey, which will start with `0020`.

Let me know what you get from either of those commands, and we'll proceed to testing the contract.

Perfect! Now we have everything we need:

1. **Public Key 1**: `038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe`
2. **Public Key 2**: `02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead`
3. **Multisig Address**: `bc1qahdd7kuunjze5nw33458fjvxk4e6n5v5hj25vcxgdwtp349v6hdq07pc00`
4. **Redeem Script**: `5221038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe2102378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead52ae`
5. **ScriptPubKey**: `0020eddadf5b9c9c859a4dd18d6874c986b573a9d194bc954660c86b9618d4acd5da`

Let's test our contract with these real values. First, make sure the contract is saved as `multisig-verify.clar` in your Clarinet project directory.

Now, let's update the Clarinet console command with the actual values:

```bash
# Start Clarinet console
clarinet console
```

Once in the Clarinet console, run:

```scheme
(contract-call? .multisig-verify verify-multisig-address
  (list
    0x038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe
    0x02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead
  )
  u2  ;; 2-of-2 multisig
  true  ;; Is SegWit (P2WSH)
  (some 0x0020eddadf5b9c9c859a4dd18d6874c986b573a9d194bc954660c86b9618d4acd5da)  ;; The actual scriptPubKey
)
```

This command should return `(ok true)` if our contract correctly verifies that the multisig address was created from these public keys.

If you want to test that it properly rejects incorrect values, you can try:

```scheme
;; With incorrect pubkeys
(contract-call? .multisig-verify verify-multisig-address
  (list
    0x03deadbeefdeaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe
    0x02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead
  )
  u2
  true
  (some 0x0020eddadf5b9c9c859a4dd18d6874c986b573a9d194bc954660c86b9618d4acd5da)
)

;; With incorrect m value
(contract-call? .multisig-verify verify-multisig-address
  (list
    0x038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe
    0x02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead
  )
  u1  ;; Changed from u2 to u1
  true
  (some 0x0020eddadf5b9c9c859a4dd18d6874c986b573a9d194bc954660c86b9618d4acd5da)
)
```

These should both return `(ok false)` since the parameters don't match the actual multisig address.

Try running these commands in Clarinet and let me know the results!

Perfect! Now we have everything we need:

1. **Public Key 1**: `038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe`
2. **Public Key 2**: `02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead`
3. **Multisig Address**: `bc1qahdd7kuunjze5nw33458fjvxk4e6n5v5hj25vcxgdwtp349v6hdq07pc00`
4. **Redeem Script**: `5221038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe2102378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead52ae`
5. **ScriptPubKey**: `0020eddadf5b9c9c859a4dd18d6874c986b573a9d194bc954660c86b9618d4acd5da`

Let's test our contract with these real values. First, make sure the contract is saved as `multisig-verify.clar` in your Clarinet project directory.

Now, let's update the Clarinet console command with the actual values:

```bash
# Start Clarinet console
clarinet console
```

Once in the Clarinet console, run:

```scheme
(contract-call? .multisig-verify verify-multisig-address
  (list
    0x038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe
    0x02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead
  )
  u2  ;; 2-of-2 multisig
  true
  (some 0x0020eddadf5b9c9c859a4dd18d6874c986b573a9d194bc954660c86b9618d4acd5da)  ;; The actual scriptPubKey
)
```

This command should return `(ok true)` if our contract correctly verifies that the multisig address was created from these public keys.

If you want to test that it properly rejects incorrect values, you can try:

```scheme
;; With incorrect pubkeys
(contract-call? .multisig-verify verify-multisig-address
  (list
    0x03deadbeefdeaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe
    0x02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead
  )
  u2
  true
  (some 0x0020eddadf5b9c9c859a4dd18d6874c986b573a9d194bc954660c86b9618d4acd5da)
)

;; With incorrect m value
(contract-call? .multisig-verify verify-multisig-address
  (list
    0x038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe
    0x02378b24c483280bf64c4913e8cbf6a6e0b45ddaaa95e5864d88741226e8421ead
  )
  u1  ;; Changed from u2 to u1
  true
  (some 0x0020eddadf5b9c9c859a4dd18d6874c986b573a9d194bc954660c86b9618d4acd5da)
)
```

These should both return `(ok false)` since the parameters don't match the actual multisig address.

Try running these commands in Clarinet and let me know the results!
