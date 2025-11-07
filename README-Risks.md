# Runes Square: 2-of-2 Multisig Bridge Design

## Key Security Properties

1. **No Arbitrary Minting**: Bridge can only mint wrapped tokens when legitimate L1 deposits are verified
2. **No Theft of L1 Runes**: Operator alone cannot access user's L1 funds due to multisig requirement
3. **Distributed Risk**: Not a central honeypot; operator would need to collude with many individual users
4. **Two-way Bridging**: Enables price arbitrage in both directions, maintaining value parity

## Implementation

1. User and operator create 2-of-3 multisig address
2. User deposits Runes to multisig
3. Bridge verifies deposit using Clarity Bitcoin library
4. Bridge mints wrapped Runes on Stacks (Clarity oracle + map multisig/tx-sender receiver)
5. For withdrawals, user burns wrapped tokens and operator co-signs release transaction

## Key Risks & Mitigations

### 1. Release Without Burning

**Risk**: Operator and user could collude to release L1 Runes without burning wrapped tokens.

**Mitigation**:

- No honeypot for bridge operator (collusion would be distributed across many users)
- Reputational risk and loss of business for operator
- Economic incentives discourage this behavior

### 2. Bridge Private Key Security

**Risk**: If bridge operator's private keys are compromised, attackers could co-sign with users to unlock L1 runes without burning L2 tokens.

**Impact Comparison**: This design significantly limits attack impact compared to traditional bridges:

- Attackers must possess real L1 runes to mint L2 tokens (no arbitrary minting)
- The exploitation process is constrained by Bitcoin's 10-minute block times
- A malicious actor would need to repeatedly cycle through: deposit L1 → mint L2 → sell L2 → withdraw L1 (without burning)
- This slow process allows for detection and intervention before significant damage

**Mitigations**:

- **Multi-Party Key Management**: Implement a 3-of-3 multisig for the bridge operator, requiring 2 compromised keys instead of 1
- **Kill Switch**: Operator can immediately suspend minting capability once compromise is detected
- **Timelocks**: Implement delay periods for large withdrawals to allow intervention (fast withdrawals = anomalie detected = triggers alert kill switch)

**User Protection**: Even in a compromise scenario:

- Users holding L2 tokens could still sell them to recover partial value
- Users would retain full access to their L1 runes
- Unlike traditional bridge hacks where users lose everything, this model allows for partial recovery

### 3. Operator Availability

**Risk**: The two-way bridge requires operator's active participation for withdrawals. Operator unavailability could temporarily lock user funds.

**Mitigations**:

- **Timelock Recovery**: Users can recover funds after a predetermined period if operator becomes unavailable
- **Multiple Signing Entities**: Distribute signing responsibility across multiple independent parties

### 4. Price Stability Considerations

**Risk**: If bridge security is compromised and users can withdraw L1 runes without burning L2 tokens, the backing of L2 tokens would be reduced.

**Analysis**:

- Unlike traditional bridges where hackers can mint unlimited tokens in seconds and completely deplete AMMs
- This design forces attackers to use slow Bitcoin transactions and real assets (l1 runes)
- The kill switch can be activated before significant damage occurs
- L2 token value may decrease, but wouldn't be completely depleted in a single block

**Mitigations**:

- **Transparent Monitoring**: Public dashboard showing bridge status and backing
- **Circuit Breakers**: Automatic suspension of operations if unusual patterns detected

### 5. Technical Verification

**Risk**: The trustless mapping between Bitcoin multisig and Stacks addresses is critical to the security model.

**Mitigation**:

- **Cryptographic Verification**: Clarity contracts verify that tx-sender's pubkey hash matches one of the multisig signers
- **Auditable Processes**: All verifications are performed on-chain and publicly verifiable
- **Formal Verification**: Critical contract components should undergo formal verification

## Additional Security Considerations

1. **No Central Honeypot**: Funds are distributed across many multisig addresses rather than a single contract
2. **User Sovereignty**: Users retain partial control of their L1 assets at all times
3. **Transparent Operations**: All bridge actions are publicly verifiable on both chains
4. **Phased Rollout**: Initial deployment with transaction limits that increase gradually
5. **Economic Alignment**: Operator's business model and reputation provide natural incentives for honest behavior (operator cannot steal runes asset without user collusion)

This design balances security, usability and capital efficiency while enabling crucial two-way arbitrage for price stability, with significant improvements over traditional federated bridge models.
