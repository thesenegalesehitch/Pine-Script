//+------------------------------------------------------------------+
//|              PROPFIRM REACTIVE EA - QuantAlgo Trading Systems     |
//+------------------------------------------------------------------+
//| Expert Advisor: Reactive BOS Strategy with PropFirm Safety      |
//| Platform: MetaTrader 5 (MQL5)                                     |
//| Author: Alexandre Albert Ndour                                   |
//| Version: 1.0.0                                                    |
//| License: MIT                                                      |
//+------------------------------------------------------------------+
//| DESCRIPTION:                                                     |
//| Reactive BOS strategy combining EMA trend with prop firm safety    |
//| features. Features daily loss/target limits and session filtering.|
//+------------------------------------------------------------------+
//| FEATURES:                                                        |
//| - BOS (Break of Structure) detection                             |
//| - EMA trend confirmation                                          |
//| - Daily loss/target limits                                       |
//| - Session filtering                                              |
//| - Risk-based position sizing                                     |
//+------------------------------------------------------------------+
//| RISK WARNING:                                                    |
//| This EA is for educational purposes. Past performance does not    |
//| guarantee future results. Always test on demo accounts first.      |
//+------------------------------------------------------------------+
#property copyright "QuantAlgo Trading Systems"
#property version   "1.0.0"
#property strict

#include <Trade/Trade.mqh>

//--- INPUTS ---
input group "=== Stratégie SMC ==="
input int      InpBOSPeriod = 15;      // Période pour détecter le BOS (Break of Structure)
input int      InpEMATrend  = 200;     // Moyenne mobile pour la tendance de fond
input int      InpATRPeriod = 14;      // Période ATR pour le Stop Loss
input double   InpATRMult   = 1.5;     // Multiplicateur ATR pour le SL

input group "=== Gestion du Risque ==="
input double   InpRiskPerTrade = 0.8;  // % de risque par trade (Conseillé: 0.8% pour 5 trades/jour) - Sécurisé
input double   InpRRRatio      = 1.5;  // Ratio Risk/Reward (1:1.5)
input double   InpDailyLossLimit = 45.0; // Limite de perte journalière en $ (Sécurité pour 50$)
input double   InpDailyTarget    = 30.0; // Objectif de profit journalier en $

input group "=== Horaires (Heure Serveur) ==="
input int      InpStartHour = 9;       // Début (Londres)
input int      InpEndHour   = 18;      // Fin (New York)

//--- GLOBALS ---
CTrade   trade;
int      handleEMA;
int      handleATR;
datetime lastTradeDay = 0;
double   dailyStartingBalance = 0;

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   handleEMA = iMA(_Symbol, PERIOD_CURRENT, InpEMATrend, 0, MODE_EMA, PRICE_CLOSE);
   handleATR = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
   
   if(handleEMA == INVALID_HANDLE || handleATR == INVALID_HANDLE)
   {
      Print("Erreur Initialisation Indicateurs");
      return(INIT_FAILED);
   }
   
   dailyStartingBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnTick - Cœur du Robot                                           |
//+------------------------------------------------------------------+
void OnTick()
{
   // 1. Reset quotidien
   MqlDateTime dt;
   TimeCurrent(dt);
   if(dt.day != lastTradeDay)
   {
      dailyStartingBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      lastTradeDay = dt.day;
   }

   // 2. Vérification des limites Prop Firm
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dailyPL = currentEquity - dailyStartingBalance;

   if(dailyPL <= -InpDailyLossLimit)
   {
      Comment("STOP: Limite de perte journalière atteinte (-", dailyPL, "$)");
      CloseAllPositions();
      return;
   }
   
   if(dailyPL >= InpDailyTarget)
   {
      Comment("SUCCESS: Objectif journalier atteint (+", dailyPL, "$)");
      // On peut choisir de continuer ou de s'arrêter. Ici on arrête pour sécuriser.
      return;
   }

   // 3. Filtre Horaire
   if(dt.hour < InpStartHour || dt.hour >= InpEndHour)
   {
      Comment("Hors session de trading (9h-18h)");
      return;
   }

   // 4. Gestion de la position existante
   if(PositionSelect(_Symbol)) 
   {
      Comment("Trade en cours...");
      return;
   }

   // 5. Analyse des Signaux (Fusion Logic)
   double ema[1];
   double atr[1];
   CopyBuffer(handleEMA, 0, 0, 1, ema);
   CopyBuffer(handleATR, 0, 0, 1, atr);

   // Calcul des High/Low pour le BOS (comme dans le script Pine)
   int highestIdx = iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, InpBOSPeriod, 1);
   int lowestIdx  = iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, InpBOSPeriod, 1);
   double bosHigh = iHigh(_Symbol, PERIOD_CURRENT, highestIdx);
   double bosLow  = iLow(_Symbol, PERIOD_CURRENT, lowestIdx);

   double close0 = iClose(_Symbol, PERIOD_CURRENT, 0);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Conditions
   bool isBullishTrend = close0 > ema[0];
   bool isBearishTrend = close0 < ema[0];
   
   bool buySignal  = isBullishTrend && close0 > bosHigh; // BOS Haussier
   bool sellSignal = isBearishTrend && close0 < bosLow;  // BOS Baissier

   // 6. Exécution
   if(buySignal)
   {
      double slDist = atr[0] * InpATRMult;
      double sl = ask - slDist;
      double tp = ask + (slDist * InpRRRatio);
      double lots = CalculateLotSize(slDist);
      
      trade.Buy(lots, _Symbol, ask, sl, tp, "V7 BOS BUY");
   }
   else if(sellSignal)
   {
      double slDist = atr[0] * InpATRMult;
      double sl = bid + slDist;
      double tp = bid - (slDist * InpRRRatio);
      double lots = CalculateLotSize(slDist);
      
      trade.Sell(lots, _Symbol, bid, sl, tp, "V7 BOS SELL");
   }
   
   Comment("En attente de signal BOS...\nPL Jour: ", dailyPL, "$");
}

//+------------------------------------------------------------------+
//| Calcul du lot en fonction du risque                              |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistance)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * (InpRiskPerTrade / 100.0);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   
   if(slDistance <= 0 || tickValue <= 0) return 0.01;

   double lotSize = riskAmount / (slDistance * tickValue);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lotSize = MathFloor(lotSize / step) * step;
   
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   
   if(lotSize < minLot) lotSize = minLot;
   if(lotSize > maxLot) lotSize = maxLot;
   
   return NormalizeDouble(lotSize, 2);
}

//+------------------------------------------------------------------+
//| Fermeture de secours                                             |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
            trade.PositionClose(ticket);
      }
   }
}
//+------------------------------------------------------------------+
