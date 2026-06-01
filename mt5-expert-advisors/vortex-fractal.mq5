//+------------------------------------------------------------------+
//|                                              VORTEX_FRACTAL.mq5 |
//|                             Algorithme de Predation Ultra-Agressif|
//+------------------------------------------------------------------+
#property copyright "Vortex Quant"
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade trade;

//--- Inputs (Les Paramètres de la Machine à Sous)
input double   RiskPercent        = 15.0;      // Risque par trade (%) - Extrême ! - Ajusté pour scalping
input double   TakeProfitMultiplier = 3.0;     // Ratio TP/SL (1:3 minimum)
input int      DisplacementATR    = 3;         // Force de la bougie d'impulsion (x ATR)
input int      ATR_Period         = 14;        // Période ATR
input int      MaxSpreadPoints    = 15;        // Filtre Spread (Anti-Scalping Broker)
input bool     CompoundingMode    = true;      // Mode Fusion Nucléaire (Compound)

//--- Variables Globales
int atrHandle;
double atrValue;
datetime lastTradeTime;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   atrHandle = iATR(_Symbol, PERIOD_M1, ATR_Period);
   if(atrHandle == INVALID_HANDLE) return(INIT_FAILED);
   trade.SetExpertMagicNumber(666999);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Ne trade qu'une fois par bougie M1
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_M1, 0);
   if(currentBarTime == lastBarTime) return;
   
   // Pas de positions ouvertes ?
   if(PositionsTotal() > 0) return;

   // Vérification du Spread (Les brokers tuent les scalpers avec le spread)
   double spread = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(spread * _Point * 10 > MaxSpreadPoints * _Point) return; // Si spread trop large, on fuit

   // Récupération ATR
   double atrArray[];
   CopyBuffer(atrHandle, 0, 1, 1, atrArray);
   atrValue = atrArray[0];

   // Calcul du Déplacement (Bougie Précédente M1)
   double open1  = iOpen(_Symbol, PERIOD_M1, 1);
   double close1 = iClose(_Symbol, PERIOD_M1, 1);
   double high1  = iHigh(_Symbol, PERIOD_M1, 1);
   double low1   = iLow(_Symbol, PERIOD_M1, 1);
   
   double displacement = MathAbs(close1 - open1);

   // CONDITION D'ENTRÉE : Displacement Anormal (Fractale de Vitesse)
   if(displacement > (atrValue * DisplacementATR))
     {
      double sl_distance = (high1 - low1) * 0.5; // SL très serré : La moitié du range de l'impulsion
      if(sl_distance < atrValue * 0.2) sl_distance = atrValue * 0.2; // Sécurité minimale
      
      double tp_distance = sl_distance * TakeProfitMultiplier;

      // Calcul de la taille du lot (Le moteur de l'explosion)
      double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      double riskAmount = currentEquity * (RiskPercent / 100.0);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double lotSize = riskAmount / (sl_distance / _Point * tickValue);
      
      // Normalisation du Lot
      double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      lotSize = MathRound(lotSize / stepLot) * stepLot;
      if(lotSize < minLot) lotSize = minLot;
      if(lotSize > maxLot) lotSize = maxLot;

      // EXÉCUTION : Vente sur impulsion haussière (Mean Reversion) ou Achat sur impulsion baissière
      if(close1 > open1) // Impulsion Haussière (On vend le retour)
        {
         double sl = high1 + sl_distance;
         double tp = close1 - tp_distance;
         trade.Sell(lotSize, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), sl, tp, "VORTEX SHORT");
        }
      else // Impulsion Baissière (On achète le retour)
        {
         double sl = low1 - sl_distance;
         double tp = close1 + tp_distance;
         trade.Buy(lotSize, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl, tp, "VORTEX LONG");
        }
      
      lastBarTime = currentBarTime; // Verrouille la bougie
     }
  }
//+------------------------------------------------------------------+
