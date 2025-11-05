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
4. Bridge mints wrapped Runes on Stacks
5. For withdrawals, user burns wrapped tokens and operator co-signs release transaction

## Key Risks

1. **Release Without Burning**: Operator and user could collude to release L1 Runes without burning wrapped tokens
2. **Operator Availability**: Two-way bridge requires operator's active participation for withdrawals
3. **Technical Verification Limits**: Clarity cannot fully verify multisig composition; relies partly on oracle

## Mitigations

1. **Timelock Recovery**: Users can recover funds after predetermined period if operator becomes unavailable
2. **Transparent Verification**: All bridge operations publicly verifiable
3. **Economic Incentives**: Operator reputation and staking mechanisms ensure honest behavior

This design balances security, usability and capital efficiency while enabling crucial two-way arbitrage for price stability.
