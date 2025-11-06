# Runes Square: 2-of-2 Multisig Bridge Design

## Key Security Properties

1. **No Arbitrary Minting**: Bridge can only mint wrapped tokens when legitimate L1 deposits are verified
2. **No Theft of L1 Runes**: Operator alone cannot access user's L1 funds due to multisig requirement
3. **Distributed Risk**: Not a central honeypot; operator would need to collude with many individual users
4. **Two-way Bridging**: Enables price arbitrage in both directions, maintaining value parity

## Implementation

1. User and operator create 2-of-2 multisig address
2. User deposits Runes to multisig
3. Bridge verifies deposit using Clarity Bitcoin library
4. Bridge mints wrapped Runes on Stacks (Clarity oracle + map multisig/tx-sender receiver)
5. For withdrawals, user burns wrapped tokens and operator co-signs release transaction

## Key Risks

1. **Release Without Burning**: Operator and user could collude to release L1 Runes without burning wrapped tokens (no honey pot for bridge operator thou + reputational risk loss of business)
2. **Operator Availability**: Two-way bridge requires operator's active participation for withdrawals
3. **Technical Verification**: Clarity can create a trustless map between multi-sig (runes receiver) and tx-sender's pubkey signer
4. **Risk bridge private keys**: if hacked, users can access their runes on l1 without the need to burn on l2

## Mitigations

1. **Timelock Recovery**: Users can recover funds after predetermined period if operator becomes unavailable (yet to study but seems extra complicated)
2. **Transparent Verification**: All bridge operations publicly verifiable
3. **Economic Incentives**: Operator reputation but no need staking mechanisms as collusion risk limited to user distribution in multi-sigs

This design balances security, usability and capital efficiency while enabling crucial two-way arbitrage for price stability.
