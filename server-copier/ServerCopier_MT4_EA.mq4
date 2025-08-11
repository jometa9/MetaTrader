//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025 "
#property link      "Metaquotes.com"
#property version   "1.00"
#property strict

enum Opt
{
   Master,
   Slave,
};

extern Opt Role = Master; //Role of this setup
extern string ServerURL = "http://localhost:80/api";
extern string apiKey = "keykey";
extern string Prefix = ""; //Prefix, for Slave
extern string Suffix = ""; //Suffix, for Slave

int xdig, slippage = 1000;
int MagicNumber = 51379;
datetime op;
string per, comment = "cp#";
bool check;
bool ConnectedOk;

struct strTradeInfo
{
   string            a;  // ticket
   string            b;  // symbol
   string            c;  // type
   string            d;  // lots
   string            e;  // openPrice
   string            f;  // tp
   string            g;  // sl
   string            h;  // open time
   string            i;  // comment
};
strTradeInfo strtrd[];

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
int OnInit()
{
//--- create timer
   EventSetMillisecondTimer(500);  // check every 0.5 second
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//--- destroy timer
   EventKillTimer();
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
string ErrorAlert(int error_code)
{
   string error_string;
//----
   switch(error_code)
   {
//---- codes returned from trade server
   case 0:
   case 1:
      error_string = "no error";
      break;
   case 2:
      error_string = "common error";
      break;
   case 3:
      error_string = "invalid trade parameters";
      break;
   case 4:
      error_string = "trade server is busy";
      break;
   case 5:
      error_string = "old version of the client terminal";
      break;
   case 6:
      error_string = "no connection with trade server";
      break;
   case 7:
      error_string = "not enough rights";
      break;
   case 8:
      error_string = "too frequent requests";
      break;
   case 9:
      error_string = "malfunctional trade operation (never returned error)";
      break;
   case 64:
      error_string = "account disabled";
      break;
   case 65:
      error_string = "invalid account";
      break;
   case 128:
      error_string = "trade timeout";
      break;
   case 129:
      error_string = "invalid price";
      break;
   case 130:
      error_string = "invalid ordersend parameter (related to stops point)";
      break;
   case 131:
      error_string = "invalid trade volume";
      break;
   case 132:
      error_string = "market is closed";
      break;
   case 133:
      error_string = "trade is disabled";
      break;
   case 134:
      error_string = "not enough money";
      break;
   case 135:
      error_string = "price changed";
      break;
   case 136:
      error_string = "off quotes";
      break;
   case 137:
      error_string = "broker is busy (never returned error)";
      break;
   case 138:
      error_string = "requote";
      break;
   case 139:
      error_string = "order is locked";
      break;
   case 140:
      error_string = "long positions only allowed";
      break;
   case 141:
      error_string = "too many requests";
      break;
   case 145:
      error_string = "modification denied because order too close to market";
      break;
   case 146:
      error_string = "trade context is busy";
      break;
   case 147:
      error_string = "expirations are denied by broker";
      break;
   case 148:
      error_string = "amount of open and pending orders has reached the limit";
      break;
   case 149:
      error_string = "hedging is prohibited";
      break;
   case 150:
      error_string = "prohibited by FIFO rules";
      break;
//---- mql4 errors
   case 4000:
      error_string = "no error (never generated code)";
      break;
   case 4001:
      error_string = "wrong function pointer";
      break;
   case 4002:
      error_string = "array index is out of range";
      break;
   case 4003:
      error_string = "no memory for function call stack";
      break;
   case 4004:
      error_string = "recursive stack overflow";
      break;
   case 4005:
      error_string = "not enough stack for parameter";
      break;
   case 4006:
      error_string = "no memory for parameter string";
      break;
   case 4007:
      error_string = "no memory for temp string";
      break;
   case 4008:
      error_string = "not initialized string";
      break;
   case 4009:
      error_string = "not initialized string in array";
      break;
   case 4010:
      error_string = "no memory for array\' string";
      break;
   case 4011:
      error_string = "too long string";
      break;
   case 4012:
      error_string = "remainder from zero divide";
      break;
   case 4013:
      error_string = "zero divide";
      break;
   case 4014:
      error_string = "unknown command";
      break;
   case 4015:
      error_string = "wrong jump (never generated error)";
      break;
   case 4016:
      error_string = "not initialized array";
      break;
   case 4017:
      error_string = "dll calls are not allowed";
      break;
   case 4018:
      error_string = "cannot load library";
      break;
   case 4019:
      error_string = "cannot call function";
      break;
   case 4020:
      error_string = "expert function calls are not allowed";
      break;
   case 4021:
      error_string = "not enough memory for temp string returned from function";
      break;
   case 4022:
      error_string = "system is busy (never generated error)";
      break;
   case 4050:
      error_string = "invalid function parameters count";
      break;
   case 4051:
      error_string = "invalid function parameter value";
      break;
   case 4052:
      error_string = "string function internal error";
      break;
   case 4053:
      error_string = "some array error";
      break;
   case 4054:
      error_string = "incorrect series array using";
      break;
   case 4055:
      error_string = "custom indicator error";
      break;
   case 4056:
      error_string = "arrays are incompatible";
      break;
   case 4057:
      error_string = "global variables processing error";
      break;
   case 4058:
      error_string = "global variable not found";
      break;
   case 4059:
      error_string = "function is not allowed in testing mode";
      break;
   case 4060:
      error_string = "function is not confirmed";
      break;
   case 4061:
      error_string = "send mail error";
      break;
   case 4062:
      error_string = "string parameter expected";
      break;
   case 4063:
      error_string = "integer parameter expected";
      break;
   case 4064:
      error_string = "double parameter expected";
      break;
   case 4065:
      error_string = "array as parameter expected";
      break;
   case 4066:
      error_string = "requested history data in update state";
      break;
   case 4099:
      error_string = "end of file";
      break;
   case 4100:
      error_string = "some file error";
      break;
   case 4101:
      error_string = "wrong file name";
      break;
   case 4102:
      error_string = "too many opened files";
      break;
   case 4103:
      error_string = "cannot open file";
      break;
   case 4104:
      error_string = "incompatible access to a file";
      break;
   case 4105:
      error_string = "no order selected";
      break;
   case 4106:
      error_string = "unknown symbol";
      break;
   case 4107:
      error_string = "invalid price parameter for trade function";
      break;
   case 4108:
      error_string = "invalid ticket";
      break;
   case 4109:
      error_string = "trade is not allowed in the expert properties";
      break;
   case 4110:
      error_string = "longs are not allowed in the expert properties";
      break;
   case 4111:
      error_string = "shorts are not allowed in the expert properties";
      break;
   case 4200:
      error_string = "object is already exist";
      break;
   case 4201:
      error_string = "unknown object property";
      break;
   case 4202:
      error_string = "object is not exist";
      break;
   case 4203:
      error_string = "unknown object type";
      break;
   case 4204:
      error_string = "no object name";
      break;
   case 4205:
      error_string = "object coordinates error";
      break;
   case 4206:
      error_string = "no specified subwindow";
      break;
   default:
      error_string = "unknown error";
   }
//----
   return(error_string);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void Post(string trdata)
{
   string jsonBody = LogOpenTradesToJSON(trdata);
   int len = StringLen(jsonBody);
   char jsonbuffer[];
   ArrayResize(jsonbuffer, len);
   for (int i = 0; i < len; i++)
      jsonbuffer[i] = (uchar)StringGetCharacter(jsonBody, i);
   char keybuffer[1024]; // to store name
   StringToCharArray(apiKey, keybuffer);
   char result[];
   string header;
   string header1 = "Content-Type: application/json\r\n";

   int res = WebRequest("POST", ServerURL, NULL, NULL, 5000, jsonbuffer, ArraySize(jsonbuffer), result, header);
   if (res == -1)
   {
      string response = CharArrayToString(result, 0, ArraySize(result));
      string err = "WebRequest failed. Error: " + GetLastError() + " " + response;
      Comment("\nConnection error. " + err);
   }
   else
   {
      if(res == 403) Comment("\nInvalid POST API key.");
      else if(res == 400) Comment("\nInvalid Json.");
      else if(res == 200) Comment("\nServer connected.");
      else Comment("\nServer connected. " + res);
   }
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
string LogOpenTradesToJSON(string trdata)
{

   string json = "{";
   json += "\"apiKey\":\"" + apiKey + "\",";
   json += "\"trades.TC" + IntegerToString(TimeCurrent()) + "\":[";
   json += trdata;
   json += "]}";

   return json;
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
string currentTrades()
{
   string data = "";
   bool first = true;

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() <= 5)
         {
            if (!first) data += ",";  // <-- Add comma between objects
            first = false;
            int otype = -1;
            if(OrderType() == OP_BUY) otype = 0;
            if(OrderType() == OP_SELL) otype = 1;
            if(OrderType() == OP_BUYLIMIT) otype = 2;
            if(OrderType() == OP_BUYSTOP) otype = 3;
            if(OrderType() == OP_SELLLIMIT) otype = 4;
            if(OrderType() == OP_SELLSTOP) otype = 5;
            data += "{";
            data += "\"a\":" + IntegerToString(OrderTicket()) + ",";
            data += "\"b\":\"" + OrderSymbol() + "\",";
            data += "\"c\":" + IntegerToString(otype) + ",";
            data += "\"d\":" + DoubleToString(OrderLots(), 2) + ",";
            data += "\"e\":" + DoubleToString(OrderOpenPrice(), 5) + ",";
            data += "\"f\":" + DoubleToString(OrderTakeProfit(), 5) + ",";
            data += "\"g\":" + DoubleToString(OrderStopLoss(), 5) + ",";
            data += "\"h\":" + IntegerToString(OrderOpenTime()) + ",";
            data += "\"i\":\"" + OrderComment() + "\"";
            data += "}";
         }
      }
   }
   return(data);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void OnTick()
{
//---

}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void OnTimer()
{
//---
   if(Role == Master)
   {
      string tradesdata = currentTrades();
      Post(tradesdata);
   }

   if(Role == Slave)
   {
      Get();
   }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void Get()
{
   int i;
   string cookie = NULL, headers;
   char post[], result[];

   string json = "{";
   json += "\"apiKey\":\"" + apiKey + "\"";
   json += "}";

   int len = StringLen(json);
   ArrayResize(post, len);
   for (i = 0; i < len; i++)
      post[i] = (uchar)StringGetCharacter(json, i);
   string url = ServerURL + "?api_key=" + apiKey;
   int res;
//--- Reset the last error code
   ResetLastError();
   int timeout = 5000;
   res = WebRequest("GET", url, cookie, NULL, timeout, post, 0, result, headers);
//--- Checking errors
   ConnectedOk = false;
   if(res == -1)
   {
      Comment("Not connected. " + GetLastError());
   }
   else
   {
      if(res == 403) Comment("\nAPI Key is not correct");
      else if(res == 404) Comment("\nData not found");
      else
      {
         Comment("\nServer connected");
         ConnectedOk = true;
      }
   }

   string jsondata = CharArrayToString(result);
   int tc1 = StringFind(jsondata, ".TC", 0);
   int tc2 = StringFind(jsondata, ":[{", 0);
   string strtmcur = StringSubstr(jsondata, tc1 + 3, tc2 - (tc1 + 3) - 1);
   string maindata = StringSubstr(jsondata, tc2 + 2, StringLen(jsondata) - (tc2 + 2) - 2);

   string ph1data[];
   string sep1 = "}";
   ushort u_sep1;
   u_sep1 = StringGetCharacter(sep1, 0);
   StringSplit(maindata, u_sep1, ph1data);
   int cnt = ArraySize(ph1data);
   string dispdata = "\n" + strtmcur + "\n\n";

   ArrayFree(strtrd);
   ArrayResize(strtrd, cnt);
   for(i = 0; i < cnt; i++)
   {
      string nowdata = ph1data[i];
      StringReplace(nowdata, ",{", "");
      StringReplace(nowdata, "{", "");

      string ph2data[];
      string sep2 = ",";
      ushort u_sep2;
      u_sep2 = StringGetCharacter(sep2, 0);
      StringSplit(nowdata, u_sep2, ph2data);

      int cnt2 = ArraySize(ph2data);
      for(int j = 0; j < cnt2; j++)
      {
         string jdata = ph2data[j];
         int x1 = StringFind(jdata, ":", 0);
         string nowjdata = StringSubstr(jdata, x1 + 1, 0);
         int y1 = StringFind(nowjdata, "\"", 0);
         if(y1 >= 0)
         {
            nowjdata = StringSubstr(nowjdata, y1 + 1, StringLen(nowjdata) - (y1 + 1) - 1);
         }

         if(j == 0) strtrd[i].a = nowjdata;
         if(j == 1) strtrd[i].b = nowjdata;
         if(j == 2) strtrd[i].c = nowjdata;
         if(j == 3) strtrd[i].d = nowjdata;
         if(j == 4) strtrd[i].e = nowjdata;
         if(j == 5) strtrd[i].f = nowjdata;
         if(j == 6) strtrd[i].g = nowjdata;
         if(j == 7) strtrd[i].h = nowjdata;
         if(j == 8) strtrd[i].i = nowjdata;
      }
   }
   for(i = 0; i < cnt; i++)
   {
      string presym = strtrd[i].b;
      string sym = Prefix + presym + Suffix;
      int tick = StringToInteger(strtrd[i].a);
      int type = StringToInteger(strtrd[i].c);
      double size = StringToDouble(strtrd[i].d);
      double openprc = StringToDouble(strtrd[i].e);
      double takeprofit = StringToDouble(strtrd[i].f);
      double stoploss = StringToDouble(strtrd[i].g);
      string xcomm = strtrd[i].i;
      if(presym != "" && SymbolExists(sym) && tick > 0)
      {
         if(StringToInteger(strtmcur) - StringToInteger(strtrd[i].h) <= 5)
         {
            if(isDone(tick)) continue;
            if(openprc <= 0.0) continue;

            if(type == 0)
            {
               buy(sym, size, stoploss, takeprofit, tick);
            }
            if(type == 1)
            {
               sell(sym, size, stoploss, takeprofit, tick);
            }
            if(type == 2)
            {
               buylim(sym, openprc, size, stoploss, takeprofit, tick);
            }
            if(type == 3)
            {
               buystop(sym, openprc, size, stoploss, takeprofit, tick);
            }
            if(type == 4)
            {
               selllim(sym, openprc, size, stoploss, takeprofit, tick);
            }
            if(type == 5)
            {
               sellstop(sym, openprc, size, stoploss, takeprofit, tick);
            }
         }

         if(openprc > 0) checkmod(i, openprc, stoploss, takeprofit);
      }
   }

   string disp = "\n";
   for(int m = OrdersTotal() - 1; m >= 0; m--)
   {
      check = OrderSelect(m, SELECT_BY_POS, MODE_TRADES);
      if(OrderMagicNumber() == MagicNumber)
      {
         bool adamasih = mshAda(OrderComment());
         disp += OrderComment() + "  " + adamasih + "\n";
         if(!adamasih && ConnectedOk)
         {
            double askk = MarketInfo(OrderSymbol(), MODE_ASK);
            double bidd = MarketInfo(OrderSymbol(), MODE_BID);

            if(OrderType() <= 1)
            {
               check = OrderClose(OrderTicket(), OrderLots(), OrderOpenPrice(), slippage, 0);
            }
            else
            {
               check = OrderDelete(OrderTicket());
            }
         }
      }
   }

}
bool mshAda(string xcomm)
{
   bool masih = false;
   int xcnt = ArraySize(strtrd);

   for(int h = 0; h < xcnt; h++)
   {
      int tick = StringToInteger(strtrd[h].a);
      if(StringFind(xcomm, (string)tick, 0) >= 0 && tick > 0)
      {
         masih = true;
         break;
      }
   }

   return(masih);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void checkmod(int r, double opprc, double mastersl, double mastertp)
{
   int m = 0;
   for(m = OrdersTotal() - 1; m >= 0; m--)
   {
      check = OrderSelect(m, SELECT_BY_POS, MODE_TRADES);
      if(OrderMagicNumber() == MagicNumber)
      {
         if(StringFind(OrderComment(), "#" + strtrd[r].a) >= 0)
         {
            if(OrderTakeProfit() != mastertp || OrderStopLoss() != mastersl)
            {
               check = OrderModify(OrderTicket(), OrderOpenPrice(), mastersl, mastertp, 0, 0);
            }
            if(OrderType() > 1)
            {
               double openprc = StringToDouble(strtrd[r].e);
               if(OrderOpenPrice() != openprc)
               {
                  check = OrderModify(OrderTicket(), openprc, OrderStopLoss(), OrderTakeProfit(), 0, 0);
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool SymbolExists(string symbol)
{
   if(MarketInfo(symbol, MODE_BID) <= 0)
      return false;
   else
      return true;
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool isDone(int tick)
{
   bool done = false;
   int kd = 0;
   for(kd = OrdersTotal() - 1; kd >= 0; kd--)
   {
      check = OrderSelect(kd, SELECT_BY_POS, MODE_TRADES);
      if(OrderMagicNumber() == MagicNumber)
      {
         if(StringFind(OrderComment(), "#" + (string)tick) >= 0)
         {
            done = true;
            break;
         }
      }
   }

   return(done);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void buy(string Sym, double Lots, double SL, double TP, int tick)
{
   double askk = MarketInfo(Sym, MODE_ASK);
   int ticket;
   RefreshRates();
   ticket = OrderSend(Sym, OP_BUY, Lots, askk, slippage, SL, TP, comment + (string)tick, MagicNumber, 0, Blue);
   if(ticket > 0)
   {
      op = Time[0];
      return;
   }
   else
   {
      Alert("Error \"" + ErrorAlert(GetLastError()) + "\" on copy a buy order on " + Sym + " #" + (string)tick + ")");
      Print(Sym, "  ", Lots, "  ", SL, "  ", TP, "  ", tick);
   }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void buystop(string Sym, double plc, double Lots, double SL, double TP, int tick)
{
   int ticket;
   RefreshRates();
   ticket = OrderSend(Sym, OP_BUYSTOP, Lots, plc, slippage, SL, TP, comment + (string)tick, MagicNumber, 0, Blue);
   if(ticket > 0)
   {
      op = Time[0];
      return;
   }
   else
   {
      Alert("Error \"" + ErrorAlert(GetLastError()) + "\" on copy a buy stop order on " + Sym + " #" + (string)tick + ")");
      Print(Sym, "  ", plc, "  ", Lots, "  ", SL, "  ", TP, "  ", tick);
   }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void buylim(string Sym, double plc, double Lots, double SL, double TP, int tick)
{
   int ticket;
   RefreshRates();
   ticket = OrderSend(Sym, OP_BUYLIMIT, Lots, plc, slippage, SL, TP, comment + (string)tick, MagicNumber, 0, Blue);
   if(ticket > 0)
   {
      op = Time[0];
      return;
   }
   else
   {
      Alert("Error \"" + ErrorAlert(GetLastError()) + "\" on copy a buy limit order on " + Sym + " #" + (string)tick + ")");
      Print(Sym, "  ", plc, "  ", Lots, "  ", SL, "  ", TP, "  ", tick);
   }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void sell(string Sym, double Lots, double SL, double TP, int tick)
{
   double bidd = MarketInfo(Sym, MODE_BID);
   int ticket;
   RefreshRates();
   ticket = OrderSend(Sym, OP_SELL, Lots, bidd, slippage, SL, TP, comment + (string)tick, MagicNumber, 0, Red);
   if(ticket > 0)
   {
      op = Time[0];
      return;
   }
   else
   {
      Alert("Error \"" + ErrorAlert(GetLastError()) + "\" on copy a sell order on " + Sym + " #" + (string)tick + ")");
      Print(Sym, "  ", Lots, "  ", SL, "  ", TP, "  ", tick);
   }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void sellstop(string Sym, double plc, double Lots, double SL, double TP, int tick)
{
   int ticket;
   RefreshRates();
   ticket = OrderSend(Sym, OP_SELLSTOP, Lots, plc, slippage, SL, TP, comment + (string)tick, MagicNumber, 0, Red);
   if(ticket > 0)
   {
      op = Time[0];
      return;
   }
   else
   {
      Alert("Error \"" + ErrorAlert(GetLastError()) + "\" on copy a sell stop order on " + Sym + " #" + (string)tick + ")");
      Print(Sym, "  ", plc, "  ", Lots, "  ", SL, "  ", TP, "  ", tick);
   }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void selllim(string Sym, double plc, double Lots, double SL, double TP, int tick)
{
   int ticket;
   RefreshRates();
   ticket = OrderSend(Sym, OP_SELLLIMIT, Lots, plc, slippage, SL, TP, comment + (string)tick, MagicNumber, 0, Red);
   if(ticket > 0)
   {
      op = Time[0];
      return;
   }
   else
   {
      Alert("Error \"" + ErrorAlert(GetLastError()) + "\" on copy a sell limit order on " + Sym + " #" + (string)tick + ")");
      Print(Sym, "  ", plc, "  ", Lots, "  ", SL, "  ", TP, "  ", tick);
   }
}
//+------------------------------------------------------------------+
