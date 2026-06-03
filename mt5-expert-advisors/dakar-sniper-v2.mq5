//+------------------------------------------------------------------+
//|                    DAKAR SNIPER V2 - QuantAlgo Trading Systems    |
//+------------------------------------------------------------------+
//| Expert Advisor: Prop Firm ICT Sniper with Africa Latency Opt      |
//| Platform: MetaTrader 5 (MQL5)                                     |
//| Author: Alexandre Albert Ndour                                   |
//| Version: 2.0.0                                                    |
//| License: MIT                                                      |
//+------------------------------------------------------------------+
//| DESCRIPTION:                                                     |
//| Prop firm survival mode EA optimized for FTMO/VPropTrader/XM     |
//| with latency considerations for African connections. Features     |
//| daily drawdown protection, phase-based risk scaling, and London  |
//| Killzone sniper entries.                                          |
//+------------------------------------------------------------------+
//| FEATURES:                                                        |
//| - Phase 1/2 auto-switch with different risk parameters            |
//| - Daily drawdown protection (90% safety margin for latency)      |
//| - London Killzone (Judas Sweep) strategy                         |
//| - Anti-swap protection (close before Asian session)              |
//| - Spread filter for XM broker                                     |
//| - Dynamic position sizing based on risk percentage                |
//+------------------------------------------------------------------+
//| RISK WARNING:                                                    |
//| This EA is for educational purposes. Past performance does not    |
//| guarantee future results. Always test on demo accounts first.      |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
CTrade trade;

//--- INPUTS RÈGLES PROP FIRM
input double   InitialCapital      = 1000.0;    // Capital Initial ($)
input double   Phase1_Target       = 100.0;     // Target Phase 1 ($)
input double   Phase1_DailyDD      = 50.0;      // Max Daily DD Phase 1 ($)
input double   Phase1_MaxDD        = 100.0;     // Max Global DD Phase 1 ($)

input double   Phase2_Target       = 200.0;     // Target Phase 2 ($)
input double   Phase2_DailyDD      = 20.0;      // Max Daily DD Phase 2 ($)
input double   Phase2_MaxDD        = 50.0;      // Max Global DD Phase 2 ($)

//--- INPUTS MOTEUR & BROKER
input double   Phase1_RiskPct      = 2.0;       // Risque Phase 1 (%) - Optimisé pour FTMO
input double   Phase2_RiskPct      = 0.75;      // Risque Phase 2 (%)
input double   RiskRewardRatio     = 3.0;       // Ratio RR (1:3)
input int      BrokerServerOffset  = 2;         // Décalage Horaire Broker (0=GMT, 1=CET, 2=XM Standard)
input int      MaxSpreadPoints     = 25;        // Filtre Spread (Points) - Sécurité XM
input bool     CloseBeforeAsia     = true;      // Fermer avant la nuit (Anti-Swap XM)

//--- VARIABLES GLOBALES
double daily_start_equity;
datetime last_bar_time;
int current_phase = 1;

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(221777); // Code Dakar
   trade.SetDeviationInPoints(15);     // Tolérance slippage large pour connexion Sénégal
   trade.SetTypeFilling(ORDER_FILLING_IOC); // FTMO et XM préfèrent IOC
   
   daily_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   last_bar_time = 0;
   
   Print("=== DAKAR SNIPER V2 ACTIVÉ ===");
   Print("Broker Offset configuré : ", BrokerServerOffset);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Exécution à chaque tick                                          |
//+------------------------------------------------------------------+
void OnTick()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   // 1. Reset de l'Equity Journalière à minuit (Heure du Broker)
   if(dt.hour == 0 && dt.min == 0) 
     {
      daily_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
      Print("Nouvelle journée Broker - Reset Equity à ", daily_start_equity);
     }

   // 2. Vérification de la Phase
   CheckPhase();

   // 3. Sécurité absolue : Vérif Rules
   if(!CheckPropRules()) return;

   // 4. ANTI-SWAP (Crucial pour XM) : On ferme tout à 21h45 heure serveur
   if(CloseBeforeAsia && dt.hour == 21 && dt.min >= 45)
     {
      CloseAllPositions();
      return;
     }

   // 5. Filtre Spread (XM élargit souvent le spread, FTMO moins)
   double spread = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(spread / _Point > MaxSpreadPoints) return;

   // 6. Filtre Temporel : Uniquement London Open (08h-10h Heure Londres)
   // Si Broker est à GMT+2, 08h Londres = 10h Serveur
   int london_hour_open = 8 + BrokerServerOffset;
   int london_hour_close = 10 + BrokerServerOffset;
   
   if(dt.hour < london_hour_open || dt.hour >= london_hour_close) return;

   // 7. Un trade par bougie M5
   datetime current_time = iTime(_Symbol, PERIOD_M5, 0);
   if(current_time == last_bar_time) return;

   // 8. Exécution Stratégie
   ExecuteJudasSweep();
   last_bar_time = current_time;
  }

//+------------------------------------------------------------------+
//| Vérification de la Phase (Auto-Switch)                           |
//+------------------------------------------------------------------+
void CheckPhase()
  {
   double current_profit = AccountInfoDouble(ACCOUNT_EQUITY) - InitialCapital;
   
   if(current_phase == 1 && current_profit >= Phase1_Target)
     {
      current_phase = 2;
      Print("!!!! PHASE 1 VALIDÉE - PASSAGE PHASE 2 - MODE SURVIE !!!!");
     }
  }

//+------------------------------------------------------------------+
//| Sécurité Prop Firm (Arrêt à 90% du DD pour cause de latence)     |
//+------------------------------------------------------------------+
bool CheckPropRules()
  {
   double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double current_profit = current_equity - InitialCapital;
   double daily_loss = daily_start_equity - current_equity;
   double global_loss = InitialCapital - current_equity;

   double max_daily_dd = (current_phase == 1) ? Phase1_DailyDD : Phase2_DailyDD;
   double max_global_dd = (current_phase == 1) ? Phase1_MaxDD : Phase2_MaxDD;
   double target = (current_phase == 1) ? Phase1_Target : Phase2_Target;

   // Sécurité Daily DD (On coupe à 90% du DD pour parer le slippage d'Orange Sonatel)
   if(daily_loss >= max_daily_dd * 0.90)
     {
      Print("!!! ALERTE: LIMITE DAILY DD ATTEINTE. LIQUIDATION FORCEE !!!");
      CloseAllPositions();
      return false;
     }

   // Sécurité Max DD
   if(global_loss >= max_global_dd * 0.90)
     {
      Print("!!! ALERTE: LIMITE MAX DD ATTEINTE. LIQUIDATION FORCEE !!!");
      CloseAllPositions();
      return false;
     }

   // Si target validée, on freeze
   if(current_profit >= target)
     {
      Print("!!! TARGET ATTEINTE. COMPTE FIGÉ !!!");
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Stratégie : Judas Sweep (London Killzone)                        |
//+------------------------------------------------------------------+
void ExecuteJudasSweep()
  {
   if(PositionsTotal() > 0) return;

   // Calcul de l'heure exacte pour lire la session Asiatique
   int asian_end_hour = 7 + BrokerServerOffset;
   
   // Trouver le Highest et Lowest de l'Asie
   int start_idx = iBarShift(_Symbol, PERIOD_H1, StringToTime(IntegerToString(TimeYear(TimeCurrent())) + "." + IntegerToString(TimeMonth(TimeCurrent())) + "." + IntegerToString(TimeDay(TimeCurrent())) + " " + IntegerToString(0) + ":00"));
   int end_idx = iBarShift(_Symbol, PERIOD_H1, StringToTime(IntegerToString(TimeYear(TimeCurrent())) + "." + IntegerToString(TimeMonth(TimeCurrent())) + "." + IntegerToString(TimeDay(TimeCurrent())) + " " + IntegerToString(asian_end_hour) + ":00"));
   
   double asian_high = 0;
   double asian_low = 999999;
   
   for(int i = end_idx; i <= start_idx; i++)
     {
      double h = iHigh(_Symbol, PERIOD_H1, i);
      double l = iLow(_Symbol, PERIOD_H1, i);
      if(h > asian_high) asian_high = h;
      if(l < asian_low) asian_low = l;
     }

   // Analyser la bougie M5 en cours pour le Sweep
   double close_m5 = iClose(_Symbol, PERIOD_M5, 1);
   double open_m5  = iOpen(_Symbol, PERIOD_M5, 1);
   double high_m5  = iHigh(_Symbol, PERIOD_M5, 1);
   double low_m5   = iLow(_Symbol, PERIOD_M5, 1);
   double atr      = iATR(_Symbol, PERIOD_M5, 14, 1);

   // --- CONDITION VENTE (Sweep du Haut Asiatique + Rejet) ---
   if(high_m5 > asian_high && close_m5 < asian_high && close_m5 < open_m5 && (open_m5 - close_m5) > atr * 1.5)
     {
      double sl_dist = (high_m5 - close_m5) + (20 * _Point); // SL large au-dessus du wick
      double tp_dist = sl_dist * RiskRewardRatio;
      EnterTrade(ORDER_TYPE_SELL, close_m5, sl_dist, tp_dist);
     }
     
   // --- CONDITION ACHAT (Sweep du Bas Asiatique + Rejet) ---
   else if(low_m5 < asian_low && close_m5 > asian_low && close_m5 > open_m5 && (close_m5 - open_m5) > atr * 1.5)
     {
      double sl_dist = (close_m5 - low_m5) + (20 * _Point); // SL large en dessous du wick
      double tp_dist = sl_dist * RiskRewardRatio;
      EnterTrade(ORDER_TYPE_BUY, close_m5, sl_dist, tp_dist);
     }
  }

//+------------------------------------------------------------------+
//| Calcul Dynamique du Lot                                          |
//+------------------------------------------------------------------+
void EnterTrade(ENUM_ORDER_TYPE type, double entry_price, double sl_dist, double tp_dist)
  {
   double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double risk_pct = (current_phase == 1) ? Phase1_RiskPct : Phase2_RiskPct;
   double risk_usd = current_equity * (risk_pct / 100.0);
   
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double lot_step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min_lot    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   
   double sl_ticks = sl_dist / tick_size;
   double lot = risk_usd / (sl_ticks * tick_value);
   
   lot = MathFloor(lot / lot_step) * lot_step;
   if(lot < min_lot) lot = min_lot;

   double sl = 0, tp = 0;
   if(type == ORDER_TYPE_BUY)
     {
      sl = entry_price - sl_dist;
      tp = entry_price + tp_dist;
      trade.Buy(lot, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl, tp, "DAKAR P" + IntegerToString(current_phase));
     }
   else
     {
      sl = entry_price + sl_dist;
      tp = entry_price - tp_dist;
      trade.Sell(lot, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), sl, tp, "DAKAR P" + IntegerToString(current_phase));
     }
  }

//+------------------------------------------------------------------+
//| Fermeture d'urgence                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC) == 221777)
        {
         trade.PositionClose(ticket);
        }
     }
  }
//+------------------------------------------------------------------+
