# Architecture Overview

## System Architecture

QuantAlgo Trading Systems is designed as a modular, scalable suite of algorithmic trading strategies with institutional-grade risk management.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     QuantAlgo Trading Systems                │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  Pine Script     │         │   MT5 Expert     │          │
│  │  Strategies      │         │   Advisors       │          │
│  │  (TradingView)   │         │   (MetaTrader)   │          │
│  └────────┬─────────┘         └────────┬─────────┘          │
│           │                            │                     │
│           └────────────┬───────────────┘                     │
│                        │                                     │
│           ┌────────────▼──────────────┐                     │
│           │   Core Components        │                     │
│           ├───────────────────────────┤                     │
│           │ • Risk Management        │                     │
│           │ • SMC Engine              │                     │
│           │ • Scoring System          │                     │
│           │ • Execution Engine        │                     │
│           └───────────────────────────┘                     │
│                        │                                     │
│           ┌────────────▼──────────────┐                     │
│           │   Data Sources           │                     │
│           ├───────────────────────────┤                     │
│           │ • Price Data             │                     │
│           │ • Volume Data            │                     │
│           │ • Multi-Timeframe Data   │                     │
│           └───────────────────────────┘                     │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Component Architecture

### 1. Risk Management Engine

**Purpose**: Protect account capital and enforce prop firm rules

**Components**:
- Daily Drawdown Monitor
- Global Drawdown Tracker
- Consecutive Loss Counter
- Dynamic Risk Scaler
- Emergency Close System

**Flow**:
```
Trade Signal → Risk Check → Position Sizing → Execution → Monitoring
                ↓
          Daily Limits
          Global Limits
          Consecutive Losses
          Market Conditions
```

### 2. SMC (Smart Money Concepts) Engine

**Purpose**: Identify institutional footprints and high-probability setups

**Components**:
- Structure Detection (BOS, CHOCH)
- Liquidity Analysis (Sweeps, Inducement)
- Imbalance Detection (FVG)
- Order Block Identification
- Breaker Block Detection

**Flow**:
```
Price Data → Pivot Detection → Structure Analysis → SMC Pattern Recognition
                                                      ↓
                                              Signal Generation
```

### 3. Scoring System

**Purpose**: Quantify signal quality with probabilistic scoring

**Components**:
- Trend Score (Multi-timeframe bias)
- Structure Score (BOS, CHOCH)
- Momentum Score (Volume, ADX)
- Zone Score (Premium/Discount)
- Adaptive Threshold Calculator

**Scoring Formula**:
```
Total Score = (Trend Weight × Trend Score) + 
              (Structure Weight × Structure Score) +
              (Momentum Weight × Momentum Score) +
              (Zone Weight × Zone Score)

Adaptive Threshold = Base Threshold × Market Regime Multiplier
```

### 4. Execution Engine

**Purpose**: Execute trades with optimal entry/exit management

**Components**:
- Entry Signal Validator
- Position Size Calculator
- Stop Loss Manager
- Take Profit Manager
- Breakeven Automator
- Trailing Stop Manager

**Execution Flow**:
```
Signal → Risk Check → SL/TP Calculation → Position Sizing → Entry
                                                    ↓
                                            Position Management
                                                    ↓
                                            Breakeven/Trailing
                                                    ↓
                                            Exit
```

## Data Flow

### Pine Script Strategy Flow

```
1. Market Data Input
   ↓
2. Indicator Calculation (EMA, ATR, ADX, RSI, Volume)
   ↓
3. Multi-Timeframe Analysis (H4, Daily)
   ↓
4. SMC Pattern Detection (BOS, CHOCH, FVG, OB)
   ↓
5. Scoring System (0-100)
   ↓
6. Adaptive Threshold Application
   ↓
7. Risk Management Check
   ↓
8. Position Sizing
   ↓
9. Entry Execution
   ↓
10. Position Management (Breakeven, Trailing)
   ↓
11. Exit (TP or SL)
```

### MT5 Expert Advisor Flow

```
1. OnTick Trigger
   ↓
2. Daily Reset Check
   ↓
3. Prop Firm Limits Check
   ↓
4. Session Filter Check
   ↓
5. Spread Filter Check
   ↓
6. New Bar Check
   ↓
7. Signal Analysis
   ↓
8. Risk Calculation
   ↓
9. Position Execution
   ↓
10. Position Management (Breakeven, Trailing)
   ↓
11. HUD Display Update
```

## Market Regime Detection

The system classifies market conditions into:

| Regime | Characteristics | Behavior |
|--------|----------------|----------|
| **Strong Trend** | ADX > 30, aligned EMAs | Lower threshold, trend-following |
| **Trending** | ADX 20-30 | Standard threshold |
| **Ranging** | ADX < 20, low vol | Higher threshold, range trading |
| **Compression** | Low vol + ranging | No trading (wait for expansion) |
| **High Volatility** | ATR ratio > 1.5 | Reduced risk, wider stops |
| **News Spike** | Sudden ATR explosion | Very high threshold or pause |
| **Danger** | High vol + ranging | No trading (choppy) |

## Risk Management Architecture

### Multi-Layer Protection

```
Layer 1: Pre-Trade Filters
├── Session Filter (Killzones)
├── Spread Filter
├── Market Regime Filter
└── HTF Bias Filter

Layer 2: Position-Level Protection
├── Risk Percentage Limit
├── Stop Loss Calculation
├── Position Sizing
└── Max Trades Per Day

Layer 3: Account-Level Protection
├── Daily Loss Limit
├── Global Drawdown Limit
├── Daily Target (stop when hit)
└── Consecutive Loss Pause

Layer 4: Emergency Protection
├── Emergency Close
├── Cooldown Period
└── Recovery Mode
```

## Technology Stack

### TradingView (Pine Script v6)
- **Language**: Pine Script v6
- **Execution**: Server-side backtesting
- **Real-time**: WebSockets
- **Alerts**: Webhook, email, SMS

### MetaTrader 5 (MQL5)
- **Language**: MQL5
- **Execution**: Client-side (terminal)
- **Real-time**: Direct API
- **Backtesting**: Strategy Tester

## Performance Considerations

### Optimization Strategies
- **Calculation on Every Tick**: Disabled (bar close only)
- **Max Objects**: Limited (200 boxes, 200 labels, 200 lines)
- **Variable Scope**: Optimized with `var` for persistence
- **Security Calls**: Minimized with proper lookahead settings

### Scalability
- **Multi-Symbol**: Ready for portfolio strategies
- **Multi-Timeframe**: Built-in MTF analysis
- **Cloud-Ready**: Architecture supports cloud deployment

## Security Architecture

### Data Protection
- No hardcoded credentials
- Environment variables for sensitive data
- Input validation on all parameters

### Trade Protection
- Hard stops on all positions
- Emergency close functionality
- Account-level monitoring
- Real-time equity tracking

## Future Architecture Plans

### Phase 2 (Q2 2026)
- Python API integration
- Multi-symbol portfolio optimization
- Machine learning model integration

### Phase 3 (Q3 2026)
- Cloud-based execution engine
- Real-time monitoring dashboard
- Mobile app integration

### Phase 4 (Q4 2026)
- Institutional-grade FIX API
- Advanced risk analytics
- Automated backtesting pipeline

---

This architecture is designed for scalability, maintainability, and institutional-grade reliability.
