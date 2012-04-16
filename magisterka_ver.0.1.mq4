//+------------------------------------------------------------------+
//|                                                   magisterka.mq4 |
//|                              Copyright © 2012, in¿. Tomasz Górny |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "in¿. Tomasz Górny"

#define BARS_TO_AVERAGE                                             10

#define TRESHOLD_HIGH_CANDLE                                       0.5
#define TRESHOLD_SMALL_CANDLE                                      0.5

#define DOJI_CANDLE                                                  0
#define SMALL_CANDLE                                                 1
#define NORMAL_CANDLE                                                2
#define BIG_CANDLE                                                   3

#define MA_DISTANCE                                                  3
#define MA_FAST                                                     10
#define MA_SLOW                                                     15
#define TREND_UP                                                     0
#define TREND_DOWN                                                   1
#define TREND_HORIZONTAL                                             2


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   
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

   int iPeriod=Period();
   int bars_count=WindowBarsPerChart();
   int bar=WindowFirstVisibleBar();
   if(Volume[0] == 1) // if the latest bar have only one tick (new bar appear)
   {
      Print("period: ", iPeriod, "bars: ", bars_count, "bar: ", bar, "high: ", High[1], "low: ", Low[1], "open: ", Open[1], "close: ", Close[1], "trend: ", trend() , "point: ", Point);
   }

   return(0);
  }


//+------------------------------------------------------------------+
//| check if candle is HAMMER                                        |
//+------------------------------------------------------------------+
bool isHammer(int candle)
{
   if(TREND_DOWN == trend() && 2.0 < lowerShadow(candle) && 0.0 == upperShadow(candle) && isWhite(candle))
      return(true);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| check if candle is HANGINGMAN                                    |
//+------------------------------------------------------------------+
bool isHangingMan(int candle)
{
   if(TREND_UP == trend() && 3.0 < lowerShadow(candle) && 0.0 == upperShadow(candle) && !isWhite(candle))
      return(true);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| return trend 0-TREND_UP 1-TREND_DOWN 2-TREND_HORIZONTAL          |
//+------------------------------------------------------------------+
int trend()
{
   double diff=iMA(NULL,0,MA_FAST,0,MODE_EMA,PRICE_CLOSE,0) - iMA(NULL,0,MA_SLOW,0,MODE_EMA,PRICE_CLOSE,0);
   if(diff-Point*MA_DISTANCE > 0)
      return(TREND_UP);
   else if(diff+Point*MA_DISTANCE < 0)
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
   return(average/candles);
}

//+------------------------------------------------------------------+
//| return upper shadow size divide by candle high                   |
//+------------------------------------------------------------------+
double upperShadow(int candle)
{
   double candleHigh = MathAbs(Close[candle]-Open[candle]);
   if(candleHigh == 0)
      candleHigh = Point;
   double upperShadow = 0.0;
   if(isWhite(candle))
      upperShadow = High[candle]-Close[candle];
   else
      upperShadow = High[candle]-Open[candle];
   return(upperShadow/candleHigh);
}

//+------------------------------------------------------------------+
//| return lower shadow size divide by candle high                   |
//+------------------------------------------------------------------+
double lowerShadow(int candle)
{
   double candleHigh = MathAbs(Close[candle]-Open[candle]);
   if(candleHigh == 0)
      candleHigh = Point;
   double lowerShadow = 0.0;
   if(isWhite(candle))
      lowerShadow = Open[candle]-Low[candle];
   else
      lowerShadow = Close[candle]-Low[candle];
   return(lowerShadow/candleHigh);
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
   double candleBody = MathAbs(Close[candle]-Open[candle]);
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