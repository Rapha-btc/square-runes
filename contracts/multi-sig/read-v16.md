Good question. Let's think through the tradeoffs:

---

**More signers (e.g., 9-of-15 with user mandatory):**

Pros:

- Higher collusion threshold (need 8 operators + user)
- More censorship resistant (need 7 operators to block)
- Looks more "decentralized" on paper

Cons:

- Opacity becomes a feature - who actually controls those keys?
- Coordination overhead for legitimate unlocks
- More attack surface (15 keys to secure vs 6)
- Liveness risk increases - need 9 parties online and responsive
- Harder to audit, harder to hold accountable
- Easy to hide concentration (what if 5 of 15 are same entity?)

---

**Fewer signers, fully transparent (e.g., 3-of-6 with user mandatory):**

Pros:

- Every signer publicly known and accountable
- Easier to verify no hidden concentration
- Simpler coordination, better liveness
- Smaller attack surface
- Users know exactly who they're trusting

Cons:

- Lower raw number for collusion (but user mandatory neutralizes this)
- Lower raw number for censorship resistance

---

**The key insight:**

With user mandatory, the collusion math changes completely. 9-of-15 without user = need 9 to steal everything. 3-of-6 with user = need 2 operators + that specific user to steal only that user's funds.

More signers protects against **operator collusion**. User mandatory protects against **everyone**.

So 9-of-15 with user mandatory is stronger on paper, but:

- Do you trust 14 anonymous operators more than 5 known ones?
- Can you verify the 14 aren't 5 entities with multiple keys?

---

**Bottom line:**

Transparent 3-of-6 with user mandatory > opaque 9-of-15 with user mandatory > any setup without user mandatory

Accountability beats numbers. You can't audit what you can't see.

===

**Tweet:**

More signers protects against operator collusion.

User mandatory protects against everyone.

---

That's it. Doesn't need anything else. Clean and lands hard.
