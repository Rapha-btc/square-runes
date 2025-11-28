Let me address each point:

**On the timelock refund** - You're right, I misspoke. In your model the refund path can't exist because the L1 tokens _must_ remain locked to back L2. A timelock escape would break the peg guarantee. Scratch that.

**Clarity contract producing Bitcoin-verifiable signatures:**

The Stacks signer infrastructure (what sBTC uses) works like this: there's a threshold signing ceremony where multiple signers collectively produce a Schnorr signature. The signers run off-chain coordination but watch Clarity contract state to decide _what_ to sign.

So theoretically:

- Your Clarity contract emits an event: "User X burned Y FT"
- Signers observe this event
- Signers collectively produce a signature attesting to it
- That signature is valid on Bitcoin (Schnorr, taproot-compatible)

The complexity is that you'd need to either (a) use the existing sBTC signer set and convince them to attest to your contract's events, or (b) run your own signer set. Option (b) is what you're already doing with your multisig operators, so it doesn't really buy you anything new - you're just replacing "operators sign withdrawal tx" with "operators sign oracle attestation."

**On embedded DLC paths:**

Yes, exactly right. DLC outcome paths are fixed at creation time. If you want to allow 10 partial withdrawals, you'd need to either:

- Pre-define 10 outcome branches (withdraw 10%, 20%, ... 100%)
- Or create 10 separate smaller DLCs

Neither is elegant compared to your capsule where Clarity just reads cumulative burn state.

**On 3-of-3 or 4-of-4:**

This is clever. By making it N-of-N instead of threshold, user signature becomes mandatory by construction since they're one of the N. The sbtc-signer-bootstrap library maps Stacks principals to pubkeys, so you get:

- User (mandatory by being 1 of N)
- Operator 1
- Operator 2
- (Operator 3 if 4-of-4)

All must sign. User validates their own tx before signing. Operators can't collude without user. User can't withdraw more than burned without operator collusion.

The downside: if _any_ party disappears, funds are locked. With 3-of-4 threshold you'd have redundancy but lose mandatory user sig unless you implement it separately (more work, as you note).

**On timelock mechanics (for completeness, even though you can't use it):**

Typically works via Bitcoin script: `OP_IF <multisig> OP_ELSE <timelock> OP_CHECKLOCKTIMEVERIFY <escape_pubkey> OP_CHECKSIG OP_ENDIF`

The timelock isn't "renewed" - it's a fixed block height or timestamp. Once passed, the escape path becomes valid. This is incompatible with your model because you need funds locked indefinitely to back L2.

**On Aki's DLC.Link:**

Ah, so they had external attestors rather than Clarity-native oracle production. That's the gap - you'd need the attestation to come _from_ the Clarity state transition itself, not from parties watching Clarity. And that's not really possible without the signer infrastructure, which loops back to "you need trusted parties anyway."

**Bottom line:**

Your N-of-N capsule with mandatory user signature is probably the right design. DLCs don't give you meaningful trust reduction here because:

1. You still need attestors (whether called "oracle" or "operator")
2. You lose flexibility (partial withdrawals, incremental deposits)
3. The "user can unilaterally exit" property requires an oracle you don't have

The main risk (operator disappearance = locked funds) is mitigated by having economically incentivized operators and accepting that worst case is "burned but still backing L2" rather than "stolen."
