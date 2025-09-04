# 🗳️ Dynamic DAO Membership with Activity Decay

> **A revolutionary DAO governance system where voting power decays over time without activity** ⏳

## 🎯 Overview

This smart contract implements a Dynamic DAO system where members' voting power naturally decays over time unless they remain active. The more engaged you are, the stronger your voice becomes in governance decisions! 

## ✨ Key Features

- 🚀 **Dynamic Voting Power**: Base voting power that decays without activity
- ⚡ **Activity Rewards**: Bonus voting power for creating proposals and voting  
- 🕒 **Time-Based Decay**: Voting power reduces every 144 blocks (~24 hours)
- 📊 **Proposal System**: Create and vote on governance proposals
- 🛡️ **Anti-Spam**: Minimum voting power threshold for proposal creation
- 🔄 **Activity Tracking**: Complete member activity statistics

## 🏗️ Contract Architecture

### Core Components

1. **Member Management** 👥
   - Join DAO with base voting power (1000)
   - Track activity and voting history
   - Automatic voting power calculation

2. **Proposal System** 📋
   - Create proposals with title and description
   - Time-limited voting periods (1008 blocks ~7 days)
   - Execution based on majority vote

3. **Activity Decay** ⏰
   - Voting power decays 100 points every 144 blocks
   - Activity resets decay timer
   - Bonus points for participation

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
git clone [your-repo-url]
cd Dynamic-DAO-Membership-with-Activity-Decay
clarinet check
clarinet test
```

## 📖 Usage Guide

### 🔗 Join the DAO

```clarity
(contract-call? .dynamic-dao-membership-with-activity-decay join-dao)
```

**Returns:** Your unique member ID

### 💡 Create a Proposal

```clarity
(contract-call? .dynamic-dao-membership-with-activity-decay 
  create-proposal 
  "Proposal Title" 
  "Detailed description of the proposal")
```

**Requirements:** 
- Minimum 1000 voting power
- Must be a DAO member

### 🗳️ Vote on Proposals

```clarity
(contract-call? .dynamic-dao-membership-with-activity-decay 
  vote-on-proposal 
  u1 ;; proposal-id
  true) ;; true for YES, false for NO
```

### ⚡ Refresh Your Membership

```clarity
(contract-call? .dynamic-dao-membership-with-activity-decay refresh-membership)
```

**Purpose:** Resets activity timer and prevents further decay

### 🏁 Execute Proposals

```clarity
(contract-call? .dynamic-dao-membership-with-activity-decay 
  execute-proposal 
  u1) ;; proposal-id
```

**Requirements:**
- Voting period must be ended
- Majority YES votes
- Minimum participation threshold met

## 📊 Query Functions

### Get Your Current Stats
```clarity
(contract-call? .dynamic-dao-membership-with-activity-decay 
  get-member-stats 
  'SP1234567890) ;; your-address
```

### Check Voting Power
```clarity
(contract-call? .dynamic-dao-membership-with-activity-decay 
  get-current-voting-power 
  'SP1234567890) ;; member-address
```

### View Proposal Details
```clarity
(contract-call? .dynamic-dao-membership-with-activity-decay 
  get-proposal 
  u1) ;; proposal-id
```

### Get Proposal Results
```clarity
(contract-call? .dynamic-dao-membership-with-activity-decay 
  get-proposal-results 
  u1) ;; proposal-id
```

## ⚙️ System Parameters

| Parameter | Value | Description |
|-----------|--------|-------------|
| `BASE_VOTING_POWER` | 1000 | Initial voting power for new members |
| `DECAY_PERIOD` | 144 blocks | ~24 hours decay interval |
| `MIN_PROPOSAL_THRESHOLD` | 1000 | Minimum voting power to create proposals |
| `VOTING_DURATION` | 1008 blocks | ~7 days voting period |
| `PROPOSAL_BONUS` | 100 points | Bonus for creating proposals |
| `VOTING_BONUS` | 50 points | Bonus for voting on proposals |

## 🧮 Voting Power Calculation

```
Current Voting Power = Base Power - (Decay Periods × 100) + Activity Bonuses

Where:
- Decay Periods = Blocks Since Last Activity ÷ 144
- Activity Bonuses = (Total Proposals × 100) + (Total Votes × 50)
- Maximum Decay: 10 periods (power becomes 0)
```

## 🔒 Security Features

- ✅ Only members can vote and create proposals
- ✅ One vote per proposal per member
- ✅ Proposal execution requires majority and quorum
- ✅ Time-locked voting periods
- ✅ Activity-based anti-spam protection

## 🚦 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| `u100` | `ERR_UNAUTHORIZED` | Not authorized for this action |
| `u101` | `ERR_NOT_MEMBER` | Address is not a DAO member |
| `u102` | `ERR_ALREADY_MEMBER` | Already joined the DAO |
| `u103` | `ERR_PROPOSAL_NOT_FOUND` | Proposal doesn't exist |
| `u104` | `ERR_VOTING_ENDED` | Voting period has ended |
| `u105` | `ERR_ALREADY_VOTED` | Already voted on this proposal |
| `u106` | `ERR_INSUFFICIENT_VOTING_POWER` | Not enough voting power |
| `u107` | `ERR_PROPOSAL_NOT_EXECUTABLE` | Proposal cannot be executed |

## 🧪 Testing

Run the test suite:

```bash
clarinet test
```

Test individual functions:

```bash
clarinet console
```

## 💡 Use Cases

- **Community DAOs** 🏘️: Reward active community members
- **Investment DAOs** 💰: Ensure engaged decision-making
- **Protocol Governance** 🔧: Incentivize ongoing participation  
- **Social Organizations** 🤝: Maintain member engagement

## 🛣️ Roadmap

- [ ] 📈 Advanced decay curves
- [ ] 🏆 Achievement-based bonuses  
- [ ] 📱 Multi-proposal batch voting
- [ ] 🔗 Cross-DAO membership integration
- [ ] 📊 Advanced analytics dashboard

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Submit a pull request

## 📜 License

MIT License - Build awesome things! 🚀

---

**Built with ❤️ for the Stacks ecosystem** 

*Empowering communities through activity-based governance* ⚡
