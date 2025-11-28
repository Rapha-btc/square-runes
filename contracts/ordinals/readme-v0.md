Bitcoin Core is getting another massive upgrade v.31 in 2026.

CLUSTER MEMPOOL

This changes how unconfirmed transactions are managed,the PR was merged recently.

What does this mean for you?

🧨 Smoother Confirmations :

The old system was like a messy family tree and could get clogged, creating unpredictable delays during fee spikes.

The new cluster system groups transactions into compact clusters based on a graph theory. Makes it organized,Your tx propagates faster and is less likely to get unfairly dropped during congestion.

🧨 RBF (Replace By Fee) works better :

The cluster mempool removes clunky old rules like "no new inputs" makes it easier to bump fees in @SparrowWallet

🧨 Spam Tax Upgrade :

Strict caps on cluster sizes (101 kvB / 64 txs) limit how much junk one entity can chain together to bloat the mempool.

High-value transactions spread quicker. This helps keep baseline fees lower during normal times and makes the network tougher against abuse

🧨 Lightning Boost :

It fixes backend for lightning ⚡️ Expect smoother channel opens/closes and fewer forced closures on your mobile wallets.

🧨 @lifofifo suggests this will be beneficial for builders like @radfi_btc and @ArchNtwrk @summraznboi is excited about how builders will use this feature.

Watch video for more.

===

**Spam Tax explained:**

Before: An attacker could create long chains of dependent transactions (parent → child → grandchild → etc.) that clog the mempool. Each transaction references the previous one, creating a bloated mess that nodes have to track and validate.

After (Cluster Mempool): Strict limits - max 101 kvB or 64 transactions per cluster. If you want to chain more, you can't. The "tax" is that spammers hit a wall. They can't endlessly bloat the mempool with cheap linked transactions.

**Why it's called a "tax":**

It's not a fee - it's a constraint. Spammers pay by being limited, not by spending more sats. Their attack surface shrinks. Legitimate users (whose transactions are usually independent or small clusters) are unaffected.

**Simple analogy:**

Old system: Anyone can reserve infinite tables at a restaurant by saying "these 200 people are all with me."

New system: Max 64 people per party. Want more? Start a separate reservation. The restaurant stays usable for everyone else.

===

**Parent-child transactions:**

In Bitcoin, you can spend an unconfirmed transaction's output. The second tx depends on the first confirming - it's the "child."

**Example:**

1. You send 1 BTC to Alice (parent tx, unconfirmed)
2. Alice immediately spends that 1 BTC to Bob (child tx, also unconfirmed)
3. Bob spends it to Carol (grandchild tx)

Now you have a chain. The child can't confirm until the parent confirms. The grandchild can't confirm until the child confirms.

**Why do this?**

Legitimate use: Alice needs to pay Bob now but her incoming funds haven't confirmed yet. She spends the unconfirmed output.

Fee bumping (CPFP): Parent tx has low fee, stuck in mempool. You create a child tx with high fee. Miners want the child's fee, so they confirm both together. Child Pays For Parent.

**The spam attack:**

Bad actor creates: tx1 → tx2 → tx3 → tx4 → ... → tx200

All unconfirmed, all linked. Nodes must track the entire chain and recalculate fees/priorities for every update. It's computational bloat.

**Cluster mempool fix:**

Max 64 txs per chain. After that, you can't add more children. Spam chains hit a ceiling. Legitimate users rarely chain more than a few, so they're unaffected.

===

**DLCs embedded - similar but different:**

Not exactly parent-child. Embedded DLCs are multiple outcome paths within one transaction structure, defined upfront. Parent-child is sequential transactions where each spends the previous output.

But your earlier point about "each DLC path must be defined in advance" has similar constraints - you're pre-committing to a structure.

**Parent-child real use cases:**

**1. You're waiting on funds but need to pay now:**

You sold something, buyer's tx is unconfirmed. You need to pay rent. You spend the unconfirmed output. Your landlord sees a child tx pending - it'll confirm when your incoming funds confirm.

**2. Fee bumping (CPFP):**

You sent a tx with 1 sat/vb. Stuck for hours. You can't RBF (maybe wallet doesn't support it). So you create a child tx spending that output with 50 sat/vb. Miners grab both because the child pays enough for the pair.

**3. Batch payouts:**

Exchange sends one tx to 100 users (parent). Each user immediately moves funds to cold storage (100 children). All pending together.

**4. Capsule-relevant example:**

User deposits to capsule (parent, unconfirmed). Clarity could theoretically see it, but can't act until confirmed. No child needed here, but if you built a system where the user immediately re-locks into a new structure before confirmation, that's parent-child.

**Simpler mental model:**

Parent-child = spending money you've received but bank hasn't cleared yet. The check is "in the mail." You write a check against it anyway.

===

Yes, heavily.

**Ordinals/Inscriptions use parent-child for:**

**1. Reveal transactions:**

Inscriptions use a two-tx pattern:

- Parent (commit): Creates a taproot output with the inscription data committed
- Child (reveal): Spends that output, revealing the inscription on-chain

The inscription doesn't exist until the child confirms. They're linked.

**2. Parent-child inscriptions (provenance):**

An NFT collection creator inscribes a "parent" inscription. Then creates "child" inscriptions that reference it. Proves the children came from the same creator. Collection authenticity.

**3. Fee bumping inscriptions:**

Inscription tx stuck? Create a child that spends the inscription output with higher fee. CPFP bumps both.

**4. BRC-20 minting chains:**

Mint tx → transfer tx → another transfer. Chains of dependent transactions. This is partly why mempool got bloated - thousands of linked BRC-20 txs.

**The spam tax connection:**

Ordinals/BRC-20 created massive parent-child chains. Cluster mempool caps at 64 txs per chain. This limits how much one minter can clog the mempool with linked inscription sequences.

Some see this as anti-spam. Others see it as Core quietly nerfing Ordinals without saying so.

===

**How inscriptions actually work:**

**Step 1 - Commit tx (parent):**

Creates a taproot output. Hidden in the script tree is a commitment to the inscription data. Nothing visible on-chain yet - just a normal-looking output.

**Step 2 - Reveal tx (child):**

Spends that output using the script path that contains the inscription. To spend via that path, you must reveal the script. The script contains:

```
OP_FALSE
OP_IF
  "ord"
  OP_PUSH content_type
  OP_PUSH data_blob
OP_ENDIF
OP_CHECKSIG
```

The `OP_FALSE OP_IF ... OP_ENDIF` block never executes (OP_FALSE guarantees the IF is skipped). It's dead code. But to use this script path, you must publish the full script on-chain - including the dead code containing your JPEG.

**Why two steps?**

Taproot lets you commit to scripts without revealing them until spent. The commit tx locks funds to a script tree. The reveal tx exposes which script path you're using.

If you did it in one tx, everyone would see your inscription before it's "minted." Two-step lets you commit first (claim your spot), reveal second.

**The inscription itself:**

It's just data stuffed in a script that never runs. Bitcoin nodes ignore it (dead code). Ordinal indexers read it and say "this satoshi now has this image attached."

**The sat connection:**

Ordinal theory tracks individual satoshis. The first sat of the reveal tx output "carries" the inscription. Whoever owns that sat owns the inscription.

===

**Taproot output:**

It's a type of UTXO. Bitcoin has different output types:

- P2PKH (legacy, starts with 1)
- P2SH (script hash, starts with 3)
- P2WPKH (segwit, starts with bc1q)
- P2TR (taproot, starts with bc1p)

Taproot outputs are special because they can be spent two ways:

1. **Key path:** Just sign with the private key. Looks like a normal payment. Cheap, private.

2. **Script path:** Reveal a script hidden in the "script tree" and satisfy it. This is where inscriptions hide.

When you create a taproot output, you commit to a script tree (Merkle root of possible scripts), but don't reveal it. Only when spending via script path do you expose which script you're using.

---

**Your clarification - you're right:**

At commit time: The script exists but is hidden. You've committed to it (the taproot output encodes the Merkle root), but nobody sees the contents.

At reveal time: You spend via script path, which requires publishing the script on-chain. Now it's visible. And the `OP_FALSE OP_IF` makes it dead code that never executes but sits on-chain forever.

So "dead code" only matters at reveal. At commit, it's just a hidden commitment.

---

**"First sat of the reveal output":**

Yes - ordinal theory assigns the inscription to the first satoshi in the first output of the reveal tx. That sat "carries" the inscription from then on.

===

Exactly.

**Commit:** You hash the script (which contains the blob). The taproot output only contains the Merkle root of the script tree. The actual data isn't on-chain yet - just a fingerprint.

**Reveal:** You spend the output via script path. To prove you're authorized, you must publish the full script. Now the blob (image, text, whatever) is on-chain in the transaction witness data.

**Decoding:**

Indexers scan reveal txs, find the `OP_FALSE OP_IF ... OP_ENDIF` pattern, extract the bytes between, read the content type header, and decode accordingly. JPEG, PNG, text, HTML, whatever.

**So:**

- Commit = "I'm locking funds to a script containing hidden data"
- Reveal = "Here's the script, here's the data, now it's permanent"

The blob lives in the witness, which is discounted (cheaper) thanks to SegWit. That's why inscriptions were economically viable - witness data costs less per byte.

===

SegWit changed how transaction size is calculated for fees.

**Before SegWit:** Every byte costs the same.

**After SegWit:** Witness data (signatures, scripts) counts as 1/4 of a byte for fee purposes.

So 100 bytes of witness data = 25 "virtual bytes" for fee calculation.

Inscriptions stuff data in the witness. A 100KB image costs fees like it's 25KB.

That's the discount. Ordinals exploit it to store large blobs cheaply.
