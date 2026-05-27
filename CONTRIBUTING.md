# Contributing to QuantAlgo Trading Systems

Thank you for your interest in contributing to QuantAlgo Trading Systems! This document provides guidelines and instructions for contributing to the project.

## 🤝 How to Contribute

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When creating a bug report, include:

- **Clear description** of the issue
- **Steps to reproduce** the problem
- **Expected behavior** vs actual behavior
- **Screenshots** if applicable
- **Environment details** (TradingView/MT5 version, OS, etc.)
- **Strategy/EA name** and configuration used

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Clear description** of the proposed enhancement
- **Use case** and benefits
- **Alternative solutions** considered
- **Implementation ideas** if applicable

### Contributing Code

#### Fork and Clone

1. Fork the repository
2. Clone your fork locally:
   ```bash
   git clone https://github.com/yourusername/quantalgo-trading-systems.git
   cd quantalgo-trading-systems
   ```

#### Create a Branch

Create a descriptive branch for your contribution:
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

#### Make Changes

- Follow the existing code style and conventions
- Add comments for complex logic
- Update documentation if needed
- Test your changes thoroughly

#### Commit Changes

Write clear, descriptive commit messages:
```bash
git commit -m "Add: New SMC indicator with FVG detection"
# or
git commit -m "Fix: Correct ATR calculation in propfirm strategy"
```

#### Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:
- Clear title and description
- Reference related issues
- Screenshots of results (if applicable)
- Backtest results for strategies

## 📝 Code Style Guidelines

### Pine Script

- Use `//@version=6` for all new scripts
- Follow the existing naming conventions (snake_case for variables)
- Group inputs logically with descriptive group names
- Add comments for complex logic
- Use consistent indentation (4 spaces)
- Include strategy metadata (description, overlay, etc.)

Example:
```pine
//@version=6
strategy("Strategy Name", overlay=true, initial_capital=1000)

// ╔══════════════════════════════════════════╗
// ║       SECTION NAME                       ║
// ╚══════════════════════════════════════════╝
grp_section = "SECTION NAME"
input_param = input.float(1.0, "Parameter Name", group=grp_section)
```

### MQL5 (MetaTrader 5)

- Follow MQL5 coding standards
- Use meaningful variable names
- Add function headers with descriptions
- Include error handling
- Use consistent indentation (4 spaces)

Example:
```cpp
//+------------------------------------------------------------------+
//| Function Description                                              |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopDistance)
{
   // Implementation
}
```

## 🧪 Testing

### Pine Script Strategies

- Test on multiple timeframes (15m, 1H, 4H)
- Test on different symbols (EURUSD, GBPUSD, XAUUSD)
- Verify risk management works correctly
- Check dashboard displays correctly
- Ensure alerts trigger properly
- Backtest with realistic commission (0.01-0.05%)

### MT5 Expert Advisors

- Test in Strategy Tester first
- Verify on demo account before live
- Check position sizing calculations
- Test trailing stop and breakeven
- Verify session filters work
- Monitor for memory leaks

## 📚 Documentation

- Update README.md if adding new strategies/EAs
- Add inline comments for complex logic
- Create documentation files for new features
- Include usage examples
- Document configuration parameters

## 🏷️ Naming Conventions

### Files

- **Pine Scripts**: `kebab-case.pine` (e.g., `smc-quant-engine.pine`)
- **MT5 EAs**: `kebab-case.mq5` (e.g., `propfirm-elite-ea.mq5`)
- **Documentation**: `kebab-case.md` (e.g., `backtesting-guide.md`)

### Variables

- **Pine Script**: `snake_case` (e.g., `bull_score`, `atr_value`)
- **MQL5**: `camelCase` (e.g., `bullScore`, `atrValue`)

### Functions

- **Pine Script**: `camelCase` (e.g., `calculateLotSize`)
- **MQL5**: `PascalCase` (e.g., `CalculateLotSize`)

## 🎯 Contribution Areas

We welcome contributions in:

- **New Strategies**: Additional SMC/quant strategies
- **Indicators**: Custom indicators for analysis
- **Documentation**: Guides, tutorials, examples
- **Bug Fixes**: Report and fix issues
- **Performance**: Optimization and backtesting
- **Testing**: Comprehensive test suites
- **Translations**: Multi-language support

## ⚠️ Guidelines for Strategy Contributions

When contributing new strategies:

1. **Risk Management**: Must include proper risk controls
2. **Backtesting**: Provide backtest results (winrate, profit factor, max DD)
3. **Documentation**: Explain the strategy logic and parameters
4. **Testing**: Test on multiple symbols and timeframes
5. **Originality**: Ensure the strategy is not a duplicate

## 📧 Communication

- Be respectful and constructive
- Respond to PR comments in a timely manner
- Ask for clarification if needed
- Help others learn and improve

## 🎉 Recognition

Contributors will be acknowledged in:
- CONTRIBUTORS.md file
- Release notes
- Strategy/EA documentation

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to QuantAlgo Trading Systems! 🚀
