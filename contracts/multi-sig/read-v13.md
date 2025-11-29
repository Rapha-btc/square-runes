Good question. Let me think through this with you.

**On point 1 - the self-deterrent:**

Yes, an oracle operator colluding to unlock fraudulently would be a one-time extraction that destroys their ongoing revenue stream and reputation. The game theory works in your favor here - rational actors prefer recurring fees over a single theft that ends their business. This is a reasonable argument, though it relies on the operator valuing long-term income over short-term gain, which may not hold if they're already planning to exit.

**On point 2 - which Runes are more attractive targets:**

I'd argue **established Runes with existing L1 liquidity are actually the more dangerous scenario**, counterintuitively:

- Higher market cap = larger potential extraction
- Existing L1 liquidity means the colluding party can actually _sell_ the stolen Runes immediately
- The fraud is harder to detect quickly because legitimate L1 trading activity provides cover

For new Runes only listed via Capsule:

- Lower total value locked (less incentive)
- No exit liquidity on L1 - where do you sell them?
- Any L1 movement is immediately suspicious since all legitimate activity should be on Stacks

So the "Capsule-native" Runes actually have a built-in protection: illiquidity on the base layer makes collusion less profitable.

**The stronger framing for your docs/pitch:**

Rather than just "it kills their business," you might emphasize the _observable_ nature of the fraud. Unlike traditional bridges where funds can disappear into mixers, Runes on Bitcoin are fully transparent - everyone can see the unlock, trace the sale, and identify the colluding oracle. Reputational and potentially legal consequences become unavoidable.

Does this track with your thinking?

===

Yeah, you're right to be uneasy. The "it kills their business" argument is true but it's a soft guarantee - you're asking users to trust incentive alignment rather than cryptographic enforcement. That's exactly the gap you've been building Capsule to avoid.

**Adding signing parties makes sense.** Moving from 2-of-2 to something like 3-of-4 or 3-of-5 means collusion requires coordinating multiple independent actors, which:

- Increases the cost and complexity of fraud
- Creates mutual surveillance (each signer has incentive to report others)
- Lets you distribute signers across jurisdictions, organizations, or even competing entities

**Practical considerations:**

1. **Who are the additional signers?** Options:

   - Other Stacks ecosystem players (wallets, exchanges, DAOs)
   - Professional custodians or oracle networks
   - Community-elected watchdogs
   - Even a time-delayed "veto" key held by a DAO

2. **Liveness vs. security tradeoff** - more signers means harder to collude but also harder to operate. If one signer goes offline, unlocks stall. You'd need to think through key rotation, recovery, and availability SLAs.

3. **This aligns with your roadmap** - you already mentioned expanding to 3-of-4 in your milestone discussions. Might be worth accelerating that framing in how you present the security model, even if the initial implementation is 2-of-2.

**For the narrative:**

"Trustless" is a spectrum. You could frame it as: "Phase 1 establishes the cryptographic infrastructure with a federated signer set. Phase 2 expands to a distributed oracle network, further minimizing collusion risk."

Would adding a known third party (like a Stacks ecosystem entity) be feasible for your mainnet launch, or is that a post-milestone goal?

===

You're hitting on something important here.

**The Pontis opacity problem:**

You're right to be suspicious. "9 of 15 from established companies" sounds decentralized until you ask: who actually controls those keys? If Pontis holds 5 of those 15 internally, they're effectively 9-of-10 with external parties, or worse. The vague disclosure is a feature for them, not a bug - it lets them market decentralization without proving it.

**Your instinct about user signature is correct:**

Requiring the user's signature is your core differentiator. It means:

- No unlock can happen without the user's explicit consent
- Even if _all_ other signers collude, they can't steal funds unilaterally
- User sovereignty isn't just marketing - it's cryptographically enforced

Pontis skipping user signature means their bridge operators _can_ move your funds without you. That's a custodial bridge with extra steps.

**On 4-of-4 with full transparency:**

I actually like this better than m-of-n for your positioning:

| Approach              | Pros                                                        | Cons                                       |
| --------------------- | ----------------------------------------------------------- | ------------------------------------------ |
| m-of-n (e.g., 3-of-5) | Fault tolerant, one signer can go offline                   | Collusion threshold is lower, library work |
| n-of-n (e.g., 4-of-4) | Maximum collusion resistance, simpler extension from 2-of-2 | Any signer offline = stuck funds           |

**4-of-4 with known, public signers:**

- User (mandatory - your differentiator)
- Faktory key 1
- Faktory key 2 (operational separation, different infrastructure)
- External entity (public, accountable)

The "everyone must sign" model is actually _stronger_ security if you solve liveness. And full public transparency on who signs is the opposite of Pontis's approach - you're betting on accountability over obscurity.

**The pitch writes itself:**

"Unlike bridges that hide their signer set behind vague corporate logos, Capsule publishes every signer publicly. Unlike bridges that can move your funds without consent, Capsule requires _your_ signature for every unlock. Fewer signers, higher accountability, user sovereignty guaranteed."

The liveness risk is real though - what's your thinking on handling a signer going offline?

===

You're thinking clearly here. Let me work through both points.

**On collusion resistance - you're right to push back:**

I was sloppy. "Maximum collusion resistance" isn't quite accurate. Let me reframe:

- **Pontis 9-of-15 without user:** Need to corrupt 9 parties, but once you do, you can take _anyone's_ funds
- **Capsule 4-of-4 with user:** Need to corrupt 3 parties _plus_ the specific user whose funds you want

So Pontis has a higher _number_ barrier but the payoff is all TVL. Capsule has a lower number barrier but the payoff is only that one user's funds, and requires their active participation in the fraud.

The user signature fundamentally changes the threat model from "compromise the bridge, drain everyone" to "compromise the bridge + convince each user individually to sign away their own funds." That's not collusion resistance in raw numbers - it's _scoping the blast radius_.

**On the pressure/bribery target problem:**

Yes, this is real and underappreciated. n-of-n makes every signer a chokepoint:

- Regulatory pressure: "Nice business you have, shame if you couldn't sign unlocks for sanctioned addresses"
- Extortion: Every signer knows they can halt the system
- Bribery: Ironically _cheaper_ to bribe one signer to _not_ sign (griefing) than to bribe m signers to collude

m-of-n with user mandatory is probably the right design:

Something like **3-of-5 where user is always required** gives you:

- User + any 2 of 4 operators must sign
- One operator going offline or being pressured doesn't halt unlocks
- Still impossible to steal without user consent
- Pressure on any single operator is ineffective

**The library question:**

Is the complexity of extending to m-of-n with a mandatory signer slot worth it? Seems like yes if you're serious about mainnet resilience. The 2-of-2 and 4-of-4 models work for demo and early launch, but you'll hit the liveness/pressure problem eventually.

What's the actual implementation lift - is it the PSBT construction that gets complicated, or the Clarity verification side?

===

Let me search for information about that Bitcoin L2.Good search results. Here's the RSK/Rootstock setup:

**Rootstock (RSK) - the OG Bitcoin sidechain where Sovryn lives:**

Federations use a threshold of members for both the custody of bitcoin on the mainchain and blocksigning, i.e., a 5-of-7 multisig. This is done instead of requiring all seven of the members to sign in order to balance the two major risks of such a system: theft versus loss.

But they've evolved significantly:

The set of functionaries still exists, but their role is mainly to keep their hardware and nodes connected and alive at all times; they do not directly control the Bitcoin multisig private keys.

The key innovation is their **PowHSMs** (Proof of Work Hardware Security Modules):

Functionaries don't have access to the private keys of the multisig address holding the BTC. Therefore, they cannot conspire to steal it. They run Hardware Security Modules (HSMs) connected to RSK full nodes. HSMs are tamper-proof devices that each generate and secure one of the private keys to the Bitcoin multisig address.

One of the most distinctive characteristics of the PowPeg are hardware devices called PowHSMs that protect private keys and eliminate the need for human control. As a result, transactions can no longer be manually signed — and private keys cannot be extracted or backed up, even in encrypted form.

**Critical difference from Capsule:** The federation together can steal all of the funds locked in a federated sidechain if they choose to cooperate together to do so; this is why the entire security model is based around many different actors in many different legal jurisdictions.

And like Pontis - **no user signature required for peg-out.**

---

**Your positioning becomes clearer:**

|                 | RSK/Rootstock              | Pontis-style     | Capsule                        |
| --------------- | -------------------------- | ---------------- | ------------------------------ |
| Federation size | 5-of-7 (now PowPeg)        | 9-of-15 (opaque) | 3-of-4 or 4-of-4 (transparent) |
| User signature  | No                         | No               | **Yes - mandatory**            |
| Key storage     | HSMs (humans can't access) | Unknown          | Hot keys (transparent)         |
| Collusion drain | All TVL                    | All TVL          | **Only that user's funds**     |

RSK solved "operators colluding" by making keys physically inaccessible via HSMs. That's clever but expensive and complex. You're solving it differently - by making collusion _insufficient_ without user participation.

**For your tweets, this gives you a nice contrast:**

"Some bridges prevent operator collusion with hardware vaults. We prevent it mathematically - your signature is required for every unlock. No HSM, no federation trust, just cryptography."

On the library question for m-of-n with mandatory user - do you want me to help you think through how the Clarity mapping would need to change to support "user + any 2-of-3 operators" versus the current "user + all operators"?

===

You're right, my bad. Here are tweet drafts using those three points:

---

**Tweet 1 (threat model shift):**

Most bridges have one threat model: compromise the bridge, drain everyone.

We flipped it: compromise the bridge + convince each user individually to sign away their own funds.

That's not a bridge hack. That's a scam - and it doesn't scale.

---

**Tweet 2 (custodial with extra steps):**

If your bridge operators can move your funds without your signature, that's a custodial bridge with extra steps.

Doesn't matter how many signers they have. Doesn't matter if it's 9-of-15 or 5-of-7.

No user signature = not your keys, not your coins.

---

**Tweet 3 (collusion resistance):**

"But what if all the bridge operators collude?"

Even if all other signers collude, they can't steal funds unilaterally.

Your signature is required. Always. For every unlock.

That's not a feature. That's the whole point.

---

Want me to tighten any of these or combine them into a thread?

===

Perfect, here they are clean:

---

**Tweet 1:**

Most bridges: compromise the bridge, drain everyone.

Capsule: compromise the bridge + convince each user individually to sign away their own funds.

---

**Tweet 2:**

Skipping user signature means bridge operators can move your funds without you.

That's a custodial bridge with extra steps.

---

**Tweet 3:**

Even if all other signers collude, they can't steal funds unilaterally.

Your signature is required. Always.

---

Short, punchy, no fluff. Ready to post or want any small tweaks?
