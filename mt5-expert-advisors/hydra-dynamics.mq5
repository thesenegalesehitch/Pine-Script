//+------------------------------------------------------------------+
//|                                                HYDRA_DYNAMICS.mq5 |
//|                            Le Cauchemar Algorithmique des Brokers |
//+------------------------------------------------------------------+
#property copyright "HYDRA QUANT"
#property link      ""
#property version   "2.00"

#include <Trade\Trade.mqh>
CTrade trade;

//--- Inputs (Les Paramètres de l'Attaque)
input double   RiskPercent        = 25.0;       // Risque par trade (%) - Mode Kamikaze Capitaliste - Ajusté pour volatilité
input double   RR_Ratio           = 2.5;        // Ratio Risque/Récompense
input double   ImpulseMultiplier  = 3.0;        // Force de la Fractale (x ATR M1)
input int      ATR_Period_M1      = 14;         // ATR Calcul
input int      MaxSpreadPoints    = 20;         // Filtre Anti-Vol Broker (Points)
input bool     DynamicTrailing    = true;       // Verrouillage Agressif des Profits

//--- Variables Globales
int atrHandle;
double atrValue;

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Initialisation de l'ATR sur M1, peu importe le graphique
   atrHandle = iATR(_Symbol, PERIOD_M1, ATR_Period_M1);
   if(atrHandle == INVALID_HANDLE) return(INIT_FAILED);
   
   trade.SetExpertMagicNumber(777999);
   trade.SetDeviationInPoints(10); // Tolérance au slippage en attaque
   trade.SetTypeFilling(ORDER_FILLING_IOC); // Immédiat ou Annulé (Vitesse max)
   
   Print("HYDRA ACTIVÉ SUR ", _Symbol, " - EN ATTENTE DE FRACTALE...");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Fonction exécutée à chaque tick (La vitesse est tout)            |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. Gestion du Trailing Stop Dynamique (Sécurisation immédiate)
   if(DynamicTrailing && PositionsTotal() > 0)
     {
      TrailingStopHydra();
     }

   // 2. Pas de trades multiples simultanés sur le même actif
   if(PositionsTotal() > 0) return;

   // 3. Filtre Spread (Ne pas payer le broker)
   double spread = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(spread / _Point > MaxSpreadPoints) return;

   // 4. Récupération ATR M1
   double atrArray[];
   CopyBuffer(atrHandle, 0, 1, 1, atrArray);
   atrValue = atrArray[0];

   // 5. Analyse de la Fractale de Vitesse (Bougie M1 en cours)
   double open0  = iOpen(_Symbol, PERIOD_M1, 0);
   double close0 = iClose(_Symbol, PERIOD_M1, 0);
   double high0  = iHigh(_Symbol, PERIOD_M1, 0);
   double low0   = iLow(_Symbol, PERIOD_M1, 0);
   
   double currentDisplacement = MathAbs(close0 - open0);

   // 6. CONDITION D'ENTRÉE : L'impulsion institutionnelle détectée
   if(currentDisplacement > (atrValue * ImpulseMultiplier))
     {
      double sl_distance = atrValue * 0.5; // SL très serré : La moitié de l'ATR (Sous la fracture)
      double tp_distance = sl_distance * RR_Ratio;

      // Calcul du Lot Dynamique (L'Effet de Levier Composé)
      double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      double riskAmount = currentEquity * (RiskPercent / 100.0);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double lotSize = riskAmount / (sl_distance / _Point * tickValue);
      
      // Normalisation du Lot
      double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      lotSize = MathFloor(lotSize / stepLot) * stepLot;
      if(lotSize < minLot) lotSize = minLot;

      // EXÉCUTION HYDRA
      if(close0 > open0) // Fractale Haussière (Achat)
        {
         double sl = low0 - sl_distance;
         double tp = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + tp_distance;
         trade.Buy(lotSize, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl, tp, "HYDRA LONG");
        }
      else // Fractale Baissière (Vente)
        {
         double sl = high0 + sl_distance;
         double tp = SymbolInfoDouble(_Symbol, SYMBOL_BID) - tp_distance;
         trade.Sell(lotSize, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), sl, tp, "HYDRA SHORT");
        }
     }
  }

//+------------------------------------------------------------------+
//| Trailing Stop Agressif : Dès que 1R est atteint, SL à Break Even|
//+------------------------------------------------------------------+
void TrailingStopHydra()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == 777999)
        {
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentSL = PositionGetDouble(POSITION_SL);
         double currentTP = PositionGetDouble(POSITION_TP);
         double currentProfit = PositionGetDouble(POSITION_PRICE_CURRENT) - openPrice;
         
         double sl_distance = MathAbs(openPrice - currentSL);
         
         // Mode Achat
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
           {
            if(currentProfit > sl_distance * 1.0) // Si +1R atteint
              {
               double newSL = openPrice + (sl_distance * 0.1); // BE + un peu de marge
               if(newSL > currentSL)
                 {
                  trade.PositionModify(ticket, newSL, currentTP);
                 }
              }
           }
         // Mode Vente
         else
           {
            double currentProfitShort = openPrice - PositionGetDouble(POSITION_PRICE_CURRENT);
            if(currentProfitShort > sl_distance * 1.0) // Si +1R atteint
              {
               double newSL = openPrice - (sl_distance * 0.1); // BE + un peu de marge
               if(newSL < currentSL || currentSL == 0.0)
                 {
                  trade.PositionModify(ticket, newSL, currentTP);
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
