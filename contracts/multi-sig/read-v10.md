Extract Your Public Key
Sign a message to reveal your Stacks public key, which will be used to create your Bitcoin multisig vault.

Your Stacks Address:

SP29D6YMDNAKN1P045T6Z817RTE1AC0JAA99WAX2B
Your Public Key (compressed):

02a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f7170
Length: 66 characters (should be 66 for compressed: 02/03 + 64 hex chars)

Signature:

0b4ff8f9ee0ad8193ee11fbffb632df88509df0a718d2cc8d076e9c6a84d917f799bf6dd6cf0976410b1119ca7b6c010af021f66db566a81cbf77ebf8705526101
Next Steps:

1. Copy your public key above
2. Use it with bitcoin-cli to create your 2-of-2 multisig:

bitcoin-cli createmultisig 2 '["BITCOIN_PUBKEY","02a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f7170"]' "bech32"

====

Perfect! Your public key extraction worked! Now let's create your 2-of-2 multisig with your Bitcoin node.

## Step 1: Generate a Bitcoin pubkey from your node

```bash
# Create or use your Bitcoin wallet
bitcoin-cli -rpcwallet=test_wallet getnewaddress "my_btc_key" "bech32"

# Get the public key for that address (replace with the address from above)
bitcoin-cli -rpcwallet=test_wallet getaddressinfo <address_from_above> | grep -o '"pubkey": "[^"]*"' | cut -d'"' -f4
```

## Step 2: Create the 2-of-2 multisig

Once you have your Bitcoin public key, run:

```bash
# Replace BITCOIN_PUBKEY with the pubkey from step 1
bitcoin-cli -rpcwallet=test_wallet createmultisig 2 '["BITCOIN_PUBKEY","02a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f7170"]' "bech32"
```

This will output something like:

```json
{
  "address": "bc1q...",
  "redeemScript": "5221...",
  "descriptor": "wsh(multi(2,...))"
}
```

## Step 3: Get the scriptPubKey

```bash
# Use the multisig address from step 2
bitcoin-cli -rpcwallet=test_wallet getaddressinfo <multisig_address>
```

Look for the `scriptPubKey` field (it will start with `0020`).

## What You'll Have:

1. ✅ **Your Stacks pubkey**: `02a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f7170`
2. ⏳ **Bitcoin pubkey**: (from your node)
3. ⏳ **Multisig address**: bc1q...
4. ⏳ **Redeem script**: 5221...
5. ⏳ **ScriptPubKey**: 0020...

Once you have all these, you can verify them in your Clarity contract using the `verify-multisig-address` function we created earlier!

Would you like me to help you create a script that automates this entire process, or would you prefer to test it manually first?

===

raphastacks@raphastacks-System-Product-Name:~$ bitcoin-cli -rpcwallet=test_wallet createmultisig 2 '["038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe","02a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f7170"]' "bech32"
{
"address": "bc1q63hzljy4mvhz3jn42adz046722hdyugkyc92q279sz6kemqhhdyq5r73u0",
"redeemScript": "5221038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe2102a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f717052ae",
"descriptor": "wsh(multi(2,038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe,02a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f7170))#chshpmqm"
}
raphastacks@raphastacks-System-Product-Name:~$

}
raphastacks@raphastacks-System-Product-Name:~$ bitcoin-cli -rpcwallet=test_wallet getaddressinfo bc1q63hzljy4mvhz3jn42adz046722hdyugkyc92q279sz6kemqhhdyq5r73u0
{
"address": "bc1q63hzljy4mvhz3jn42adz046722hdyugkyc92q279sz6kemqhhdyq5r73u0",
"scriptPubKey": "0020d46e2fc895db2e28ca75575a27d75e52aed27116260aa02bc580b56cec17bb48",
"ismine": false,
"solvable": false,
"iswatchonly": false,
"isscript": true,
"iswitness": true,
"witness_version": 0,
"witness_program": "d46e2fc895db2e28ca75575a27d75e52aed27116260aa02bc580b56cec17bb48",
"ischange": false,
"labels": [
]
}
raphastacks@raphastacks-System-Product-Name:~$

===

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.multisig-verify verify-multisig-address
(list
0x038b39a74e2deaf00d4a6abb18acbd7a48ac2d1ba488f9049af96e96f6c61fcdfe
0x02a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f7170
)
u2  
 true
(some 0x0020d46e2fc895db2e28ca75575a27d75e52aed27116260aa02bc580b56cec17bb48)
)

===

Perfect! 🎉 It works! `(ok true)` means your contract successfully verified that the multisig address was created from those two public keys.

Now you have a complete working example of your Runes Capsule architecture:

## What You've Proven:

1. ✅ **Extracted your Stacks public key** from your wallet (`02a8dbe8f8dfc66e15898a8684564611be75550d652b519b82539f3806d29f7170`)
2. ✅ **Created a 2-of-2 multisig** on Bitcoin with your Stacks pubkey + Bitcoin node pubkey
3. ✅ **Verified in Clarity** that the multisig was constructed correctly

## Next Steps for Runes Capsule:

Now you can build the full bridge flow:

1. **User Registration**: User signs message → extracts their Stacks pubkey
2. **Vault Creation**:
   - Generate bridge operator's Bitcoin pubkey
   - Create 2-of-2 multisig with user's Stacks pubkey + operator pubkey
   - Store vault details in Clarity contract
3. **User Sovereignty**: Any withdrawal requires:
   - User's signature (from their Stacks wallet)
   - Operator's signature (for the bridge logic)

This is exactly what you wanted: **"nothing goes out of their vault without their signature"** 🔐

Want me to help you build the full vault registration contract that ties this all together?
