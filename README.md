# ⚡ QuantAlgo Trading Systems

<div align="center">

**Institutional-Grade Algorithmic Trading Strategies**

[![Pine Script v6](https://img.shields.io/badge/Pine%20Script-v6-blue)](https://www.tradingview.com/pine-script-docs/)
[![MT5](https://img.shields.io/badge/MT5-Expert%20Advisor-green)](https://www.mql5.com/en/docs/metatrader5)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![AI-Assisted Development](https://img.shields.io/badge/AI--Assisted-ChatGPT-purple)](https://openai.com/chatgpt)
[![Pull Shark](https://img.shields.io/badge/Pull--Shark-Ready-blueviolet)](https://github.com/thesenegalesehitch/Pine-Script/pulls)
[![Pair Programming](https://img.shields.io/badge/Pair--Programming-Active-brightgreen)](https://github.com/thesenegalesehitch/Pine-Script)
[![YOLO](https://img.shields.io/badge/YOLO-🚀-ff69b4)](https://github.com/thesenegalesehitch/Pine-Script)

[Quick Start](#-quick-start) • [Features](#-features) • [Strategies](#-strategies) • [Installation](#-installation) • [Documentation](#-documentation)

</div>

---

## 🎯 Overview

**QuantAlgo Trading Systems** is a professional suite of algorithmic trading strategies designed for prop firms, hedge funds, and serious quantitative traders. Built with institutional-grade risk management, Smart Money Concepts (SMC), and advanced quantitative methods.

### 🏆 Key Highlights

- **Institutional Risk Engine**: Advanced drawdown protection, daily loss limits, and dynamic risk scaling
- **Smart Money Concepts**: BOS, CHOCH, FVG, Order Blocks, Liquidity Sweeps, Breaker Blocks
- **Multi-Timeframe Analysis**: H4/Daily bias integration for higher probability setups
- **Adaptive Scoring System**: Probabilistic signal scoring (0-100) with market regime detection
- **PropFirm Optimized**: Built-in protections for prop firm challenges (daily targets, max drawdown, consecutive loss pauses)
- **Professional Execution**: Breakeven automation, trailing stops, and multi-TP management

---

## ✨ Features

### 🛡️ Risk Management
- **Daily Drawdown Protection**: Hard stops to prevent account blowouts
- **Dynamic Risk Scaling**: Automatic position sizing adjustment based on market conditions
- **Consecutive Loss Pause**: Cooldown periods after losing streaks
- **Recovery Mode**: Reduced risk exposure during drawdown recovery
- **Global Drawdown Monitoring**: Total account equity protection

### 🏗️ Smart Money Concepts (SMC)
- **Break of Structure (BOS)**: Trend continuation detection
- **Change of Character (CHOCH)**: Reversal pattern identification
- **Fair Value Gaps (FVG)**: Imbalance zone detection
- **Order Blocks (OB)**: Institutional footprints
- **Liquidity Sweeps**: Fakeout detection and entry optimization
- **Breaker Blocks**: Failed structure reversals
- **Premium/Discount Zones**: Optimal entry zone identification

### 📊 Quantitative Analysis
- **Market Regime Detection**: Trending, ranging, compression, high volatility
- **Multi-Timeframe Bias**: H4 and Daily trend alignment
- **Volume Analysis**: Spike detection and momentum confirmation
- **ADX Trend Strength**: Trend vs ranging market filtering
- **ATR-Based Position Sizing**: Volatility-adjusted risk management

### ⚡ Execution Features
- **Adaptive Thresholds**: Dynamic signal filtering based on market conditions
- **Killzone Filtering**: London and New York session optimization
- **Breakeven Automation**: Risk-free profit protection
- **Trailing Stop**: Volatility-based profit maximization
- **Multi-Take Profit**: Tiered exit strategy (TP1/TP2)

---

## 📁 Strategies

### Pine Script Strategies (TradingView)

| Strategy | Type | Complexity | Best For |
|----------|------|------------|----------|
| **[institutional-hft-engine](pine-scripts/strategies/institutional-hft-engine.pine)** | HFT | ⭐⭐⭐⭐⭐ | High-frequency trading with probabilistic scoring |
| **[propfirm-ultra-strategy](pine-scripts/strategies/propfirm-ultra-strategy.pine)** | PropFirm | ⭐⭐⭐⭐⭐ | Prop firm challenges with maximum protection |
| **[propfirm-elite-strategy](pine-scripts/strategies/propfirm-elite-strategy.pine)** | PropFirm | ⭐⭐⭐⭐⭐ | Elite prop firm trading with advanced SMC |
| **[smc-quant-engine](pine-scripts/strategies/smc-quant-engine.pine)** | Quant | ⭐⭐⭐⭐ | Quantitative SMC with scoring system |
| **[hedge-fund-smc-strategy](pine-scripts/strategies/hedge-fund-smc-strategy.pine)** | Hedge Fund | ⭐⭐⭐ | Institutional trend-following with SMC |
| **[ultimate-propfirm-strategy](pine-scripts/strategies/ultimate-propfirm-strategy.pine)** | PropFirm | ⭐⭐⭐ | Complete prop firm solution with visuals |
| **[smc-starter-robot](pine-scripts/strategies/smc-starter-robot.pine)** | Educational | ⭐ | Learning SMC basics (no risk management) |

### MT5 Expert Advisors (MetaTrader 5)

| EA | Type | Complexity | Best For |
|----|------|------------|----------|
| **[propfirm-elite-ea](mt5-expert-advisors/propfirm-elite-ea.mq5)** | PropFirm | ⭐⭐⭐⭐⭐ | Complete MT5 solution with BOS+FVG+RSI+Volume |
| **[propfirm-reactive-ea](mt5-expert-advisors/propfirm-reactive-ea.mq5)** | PropFirm | ⭐⭐⭐ | Reactive BOS strategy with prop firm protections |
| **[hedge-fund-smc-ea](mt5-expert-advisors/hedge-fund-smc-ea.mq5)** | Hedge Fund | ⭐⭐ | Basic EMA trend + BOS with trailing stop |

---

## 🚀 Quick Start

### TradingView (Pine Script)

1. **Copy the Strategy**
   ```bash
   # Navigate to the strategy file
   cd pine-scripts/strategies
   # Open the desired strategy in your editor
   ```

2. **Import to TradingView**
   - Open TradingView Chart
   - Pine Script Editor → Open → Upload File
   - Select the `.pine` file
   - Click "Add to Chart"

3. **Configure Parameters**
   - Adjust risk percentage (default: 0.5-1.0%)
   - Set daily loss limit (prop firm: 50% of max allowed)
   - Configure killzones (London: 7-10 UTC, NY: 13-16 UTC)
   - Set score threshold (recommended: 5-8)

4. **Backtest**
   - Select timeframe (recommended: 15m, 1H)
   - Set initial capital (match your prop firm size)
   - Enable commission (0.01-0.05%)
   - Run backtest and analyze metrics

### MetaTrader 5 (Expert Advisor)

1. **Copy the EA**
   ```bash
   # Navigate to MT5 EAs
   cd mt5-expert-advisors
   # Copy the .mq5 file
   ```

2. **Install in MT5**
   - Open MT5 Terminal
   - File → Open Data Folder → MQL5 → Experts
   - Paste the `.mq5` file
   - In MT5: View → Navigator → Right-click EA → Compile

3. **Attach to Chart**
   - Drag EA onto chart
   - Enable "Allow live trading"
   - Configure inputs (risk, sessions, limits)
   - Click OK

---

## 📖 Installation

### Prerequisites

- **TradingView**: Pro+ or higher for backtesting (free for basic use)
- **MetaTrader 5**: Latest version from MetaQuotes
- **Knowledge**: Understanding of SMC, risk management, and prop firm rules

### Repository Structure

```
quantalgo-trading-systems/
├── pine-scripts/
│   ├── strategies/          # TradingView strategies
│   └── indicators/          # Custom indicators (coming soon)
├── mt5-expert-advisors/     # MetaTrader 5 EAs
├── docs/                    # Documentation
├── examples/                # Usage examples
├── assets/                  # Screenshots, backtests
├── README.md                # This file
├── LICENSE                  # MIT License
├── CONTRIBUTING.md          # Contribution guidelines
└── .gitignore               # Git ignore rules
```

---

## 📚 Documentation

### Strategy Guides

- [SMC Concepts Explained](docs/smc-concepts.md) *(coming soon)*
- [PropFirm Risk Management](docs/propfirm-risk.md) *(coming soon)*
- [Backtesting Best Practices](docs/backtesting-guide.md) *(coming soon)*
- [MT5 EA Configuration](docs/mt5-setup.md) *(coming soon)*

### Performance Notes

- **Winrate Target**: 45-55% (focus on risk/reward)
- **Profit Factor**: Aim for 1.5+ for sustainable growth
- **Max Drawdown**: Keep under 10% for prop firm safety
- **Average R:R**: 1:2 to 1:3 minimum

### Market Conditions

**Best Conditions:**
- London/NY Killzones (7-10 UTC, 13-16 UTC)
- Trending markets (ADX > 20)
- Volatility expansion (ATR ratio > 1.0)

**Avoid:**
- Low volatility compression
- News spikes (unless configured)
- Friday afternoon (liquidity risk)
- Choppy/ranging markets

---

## ⚙️ Configuration

### Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `riskPct` | 0.5% | Risk per trade (0.3-1.0% recommended) |
| `dailyLossMax` | $50 | Daily loss limit (prop firm: 50% of max) |
| `dailyTarget` | $100 | Daily profit target (stop when hit) |
| `maxTradesDay` | 20 | Maximum trades per day |
| `maxConsecLoss` | 3 | Pause after consecutive losses |
| `minScore` | 5-8 | Minimum signal quality score |
| `useKillzones` | true | Trade only during London/NY |

### Risk Management Best Practices

1. **Start Small**: 0.3-0.5% risk per trade
2. **Scale Up**: Increase to 1% only after consistent profitability
3. **Respect Limits**: Never exceed daily loss/target
4. **Monitor Equity**: Check account status regularly
5. **Keep Logs**: Record all trades for analysis

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Areas for Contribution

- **New Strategies**: Additional SMC/quant strategies
- **Indicators**: Custom indicators for analysis
- **Documentation**: Guides, tutorials, examples
- **Bug Fixes**: Report and fix issues
- **Performance**: Optimization and backtesting

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Disclaimer**: These strategies are provided for educational purposes. Trading involves substantial risk of loss. Past performance is not indicative of future results. Always test thoroughly and use proper risk management.

---

## 🙏 Acknowledgments

- **Smart Money Concepts**: Based on ICT (Inner Circle Trader) methodology
- **Quantitative Methods**: Inspired by institutional trading practices
- **Community**: Built for the trading and developer community

---

## 📊 Roadmap

### Q2 2026
- [ ] Additional indicators library
- [ ] Multi-symbol portfolio strategies
- [ ] Machine learning integration
- [ ] Web dashboard for monitoring

### Q3 2026
- [ ] Python API for strategy execution
- [ ] Backtesting optimization tools
- [ ] Mobile app for trade alerts
- [ ] Community strategy sharing

### Q4 2026
- [ ] Institutional-grade execution engine
- [ ] Advanced ML models
- [ ] Cloud-based backtesting
- [ ] Enterprise features

---

## 📞 Support & Community

- **Issues**: Report bugs on GitHub Issues
- **Discussions**: Join our GitHub Discussions
- **Twitter**: Follow for updates *(coming soon)*
- **Discord**: Community server *(coming soon)*

---

## ⚠️ Disclaimer

**IMPORTANT NOTICE**: 

Trading financial instruments involves significant risk and may not be suitable for all investors. These strategies are provided for educational and research purposes only. 

- Past performance does not guarantee future results
- You are solely responsible for your trading decisions
- Always test strategies thoroughly on demo accounts first
- Never risk more than you can afford to lose
- Prop firm challenges have specific rules - read them carefully

The authors and contributors of this project assume no liability for any financial losses incurred while using these strategies.

---

<div align="center">

**Built with ❤️ for the quantitative trading community**

[⭐ Star this repo](https://github.com/yourusername/quantalgo-trading-systems) • [🐛 Report Issues](https://github.com/yourusername/quantalgo-trading-systems/issues) • [📖 Documentation](docs/)

</div>
