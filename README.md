# 🎰 Provably Fair Raffle Contest

A decentralized, provably fair raffle smart contract built with Foundry. Uses **Chainlink VRF v2.5** for verifiable randomness and **Chainlink Automation** for autonomous winner selection — no admin intervention required.

Built while completing [Cyfrin Updraft's Foundry Fundamentals](https://updraft.cyfrin.io/courses/foundry) course.

---

## What It Does

- Users enter the raffle by paying an entrance fee in ETH
- After a set time interval, Chainlink Automation triggers winner selection
- Chainlink VRF picks a provably random winner
- The entire prize pool is sent automatically to the winner
- The raffle resets and opens again for the next round

---

## Tech Stack

- **Solidity** `0.8.19`
- **Foundry** (Forge, Cast, Anvil)
- **Chainlink VRF v2.5** — verifiable random number generation
- **Chainlink Automation** — autonomous upkeep (no manual trigger needed)
- **OpenZeppelin / Solmate** — ERC20 (LinkToken mock)
- **forge-std** — testing utilities
- **Cyfrin/foundry-devops** — most recent deployment lookup

---

## Project Structure

```
├── src/
│   └── Raffle.sol              # Core raffle contract
├── script/
│   ├── DeployRaffle.s.sol      # Deployment script (handles sub creation, funding, consumer registration)
│   ├── HelperConfig.s.sol      # Chain-aware config (Sepolia + Anvil local)
│   └── Interactions.s.sol      # CreateSubscription, FundSubscription, AddConsumer
├── test/
│   ├── unit/
│   │   └── RaffleTest.t.sol    # Unit tests (12 tests, all passing)
│   ├── integration/
│   │   └── Interactions.t.sol  # Integration tests (WIP)
│   └── mocks/
│       └── LinkToken.sol       # ERC677 LINK token mock
├── broadcast/                  # Deployment broadcast logs
└── foundry.toml
```

---

## Getting Started

### Prerequisites

- [Git](https://git-scm.com/downloads)
- [Foundry](https://book.getfoundry.sh/getting-started/installation) (includes Forge, Cast, Anvil)
- [Solidity](https://docs.soliditylang.org/) `0.8.19` (handled by Foundry/solc, no manual install needed)

### Install

```bash
git clone https://github.com/04arush/Raffle-Contest
cd Raffle-Contest/
forge install
```

### Build

```bash
forge build
```

### Test

```bash
forge test
```

Run with verbosity and gas output:

```bash
forge test -vvv
```

### Coverage

```bash
forge coverage
```

---

## Deployment

### Local (Anvil)

Spins up mock VRF Coordinator and LinkToken automatically.

```bash
anvil
forge script script/DeployRaffle.s.sol --broadcast
```

### Sepolia Testnet

Create a `.env` file with your Alchemy RPC URL:

```env
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/<your_api_key>
```

Private key is managed securely via Cast's encrypted keystore — not stored in `.env`:

```bash
cast wallet import  --interactive
```

Then deploy:

```bash
forge script script/DeployRaffle.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --account  \
  --broadcast
```

The deploy script auto-handles subscription creation, LINK funding, and consumer registration regardless of which network you're on.

---

## How the Deploy Script Works

`DeployRaffle.s.sol` is chain-aware via `HelperConfig`:

- On **Anvil**: deploys `VRFCoordinatorV2_5Mock` and `LinkToken`, creates + funds a subscription programmatically
- On **Sepolia**: uses live Chainlink contracts (coordinator at `0x9DdfaCa8183...`, LINK at `0x779877A7...`)

In both cases, `AddConsumer` registers the deployed `Raffle` contract with the VRF subscription automatically.

---

## Tests

12 unit tests — all passing.

```
testRaffleInitializesInOpenState
testRaffleRevertsWhenYouDontPayEnough
testRaffleRecordsParticipantsWhenTheyEnter
testEnteringRaffleEmitsEvent
testDontAllowPeopleToParticipateWhileRaffleIsCalculating
testCheckUpkeepReturnsFalseIfItHasNoBalance
testCheckUpkeepReturnsFalseIfRaffleIsNotOpen
testPerformUpkeepCanOnlyRunIfUpkeepIsTrue
testPerformUpkeepRevertsIfUpkeepIsFalse
testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId
testFullfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep (fuzz, 256 runs)
testFullfillRandomWordsPicksAWinnerResetsAndSendsMoney
```

Fork tests (Sepolia) are skipped locally via the `skipFork` modifier — VRF mock tests only run on Anvil.

---

## Sepolia Deployment

| Item | Value |
|---|---|
| Network | Sepolia (`11155111`) |
| VRF Coordinator | `0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B` |
| LINK Token | `0x779877A7B0D9E8603169DdbD7836e478b4624789` |
| Deployer | `0xF5eB5c100e15D7e443dd5edD4A325Fcc3bbC8d46` |

---

## What I Learned

- Foundry project setup, `forge-std`, testing patterns, and fuzz testing
- Writing and deploying smart contracts with Foundry scripts
- Chain-aware deployment using `HelperConfig` pattern
- Integrating **Chainlink VRF v2.5** for on-chain randomness
- Integrating **Chainlink Automation** (`checkUpkeep` / `performUpkeep`)
- Mocking external contracts for local testing
- Coverage reporting and the `skipFork` pattern for multi-chain test suites
- Broadcast logs and deployment tracking

---

## Course

[Cyfrin Updraft — Foundry Fundamentals](https://updraft.cyfrin.io/courses/foundry)