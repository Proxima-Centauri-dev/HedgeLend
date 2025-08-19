# HedgeLend

[![Stacks](https://img.shields.io/badge/Built%20on-Stacks-blue)](https://stacks.co)
[![Clarity](https://img.shields.io/badge/Language-Clarity-orange)](https://clarity-lang.org)
[![License](https://img.shields.io/badge/License-ISC-green)](LICENSE)

HedgeLend is a sophisticated DeFi lending protocol built on the Stacks blockchain that implements hedge fund-inspired lending strategies with advanced risk management capabilities. The protocol features dynamic interest rates, real-time health factor monitoring, and automated liquidation mechanisms.

## 🚀 Features

### Core Lending Functions
- **Deposit & Withdraw**: Seamless STX deposits and withdrawals with real-time tracking
- **Collateralized Borrowing**: Borrow against deposited collateral with dynamic LTV ratios
- **Interest Accrual**: Compound interest calculations with time-based precision
- **Flexible Repayment**: Partial or full debt repayment with interest settlement

### Advanced Risk Management
- **Dynamic Interest Rates**: Utilization-based interest rate model that adjusts automatically
- **Health Factor Monitoring**: Real-time position health tracking with liquidation warnings
- **Risk-Adjusted Pricing**: Sophisticated pricing model incorporating volatility and risk weights
- **Liquidation Protection**: Automated liquidation system with configurable thresholds

### Hedge Fund Strategies
- **Utilization Rate Optimization**: Interest rates respond to pool utilization for optimal capital efficiency
- **Risk Premium Calculation**: Dynamic risk premiums based on market conditions
- **Position Management**: Advanced position tracking with health factor calculations
- **Emergency Controls**: Circuit breakers and emergency shutdown capabilities

## 🛠 Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Epoch**: 2.5
- **Precision**: 10,000 basis points (0.01% precision)
- **Liquidation Threshold**: 80% (configurable)
- **Base Interest Rate**: 2% (adjustable)
- **Maximum Utilization**: 90%

### Key Constants
```clarity
LIQUIDATION_THRESHOLD: 8000 (80%)
LIQUIDATION_PENALTY: 500 (5%)
MAX_UTILIZATION_RATE: 9000 (90%)
BASE_INTEREST_RATE: 200 (2%)
PRECISION: 10000 (basis points)
```

## 📋 Installation

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) CLI tool
- [Node.js](https://nodejs.org/) v16 or higher
- [Git](https://git-scm.com/)

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd HedgeLend
   ```

2. **Navigate to contract directory**
   ```bash
   cd HedgeLend_contract
   ```

3. **Install dependencies**
   ```bash
   npm install
   ```

4. **Run tests**
   ```bash
   npm test
   ```

5. **Start development environment**
   ```bash
   clarinet console
   ```

## 🎯 Usage Examples

### Basic Operations

#### Deposit STX
```clarity
(contract-call? .HedgeLend deposit u1000000) ;; Deposit 1 STX (1,000,000 microSTX)
```

#### Add Collateral
```clarity
(contract-call? .HedgeLend add-collateral u2000000) ;; Add 2 STX as collateral
```

#### Borrow Against Collateral
```clarity
(contract-call? .HedgeLend borrow u800000) ;; Borrow 0.8 STX (within 80% LTV)
```

#### Repay Debt
```clarity
(contract-call? .HedgeLend repay u800000) ;; Repay borrowed amount
```

#### Withdraw Deposits
```clarity
(contract-call? .HedgeLend withdraw u500000) ;; Withdraw 0.5 STX
```

### Administrative Functions

#### Set Risk Parameters
```clarity
(contract-call? .HedgeLend set-risk-parameters 
  'SP000000000000000000002Q6VF78 ;; Asset principal
  u7000  ;; LTV ratio (70%)
  u8000  ;; Liquidation threshold (80%)
  u500   ;; Liquidation penalty (5%)
  u1500  ;; Price volatility (15%)
  u1000) ;; Risk weight (10%)
```

#### Emergency Shutdown
```clarity
(contract-call? .HedgeLend toggle-emergency-shutdown)
```

### Query Functions

#### Check User Account
```clarity
(contract-call? .HedgeLend get-user-account 'SP1234567890ABCDEF)
```

#### Get Protocol Statistics
```clarity
(contract-call? .HedgeLend get-protocol-stats)
```

#### Check Health Factor
```clarity
(contract-call? .HedgeLend get-user-health-factor 'SP1234567890ABCDEF)
```

## 📚 Contract Functions Documentation

### Public Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `deposit` | Deposit STX to earn interest | `amount: uint` | `(response uint uint)` |
| `withdraw` | Withdraw deposited STX | `amount: uint` | `(response uint uint)` |
| `add-collateral` | Add STX as collateral | `amount: uint` | `(response uint uint)` |
| `borrow` | Borrow against collateral | `amount: uint` | `(response uint uint)` |
| `repay` | Repay borrowed amount | `amount: uint` | `(response uint uint)` |
| `liquidate` | Liquidate undercollateralized position | `user: principal, debt-to-cover: uint` | `(response {liquidated-debt: uint, seized-collateral: uint} uint)` |
| `set-risk-parameters` | Configure asset risk parameters | `asset: principal, ltv-ratio: uint, liquidation-threshold: uint, liquidation-penalty: uint, price-volatility: uint, risk-weight: uint` | `(response bool uint)` |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-user-account` | Get user account details | `(optional {deposits: uint, borrowed: uint, collateral: uint, last-interaction-height: uint, health-factor: uint, accrued-interest: uint})` |
| `get-user-health-factor` | Calculate user's health factor | `uint` |
| `get-current-interest-rate` | Get current dynamic interest rate | `uint` |
| `get-utilization-rate` | Get pool utilization rate | `uint` |
| `get-protocol-stats` | Get comprehensive protocol statistics | `{total-deposits: uint, total-borrowed: uint, utilization-rate: uint, current-interest-rate: uint, emergency-shutdown: bool}` |
| `can-user-borrow` | Check if user can borrow amount | `bool` |
| `is-position-liquidatable` | Check if position can be liquidated | `bool` |

## 🚀 Deployment Guide

### Testnet Deployment

1. **Configure Clarinet for testnet**
   ```bash
   clarinet check
   ```

2. **Deploy to testnet**
   ```bash
   clarinet deploy --testnet
   ```

3. **Verify deployment**
   ```bash
   clarinet console --testnet
   ```

### Mainnet Deployment

1. **Final testing**
   ```bash
   npm run test
   clarinet check
   ```

2. **Deploy to mainnet**
   ```bash
   clarinet deploy --mainnet
   ```

3. **Post-deployment verification**
   - Verify contract deployment on Stacks Explorer
   - Test basic functions with small amounts
   - Monitor for any issues

### Environment Configuration

The contract includes configuration files for different networks:
- `settings/Devnet.toml` - Local development
- `settings/Testnet.toml` - Testnet deployment  
- `settings/Mainnet.toml` - Production deployment

## 🔒 Security Features

### Risk Management
- **Liquidation Threshold**: Positions are liquidated at 80% LTV to protect lenders
- **Health Factor Monitoring**: Continuous monitoring of position health
- **Emergency Shutdown**: Owner can halt all operations in emergency situations
- **Interest Rate Caps**: Maximum utilization rate prevents excessive borrowing costs

### Access Controls
- **Owner-Only Functions**: Critical functions restricted to contract owner
- **User Authentication**: All functions verify caller permissions
- **Parameter Validation**: Input validation prevents invalid operations

### Economic Security
- **Liquidation Incentives**: 5% liquidation penalty incentivizes timely liquidations
- **Dynamic Interest Rates**: Market-responsive rates prevent exploitation
- **Collateral Requirements**: Over-collateralization protects against defaults

## ⚠️ Security Considerations

### Auditing
- **Code Review**: Thoroughly review all contract logic before deployment
- **Test Coverage**: Ensure comprehensive test coverage of all functions
- **Third-Party Audit**: Consider professional smart contract audit

### Risk Factors
- **Price Oracle Dependency**: Currently uses simplified pricing logic
- **Liquidation Risk**: Users must monitor their health factors
- **Smart Contract Risk**: Inherent risks in smart contract technology
- **Regulatory Risk**: DeFi protocols may face regulatory changes

### Best Practices
- **Start Small**: Begin with limited deposits to test functionality
- **Monitor Positions**: Regularly check health factors and market conditions
- **Diversify Risk**: Don't concentrate all assets in a single protocol
- **Stay Informed**: Keep updated on protocol changes and market conditions

## 🧪 Testing

### Run Test Suite
```bash
npm test                    # Run all tests
npm run test:report        # Run tests with coverage report
npm run test:watch         # Watch mode for development
```

### Test Coverage
The test suite covers:
- Core lending functions (deposit, withdraw, borrow, repay)
- Risk management (health factors, liquidations)
- Interest rate calculations
- Edge cases and error conditions
- Access control mechanisms

## 📈 Monitoring & Analytics

### Key Metrics to Monitor
- **Total Value Locked (TVL)**: Sum of all deposits
- **Utilization Rate**: Percentage of deposits currently borrowed
- **Interest Rates**: Current borrowing and lending rates
- **Health Factor Distribution**: Risk profile of all positions
- **Liquidation Activity**: Frequency and size of liquidations

### Protocol Statistics
Use the `get-protocol-stats` function to retrieve:
- Total deposits and borrowed amounts
- Current utilization and interest rates
- Emergency shutdown status

## 🤝 Contributing

We welcome contributions to improve HedgeLend! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes with comprehensive tests
4. Submit a pull request with detailed description

## 📄 License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For questions, issues, or support:
- Open an issue on GitHub
- Review the documentation
- Check existing test cases for usage examples

## ⚡ Performance Considerations

- **Gas Optimization**: Functions are optimized for minimal execution costs
- **State Efficiency**: Data structures minimize storage requirements
- **Batch Operations**: Consider batching multiple operations when possible
- **Rate Limiting**: Be aware of Stacks network transaction limits

---

**Disclaimer**: This software is provided as-is and may contain bugs or vulnerabilities. Users should conduct their own due diligence and consider the risks before using this protocol with significant funds. The developers are not responsible for any losses incurred through the use of this software.
