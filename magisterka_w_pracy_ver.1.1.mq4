//+------------------------------------------------------------------+
//|                                                   magisterka.mq4 |
//|                              Copyright © 2012, in¿. Tomasz Górny |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "in¿. Tomasz Górny"

#define BARS_TO_AVERAGE                                             100

#define TRESHOLD_HIGH_CANDLE                                       0.5
#define TRESHOLD_SMALL_CANDLE                                      0.5

#define DOJI_CANDLE                                                  0
#define SMALL_CANDLE                                                 1
#define NORMAL_CANDLE                                                2
#define BIG_CANDLE                                                   3

//#define MA_DISTANCE                                                  3
//#define MA_FAST                                                      5
//#define MA_SLOW                                                     10
extern int MA_DISTANCE=1;
extern int MA_FAST=18;
extern int MA_SLOW=25;
extern int hammerTreshold1=4;
extern double hammerTreshold2=1.5;

extern int hangingManTreshold1=3;
extern double hangingManTreshold2=1.5;

extern int shootingStarTreshold1=3;
extern double shootingStarTreshold2=2;

extern double engulfingTreshold1=1.5;
extern double engulfingTreshold2=1.5;

extern double haramiTreshold1=1.5;
extern double haramiTreshold2=1.5;



#define TREND_UP                                                     0
#define TREND_DOWN                                                   1
#define TREND_HORIZONTAL                                             2

int takeProfitExtern=1000;
int stopLossExtern= 20;

bool work=true;
string symbol;

double prevPrice=NULL;
int    spread;
double point = 0.0001;
double stopLossMin;
double lots= -1.1;
bool lastWin=true;
double lastFreeMargin=NULL;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
//----
   lastFreeMargin=AccountFreeMargin();
   symbol=Symbol();
   spread=MarketInfo(symbol,MODE_SPREAD);
//----
   return(0);
}

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
{
//----
   
//----
   return(0);
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{

   if(work==false)                             
   {
      Print("Critical error.");
      return;                                  
   }
   
   //close order if it is end of week
   /*
   if(DayOfWeek()>=4 && Hour()>21)
   {
      if(OrdersTotal()>0)
      {
         for(int i=0; i<OrdersTotal(); i++)
         {
            if(OrderSelect(i,SELECT_BY_POS))
               closeOrder(true, true);
         }
      }  
   }
   */

   if(prevPrice==NULL)
   {
      RefreshRates(); 
      prevPrice=Ask;
      return;
   }

   //modify stop loss
   //modifyStopLoss();
   
   //check close criteria, set closeBuy and closeSell, close order
   bandsCloseCriteria();
   RefreshRates(); 
   prevPrice=Ask;
   //work only with one order
   if(OrdersTotal()>0)
      return;
   //new bar appear (if the latest bar have only one tick)
   if(Volume[0]==1)
   {     
      //check open criteria and open order
      candleOpenCriteria();

   }
   
   
   return(0);
}

//+------------------------------------------------------------------+
//|         random trading criteria, set openBuy                     | 
//+------------------------------------------------------------------+
void randomOpenCriteria(bool openBuy, bool openSell)
{
   double diff=iMA(NULL,0,MA_FAST,0,MODE_EMA,PRICE_CLOSE,0)-iMA(NULL,0,MA_SLOW,0,MODE_EMA,PRICE_CLOSE,0);
   if(diff>0)
   {
      openBuy=true;
      Print("Signal to buy");         
   }
   else if(diff<0)
   {
      openSell=true; 
      Print("Signal to sell"); 
   }
   //Print("last: ", lastFreeMargin, " current: ", AccountFreeMargin());
   if(lastFreeMargin>AccountFreeMargin())
      lots=lots*2;
   else
      lots= -1.0;
   lastFreeMargin=AccountFreeMargin();
}

//+------------------------------------------------------------------+
//|         candles trading criteria, set openBuy and openSell       | 
//+------------------------------------------------------------------+
void candleOpenCriteria()
{  
   //hammer and later confirmation


   if(isHammer(2) && Close[1]>Close[2])         
   {   
      //1 18 25 - trend parameters                                      
      openOrder(true, false, lots, takeProfitExtern, Low[2]);
      Print("Hammer candle appears", " Open: ", Open[2], " High: ", High[2], " Low: ", Low[2], " Close: ", Close[2], " Time: ",TimeMinute(Time[2]));                           
   }

  
   //hanging man and later confirmation
   
   else if(isHangingMan(2) && Close[2]>=Close[1])         
   {    
      Print("HIGH[2]: ", High[2]);
      openOrder(false, true, lots, takeProfitExtern, High[2]);
      Print("Hanging man candle appears", " Open: ", Open[2], " High: ", High[2], " Low: ", Low[2], " Close: ", Close[2], " Time: ",TimeMinute(Time[2]));                                                  
   }
 
   else if(isShootingStar(2) && Close[2]>=Close[1]) 
   {   
      openOrder(false, true, lots, takeProfitExtern, High[2]);  
      Print("Shooting Star candle appears", " Open: ", Open[1], " High: ", High[1], " Low: ", Low[1], " Close: ", Close[1], " Time: ",TimeMinute(Time[1])); 
   }

   // zysk ale tylko 20% trafnych transakcji
   else if(isBullishEngulfing(1)) 
   {
      openOrder(true, false, lots, takeProfitExtern, Low[1]);      
      Print("BullishEngulfing candle appears", " Open: ", Open[1], " High: ", High[1], " Low: ", Low[1], " Close: ", Close[1], " Time: ",TimeMinute(Time[1])); 
   }
  
   else if(isBearishEngulfing(1)) 
   {
      openOrder(false, true, lots, takeProfitExtern, High[1]);     
      Print("BearishEngulfing candle appears", " Open: ", Open[1], " High: ", High[1], " Low: ", Low[1], " Close: ", Close[1], " Time: ",TimeMinute(Time[1])); 
   }
   /*
   //Bullish Harami and later confirmation
   else if(isBullishHarami(2) && Close[1]>=Close[2]) 
   {
      openOrder(true, false, lots, takeProfitExtern, Low[3]);    
      Print("BullishHarami candle appears", " Open: ", Open[1], " High: ", High[1], " Low: ", Low[1], " Close: ", Close[1], " Time: ",TimeMinute(Time[1])); 
   }
/*
   //Bearish Harami and later confirmation
   else if(isBearishHarami(2) && Close[1]<=Close[2]) 
   {
      openSell=true;      
      Print("BearishHarami candle appears", " Open: ", Open[1], " High: ", High[1], " Low: ", Low[1], " Close: ", Close[1], " Time: ",TimeMinute(Time[1])); 
   }

   else if(isDarkCloudCover(1))
   {
      openSell=true;      
      Print("DarkCloudCover candle appears", " Open: ", Open[1], " High: ", High[1], " Low: ", Low[1], " Close: ", Close[1], " Time: ",TimeMinute(Time[1])); 
   }

   else if(isPiercingLine(1))
   {
      openBuy=true;      
      Print("PiercingLine candle appears", " Open: ", Open[1], " High: ", High[1], " Low: ", Low[1], " Close: ", Close[1], " Time: ",TimeMinute(Time[1])); 
   }
   
   else if(isMorningStar(1))
   {
      openBuy=true;      
      Print("MorningStar candle appears", " Open: ", Open[1], " High: ", High[1], " Low: ", Low[1], " Close: ", Close[1], " Time: ",TimeMinute(Time[1])); 
   }

   else if(isEveningStar(1))
   {
      openSell=true;      
      Print("EveningStar candle appears", " Open: ", Open[1], " High: ", High[1], " Low: ", Low[1], " Close: ", Close[1], " Time: ",TimeMinute(Time[1])); 
   }
*/
}

//+------------------------------------------------------------------+
//| open criteria for strategy bollinger bands                       |
//| set openBuy and openSell                                         | 
//+------------------------------------------------------------------+
void bandsOpenCriteria(bool openBuy, bool openSell)
{
   double midBand=iMA(NULL,0,20,0,MODE_SMA,PRICE_CLOSE,0);
      
   if(TREND_UP==trend())
   {
      RefreshRates();
      if(Ask>=midBand && prevPrice<midBand)
         openBuy=true;

   }
   else if(TREND_DOWN==trend())
   {
      RefreshRates();
      if(Bid<=midBand && prevPrice>midBand)
         openSell=true;
   }
}

//+------------------------------------------------------------------+
//| modify stop loss                                                 |
//+------------------------------------------------------------------+
void modifyStopLoss()
{
   double sl;
   double tp;
   double price;
   int    ticket;
   bool ans;

   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS))
      {
         sl=OrderStopLoss();
         if(OrderType()==OP_BUY)
         {
            if( ( (Bid-sl) / point ) > (1.5*stopLossExtern) )
            {
               tp    =OrderTakeProfit();    // tp of the selected order
               price =OrderOpenPrice();     // price of the selected order
               ticket=OrderTicket();        // ticket of the selected order
               sl = Bid - point*10;
               Print("Modification buy order: ",ticket,". Awaiting response..");
               
               ans=OrderModify(ticket, price, sl, tp, 0);//Modify it!
               if(ans)
                  Print("Modificated buy order: ", ticket);
               else
                  processError(GetLastError());
            }   
         }
         else if(OrderType()==OP_SELL)
         {
            if( ( (sl-Ask) / point ) > (1.5*stopLossExtern) )
            {
               tp    =OrderTakeProfit();    // tp of the selected order
               price =OrderOpenPrice();     // price of the selected order
               ticket=OrderTicket();        // ticket of the selected order
               sl = Ask + point*10;
               Print("Modification buy order: ",ticket,". Awaiting response..");
               
               ans=OrderModify(ticket, price, sl, tp, 0);//Modify it!
               if(ans)
                  Print("Modificated buy order: ", ticket);
               else
                  processError(GetLastError());
            } 
            
         }
      }
   } 
}

//+------------------------------------------------------------------+
//| closing criteria for strategy bollinger bands                    |
//| set closeBuy and closeSell                                       | 
//+------------------------------------------------------------------+
void bandsCloseCriteria()
{
   double upperBand=iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_UPPER,0);
   double lowerBand=iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_LOWER,0);
   double midBand=iMA(NULL,0,20,0,MODE_SMA,PRICE_CLOSE,0);
   int orderType=NULL;
   bool closeBuy=false;
   bool closeSell=false;
   
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS))
      {
         closeBuy=false;
         closeSell=false;
         orderType=OrderType();
         if(orderType>1)
         {
            Print("Pending order detected. Candle advisor doesn't work");
            return;                             
         }
         else if(orderType==OP_BUY)
         {
            //if(prevPrice-spread*point>upperBand && Bid<=upperBand)
            if(High[2]>upperBand && Low[1]<=upperBand)
            {
               Print("Close order BUY: true ");
               closeBuy=true;
            }
         }
         else if(orderType==OP_SELL)
         {
            Print("prevPrice: ", prevPrice, " Ask: ", Ask);
            //if(prevPrice<lowerBand && Ask>=lowerBand)
            if(Low[2]<lowerBand && High[1]>=lowerBand)
            {
               Print("Close order SELL: true ");
               closeSell=true;
            }
         }
         closeOrder(closeBuy, closeSell);
      }
   }//end for
}

//+------------------------------------------------------------------+
//| try to close selected order                                      | 
//+------------------------------------------------------------------+
void closeOrder(bool closeBuy, bool closeSell)
{  
   int orderType=OrderType();
   int ticket=OrderTicket();
   double lots=OrderLots();
   bool ans=false;
   while(true)                                
   {
      if(orderType==OP_BUY && closeBuy==true)                
      {
         Print("Attempt to close Buy ",ticket,". Waiting for response..");                                      
         RefreshRates();                        
         ans=OrderClose(ticket,lots,NormalizeDouble(Bid,Digits),2);      
         if(ans==true)                        
         {
            Print("Closed order Buy ",ticket);
            break;                             
         }
         if(processError(GetLastError())==1)      
            continue;                           
         return;                               
      }
 
      if(orderType==OP_SELL && closeSell==true)                
      {                                       
         Print("Attempt to close Sell ",ticket,". Waiting for response..");                                      
         RefreshRates();                        
         ans=OrderClose(ticket,lots,NormalizeDouble(Ask,Digits),2);    
         if(ans==true)                         
         {
            Print("Closed order Sell ",ticket);
            break;                             
         }
         if(processError(GetLastError())==1)      
            continue;                          
         return;                              
      }
      break;                                    // Exit while
   }//end while
}

//+------------------------------------------------------------------+
//| try to open new order                                            | 
//+------------------------------------------------------------------+
void openOrder(bool openBuy, bool openSell, double lots, double takeProfitExtern, double stopLossMin)
{

   double minLot=MarketInfo(symbol,MODE_MINLOT);
   if(lots<0)
      lots=getLotsToOrder(); 
   if(lots<minLot)
   {
      //Print(" Not enough money for ", minLot," lots.");
      return;
   }
   double stopLoss=NULL;
   double takeProfit=NULL;
   int ticket=NULL;

   while(true)                               
   {
      if(openBuy==true)              
      {                                    
         RefreshRates();                      
         //stopLoss=Bid-MarketInfo(symbol,MODE_STOPLEVEL)*point;    
         stopLoss=Bid - point*stopLossExtern;   
         takeProfit=Bid + point*takeProfitExtern;   
            
         Print("Attempt to open Buy. Waiting for response...", " sl: ", stopLoss, " bid: ", Bid, " point: ", point);
         ticket=OrderSend(symbol,OP_BUY,lots,NormalizeDouble(Ask,Digits),2,NormalizeDouble(stopLossMin, Digits),NormalizeDouble(takeProfit, Digits));
         if(ticket>0)                      
         {
            Print("Opened order Buy ",ticket);
            return;                            
         }
         if(processError(GetLastError())==1)     
            continue;                          
         return;                               
      }//end if
      if(openSell==true)              
      {                                      
         RefreshRates();                        
         stopLoss=Ask+stopLossExtern*point;   
         takeProfit=Ask-takeProfitExtern*point;  
            
         Print("Attempt to open Sell. Waiting for response...", " sl: ", stopLoss, " bid: ", Bid, " point: ", point, "slmin: ", NormalizeDouble(takeProfit, Digits));
      
         ticket=OrderSend(symbol,OP_SELL,lots,NormalizeDouble(Bid,Digits),2,NormalizeDouble(stopLossMin, Digits), NormalizeDouble(takeProfit, Digits));
         if(ticket>0)                       
         {
            Print("Opened order Sell ",ticket);
            return;                             
         }
         if(processError(GetLastError())==1)      
            continue;                           
         return;                             
      }//end if
      break;                                    
   }//end while
}

//+------------------------------------------------------------------+
//| calculate max lots to order                                      |
//+------------------------------------------------------------------+
double getLotsToOrder()
{
   double lots=NULL;
   double freeMargin=NULL;
   double oneLot=NULL;
   double step=NULL;
   
   RefreshRates();    
        
   freeMargin=AccountFreeMargin();               
   oneLot=MarketInfo(symbol,MODE_MARGINREQUIRED);    
   step=MarketInfo(symbol,MODE_LOTSTEP);
      
   lots=MathFloor(freeMargin/oneLot/step)*step;
   
   return(lots);
}

//+------------------------------------------------------------------+
//| check if candle is HAMMER                                        |
//+------------------------------------------------------------------+
bool isHammer(int candle)
{
   if(TREND_UP== trend() && TREND_DOWN == bbFilter(candle) && hammerTreshold1<(lowerShadow(candle)/candleHigh(candle)) && 2>=upperShadow(candle) && lowerShadow(candle)>hammerTreshold2*averageCandleBody(BARS_TO_AVERAGE))
      return(true);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| check if candle is HANGINGMAN                                    |
//+------------------------------------------------------------------+
bool isHangingMan(int candle)
{
   if(TREND_DOWN == trend() && TREND_UP == bbFilter(candle) && hangingManTreshold1<(lowerShadow(candle)/candleHigh(candle)) && 2>=upperShadow(candle) && !isWhite(candle) && lowerShadow(candle)>hangingManTreshold2*averageCandleBody(BARS_TO_AVERAGE))
      return(true);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| check if candle is SHOOTING STAR                                 |
//+------------------------------------------------------------------+
bool isShootingStar(int candle)
{
   if(TREND_DOWN == trend() && TREND_UP == bbFilter(candle) && shootingStarTreshold1<(upperShadow(candle)/candleHigh(candle)) && 3>=lowerShadow(candle) && upperShadow(candle)>shootingStarTreshold2*averageCandleBody(BARS_TO_AVERAGE))
      return(true);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| check if candle is BULLISH ENGULFING                             |
//+------------------------------------------------------------------+
bool isBullishEngulfing(int candle)
{
   if(TREND_UP == trend() && TREND_DOWN == bbFilter(candle) && !isWhite(candle+1) && Close[candle]>Open[candle+1] && Open[candle]<Close[candle+1] && candleHigh(candle+1)>engulfingTreshold1*averageCandleBody(BARS_TO_AVERAGE))
      return(true);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| check if candle is BEARISH ENGULFING                             |
//+------------------------------------------------------------------+
bool isBearishEngulfing(int candle)
{
   if(TREND_DOWN == bbFilter(candle) && TREND_UP == trend() && isWhite(candle+1) && Close[candle]<Low[candle+1] && Open[candle]>High[candle+1] && candleHigh(candle+1)>engulfingTreshold2*averageCandleBody(BARS_TO_AVERAGE))
      return(true);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| check if candle is BULLISH HARAMI                                |
//+------------------------------------------------------------------+
bool isBullishHarami(int candle)
{
   if(TREND_UP == bbFilter(candle) && TREND_DOWN == trend() && !isWhite(candle+1) && Open[candle+1]>Close[candle] && Close[candle+1]<Open[candle] && candleHigh(candle)>haramiTreshold1*averageCandleBody(BARS_TO_AVERAGE))
      return(true);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| check if candle is BEARISH HARAMI                                |
//+------------------------------------------------------------------+
bool isBearishHarami(int candle)
{
   if(TREND_DOWN == bbFilter(candle) && TREND_UP == trend() && isWhite(candle+1) && Close[candle+1]>Open[candle] && Open[candle+1]<Close[candle] && candleBodySize(candle+1)==BIG_CANDLE)
      return(true);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| check if candle is DARK CLOUD COVER                              |
//+------------------------------------------------------------------+
bool isDarkCloudCover(int candle)
{
   if(TREND_UP == bbFilter(candle) && TREND_DOWN == trend() && isWhite(candle+1) && Open[candle]>High[candle+1] && ( (Open[candle+1]+Close[candle+1])/2 )>Close[candle] && Close[candle]>Open[candle+1] && candleBodySize(candle+1)>SMALL_CANDLE)
      return(true);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| check if candle is PIERCING LINE                                 |
//+------------------------------------------------------------------+
bool isPiercingLine(int candle)
{
   if(TREND_DOWN == bbFilter(candle) && TREND_UP == trend() && !isWhite(candle+1) && Open[candle]<Low[candle+1] && ( (Open[candle+1]+Close[candle+1])/2 )<Close[candle] && Close[candle]<Open[candle+1] && candleBodySize(candle+1)>SMALL_CANDLE)
      return(true);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| check if candle is MORNING STAR                                  |
//+------------------------------------------------------------------+
bool isMorningStar(int candle)
{  
   double star;
   if(isWhite(candle+1))
      star = Close[candle+1];
   else
      star = Open[candle+1]; 
   if(TREND_DOWN == bbFilter(candle) && TREND_UP == trend() && !isWhite(candle+2) && isWhite(candle) && candleBodySize(candle+2)>SMALL_CANDLE && candleBodySize(candle)>SMALL_CANDLE && Close[candle+2]>star && Open[candle]>star)
      return(true);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| check if candle is EVENING STAR                                  |
//+------------------------------------------------------------------+
bool isEveningStar(int candle)
{  
   double star;
   if(!isWhite(candle+1))
      star = Close[candle+1];
   else
      star = Open[candle+1]; 
   if(TREND_UP == bbFilter(candle) && TREND_DOWN== trend() && isWhite(candle+2) && !isWhite(candle) && candleBodySize(candle+2)>SMALL_CANDLE && candleBodySize(candle)>SMALL_CANDLE && Close[candle+2]<star && Open[candle]<star)
      return(true);
   else
      return(false);
}


//+------------------------------------------------------------------+
//| return trend 0-TREND_UP 1-TREND_DOWN 2-TREND_HORIZONTAL          |
//+------------------------------------------------------------------+
int trend()
{
   double diff=iMA(NULL,0,MA_FAST,0,MODE_EMA,PRICE_CLOSE,0)-iMA(NULL,0,MA_SLOW,0,MODE_EMA,PRICE_CLOSE,0);
   if(diff-point*MA_DISTANCE > 0)
      return(TREND_UP);
   else if(diff+point*MA_DISTANCE < 0)
      return(TREND_DOWN);
   else
      return(TREND_HORIZONTAL);
}

//+------------------------------------------------------------------+
//| bollinger bands filter                                           |
//+------------------------------------------------------------------+
int bbFilter(int candle)
{
   double upperBand=iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_UPPER,candle);
   double lowerBand=iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_LOWER,candle);
   double midBand=iMA(NULL,0,20,0,MODE_SMA,PRICE_CLOSE,0);
   if(High[candle]>midBand)
      return(TREND_UP);
   else if(Low[candle]<midBand)
      return(TREND_DOWN);
   else
      return(TREND_HORIZONTAL);
}

//+------------------------------------------------------------------+
//| return average body size from candles                            |
//+------------------------------------------------------------------+
double averageCandleBody(int candles)
{
   double average=0;
   for(int candle=1; candle<candles+1; candle++)
   {
      average+=MathAbs(Close[candle]-Open[candle]);
   }
   return(average/(point*candles));
}

//+------------------------------------------------------------------+
//| return upper shadow size divide by candle high                   |
//+------------------------------------------------------------------+
double upperShadow(int candle)
{
   double upperShadow = NULL;
   if(isWhite(candle))
      upperShadow = High[candle]-Close[candle];
   else
      upperShadow = High[candle]-Open[candle];
   return(upperShadow/point);
}

//+------------------------------------------------------------------+
//| return lower shadow size divide by candle high in points         |
//+------------------------------------------------------------------+
double lowerShadow(int candle)
{ 
   double lowerShadow = NULL;
   if(isWhite(candle))
      lowerShadow = Open[candle]-Low[candle];
   else
      lowerShadow = Close[candle]-Low[candle];
   return(lowerShadow/point);
}

//+------------------------------------------------------------------+
//| return candle high in points                                     |
//+------------------------------------------------------------------+
double candleHigh(int candle)
{
   double candleHigh = MathAbs(Close[candle]-Open[candle]);
   if(candleHigh == 0)
      candleHigh = point;
   return(candleHigh/point);
}

//+------------------------------------------------------------------+
//| check if candle is white TRUE-WHITE FALSE-BLACK                  |
//+------------------------------------------------------------------+
bool isWhite(int candle)
{
   double diff = Close[candle]-Open[candle];
   if(diff > 0)
      return(true);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| how big is candle body 0-DOJI_CANDLE, 1-SMALL_CANDLE,            | 
//|                        2-NORMAL_CANDLE, 3-BIG_CANDLE             |
//+------------------------------------------------------------------+
int candleBodySize(int candle)
{
   double candleBody = MathAbs(Close[candle]-Open[candle])/point;
   double average = averageCandleBody(BARS_TO_AVERAGE);
   double ratio = candleBody/average;
   if(ratio>(1+TRESHOLD_HIGH_CANDLE))
      return(BIG_CANDLE);
   else if(candleBody == 0)
      return(DOJI_CANDLE);
   else if(ratio<TRESHOLD_SMALL_CANDLE)
      return(SMALL_CANDLE);
   else
      return(NORMAL_CANDLE);
}

//+------------------------------------------------------------------+
//| process Errors 0 - critical error 1 - not crucial error          | 
//+------------------------------------------------------------------+
int processError(int error)                       
{
   switch(error)
   {
      // Not crucial errors                                                     
      case  4: Print("Trade server is busy. Trying once again...");
         Sleep(3000);                        
         return(1);                             
      case 135:Print("Price changed. Trying once again..");
         RefreshRates();                  
         return(1);                           
      case 136:Print("No prices. Waiting for a new tick..");
         while(RefreshRates()==false)          
            Sleep(1);                          
         return(1);                            
      case 137:Print("Broker is busy. Trying once again..");
         Sleep(3000);                         
         return(1);                        
      case 146:Print("Trading subsystem is busy. Trying once again..");
         Sleep(500);                          
         return(1);                      
      // Critical errors
      case  2: Print("Common error.");
         return(0);                            
      case  5: Print("Old terminal version.");
         work=false;                           
         return(0);                             
      case 64: Print("Account blocked.");
         work=false;                          
         return(0);                             
      case 133:Print("Trading forbidden.");
         return(0);                           
      case 134:Print("Not enough money to execute operation.");
         return(0);                             
      default: Print("Error occurred: ",error);  
         return(0);                             
   }
}
 
//+------------------------------------------------------------------+