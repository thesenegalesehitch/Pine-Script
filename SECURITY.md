# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.0   | ✅        |

## Reporting a Vulnerability

If you discover a security vulnerability in QuantAlgo Trading Systems, please report it responsibly.

### How to Report

1. **Do NOT** create a public issue
2. Send an email to: security@quantalgo-trading-systems.com
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if known)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Investigation**: Within 7 days
- **Resolution**: As soon as feasible, based on severity

### Security Best Practices for Users

#### API Keys and Credentials
- Never commit API keys to the repository
- Use environment variables for sensitive data
- Rotate credentials regularly

#### TradingView
- Use private scripts for sensitive strategies
- Enable two-factor authentication
- Review sharing settings

#### MetaTrader 5
- Use demo accounts for testing
- Verify EA permissions
- Monitor account activity
- Keep MT5 updated

#### Risk Management
- Always use stop losses
- Never risk more than you can afford to lose
- Test strategies on demo accounts first
- Monitor positions regularly

### Known Limitations

- Strategies are provided as-is without warranty
- Past performance does not guarantee future results
- Users are responsible for their own trading decisions
- No real-time monitoring of live accounts

### Disclosure Policy

We will:
- Acknowledge receipt of vulnerability reports
- Provide regular updates on resolution progress
- Disclose vulnerabilities after fixes are deployed
- Credit security researchers (if desired)

We will not:
- Share your contact information without permission
- Pursue legal action for good-faith security research
- Require NDAs for vulnerability reports

### Security Features

#### Built-in Protections
- Daily drawdown limits
- Maximum loss protection
- Consecutive loss pauses
- Emergency close functionality
- Session filtering

#### Code Review
- All contributions are reviewed
- Risk management logic is verified
- Input validation is checked
- Backtesting is required for new strategies

---

Thank you for helping keep QuantAlgo Trading Systems secure! 🔒
