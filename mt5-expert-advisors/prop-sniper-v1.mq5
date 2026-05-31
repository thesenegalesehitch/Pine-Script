//+------------------------------------------------------------------+
//|                                              PROP_SNIPER_V1.mq5  |
//|              Robot de Validation Prop Firm Ultra-Sécurisé         |
//+------------------------------------------------------------------+
#property copyright "PROP QUANT"
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade trade;

//--- INPUTS PARAMÈTRES PROP FIRM
input double   InitialCapital      = 1000.0;    // Capital Initial ($)
input double   Phase1_Target       = 100.0;     // Target Phase 1 ($)
input double   Phase1_DailyDD      = 50.0;      // Max Daily DD Phase 1 ($)
input double   Phase1_MaxDD        = 100.0;     // Max Global DD Phase 1 ($)

input double   Phase2_Target       = 200.0;     // Target Phase 2 ($)
input double   Phase2_DailyDD      = 20.0;      // Max Daily DD Phase 2 ($)
input double   Phase2_MaxDD        = 50.0;      // Max Global DD Phase 2 ($)

//--- INPUTS STRATÉGIE
input double   Phase1_RiskPct      = 2.5;       // Risque Phase 1 (%)
input double   Phase2_RiskPct      = 0.75;      // Risque Phase 2 (%) - Mode défensif
input double   RiskRewardRatio     = 3.0;       // Ratio RR (1:3)
input int      AsianSessionEndHour = 7;         // Heure fin session Asie (Serveur)
input int      LondonStartHour     = 8;         // Heure début London (Serveur)
input int      LondonEndHour       = 10;        // Heure fin trades (Serveur)

//--- VARIABLES GLOBALES
double daily_start_equity;
datetime last_bar_time;
int current_phase = 1;

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(888999);
   trade.SetDeviationInPoints(5);
   trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   daily_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   last_bar_time = 0;
   
   Print("=== PROP SNIPER V1 ACTIVÉ ===");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Exécution à chaque tick                                          |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. Réinitialiser l'Equity Journalière à minuit
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.hour == 0 && dt.min == 0) 
     {
      daily_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
      Print("Nouvelle journée - Reset Daily Equity à ", daily_start_equity);
     }

   // 2. Vérifier la Phase Actuelle
   CheckPhase();

   // 3. Vérifications de Sécurité (PROP FIRM RULES)
   if(!CheckPropRules()) return;

   // 4. Ne trader qu'une fois par bougie M5
   datetime current_time = iTime(_Symbol, PERIOD_M5, 0);
   if(current_time == last_bar_time) return;

   // 5. Filtre Temporel (Uniquement London Open)
   if(dt.hour < LondonStartHour || dt.hour >= LondonEndHour) return;

   // 6. Logique d'Entrée : Le Judas Sweep
   // On attends la clôture de la bougie de 08h00 ou 08h05
   if(dt.hour == LondonStartHour)
     {
      ExecuteJudasSweep();
      last_bar_time = current_time;
     }
  }

//+------------------------------------------------------------------+
//| Vérification et Mise à jour de la Phase                         |
//+------------------------------------------------------------------+
void CheckPhase()
  {
   double current_profit = AccountInfoDouble(ACCOUNT_EQUITY) - InitialCapital;
   
   if(current_phase == 1 && current_profit >= Phase1_Target)
     {
      current_phase = 2;
      Print("!!!! PHASE 1 VALIDÉE - PASSAGE EN PHASE 2 - MODE DEFENSIF !!!!");
     }
  }

//+------------------------------------------------------------------+
//| Sécurité Prop Firm : Bloquer si DD atteint                       |
//+------------------------------------------------------------------+
bool CheckPropRules()
  {
   double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double current_profit = current_equity - InitialCapital;
   double daily_loss = daily_start_equity - current_equity;
   double global_loss = InitialCapital - current_equity;

   // Vérification Daily DD
   double max_daily_dd = (current_phase == 1) ? Phase1_DailyDD : Phase2_DailyDD;
   if(daily_loss >= max_daily_dd * 0.95) // Marge de sécurité de 5% pour le slippage
     {
      Print("!!! ALERTE: LIMITE DAILY DD QUASI ATTEINTE. TRADING BLOQUÉ POUR LA JOURNÉE !!!");
      CloseAllPositions();
      return false;
     }

   // Vérification Max DD
   double max_global_dd = (current_phase == 1) ? Phase1_MaxDD : Phase2_MaxDD;
   if(global_loss >= max_global_dd * 0.95)
     {
      Print("!!! ALERTE: LIMITE MAX DD QUASI ATTEINTE. TRADING BLOQUÉ !!!");
      CloseAllPositions();
      return false;
     }

   // Si target atteinte, on ne trade plus
   double target = (current_phase == 1) ? Phase1_Target : Phase2_Target;
   if(current_profit >= target)
     {
      Print("!!! TARGET ATTEINTE. ON NE TOUCHE PLUS À RIEN !!!");
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Stratégie : Judas Sweep (Sweep Asiatique + Displacement)         |
//+------------------------------------------------------------------+
void ExecuteJudasSweep()
  {
   if(PositionsTotal() > 0) return; // Un seul trade à la fois

   // Récupérer les plus hauts et plus bas de la session Asiatique
   double asian_high = iHigh(_Symbol, PERIOD_H1, iHighest(_Symbol, PERIOD_H1, MODE_HIGH, LondonStartHour - 1, 1));
   double asian_low  = iLow(_Symbol, PERIOD_H1, iLowest(_Symbol, PERIOD_H1, MODE_LOW, LondonStartHour - 1, 1));
   
   double close_m5 = iClose(_Symbol, PERIOD_M5, 1);
   double open_m5  = iOpen(_Symbol, PERIOD_M5, 1);
   double high_m5  = iHigh(_Symbol, PERIOD_M5, 1);
   double low_m5   = iLow(_Symbol, PERIOD_M5, 1);

   // Définition du Déplacement (Displacement)
   double atr = iATR(_Symbol, PERIOD_M5, 14, 1);

   // --- CONDITION VENTE (Bearish Judas Swing) ---
   // Le prix a dépassé le plus haut Asiatique (Sweep BSL) mais a clôturé en dessérieur (Rejet)
   if(high_m5 > asian_high && close_m5 < asian_high && close_m5 < open_m5 && (open_m5 - close_m5) > atr * 1.5)
     {
      double sl_dist = high_m5 - close_m5 + (10 * _Point); // SL au dessus du wick
      double tp_dist = sl_dist * RiskRewardRatio;
      
      EnterTrade(ORDER_TYPE_SELL, close_m5, sl_dist, tp_dist);
     }
     
   // --- CONDITION ACHAT (Bullish Judas Swing) ---
   // Le prix a dépassé le plus bas Asiatique (Sweep SSL) mais a clôturé au dessus (Rejet)
   else if(low_m5 < asian_low && close_m5 > asian_low && close_m5 > open_m5 && (close_m5 - open_m5) > atr * 1.5)
     {
      double sl_dist = close_m5 - low_m5 + (10 * _Point); // SL en dessous du wick
      double tp_dist = sl_dist * RiskRewardRatio;
      
      EnterTrade(ORDER_TYPE_BUY, close_m5, sl_dist, tp_dist);
     }
  }

//+------------------------------------------------------------------+
//| Exécution du Trade avec Calcul de Lot Dynamique                  |
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
   
   // Calcul du Lot
   double sl_ticks = sl_dist / tick_size;
   double lot = risk_usd / (sl_ticks * tick_value);
   
   // Normalisation du Lot
   lot = MathFloor(lot / lot_step) * lot_step;
   if(lot < min_lot) lot = min_lot;

   double sl = 0, tp = 0;
   if(type == ORDER_TYPE_BUY)
     {
      sl = entry_price - sl_dist;
      tp = entry_price + tp_dist;
      trade.Buy(lot, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl, tp, "PROP SNIPER P" + IntegerToString(current_phase));
     }
   else
     {
      sl = entry_price + sl_dist;
      tp = entry_price - tp_dist;
      trade.Sell(lot, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), sl, tp, "PROP SNIPER P" + IntegerToString(current_phase));
     }
  }

//+------------------------------------------------------------------+
//| Fermer toutes les positions en cas de danger                     |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == 888999)
        {
         trade.PositionClose(ticket);
        }
     }
  }
//+------------------------------------------------------------------+
