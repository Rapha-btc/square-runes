**The Big Picture: Proving Bitcoin stuff happened on Stacks**

You have a Bitcoin transaction (`fdb74387...`) that:
1. Sends Runes (via OP_RETURN in output 0)
2. Sends 546 sats to a 2-of-2 multisig "capsule" (output 1)

**The problem:** Stacks smart contracts can't see Bitcoin directly.

**The solution:** Merkle proofs.

---

**The Flow:**

1. **User sends a Bitcoin PSBT** → Runes go into the multisig capsule

2. **Faktory API** (`/api/proof/{txid}`) takes the confirmed tx and generates:
   - Block header
   - Merkle proofs proving this tx is in that block
   - Witness data
   - Coinbase tx proof

3. **Your backend** (`getBitcoinProofData`) formats all that into Clarity-compatible values

4. **Clarity contract** receives those proofs and:
   - Calls `clarity-bitcoin-lib-v7.was-segwit-tx-mined-compact` → verifies the tx was actually mined in a real Bitcoin block
   - Parses the tx outputs to read the OP_RETURN (Runestone data)
   - Finds the multisig output and confirms 546 sats were sent there

**Result:** You've cryptographically proven on Stacks that a specific Runes transfer to a specific multisig happened on Bitcoin. This is the foundation for your bridge.