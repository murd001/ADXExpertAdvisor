//+------------------------------------------------------------------+
//|                                                          105.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

double dPlusarray[];
double dMiusarray[];
double adxarray[];
int handleAdx;
input double lotSize = 0.001;
input double percTarget = 1.10;
input double adxFilter = 25.0;
input int redEmaPeriod = 200;
input int greenEmaPeriod = 34;
input double stopLoss = -1000.0;

int redEmaHandle, greenEmaHandle;
double redEma[], greenEma[];

MqlDateTime currentTime;
int time;
int newTime;

double initalDeposit;
double accountTarget;
double difference;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   handleAdx = iADX(_Symbol, PERIOD_CURRENT, 14);
   redEmaHandle = iMA(_Symbol, PERIOD_CURRENT, redEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   greenEmaHandle = iMA(_Symbol,PERIOD_CURRENT, greenEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   initalDeposit = 100.0;
   return(INIT_SUCCEEDED);
//---
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);

   TimeToStruct(TimeLocal(),currentTime);
   time = currentTime.min;
   newTime = currentTime.sec;

   ArraySetAsSeries(redEma, true);
   ArraySetAsSeries(greenEma, true);
   ArraySetAsSeries(dPlusarray, true);
   ArraySetAsSeries(dMiusarray, true);
   ArraySetAsSeries(adxarray, true);
   CopyBuffer(greenEmaHandle, 0, 0, 3, greenEma);
   CopyBuffer(redEmaHandle, 0, 0, 3, redEma);
   CopyBuffer(handleAdx, 0, 0, 3, adxarray);
   CopyBuffer(handleAdx, 1, 0, 3, dPlusarray);
   CopyBuffer(handleAdx, 2, 0, 3, dMiusarray);

   if(redEma[1] < greenEma[1] && greenEma[0] < Bid)
     {
      if(time == 15 || time == 30 || time == 45 || time == 00)
        {
         if(newTime == 0)
           {
            if(dPlusarray[2] < dMiusarray[2] && dPlusarray[1] > dMiusarray[1] && adxarray[1] > adxFilter)
              {
               if(PositionsTotal() < 1)
                 {
                  trade.Buy(lotSize, _Symbol, NULL);
                 }
               else
                  if(PositionsTotal() >= 1)
                    {
                     if(PositionSelect(_Symbol) == true)
                       {
                        int positionType = PositionGetInteger(POSITION_TYPE);
                        double positionProfit = PositionGetDouble(POSITION_PROFIT);
                        if(positionType == 1)
                          {
                           trade.PositionClose(_Symbol);
                           initalDeposit = initalDeposit + positionProfit;
                           trade.Buy(lotSize, _Symbol, NULL);
                          }
                       }
                    }
              }
           }

        }

     }
     
   if(redEma[1] > greenEma[1] && greenEma[0] > Bid)
     {
      if(time == 15 || time == 30 || time == 45 || time == 00)
        {
         if(newTime == 0)
           {
            if(dPlusarray[2] > dMiusarray[2] && dPlusarray[1] < dMiusarray[1] && adxarray[1] > adxFilter)
              {
               if(PositionsTotal() < 1)
                 {
                  trade.Sell(lotSize, _Symbol, NULL);
                 }
               else
                  if(PositionsTotal() >= 1)
                    {
                     if(PositionSelect(_Symbol) == true)
                       {
                        int positionType = PositionGetInteger(POSITION_TYPE);
                        double positionProfit = PositionGetDouble(POSITION_PROFIT);
                        if(positionType == 0)
                          {
                           trade.PositionClose(_Symbol);
                           initalDeposit = initalDeposit + positionProfit;
                           trade.Sell(lotSize, _Symbol, NULL);
                          }
                       }
                    }
              }
           }

        }
     }

   if(PositionSelect(_Symbol) == true)
     {
      accountTarget = initalDeposit * percTarget;
      difference = accountTarget - initalDeposit;
      Comment("Initial Deposit: ",initalDeposit,"\n");
      Comment("Account Target: ",accountTarget, "\n");
      Comment("Difference", difference,"\n");
      for(int i=PositionsTotal()-1; i>=0; i--)
        {
         double positionProfit = PositionGetDouble(POSITION_PROFIT);
         Comment("Position Profit: ",positionProfit);
         if(positionProfit >= percTarget || positionProfit <= stopLoss)
           {
            trade.PositionClose(_Symbol);
            initalDeposit = initalDeposit + difference;
           }
        }
     }
  }
//+------------------------------------------------------------------+
