//+------------------------------------------------------------------+
//|              HEDGE FUND SMC EA - QuantAlgo Trading Systems        |
//+------------------------------------------------------------------+
//| Expert Advisor: Institutional Trend-Following with SMC            |
//| Platform: MetaTrader 5 (MQL5)                                     |
//| Author: Alexandre Albert Ndour                                   |
//| Version: 1.0.0                                                    |
//| License: MIT                                                      |
//+------------------------------------------------------------------+
//| DESCRIPTION:                                                     |
//| Basic institutional strategy combining EMA trend following with   |
//| simple SMC concepts and trailing stop management.                 |
//+------------------------------------------------------------------+
//| FEATURES:                                                        |
//| - EMA trend confirmation (50/200)                                 |
//| - ATR-based position sizing                                       |
//| - Trailing stop automation                                        |
//| - Risk-based lot calculation                                     |
//+------------------------------------------------------------------+
//| RISK WARNING:                                                    |
//| This EA is for educational purposes. Past performance does not    |
//| guarantee future results. Always test on demo accounts first.      |
//+------------------------------------------------------------------+
#property strict

#include <Trade/Trade.mqh>
CTrade trade;

input double RiskPercent = 1.0; // Risque par trade (%) - Institutionnel
input int EMAFast = 50;
input int EMASlow = 200;
input int ATRPeriod = 14;
input double SL_Mult = 2.0;
input double TP1_Mult = 1.5;
input double TP2_Mult = 4.0;
input bool UseTrailing = true;

int handleEMA50;
int handleEMA200;
int handleATR;

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   handleEMA50 = iMA(_Symbol, PERIOD_CURRENT, EMAFast, 0, MODE_EMA, PRICE_CLOSE);
   handleEMA200 = iMA(_Symbol, PERIOD_CURRENT, EMASlow, 0, MODE_EMA, PRICE_CLOSE);
   handleATR = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);

   if(handleEMA50 == INVALID_HANDLE || handleEMA200 == INVALID_HANDLE || handleATR == INVALID_HANDLE)
   {
      Print("Erreur lors du chargement des indicateurs");
      return(INIT_FAILED);
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Fonction principale                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   if(PositionSelect(_Symbol))
   {
      ManageTrailingStop();
      return;
   }

   double ema50[2];
   double ema200[2];
   double atr[1];

   CopyBuffer(handleEMA50, 0, 0, 2, ema50);
   CopyBuffer(handleEMA200, 0, 0, 2, ema200);
   CopyBuffer(handleATR, 0, 0, 1, atr);

   double AskPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double BidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   bool bullishTrend = ema50[0] > ema200[0];
   bool bearishTrend = ema50[0] < ema200[0];

   double prevHigh = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double prevLow  = iLow(_Symbol, PERIOD_CURRENT, 1);

   double currentClose = iClose(_Symbol, PERIOD_CURRENT, 0);

   bool buySignal = bullishTrend && currentClose > prevHigh;
   bool sellSignal = bearishTrend && currentClose < prevLow;

   double stopDistance = atr[0] * SL_Mult;

   double lotSize = CalculateLotSize(stopDistance);

   if(buySignal)
   {
      double sl = AskPrice - stopDistance;
      double tp = AskPrice + (atr[0] * TP2_Mult);

      trade.Buy(lotSize, _Symbol, AskPrice, sl, tp, "V6 BUY");
   }

   if(sellSignal)
   {
      double sl = BidPrice + stopDistance;
      double tp = BidPrice - (atr[0] * TP2_Mult);

      trade.Sell(lotSize, _Symbol, BidPrice, sl, tp, "V6 SELL");
   }
}

//+------------------------------------------------------------------+
//| Calcul du lot automatique                                        |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopDistance)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * (RiskPercent / 100.0);

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   double lotSize = riskAmount / (stopDistance * tickValue);

   lotSize = MathFloor(lotSize / lotStep) * lotStep;

   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   if(lotSize < minLot) lotSize = minLot;
   if(lotSize > maxLot) lotSize = maxLot;

   return NormalizeDouble(lotSize, 2);
}

//+------------------------------------------------------------------+
//| Trailing Stop                                                    |
//+------------------------------------------------------------------+
void ManageTrailingStop()
{
   if(!UseTrailing) return;

   double atr[1];
   CopyBuffer(handleATR, 0, 0, 1, atr);

   ulong ticket = PositionGetInteger(POSITION_TICKET);
   double currentSL = PositionGetDouble(POSITION_SL);
   double tp = PositionGetDouble(POSITION_TP);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);

   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   if(type == POSITION_TYPE_BUY)
   {
      double newSL = SymbolInfoDouble(_Symbol, SYMBOL_BID) - atr[0];

      if(newSL > currentSL && newSL > openPrice)
      {
         trade.PositionModify(ticket, newSL, tp);
      }
   }

   if(type == POSITION_TYPE_SELL)
   {
      double newSL = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + atr[0];

      if(newSL < currentSL || currentSL == 0)
      {
         trade.PositionModify(ticket, newSL, tp);
      }
   }
}
//+------------------------------------------------------------------+
