
#property copyright "Copyright 2021, Joaquin Metayer."
#property link      "https://www.mql5.com/en/users/joaquinmetayer/seller"
#property version   "1.00"
#property strict



enum brokertype{
   four, // Four Digit Broker
   five, // Five Digit Broker
};


extern int magicnum = 892735; // Unique Magic Number
extern brokertype Broker = five; // Broker Type
double SL = 0; // SL in pips(0=no SL);
double TP = 0; // TP in pips(0=no TP);
extern double HardSL = 100; // First Level StopLoss(points)
extern double LevelDistance = 100; // Profit Distance to Place Next Order
extern double Lots = 0.1; // Lot size;
extern double Multiplier = 2; // Multiplier
extern double RetraceFromProfit = 100; // average reverse cycle at closing(points)


bool UseDebug = TRUE; // Print Debug Statements
string SymbolPrefix = ""; // Symbol Prefix(Usually left unchanged)
string SymbolSuffix = ""; // Symbol Suffix(Usually left unchanged)
double pip_multiplier;
double pip_point;
datetime bartime;


struct tradedetails{
   int ticket;
   double sl;
   double tp;
   double price;
   double lots;
};



tradedetails buycycle[];
tradedetails sellcycle[];
   

void OnInit(){
   if(Broker==five){
      pip_point = 10*Point;
      pip_multiplier = 10;
   }
   else if(Broker==four){
      pip_point = Point;
      pip_multiplier = 1;
   }

   bartime = Time[0];
   UnlockTradingThread();
   MathSrand(WindowHandle(Symbol(),Period()));
}


void OnDeinit(const int reason){
}

int start(){
   if(bartime!=Time[0]){
      bartime=Time[0];
   }
   int buysize = ArraySize(buycycle);
   int sellsize = ArraySize(sellcycle);
   
   if(buysize==0){
      int tic = longentry(Lots);
      if(tic>0){
         bool check=OrderSelect(tic,SELECT_BY_TICKET);
         if(check){
            ArrayResize(buycycle,1);
            buycycle[0].ticket = tic;
            buycycle[0].price = OrderOpenPrice();
            buycycle[0].sl = OrderStopLoss();
            buycycle[0].lots = OrderLots();
         }
         tic = longpendingentry(buycycle[0].price+LevelDistance*Point,buycycle[0].sl,Lots*Multiplier);
         if(tic>0){
            check=OrderSelect(tic,SELECT_BY_TICKET);
            if(check){
               ArrayResize(buycycle,2);
               buycycle[1].ticket = tic;
               buycycle[1].price = OrderOpenPrice();
               buycycle[1].sl = OrderStopLoss();
               buycycle[1].lots = OrderLots();
            }
         }
      }
   }
   
   if(sellsize==0){
      int tic = shortentry(Lots);
      if(tic>0){
         bool check=OrderSelect(tic,SELECT_BY_TICKET);
         if(check){
            ArrayResize(sellcycle,1);
            sellcycle[0].ticket = tic;
            sellcycle[0].price = OrderOpenPrice();
            sellcycle[0].sl = OrderStopLoss();
            sellcycle[0].lots = OrderLots();
         }
         tic = shortpendingentry(sellcycle[0].price-LevelDistance*Point,sellcycle[0].sl,Lots*Multiplier);
         if(tic>0){
            check=OrderSelect(tic,SELECT_BY_TICKET);
            if(check){
               ArrayResize(sellcycle,2);
               sellcycle[1].ticket = tic;
               sellcycle[1].price = OrderOpenPrice();
               sellcycle[1].sl = OrderStopLoss();
               sellcycle[1].lots = OrderLots();
            }
         }
      }
   }
   
   CleanupEmptyCycles();
   ManageHardSL();
   ManageNewOrders();
   //ManageGroupExit();
   
      
   return(0);
}

void CleanupEmptyCycles(){
   int buysize=ArraySize(buycycle);
   int sellsize = ArraySize(sellcycle);
   int count=0;
   bool ISEMPTY=true;
   
   if(buysize>0){
      while(count<buysize){
         bool check=OrderSelect(buycycle[count].ticket,SELECT_BY_TICKET);
         if(check&&OrderCloseTime()<=0){
            ISEMPTY=false;
            break;
         }
         count++;
      }
      if(ISEMPTY){
         ArrayResize(buycycle,0);
      }
   }
   
   count=0;
   ISEMPTY=true;
   if(sellsize>0){
      while(count<sellsize){
         bool check=OrderSelect(sellcycle[count].ticket,SELECT_BY_TICKET);
         if(check&&OrderCloseTime()<=0){
            ISEMPTY=false;
            break;
         }
         count++;
      }
      if(ISEMPTY){
         ArrayResize(sellcycle,0);
      }
   }
}
/*
void ManageGroupExit(){
   //check buytrades
   int buysize = ArraySize(buycycle);
   
   if(buysize>0){
      double lastbuytrade = buycycle[buysize-2].price;
      
      if(Bid<=lastbuytrade-RetraceFromProfit*Point){ // trigger to exit all
         CloseAllTradesInDirection(1);
         ArrayResize(buycycle,0);
         Print("exit at group exit");
      }
   }
   
   //check buytrades
   int sellsize = ArraySize(sellcycle);
   
   if(sellsize>0){
      double lastselltrade = sellcycle[sellsize-2].price;
      
      if(Ask>=lastselltrade+RetraceFromProfit*Point){ // trigger to exit all
         CloseAllTradesInDirection(-1);
         ArrayResize(sellcycle,0);
         Print("exit at group exit");
      }
   }

}
*/

void ManageNewOrders(){
   double nextlevel=0,nextlot=0,newsl=0;
   
   //check buy trades
   int buysize = ArraySize(buycycle);
   if(buysize>0){ // trades exist
      bool check = OrderSelect(buycycle[buysize-1].ticket,SELECT_BY_TICKET);
      if(check&&OrderType()==OP_BUY){
         nextlevel = buycycle[buysize-1].price+LevelDistance*Point;
         nextlot = buycycle[buysize-1].lots*Multiplier;
         newsl = buycycle[buysize-1].price-RetraceFromProfit*Point;
         int tic=longpendingentry(nextlevel,OrderStopLoss(),nextlot);
         if(tic>0){
            check=OrderSelect(tic,SELECT_BY_TICKET);
            if(check){
               ArrayResize(buycycle,buysize+1);
               buycycle[buysize].ticket = tic;
               buycycle[buysize].price = OrderOpenPrice();
               buycycle[buysize].lots = OrderLots();
            }
         }
         buycycle[0].sl=newsl;
         UpdateSL(buycycle,newsl);
      }
      
   }
   
   
   //check sell trades
   int sellsize = ArraySize(sellcycle);
   if(sellsize>0){ // trades exist
      bool check = OrderSelect(sellcycle[sellsize-1].ticket,SELECT_BY_TICKET);
      if(check&&OrderType()==OP_SELL){
         nextlevel = sellcycle[sellsize-1].price-LevelDistance*Point;
         nextlot = sellcycle[sellsize-1].lots*Multiplier;
         newsl = sellcycle[sellsize-1].price+RetraceFromProfit*Point;
         int tic=shortpendingentry(nextlevel,OrderStopLoss(),nextlot);
         if(tic>0){
            check=OrderSelect(tic,SELECT_BY_TICKET);
            if(check){
               ArrayResize(sellcycle,sellsize+1);
               sellcycle[sellsize].ticket = tic;
               sellcycle[sellsize].price = OrderOpenPrice();
               sellcycle[sellsize].lots = OrderLots();
            }
         }
         sellcycle[0].sl=newsl;
         UpdateSL(sellcycle,newsl);
      }
   }
}

void UpdateSL(tradedetails& cycle[],double sl){
   int count=0;
   int size = ArraySize(cycle);
   
   while(count<size){
      bool check = OrderSelect(cycle[count].ticket,SELECT_BY_TICKET);
      if(check&&ND(OrderStopLoss())!=ND(sl)){
         _OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),OrderExpiration());
      }
      count++;
   }
}

void ManageHardSL(){
   //check buy trades
   
   //check for SL
   int buysize = ArraySize(buycycle);
   
   if(buysize>0){ // trades exist
      if(Bid<=buycycle[0].sl){ // sl hit
         CloseAllTradesInDirection(1);
         ArrayResize(buycycle,0);
         Print("exit at hard sl");
      }
   }
   
   //check sell trades
   
   //check for SL
   int sellsize = ArraySize(sellcycle);
   
   if(sellsize>0){ // trades exist
      if(Ask>=sellcycle[0].sl){ // sl hit
         CloseAllTradesInDirection(-1);
         ArrayResize(sellcycle,0);
         Print("exit at hard sl");
      }
   }

}



int longentry(double lots,string comments=""){
   int count=0;
   double tp,sl;
   double realpoint = MarketInfo(Symbol(),MODE_POINT)*pip_multiplier;
   tp = MarketInfo(Symbol(),MODE_ASK)+TP*realpoint;
   sl = MarketInfo(Symbol(),MODE_ASK)-HardSL*Point;
   if(TP<=0.01){
      tp=0;
   }

   
   int ordernum = _OrderSend(Symbol(),OP_BUY,lots,-1,10,sl,tp,comments,magicnum,0,Lime);
   
   bool check = OrderSelect(ordernum,SELECT_BY_TICKET);
   if(check){
      if(OrderStopLoss()!=0&&OrderStopLoss()!=ND(OrderOpenPrice()-HardSL*Point)&&HardSL!=0){
         _OrderModify(ordernum,OrderOpenPrice(),OrderOpenPrice()-HardSL*Point,OrderTakeProfit(),0,Lime);
      }
   }

   return(ordernum);
}

int shortentry(double lots,string comments=""){
   int count=0;
   double tp,sl;
   double realpoint = MarketInfo(Symbol(),MODE_POINT)*pip_multiplier;
   tp = MarketInfo(Symbol(),MODE_BID)-TP*realpoint;
   sl = MarketInfo(Symbol(),MODE_BID)+HardSL*Point;
   if(TP<=0.01){
      tp=0;
   }

   int ordernum = _OrderSend(Symbol(),OP_SELL,lots,-1,10,sl,tp,comments,magicnum,0,Red);
   
   bool check = OrderSelect(ordernum,SELECT_BY_TICKET);
   if(check){
      if(OrderStopLoss()!=0&&OrderStopLoss()!=ND(OrderOpenPrice()+HardSL*Point)&&HardSL!=0){
         _OrderModify(ordernum,OrderOpenPrice(),OrderOpenPrice()+HardSL*Point,OrderTakeProfit(),0,Lime);
      }
   }

   return(ordernum);
}

int longpendingentry(double price,double sl,double lots,string comments=""){
   int count=0;
   double tp;
   double realpoint = MarketInfo(Symbol(),MODE_POINT)*pip_multiplier;
   tp = MarketInfo(Symbol(),MODE_ASK)+TP*realpoint;

   if(TP<=0.01){
      tp=0;
   }

   
   int ordernum = _OrderSend(Symbol(),OP_BUYSTOP,lots,price,10,sl,tp,comments,magicnum,0,Lime);

   return(ordernum);
}

int shortpendingentry(double price,double sl,double lots,string comments=""){
   int count=0;
   double tp;
   double realpoint = MarketInfo(Symbol(),MODE_POINT)*pip_multiplier;
   tp = MarketInfo(Symbol(),MODE_BID)-TP*realpoint;

   if(TP<=0.01){
      tp=0;
   }


   int ordernum = _OrderSend(Symbol(),OP_SELLSTOP,lots,price,10,sl,tp,comments,magicnum,0,Red);

   return(ordernum);
}


int CountTradesInDirection(int direction){
   int pos=0;
   int count=0;
   for(pos = OrdersTotal()-1; pos >= 0 ; pos--){
      bool check = OrderSelect(pos, SELECT_BY_POS);
      if(check &&OrderMagicNumber()==magicnum&&OrderSymbol()==Symbol()){   
         if(OrderType()==OP_BUY&&direction>=0){
            count++;
         }
         if(OrderType()==OP_SELL&&direction<=0){
            count++;
         }
      }
   }
   return(count);
}

void CloseTrade(int ticket){
      bool check = OrderSelect(ticket,SELECT_BY_TICKET);
      if(check&&OrderCloseTime()<=0){
            if(OrderType()==OP_BUY){
               _OrderClose(OrderTicket(),OrderLots(),-1,100,Lime);
            }
            else if(OrderType()==OP_SELL){
               _OrderClose(OrderTicket(),OrderLots(),-1,100,Red);
            }
            else{
               check = OrderDelete(OrderTicket(),Violet);
            }
      }
}

void CloseAllTrades(){
   int pos=0;
   for(pos = OrdersTotal()-1; pos >= 0 ; pos--){
      bool check = OrderSelect(pos, SELECT_BY_POS);
      if(check &&OrderMagicNumber()==magicnum&&OrderSymbol()==Symbol()){
            if(OrderType()==OP_BUY){
               _OrderClose(OrderTicket(),OrderLots(),-1,100,Lime);
            }
            else if(OrderType()==OP_SELL){
               _OrderClose(OrderTicket(),OrderLots(),-1,100,Red);
            }
            else{
               check = OrderDelete(OrderTicket(),Violet);
            }
      }
   }
}

void CloseAllTradesInDirection(int dir=0){
   int pos=0;
   for(pos = OrdersTotal()-1; pos >= 0 ; pos--){
      bool check = OrderSelect(pos, SELECT_BY_POS);
      if(check &&OrderMagicNumber()==magicnum&&OrderSymbol()==Symbol()){
            if(OrderType()==OP_BUY&&dir>=0){
               _OrderClose(OrderTicket(),OrderLots(),-1,100,Lime);
            }
            else if(OrderType()==OP_SELL&&dir<=0){
               _OrderClose(OrderTicket(),OrderLots(),-1,100,Red);
            }
            else if((OrderType()==OP_SELLSTOP||OrderType()==OP_SELLLIMIT)&&dir<=0){
               check = OrderDelete(OrderTicket(),Violet);
            }
            else if((OrderType()==OP_BUYSTOP||OrderType()==OP_BUYLIMIT)&&dir>=0){
               check = OrderDelete(OrderTicket(),Violet);
            }
      }
   }
}


























































/////////////////////////////////////////////////////////////////////////
// 
// Replace internal functions with updated ones to use trade semaphores
//
/////////////////////////////////////////////////////////////////////////
int _OrderSend(string symbol, int cmd, double volume, double price, int slippage, double stoploss, double takeprofit, string comment="", int magic=0, datetime expiration=0, color arrow_color=CLR_NONE) {
   int res = -1;
   RefreshRates();
   double price1=price;

   if(IsTesting()){
      if(price<=0){
         if(cmd==OP_BUY){
            price1=MarketInfo(symbol,MODE_ASK);
         }
         else if(cmd==OP_SELL){
            price1=MarketInfo(symbol,MODE_BID);
         }
      }
      else{
         price1=price;
      }
      res = OrderSend(symbol, cmd, volume, ND(price1), slippage, ND(stoploss), ND(takeprofit), comment, magic, expiration, arrow_color);
      return(res);
   }
   //try to lock resource
   if (LockTradingThread()<0) {
      Alert("Unable to place trade, timeout exceeded.");
      return(res);
   }
   RefreshRates();
   if(price<=0){
      if(cmd==OP_BUY){
         price1=MarketInfo(symbol,MODE_ASK);
      }
      else if(cmd==OP_SELL){
         price1=MarketInfo(symbol,MODE_BID);
      }
   }
   //place trade
   res = OrderSend(symbol, cmd, volume, ND(price1), slippage, ND(stoploss), ND(takeprofit), comment, magic, expiration, arrow_color);
   
   //unlock resource
   UnlockTradingThread();
   return(res);
}

bool _OrderModify( int ticket, double price, double stoploss, double takeprofit, datetime expiration, color arrow_color=CLR_NONE) {

   bool res = false;
   if(IsTesting()){
      res = OrderModify(ticket, ND(price), ND(stoploss), ND(takeprofit), expiration, arrow_color);
      return(res);
   }
      
   //try to lock resource
   if (LockTradingThread()<0) {
      Alert("Unable to modify trade, timeout exceeded.");
      return(res);
   }
   RefreshRates();
   
   //modify order
   res = OrderModify(ticket, ND(price), ND(stoploss), ND(takeprofit), expiration, arrow_color);
   
   //unlock resource
   UnlockTradingThread();
   return(res);
}


bool _OrderClose(	int ticket, double function_lots, double price, int slippage, color Color=CLR_NONE) {

   bool res = false;
   double price1=price;
   //try to lock resource
   if (LockTradingThread()<0) {
      Alert("Unable to modify trade, timeout exceeded.");
      return(res);
   }
   RefreshRates();
   
   //modify order
   bool check = OrderSelect(ticket,SELECT_BY_TICKET);
   if(price<=0){
      if(OrderType()==OP_BUY){
         price1=MarketInfo(OrderSymbol(),MODE_BID);
      }
      else if(OrderType()==OP_SELL){
         price1=MarketInfo(OrderSymbol(),MODE_ASK);
      }
   }
   else{
      price1=price;
   }
   
   int dig = (int)MarketInfo(OrderSymbol(),MODE_DIGITS);
   
   res = OrderClose(ticket, function_lots, NormalizeDouble(price1,dig), slippage*10, Color);
   
   //unlock resource
   UnlockTradingThread();
   /*
   if(!res){
      Sleep(1000);
      res=_OrderClose(ticket,function_lots,price,slippage*2,Color);
   }
   */
   return(res);
}

bool _OrderDelete(int ticket,color Color=CLR_NONE) {

   bool res = false;
   if(IsTesting()){
      res = OrderDelete(ticket,Color);
      return(res);
   }
   //try to lock resource
   if (LockTradingThread()<0) {
      Alert("Unable to delete trade, timeout exceeded.");
      return(res);
   }
   RefreshRates();
   
   //modify order
   res = OrderDelete(ticket,Color);
   
   //unlock resource
   UnlockTradingThread();
   return(res);
}


/////////////////////////////////////////////////////////////////////////////////
// int LockTradingThread( int MaxWaiting_sec = 30 )
//
// The function replaces the LockTradingThread value 0 with 1.
// If LockTradingThread = 1 at the moment of launch, the function waits until LockTradingThread is 0, 
// and then replaces.
// If there is no global variable LockTradingThread, the function creates it.
// Return codes:
//  1 - successfully completed. The global variable LockTradingThread was assigned with value 1
// -1 - LockTradingThread = 1 at the moment of launch of the function, the waiting was interrupted by the user
//      (the expert was removed from the chart, the terminal was closed, the chart period and/or symbol 
//      was changed, etc.)
// -2 - LockTradingThread = 1 at the moment of launch of the function, the waiting limit was exceeded
//      (MaxWaiting_sec)
/////////////////////////////////////////////////////////////////////////////////
int LockTradingThread( uint MaxWaiting_sec = 30 )
{
   // at testing, there is no resaon to divide the trade context - just terminate 
   // the function
   if(IsTesting()) return(1);
    
   int _GetLastError = 0;
   uint StartWaitingTime = GetTickCount();
   //+------------------------------------------------------------------+
   //| Check whether a global variable exists and, if not, create it    |
   //+------------------------------------------------------------------+
   while(true)
   {
      // if the expert was terminated by the user, stop operation
      if(IsStopped()) 
      { 
         Print("The expert was terminated by the user!"); 
         return(-1); 
      }
      // if the waiting time exceeds that specified in the variable 
      // MaxWaiting_sec, stop operation, as well
      if(int(GetTickCount()) - StartWaitingTime > MaxWaiting_sec * 1000)
      {
         Print("Waiting time (" + IntegerToString(int(MaxWaiting_sec)) + " sec) exceeded!");
         return(-2);
      }
      // check whether the global variable exists
      // if it does, leave the loop and go to the block of changing 
      // LockTradingThread value
      if(GlobalVariableCheck( "LockTradingThread" )) 
         break;
      else
      // if the GlobalVariableCheck returns FALSE, it means that it does not exist or  
      // an error has occurred during checking
      {
         _GetLastError = GetLastError();
         // if it is still an error, display information, wait for 0.1 second, and 
         // restart checking
         if(_GetLastError != 0)
         {
            Print("LockTradingThread()-GlobalVariableCheck(\"LockTradingThread\")-Error #",
                    _GetLastError );
            Sleep(100);
            continue;
         }
      }
      // if there is no error, it means that there is just no global variable, try to create
      // it
      // if the GlobalVariableSet > 0, it means that the global variable has been successfully created. 
      // Leave the function
      if(GlobalVariableSet( "LockTradingThread", 1.0 ) > 0 ) 
         return(1);
      else
      // if the GlobalVariableSet has returned a value <= 0, it means that an error 
      // occurred at creation of the variable
      {
         _GetLastError = GetLastError();
         // display information, wait for 0.1 second, and try again
         if(_GetLastError != 0)
         {
            Print("LockTradingThread()-GlobalVariableSet(\"LockTradingThread\",0.0 )-Error #",
                    _GetLastError );
            Sleep(100);
            continue;
         }
      }
   }
   //+----------------------------------------------------------------------------------+
   //| If the function execution has reached this point, it means that global variable  | 
   //| variable exists.                                                                 |
   //| Wait until the LockTradingThread becomes = 0 and change the value of LockTradingThread for 1 |
   //+----------------------------------------------------------------------------------+
   while(true)
   {
      // if the expert was terminated by the user, stop operation
      if(IsStopped()) 
      { 
         Print("The expert was terminated by the user!"); 
         return(-1); 
      }
      // if the waiting time exceeds that specified in the variable 
      // MaxWaiting_sec, stop operation, as well
      if(int(GetTickCount()) - StartWaitingTime > MaxWaiting_sec * 1000)
      {
         Print("The waiting time (" + IntegerToString(int(MaxWaiting_sec)) + " sec) exceeded!");
         return(-2);
      }
      // try to change the value of the LockTradingThread from 0 to 1
      // if succeed, leave the function returning 1 ("successfully completed")
      if(GlobalVariableSetOnCondition( "LockTradingThread", 1.0, 0.0 )) 
         return(1);
      else
      // if not, 2 reasons for it are possible: LockTradingThread = 1 (then one has to wait), or 

      // an error occurred (this is what we will check)
      {
         _GetLastError = GetLastError();
         // if it is still an error, display information and try again
         if(_GetLastError != 0)
         {
            Print("LockTradingThread()-GlobalVariableSetOnCondition(\"LockTradingThread\",1.0,0.0 )-Error #",
            _GetLastError );
            continue;
         }
      }
      //if there is no error, it means that LockTradingThread = 1 (another expert is trading), then display 
      // information and wait...
      Print("Wait until another expert finishes trading...");
      int num = 1 + 10*MathRand()/32768; // 1-10      
      Sleep(1000+num*100);
   }
   return(-400);
}

/////////////////////////////////////////////////////////////////////////////////
// void UnlockTradingThread()
//
// The function sets the value of the global variable LockTradingThread = 0.
// If the LockTradingThread does not exist, the function creates it.
/////////////////////////////////////////////////////////////////////////////////
int UnlockTradingThread()
{
   int _GetLastError;
   // at testing, there is no sense to divide the trade context - just terminate 
   // the function
   if(IsTesting()) 
   { 
      return(0); 
   }
   while(true)
   {
      // if the expert was terminated by the user, ?????????? ??????
      if(IsStopped()) 
      { 
         Print("The expert was terminated by the user!"); 
         return(-1); 
      }
      // try to set the global variable value = 0 (or create the global 
      // variable)
      // if the GlobalVariableSet returns a value > 0, it means that everything 
      // has succeeded. Leave the function
      if(GlobalVariableSet( "LockTradingThread", 0.0 ) > 0) 
         return(1);
      else
      // if the GlobalVariableSet returns a value <= 0, this means that an error has occurred. 
      // Display information, wait, and try again
      {
         _GetLastError = GetLastError();
         if(_GetLastError != 0 )
            Print("UnlockTradingThread()-GlobalVariableSet(\"LockTradingThread\",0.0)-Error #", 
                 _GetLastError );
      }
      Sleep(100);
   }
   return(-400);
}

double ND(double val){
   return(NormalizeDouble(val,Digits));
}



double NL(double p){
    double ls = MarketInfo(Symbol(), MODE_LOTSTEP);
    double lots = MathRound(p/ls)*ls;
    lots=MathMax(lots,MarketInfo(Symbol(),MODE_MINLOT));
    lots=MathMin(lots,MarketInfo(Symbol(),MODE_MAXLOT));
    return( lots);
}

void Debug(string msg){
   if(UseDebug){
      Print(msg);
   }
}





