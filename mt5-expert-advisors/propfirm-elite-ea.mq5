//+------------------------------------------------------------------+
//|              PROPFIRM ELITE EA - QuantAlgo Trading Systems        |
//+------------------------------------------------------------------+
//| Expert Advisor: Complete MT5 Solution for Prop Firms             |
//| Platform: MetaTrader 5 (MQL5)                                     |
//| Author: Alexandre Albert Ndour                                   |
//| Version: 1.0.0                                                    |
//| License: MIT                                                      |
//+------------------------------------------------------------------+
//| DESCRIPTION:                                                     |
//| Elite MT5 Expert Advisor with BOS + FVG + EMA + RSI + Volume,     |
//| trailing stop, breakeven automation, and comprehensive prop firm   |
//| protection. Optimized for $1000 prop firm challenges.            |
//+------------------------------------------------------------------+
//| FEATURES:                                                        |
//| - Multi-confirmation signal scoring                               |
//| - Breakeven automation                                           |
//| - Trailing stop with ATR                                         |
//| - Daily loss/target limits                                       |
//| - Session filtering                                              |
//| - Spread protection                                               |
//| - HUD display                                                    |
//+------------------------------------------------------------------+
//| RISK WARNING:                                                    |
//| This EA is for educational purposes. Past performance does not    |
//| guarantee future results. Always test on demo accounts first.      |
//+------------------------------------------------------------------+
#property copyright "QuantAlgo Trading Systems"
#property version   "1.0.0"
#property strict

#include <Trade/Trade.mqh>

//=== STRATÉGIE ===
input group "=== Structure du Marché (SMC) ==="
input int      InpBOSPeriod    = 12;       // Période BOS (plus court = plus réactif)
input int      InpEMAFast      = 21;       // EMA Rapide (tendance court terme)
input int      InpEMASlow      = 50;       // EMA Lente (tendance moyen terme)
input int      InpEMATrend     = 200;      // EMA Macro (direction générale)

input group "=== Confirmations ==="
input int      InpRSIPeriod    = 7;        // RSI Période (court = réactif)
input int      InpRSIOverbought = 75;      // RSI Surachat
input int      InpRSIOversold   = 25;      // RSI Survente
input double   InpVolumeMult   = 1.3;      // Multiplicateur Volume (confirmation momentum)

input group "=== Gestion du Risque ==="
input double   InpRiskPercent  = 0.75;     // Risque par trade (%) - Conservateur
input double   InpRR_Ratio     = 2.0;      // Ratio Risk:Reward
input double   InpATRMult      = 1.2;      // Multiplicateur ATR pour SL
input int      InpATRPeriod    = 10;       // Période ATR

input group "=== Trailing & Breakeven ==="
input bool     InpUseBreakeven = true;     // Activer Breakeven
input double   InpBE_Trigger   = 1.0;      // Breakeven après X * SL en profit
input bool     InpUseTrailing  = true;     // Activer Trailing Stop
input double   InpTrailATRMult = 0.8;      // Trailing = X * ATR

input group "=== Protection Prop Firm ==="
input double   InpDailyLossMax = 40.0;     // Perte Max Jour $ (sécurité: 40 sur 50)
input double   InpTotalLossMax = 120.0;    // Perte Max Totale $ (sécurité: 120 sur 150)
input double   InpDailyTarget  = 20.0;     // Objectif Jour $ (sécuriser les gains)
input int      InpMaxTrades    = 5;        // Max trades par jour
input double   InpMaxSpread    = 25.0;     // Spread max autorisé (en points)

input group "=== Sessions (Heure Serveur) ==="
input int      InpSession1Start = 8;       // Session Londres début
input int      InpSession1End   = 11;      // Session Londres fin
input int      InpSession2Start = 14;      // Session New York début  
input int      InpSession2End   = 17;      // Session New York fin

//=== VARIABLES GLOBALES ===
CTrade   trade;
int      hEMAFast, hEMASlow, hEMATrend, hATR, hRSI, hVol;
datetime g_lastDay        = 0;
double   g_dayStartBalance = 0;
double   g_initialBalance  = 0;
int      g_dailyTradeCount = 0;

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   hEMAFast  = iMA(_Symbol, PERIOD_CURRENT, InpEMAFast, 0, MODE_EMA, PRICE_CLOSE);
   hEMASlow  = iMA(_Symbol, PERIOD_CURRENT, InpEMASlow, 0, MODE_EMA, PRICE_CLOSE);
   hEMATrend = iMA(_Symbol, PERIOD_CURRENT, InpEMATrend, 0, MODE_EMA, PRICE_CLOSE);
   hATR      = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
   hRSI      = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
   hVol      = iVolumes(_Symbol, PERIOD_CURRENT, VOLUME_TICK);

   if(hEMAFast == INVALID_HANDLE || hEMASlow == INVALID_HANDLE ||
      hEMATrend == INVALID_HANDLE || hATR == INVALID_HANDLE ||
      hRSI == INVALID_HANDLE || hVol == INVALID_HANDLE)
   {
      Print("ERREUR: Impossible de charger les indicateurs");
      return(INIT_FAILED);
   }

   trade.SetDeviationInPoints(10);
   g_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_initialBalance  = AccountInfoDouble(ACCOUNT_BALANCE);

   Print("V8 Elite initialisé | Balance: ", g_initialBalance, "$");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Libération des ressources                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(hEMAFast);
   IndicatorRelease(hEMASlow);
   IndicatorRelease(hEMATrend);
   IndicatorRelease(hATR);
   IndicatorRelease(hRSI);
   IndicatorRelease(hVol);
}

//+------------------------------------------------------------------+
//| Tick Principal                                                   |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Reset quotidien
   MqlDateTime dt;
   TimeCurrent(dt);
   if(dt.day != g_lastDay)
   {
      g_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      g_dailyTradeCount = 0;
      g_lastDay = dt.day;
   }

   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double dailyPL = equity - g_dayStartBalance;
   double totalPL = equity - g_initialBalance;

   //--- PROTECTION 1: Perte journalière
   if(dailyPL <= -InpDailyLossMax)
   {
      CloseAllPositions();
      ShowHUD(dailyPL, totalPL, "BLOQUÉ: Limite perte jour");
      return;
   }

   //--- PROTECTION 2: Perte totale (Drawdown max)
   if(totalPL <= -InpTotalLossMax)
   {
      CloseAllPositions();
      ShowHUD(dailyPL, totalPL, "BLOQUÉ: Drawdown total max");
      return;
   }

   //--- PROTECTION 3: Objectif journalier atteint
   if(dailyPL >= InpDailyTarget)
   {
      ShowHUD(dailyPL, totalPL, "OBJECTIF JOUR ATTEINT - Repos");
      return;
   }

   //--- Gestion des positions ouvertes
   if(PositionSelect(_Symbol))
   {
      ManageOpenPosition();
      ShowHUD(dailyPL, totalPL, "Position ouverte - Gestion active");
      return;
   }

   //--- PROTECTION 4: Max trades atteint
   if(g_dailyTradeCount >= InpMaxTrades)
   {
      ShowHUD(dailyPL, totalPL, "Max trades jour atteint");
      return;
   }

   //--- FILTRE: Session de trading
   bool inSession = (dt.hour >= InpSession1Start && dt.hour < InpSession1End) ||
                    (dt.hour >= InpSession2Start && dt.hour < InpSession2End);
   if(!inSession)
   {
      ShowHUD(dailyPL, totalPL, "Hors session");
      return;
   }

   //--- FILTRE: Spread
   double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread > InpMaxSpread)
   {
      ShowHUD(dailyPL, totalPL, "Spread trop élevé: " + DoubleToString(spread, 0));
      return;
   }

   //--- Nouvelle bougie uniquement
   static datetime lastBar = 0;
   datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBar == lastBar) return;
   lastBar = currentBar;

   //--- ANALYSE DU SIGNAL
   int signal = AnalyzeSignal();

   if(signal == 0)
   {
      ShowHUD(dailyPL, totalPL, "Analyse... Pas de signal");
      return;
   }

   //--- EXÉCUTION
   ExecuteTrade(signal);
   ShowHUD(dailyPL, totalPL, signal > 0 ? "SIGNAL BUY EXÉCUTÉ" : "SIGNAL SELL EXÉCUTÉ");
}

//+------------------------------------------------------------------+
//| Analyse Multi-Confirmation                                       |
//+------------------------------------------------------------------+
int AnalyzeSignal()
{
   //--- Buffers
   double emaF[3], emaS[3], emaT[2], atr[1], rsi[2], vol[3];
   if(CopyBuffer(hEMAFast, 0, 0, 3, emaF) < 3) return 0;
   if(CopyBuffer(hEMASlow, 0, 0, 3, emaS) < 3) return 0;
   if(CopyBuffer(hEMATrend, 0, 0, 2, emaT) < 2) return 0;
   if(CopyBuffer(hATR, 0, 0, 1, atr) < 1) return 0;
   if(CopyBuffer(hRSI, 0, 0, 2, rsi) < 2) return 0;
   if(CopyBuffer(hVol, 0, 0, 3, vol) < 3) return 0;

   //--- BOS (Break of Structure)
   int highIdx = iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, InpBOSPeriod, 1);
   int lowIdx  = iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, InpBOSPeriod, 1);
   double bosHigh = iHigh(_Symbol, PERIOD_CURRENT, highIdx);
   double bosLow  = iLow(_Symbol, PERIOD_CURRENT, lowIdx);
   double close1  = iClose(_Symbol, PERIOD_CURRENT, 1);

   bool bullBOS = close1 > bosHigh;
   bool bearBOS = close1 < bosLow;

   //--- FVG (Fair Value Gap) simplifié
   double high1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double low1  = iLow(_Symbol, PERIOD_CURRENT, 1);
   double high3 = iHigh(_Symbol, PERIOD_CURRENT, 3);
   double low3  = iLow(_Symbol, PERIOD_CURRENT, 3);
   bool bullFVG = low1 > high3;  // Gap haussier
   bool bearFVG = high1 < low3;  // Gap baissier

   //--- Tendance Triple EMA
   bool bullTrend = emaF[0] > emaS[0] && emaS[0] > emaT[0];
   bool bearTrend = emaF[0] < emaS[0] && emaS[0] < emaT[0];

   //--- EMA Crossover récent (momentum)
   bool bullCross = emaF[1] <= emaS[1] && emaF[0] > emaS[0];
   bool bearCross = emaF[1] >= emaS[1] && emaF[0] < emaS[0];

   //--- RSI Confirmation
   bool rsiBuy  = rsi[0] > InpRSIOversold && rsi[0] < 65;
   bool rsiSell = rsi[0] < InpRSIOverbought && rsi[0] > 35;

   //--- Volume Spike
   double avgVol = (vol[0] + vol[1] + vol[2]) / 3.0;
   bool volConfirm = vol[0] > avgVol * InpVolumeMult;

   //=== SCORING SYSTEM (Plus de points = signal plus fort) ===
   int bullScore = 0;
   int bearScore = 0;

   // BOS = 3 points (signal principal)
   if(bullBOS) bullScore += 3;
   if(bearBOS) bearScore += 3;

   // Tendance = 2 points
   if(bullTrend) bullScore += 2;
   if(bearTrend) bearScore += 2;

   // FVG = 2 points (confluence SMC)
   if(bullFVG) bullScore += 2;
   if(bearFVG) bearScore += 2;

   // EMA Cross = 1 point (bonus momentum)
   if(bullCross) bullScore += 1;
   if(bearCross) bearScore += 1;

   // RSI = 1 point
   if(rsiBuy)  bullScore += 1;
   if(rsiSell) bearScore += 1;

   // Volume = 1 point
   if(volConfirm) { bullScore += 1; bearScore += 1; }

   //=== Seuil minimum: 5 points pour entrer ===
   if(bullScore >= 5) return  1;  // BUY
   if(bearScore >= 5) return -1;  // SELL

   return 0;
}

//+------------------------------------------------------------------+
//| Exécution du Trade                                               |
//+------------------------------------------------------------------+
void ExecuteTrade(int direction)
{
   double atr[1];
   CopyBuffer(hATR, 0, 0, 1, atr);
   if(atr[0] <= 0) return;

   double slDist = atr[0] * InpATRMult;
   double tpDist = slDist * InpRR_Ratio;
   double lots   = CalcLots(slDist);
   if(lots <= 0) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   if(direction > 0)
   {
      double sl = NormalizeDouble(ask - slDist, digits);
      double tp = NormalizeDouble(ask + tpDist, digits);
      if(trade.Buy(lots, _Symbol, ask, sl, tp, "V8 ELITE BUY"))
         g_dailyTradeCount++;
   }
   else
   {
      double sl = NormalizeDouble(bid + slDist, digits);
      double tp = NormalizeDouble(bid - tpDist, digits);
      if(trade.Sell(lots, _Symbol, bid, sl, tp, "V8 ELITE SELL"))
         g_dailyTradeCount++;
   }
}

//+------------------------------------------------------------------+
//| Gestion Position: Breakeven + Trailing Stop                      |
//+------------------------------------------------------------------+
void ManageOpenPosition()
{
   double atr[1];
   CopyBuffer(hATR, 0, 0, 1, atr);

   ulong ticket  = PositionGetInteger(POSITION_TICKET);
   double openPx = PositionGetDouble(POSITION_PRICE_OPEN);
   double curSL  = PositionGetDouble(POSITION_SL);
   double curTP  = PositionGetDouble(POSITION_TP);
   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   double slDist = MathAbs(openPx - curSL);

   if(type == POSITION_TYPE_BUY)
   {
      double profit = bid - openPx;

      // Breakeven: si profit >= 1x le SL, on met SL au prix d'entrée + 1 pip
      if(InpUseBreakeven && profit >= slDist * InpBE_Trigger && curSL < openPx)
      {
         double newSL = NormalizeDouble(openPx + SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 5, digits);
         trade.PositionModify(ticket, newSL, curTP);
         return;
      }

      // Trailing: suit le prix à distance de X * ATR
      if(InpUseTrailing && profit > slDist * InpBE_Trigger)
      {
         double trailSL = NormalizeDouble(bid - atr[0] * InpTrailATRMult, digits);
         if(trailSL > curSL)
            trade.PositionModify(ticket, trailSL, curTP);
      }
   }
   else if(type == POSITION_TYPE_SELL)
   {
      double profit = openPx - ask;

      if(InpUseBreakeven && profit >= slDist * InpBE_Trigger && (curSL > openPx || curSL == 0))
      {
         double newSL = NormalizeDouble(openPx - SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 5, digits);
         trade.PositionModify(ticket, newSL, curTP);
         return;
      }

      if(InpUseTrailing && profit > slDist * InpBE_Trigger)
      {
         double trailSL = NormalizeDouble(ask + atr[0] * InpTrailATRMult, digits);
         if(trailSL < curSL || curSL == 0)
            trade.PositionModify(ticket, trailSL, curTP);
      }
   }
}

//+------------------------------------------------------------------+
//| Calcul Lot Size                                                  |
//+------------------------------------------------------------------+
double CalcLots(double slDist)
{
   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmt   = balance * (InpRiskPercent / 100.0);
   double tickVal   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(slDist <= 0 || tickVal <= 0 || tickSize <= 0) return 0.01;

   double lots = riskAmt / ((slDist / tickSize) * tickVal);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lots = MathFloor(lots / step) * step;

   lots = MathMax(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
   lots = MathMin(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));

   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Fermeture d'urgence                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
            trade.PositionClose(ticket);
   }
}

//+------------------------------------------------------------------+
//| Affichage HUD sur le graphique                                   |
//+------------------------------------------------------------------+
void ShowHUD(double dailyPL, double totalPL, string status)
{
   string txt = "";
   txt += "═══════ V8 ELITE SMC ═══════\n";
   txt += "Status: " + status + "\n";
   txt += "PL Jour:  " + DoubleToString(dailyPL, 2) + "$ / -" + DoubleToString(InpDailyLossMax, 0) + "$\n";
   txt += "PL Total: " + DoubleToString(totalPL, 2) + "$ / -" + DoubleToString(InpTotalLossMax, 0) + "$\n";
   txt += "Trades:   " + IntegerToString(g_dailyTradeCount) + " / " + IntegerToString(InpMaxTrades) + "\n";
   txt += "Spread:   " + DoubleToString(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), 0) + " pts\n";
   txt += "════════════════════════════";
   Comment(txt);
}
//+------------------------------------------------------------------+
