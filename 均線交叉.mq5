//+------------------------------------------------------------------+
//|                                                         均線交叉.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

input int MagicNumber=1234;//區分不同支EA
input ENUM_ORDER_TYPE_FILLING fillingType = ORDER_FILLING_IOC;

int 多單單號,空單單號;
bool 多單條件,空單條件;
double 長均線1,短均線1,長均線2,短均線2;

input double 下單手數=0.01;//input變外部參數
input int 止損點數=1000;
input int 獲利點數=2000;

input int 短均參數=20;
input ENUM_MA_METHOD 短均方法=MODE_SMA;

input int 長均參數=60;
input ENUM_MA_METHOD 長均方法=MODE_SMA;
 

int 短MA_handler;
double 短MA[];

int 長MA_handler;
double 長MA[];


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()//這是EA載入執行一次
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)//這是EA移除時執行一次
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
 {
  
  
 //ctrl+z=上一步 ctrl+y=下一步
 //第 一步:取會用到的值---
 
   短MA_handler=iMA(Symbol(),PERIOD_CURRENT,短均參數,0,短均方法,PRICE_CLOSE);
   CopyBuffer(短MA_handler,0,0,100,短MA);
   ArraySetAsSeries(短MA,true);
   
   短均線1 =短MA[1];
   短均線2 =短MA[2];
   
   //交叉取前兩根k棒
   //前一根K棒均線值  
      
   長MA_handler=iMA(Symbol(),PERIOD_CURRENT,長均參數,0,長均方法,PRICE_CLOSE);
   CopyBuffer(長MA_handler,0,0,100,長MA);
   ArraySetAsSeries(長MA,true);
   
   長均線1 =長MA[1];
   長均線2 =長MA[2];
   
    //前一根K棒均線值  
   
 
 
 
    //第二步:判斷下單條件  
    
    //黃金交叉: 短均2<長均2 &&(並且) 短均1>長均1 
    多單條件 = 短均線2<長均線2 && 短均線1>長均線1;
    
    //死亡交叉: 短均2>長均2 && 短均1<長均1
    空單條件 = 短均線2>長均線2 && 短均線1<長均線1;
    
   
 //第三步:下單與平倉  
 
if(多單條件==true && 多單筆數()==0)//(條件))
   {
      MqlTradeRequest request={};
      MqlTradeResult  result={0};
      request.order=多單單號;
      request.action=TRADE_ACTION_DEAL;
      request.symbol=Symbol();
      request.type=ORDER_TYPE_BUY;
      request.volume=下單手數;
      request.deviation=30;
      request.price=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
      request.sl=SymbolInfoDouble(Symbol(),SYMBOL_ASK)-止損點數*Point();
      request.tp=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+獲利點數*Point();
      request.comment="均線交叉_BUY";
      request.magic=MagicNumber;
      request.type_filling=fillingType;
      
      if(!OrderSend(request,result))
         PrintFormat("OrderSend error %d",GetLastError());
      PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      


   } //{做什麼事}
   
  if (空單條件==true && 空單筆數()==0)
    {
      MqlTradeRequest request={};
      MqlTradeResult  result={0};
      request.order=空單單號;
      request.action=TRADE_ACTION_DEAL;
      request.symbol=Symbol();
      request.type=ORDER_TYPE_SELL;
      request.volume=下單手數;
      request.deviation=30;
      request.price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
      request.sl=SymbolInfoDouble(Symbol(),SYMBOL_BID)+止損點數*Point();
      request.tp=SymbolInfoDouble(Symbol(),SYMBOL_BID)-獲利點數*Point();
      request.comment="均線交叉_SELL";
      request.magic=MagicNumber;
      request.type_filling=fillingType;
      
      if(!OrderSend(request,result))
         PrintFormat("OrderSend error %d",GetLastError());
      PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);

 
   }
 
 //---------平倉出場
   if(多單筆數()>0 && 空單條件==true) 多單平倉();
 
   if(空單筆數()>0 && 多單條件==true) 空單平倉();
 
  }
//+------------------------------------------------------------------+










//----------------------------------------------------------------------------------
//                                         函數庫
//----------------------------------------------------------------------------------   
//---------------------------------------------------------多單筆數

int 多單筆數()
  {
   int count=0;
   for(int i=0;i<PositionsTotal();i++)
     {
      if(PositionGetTicket(i)>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && PositionGetInteger(POSITION_MAGIC)==MagicNumber)
         count++;
        }
     }
   return(count);
  }
//---------------------------------------------------------空單筆數

int 空單筆數()
  {
   int count=0;
   for(int i=0;i<PositionsTotal();i++)
     {
      if(PositionGetTicket(i)>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && PositionGetInteger(POSITION_MAGIC)==MagicNumber)
         count++;
        }
     }
   return(count);
  }

//---------------------------------------------------------多單Close寫法

void 多單平倉()
  {
   int t=PositionsTotal();
   for(int i=t-1;i>=0;i--)
     {
      if(PositionGetTicket(i)>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && MagicNumber==PositionGetInteger(POSITION_MAGIC))
           {
            MqlTradeRequest request={};
            MqlTradeResult  result={0};
            request.action=TRADE_ACTION_DEAL;
            request.symbol=Symbol();
            request.volume=PositionGetDouble(POSITION_VOLUME);
            request.type=ORDER_TYPE_SELL;
            request.price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            request.deviation=100;
            request.position =PositionGetTicket(i);
            request.type_filling=fillingType;
            
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());
           }
        }
     }
  }
//---------------------------------------------------------空單Close寫法

void 空單平倉()
  {
   int t=PositionsTotal();
   for(int i=t-1;i>=0;i--)
     {
      if(PositionGetTicket(i)>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && MagicNumber==PositionGetInteger(POSITION_MAGIC))
           {
            MqlTradeRequest request={};
            MqlTradeResult  result={0};
            request.action=TRADE_ACTION_DEAL;
            request.symbol=Symbol();
            request.volume=PositionGetDouble(POSITION_VOLUME);
            request.type=ORDER_TYPE_BUY;
            request.price=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            request.deviation=100;
            request.position =PositionGetTicket(i);
            request.type_filling=fillingType;
            
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());
           }
        }
     }
  }
