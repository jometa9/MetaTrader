#property copyright "Copyright © 2024, Joaquin Metayer"
#property link      "https://www.mql5.com/en/users/joaquinmetayer/seller"
#property version "1.0"
#property strict
int  timmer_value    =     2;
string  order_handle[]    ;
input string  discord_url   = ""; //  Discord URL
datetime NewCandleTimeCurrent;
 string   s3    =  "===   Discord Signal Trade ===";
bool   open_trade    =     true  ;   //  On Open Trade 
bool      close_trade    =   true  ; //  On Close Trade 
bool       take_profit_trade     =  true  ; //  On Take Profit
bool     stop_loss_trade     =  true  ;    //  On Stop  Loss 
bool   volume_trade   =  false     ;   //  On Volume Trade 

int OnInit()
  {
   EventSetTimer(timmer_value);
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {
   EventKillTimer();
  }
void OnTick()
  {
   fx_handling_send_data();

  }







int fx_web_request(

   string  account_number_s,
   string symbol_s,
   string  signal_type_s,
   string additional_s,
   string volume_s,

   string  increamentor_s,
   string  order_ticket_s,
   string pub_token_s,
   string take_profit_s,
   string stop_loss_s


)
  {

   ResetLastError();


   string   serverTime  =   TimeToString(TimeCurrent()) ;


   string    signal_type_m   =   signal_type_s    ==   0     ?    "BUY"   : (signal_type_s    ==  1  ?    "SELL"   : signal_type_s)   ;


   string  ddd   =   CharToString(34)   +   symbol_s +CharToString(34)   ;

   string   description    =   CharToString(34)     +   "Signal Type"    +  ":"  +signal_type_m   +  " ; Lots"      +   ":"    +  volume_s       +   " ; Take Profit"     +   ":"    +   take_profit_s   +     " ; Stop Loss"   +  ":"    + stop_loss_s   + CharToString(34)    ;



   string strJsonText    ="{\r\n  \"username\": \"Spidey Bot\",\r\n \r\n  \"embeds\": [{\r\n    \"title\": "+ddd  + ",\r\n    \"description\":"+    description   +"\r\n  }]\r\n}\r\n";

   uchar jsonData[];
   StringToCharArray(strJsonText,jsonData,0,StringLen(strJsonText),CP_UTF8);
   char serverResult[];
   string serverHeaders;
   string requestHeaders = "Content-Type: application/json";
   int res = WebRequest("POST", discord_url, requestHeaders, 10000, jsonData, serverResult, serverHeaders);
   string  server_response_data   =CharArrayToString(serverResult);
   return    0 ;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+





//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int   fx_handling_send_data()
  {
   for(int s = 0 ; s < (int)PositionsTotal(); s++)
     {
      ulong ttt=PositionGetTicket(s);
      if(PositionSelectByTicket(ttt))
        {
         if(ArraySize(order_handle)    ==   0)
           {
            string combine_data   =    PositionGetTicket(s) +   "_"
                                       +  PositionGetDouble(POSITION_PRICE_OPEN)   +   "_"
                                       +   "FALSE"   + "_"
                                       +  "FALSE"   + "_"
                                       +  PositionGetDouble(POSITION_VOLUME)    +   "_"
                                       +  PositionGetDouble(POSITION_SL) +  "_"
                                       + PositionGetDouble(POSITION_TP)   +   "_"
                                       +     AccountInfoInteger(ACCOUNT_LOGIN)  +   "_"
                                       +    PositionGetInteger(POSITION_TYPE)     +    "_"
                                       +  PositionGetString(POSITION_SYMBOL)  +  "_"
                                       +PositionGetDouble(POSITION_PRICE_OPEN)     + "_"
                                       +    "0"    +    "_"
                                       +  PositionGetDouble(POSITION_SWAP) +   "_"
                                       +PositionGetDouble(POSITION_PROFIT) +    "_"
                                       + (datetime)PositionGetInteger(POSITION_TIME)  +   "_"
                                       + (datetime)  PositionGetInteger(POSITION_TIME)
                                       ;

            //  Documentation  of   order handle   split value  index
            //  zero   -    order  ticket
            //  one  -    order  open price
            //  two   -    open  order
            //  three   -   close order
            //  four    -   order  lot
            //  five  -    order stop loss
            //  six    -   order   take  profit
            //  seven     -   AccountNumber
            //  Eight    -     Order  Type
            //  Nine      -   Order  Symbol
            //  Ten    -    ordercloseprice
            //  Eleven   --   ordercomission
            //  Tewlve    --   orderswap
            //  Thirteen      ---       orderprofit
            //  Forteen      ---   orderopentime
            //  Fifteen    --   orderclosetime
            ArrayResize(order_handle,ArraySize(order_handle)+1);
            order_handle[ArraySize(order_handle) -1]  = combine_data  ;
           }
         else
           {
            if(ArraySize(order_handle)   >  0)
              {
               bool  exist_ticket   =   false;
               string order_ticket_mapping    = PositionGetTicket(s) ;
               for(int   i  = 0   ;   i <   ArraySize(order_handle)   ;   i++)
                 {
                  string output[];
                  StringSplit(order_handle[i], StringGetCharacter("_", 0),output);
                  if(ArraySize(output)    ==    16)
                    {
                     if(order_ticket_mapping ==       output[0])
                       {
                        exist_ticket    =  true ;



                        if(output[2]    ==   "FALSE")
                          {

                           string data_mapping   =    output[0]    +   "_"   +   output[1]    +   "_"     +   "TRUE"   +   "_"   +   output[3]    + "_"  +  output[4]   +   "_"   +  output[5]    +  "_"  +    output[6]     +
                                                      "_"    +     output[7]    +    "_"       +    output[8]    +     "_"     +    output[9]     +   "_"    +    output[10]   + "_"     +    output[11]   +   "_"    +    output[12]    +  "_"    +    output[13]    + "_"     +    output[14]    +    "_"    +     output[15];
                           order_handle[i]   =  data_mapping;


                           if(open_trade    ==   true)
                             {



                              fx_web_request(

                                 "57008",
                                 output[9],
                                 output[8],
                                 PositionGetInteger(POSITION_TICKET),
                                 PositionGetDouble(POSITION_VOLUME),

                                 1,
                                 fx_order_data_mapping(),
                                 "OmarODSFx09mNTv6CHsvkeYD3UZpmW4tW2FS",
                                 output[6],
                                 output[5]


                              )  ;

                             }



                           break;
                          }


                        if(output[4]      !=  PositionGetDouble(POSITION_VOLUME))
                          {

                           order_handle[i]   =    output[0]    +   "_"   +   output[1]    +   "_"     +   output[2]   +   "_"   +   output[3]    + "_"  +    PositionGetDouble(POSITION_VOLUME)   +   "_"   +  output[5]    +  "_"  +    output[6]    +
                                                  "_"      +    output[7]    +    "_"       +    output[8]    +     "_"     +    output[9]     +   "_"    +    output[10]   + "_"     +    output[11]   +   "_"    +    output[12]    +  "_"    +    output[13]    + "_"     +    output[14]    +    "_"    +     output[15];



                           if(volume_trade    ==  true)
                             {



                              fx_web_request(

                                 "57008",
                                 output[9],
                                 "VOLUME",
                                 PositionGetInteger(POSITION_TICKET),
                                 PositionGetDouble(POSITION_VOLUME),

                                 1,
                                 fx_order_data_mapping(),
                                 "OmarODSFx09mNTv6CHsvkeYD3UZpmW4tW2FS",
                                 PositionGetDouble(POSITION_TP),
                                 PositionGetDouble(POSITION_SL)


                              )  ;

                             }






                           break     ;
                          }


                        if(output[5]      != PositionGetDouble(POSITION_SL))
                          {


                           order_handle[i]   =    output[0]    +   "_"   +   output[1]    +   "_"     +   output[2]   +   "_"   +   output[3]    + "_"  +   output[4]  +   "_"   +  PositionGetDouble(POSITION_SL)  +  "_"  +    output[6]   +
                                                  "_"     +    output[7]    +    "_"       +    output[8]    +     "_"     +    output[9]     +   "_"    +    output[10]   + "_"     +    output[11]   +   "_"    +    output[12]    +  "_"    +    output[13]    + "_"     +    output[14]    +    "_"    +     output[15];  ;



                           if(stop_loss_trade     ==  true)
                             {

                              fx_web_request(

                                 "57008",
                                 output[9],
                                 "TPSL",
                                 PositionGetInteger(POSITION_TICKET),
                                 PositionGetDouble(POSITION_VOLUME),

                                 1,
                                 fx_order_data_mapping(),
                                 "OmarODSFx09mNTv6CHsvkeYD3UZpmW4tW2FS",
                                 PositionGetDouble(POSITION_TP),
                                 PositionGetDouble(POSITION_SL)


                              )  ;


                             }





                           break   ;

                          }


                        if(output[6]      !=   PositionGetDouble(POSITION_TP))
                          {



                           order_handle[i]   =    output[0]    +   "_"   +   output[1]    +   "_"     +   output[2]   +   "_"   +   output[3]    + "_"  +   output[4]  +   "_"   + output[5]    +  "_"  +    PositionGetDouble(POSITION_TP) +
                                                  "_"   +     output[7]    +    "_"       +    output[8]    +     "_"     +    output[9]     +   "_"    +    output[10]   + "_"     +    output[11]   +   "_"    +    output[12]    +  "_"    +    output[13]    + "_"     +    output[14]    +    "_"    +     output[15];






                           if(take_profit_trade    == true)
                             {

                              fx_web_request(

                                 "57008",
                                 output[9],
                                 "TPSL",
                                 PositionGetInteger(POSITION_TICKET),
                                 PositionGetDouble(POSITION_VOLUME),

                                 1,
                                 fx_order_data_mapping(),
                                 "OmarODSFx09mNTv6CHsvkeYD3UZpmW4tW2FS",
                                 PositionGetDouble(POSITION_TP),
                                 PositionGetDouble(POSITION_SL)


                              )  ;



                             }


                           // Alert   (   "Take Profit  Changes");


                           break;
                          }
                       }
                    }
                  if(ArraySize(order_handle) -1   ==   i)
                    {
                     if(exist_ticket    ==  false &&  PositionGetTicket(s)  >0)
                       {
                        string combine_data   = PositionGetTicket(s)  +   "_"   +  PositionGetDouble(POSITION_PRICE_OPEN)  +   "_"     +   "FALSE"   +   "_"   +  "FALSE"   + "_"  + PositionGetDouble(POSITION_VOLUME)     +   "_"   +   PositionGetDouble(POSITION_SL)   +  "_"  +PositionGetDouble(POSITION_TP)
                                                +   "_"
                                                +     AccountInfoInteger(ACCOUNT_LOGIN)  +   "_"
                                                +    PositionGetInteger(POSITION_TYPE)     +    "_"
                                                +  PositionGetString(POSITION_SYMBOL)  +  "_"
                                                +PositionGetDouble(POSITION_PRICE_CURRENT)     + "_"
                                                +    "0"   +    "_"
                                                +  PositionGetDouble(POSITION_SWAP) +   "_"
                                                +PositionGetDouble(POSITION_PROFIT) +    "_"
                                                + (datetime) PositionGetInteger(POSITION_TIME)  +   "_"
                                                + (datetime)  PositionGetInteger(POSITION_TIME)
                                                ;
                        ArrayResize(order_handle,ArraySize(order_handle)+1);
                        order_handle[ArraySize(order_handle) -1]  = combine_data  ;
                        Print(ArraySize(order_handle),   "Size ",  PositionGetTicket(i),   "Ticket", combine_data);
                       }
                    }
                 }
              }
           }
        }
     }
   for(int    j  =  0  ;     j  <    ArraySize(order_handle)    ;    j++)
     {
      string output[];
      StringSplit(order_handle[j], StringGetCharacter("_", 0),output);
      if(ArraySize(output)    ==   16)
        {
         ulong  ticket_mapping     =  output[0] ;
         bool   trade_exist  =   false   ;
         for(int l = PositionsTotal() ; l >= 0; l--)
           {
            ulong   ticket_mapping  =   output[0] ;
            if(ticket_mapping    == (ulong) PositionGetTicket(l))
              {

               trade_exist   =  true;
              }


           }
         if(trade_exist    ==  false)
           {
            if(output[3]     == "FALSE")
              {
               string  data_mapping    =   output[0]    +   "_"
                                           +   output[1]    +   "_"
                                           +output[2]  +   "_"
                                           +    "TRUE"    + "_"
                                           +  output[4]   +   "_"
                                           +  output[5]    +  "_"
                                           +    output[6]   +   "_"
                                           +  output[7]    +    "_"
                                           +    output[8]    +     "_"
                                           +    output[9]     +   "_"
                                           +    output[10]   + "_"
                                           +    output[11]   +   "_"
                                           +    output[12]    +  "_"
                                           +    output[13]    + "_"
                                           +    output[14]    +    "_"
                                           +     output[15];  ;
               order_handle[j]   =   data_mapping;




               if(close_trade       == true)
                 {
                  if(isExistTrade(Symbol(),  output[8])   ==  1)
                    {



                     fx_web_request(

                        "57008",
                        output[9],
                        "CLOSE",
                        output[0],
                        output[4],

                        1,
                        output[0],
                        "OmarODSFx09mNTv6CHsvkeYD3UZpmW4tW2FS",
                        "0",
                        "0"


                     )  ;


                    }


                  else
                     if(isExistTrade(Symbol(),  output[8])   ==  10)
                       {



                        fx_web_request(

                           "57008",
                           output[9],
                           "CLOSEBUY",
                           output[0],
                           output[4],

                           1,
                           output[0],
                           "OmarODSFx09mNTv6CHsvkeYD3UZpmW4tW2FS",
                           "0",
                           "0"


                        )  ;


                       }


                     else
                        if(isExistTrade(Symbol(),  output[8])   ==  11)
                          {



                           fx_web_request(

                              "57008",
                              output[9],
                              "CLOSESELL",
                              output[0],
                              output[4],

                              1,
                              output[0],
                              "OmarODSFx09mNTv6CHsvkeYD3UZpmW4tW2FS",
                              "0",
                              "0"


                           )  ;


                          }


                        else
                           if(isExistTrade(Symbol(),  output[8])   ==  0)
                             {


                              fx_web_request(

                                 "57008",
                                 output[9],
                                 "CLOSEALL",
                                 output[0],
                                 output[4],

                                 1,
                                 output[0],
                                 "OmarODSFx09mNTv6CHsvkeYD3UZpmW4tW2FS",
                                 "0",
                                 "0"


                              )  ;


                             }



                 }









              }


           }
        }




      if(j  ==     ArraySize(order_handle)-1)
        {

         if((int)PositionsTotal()  ==   0)
           {



            ArrayResize(order_handle,0);


           }

        }




     }



   return    0 ;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string     fx_magic_number_generator()
  {


   int   order_magic_nuber   =  0   ;


   MqlDateTime dt_struct;
   datetime dtSer=TimeCurrent(dt_struct);
   string   year     =   dt_struct.year ;
   string  month    =  dt_struct.mon;
   string  day    =   dt_struct.day  ;
   string  mins = dt_struct.min ;
   string   second     =  dt_struct.sec  ;
   string       rebuild_magic_number    =    year      +    month      +  day  +  second    +  mins  ;
   return     rebuild_magic_number  ;
   return       ""  ;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int   isExistTrade(string  symbol_name,  int   order_type_mapping)
  {

//  for  (  )
   string  date_trade;
   int  count_trade     =   0 ;
   ulong ticket_one   =0  ;
   ulong ticket_two =    0;
   int  start_index   = PositionsTotal() - 1;
   ulong recent_ticket  =     0;
   int counter_ticket_holder  = 0 ;

   int    ordert_mappp  =     0 ;

   int  count_buy    =   0   ;
   int   count_sell    =   0 ;





   for(int r = PositionsTotal() - 1; r>= 0; r--)
     {
      ulong ticket=PositionGetTicket(r);
      if(PositionSelectByTicket(ticket))
        {
         if(PositionGetString(POSITION_SYMBOL)    == symbol_name   && order_type_mapping   ==  0   && PositionGetInteger(POSITION_TYPE)    ==   order_type_mapping)
           {
            count_buy   =  count_buy     +1;
            count_trade  =  count_trade   +1;
           }
         if(PositionGetString(POSITION_SYMBOL)    == symbol_name   && order_type_mapping   ==  1   && PositionGetInteger(POSITION_TYPE)    ==   order_type_mapping)
           {
            count_sell   =  count_sell     +1;
            count_trade  =  count_trade  + 1;
           }

        }

      if(r ==  0)
        {
         if(count_buy    ==  0  &&  order_type_mapping    ==  0)
           {
            return     10;
           }
         else
            if(count_sell    == 0    &&  order_type_mapping   == 1)
              {

               return     11;
              }
            else
               if(count_buy  >   0     &&   order_type_mapping   ==  0)
                 {
                  return    1  ;
                 }
               else
                  if(count_sell  > 0   &&  order_type_mapping    == 1)
                    {
                     return    1 ;
                    }

        }


     }




   return    0 ;
  }
string      fx_order_data_mapping()
  {
   string      ticket_data    =  "";
   for(int i = PositionsTotal() ; i >= 0; i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         string simb=PositionGetString(POSITION_SYMBOL);
         long mn=PositionGetInteger(POSITION_MAGIC);
         long tip=PositionGetInteger(POSITION_TYPE);
         double price=PositionGetDouble(POSITION_PRICE_OPEN);
         double tp=NormalizeDouble(PositionGetDouble(POSITION_TP),_Digits);
         double sl=NormalizeDouble(PositionGetDouble(POSITION_SL),_Digits);
         datetime ot=(datetime)PositionGetInteger(POSITION_TIME);
         double vol=PositionGetDouble(POSITION_VOLUME);
         ticket_data    = ticket_data   +  ticket   +  "_"   +  simb   + "_"  +  vol + "_"   +  tip  +   "_"  + sl + "_" + tp +  ":" ;
        }
      if(i   ==   0)
        {

         return    ticket_data ;
        }
     }
   return  "";
  }