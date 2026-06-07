//+------------------------------------------------------------------+
//|                         LotCalc                                  |
//|                  Minimal lot calculator for MT5                  |
//+------------------------------------------------------------------+
#property copyright   ""
#property version     "1.00"
#property description "Click RISK$ -> click entry -> click SL -> shows lot size."
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

// ====================================================================
// INPUTS
// ====================================================================
input double InpRiskMoney  = 100.0;        // Risk amount ($)
input color  InpFollowCol  = clrGold;      // Follower line color
input color  InpEntryCol   = clrDodgerBlue; // Entry line color
input color  InpSLCol      = clrRed;       // Stop-loss line color
input int    InpPanelX     = 0;            // Panel X from corner (px)
input int    InpPanelY     = 85;           // Panel Y from corner (px)
input int    InpPanelW     = 190;          // Panel width (px)

// ====================================================================
// CONSTANTS
// ====================================================================
const string PFX             = "LC_";
const string BTN_RISK        = PFX + "btn_risk";
const string LBL_RESULT      = PFX + "lbl_result";
const string LINE_FOLLOW     = PFX + "line_follow";
const string LINE_ENTRY      = PFX + "line_entry";
const string LINE_SL         = PFX + "line_sl";

#define STATE_IDLE       0
#define STATE_AWAIT_ENTRY 1
#define STATE_AWAIT_SL   2

// ====================================================================
// GLOBALS
// ====================================================================
int    g_state         = STATE_IDLE;
double g_entry         = 0.0;
double g_lastLot       = 0.0;
uint   g_startMs       = 0;
uint   g_entryMs       = 0;

// ====================================================================
// LIFECYCLE
// ====================================================================
int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, "LotCalc");
   Cleanup();
   CreatePanel();
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
   ChartRedraw();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
   Cleanup();
   ChartRedraw();
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int      &spread[])
{
   return rates_total;
}

void OnChartEvent(const int    id,
                  const long   &lparam,
                  const double &dparam,
                  const string &sparam)
{
   // ESC cancela siempre
   if(id == CHARTEVENT_KEYDOWN && (int)lparam == 27)
   {
      Cancel();
      return;
   }

   // Mouse move -> follower line
   if(id == CHARTEVENT_MOUSE_MOVE && g_state != STATE_IDLE)
   {
      datetime t; double price; int sub;
      if(ChartXYToTimePrice(0, (int)lparam, (int)dparam, sub, t, price))
         DrawHLine(LINE_FOLLOW, price, InpFollowCol, STYLE_DOT, 2);
      ChartRedraw();
      return;
   }

   // Click en el chart -> captura entry / SL
   if(id == CHARTEVENT_CLICK && g_state != STATE_IDLE)
   {
      if(g_state == STATE_AWAIT_ENTRY && GetTickCount() - g_startMs < 200) return;
      if(g_state == STATE_AWAIT_SL    && GetTickCount() - g_entryMs  < 200) return;

      datetime t; double price; int sub;
      if(!ChartXYToTimePrice(0, (int)lparam, (int)dparam, sub, t, price)) return;

      if(g_state == STATE_AWAIT_ENTRY)
      {
         g_entry  = price;
         g_entryMs = GetTickCount();
         DrawHLine(LINE_ENTRY, price, InpEntryCol, STYLE_SOLID, 2);
         g_state = STATE_AWAIT_SL;
         SetLabel("STOP");
      }
      else if(g_state == STATE_AWAIT_SL)
      {
         double sl  = price;
         DrawHLine(LINE_SL, sl, InpSLCol, STYLE_SOLID, 2);

         double lot = CalcLot(g_entry, sl, InpRiskMoney);
         g_lastLot  = lot;
         double pts = MathAbs(g_entry - sl) / _Point;
         SetLabel(StringFormat("%.2f", lot));

         g_state = STATE_IDLE;
         ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
         ClearLines();
      }
      ChartRedraw();
      return;
   }

   // Click en el boton RISK$
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == BTN_RISK)
   {
      ObjectSetInteger(0, BTN_RISK, OBJPROP_STATE, false);
      if(g_state != STATE_IDLE) { Cancel(); return; }
      StartMeasure();
      return;
   }

   // Click en el label resultado -> reset
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == LBL_RESULT)
   {
      ObjectSetInteger(0, LBL_RESULT, OBJPROP_STATE, false);
      g_lastLot = 0;
      ClearLines();
      Cancel();
      return;
   }
}

// ====================================================================
// LOGICA
// ====================================================================
void StartMeasure()
{
   g_state    = STATE_AWAIT_ENTRY;
   g_entry    = 0;
   g_startMs  = GetTickCount();
   ClearLines();
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid > 0) DrawHLine(LINE_FOLLOW, bid, InpFollowCol, STYLE_DOT, 2);
   SetLabel("ENTRY");
   ChartRedraw();
}

void Cancel()
{
   g_state = STATE_IDLE;
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
   if(ObjectFind(0, LINE_FOLLOW) >= 0) ObjectDelete(0, LINE_FOLLOW);
   SetLabel(g_lastLot > 0 ? StringFormat("%.2f", g_lastLot) : "-");
   ChartRedraw();
}

double CalcLot(double entry, double sl, double riskMoney)
{
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double dist     = MathAbs(entry - sl);
   if(tickVal <= 0 || tickSize <= 0 || dist <= 0) return 0.0;
   double lossPerLot = (dist / tickSize) * tickVal;
   if(lossPerLot <= 0) return 0.0;

   double vmin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double vstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double lot   = riskMoney / lossPerLot;
   if(vstep > 0) lot = MathFloor(lot / vstep) * vstep;
   lot = MathMax(vmin, MathMin(vmax, lot));
   return lot;
}

// ====================================================================
// UI
// ====================================================================
int BtnH() { return InpPanelW / 5; }

void CreatePanel()
{
   // Boton RISK$
   MakeBtn(BTN_RISK,
           StringFormat("$%.0f", InpRiskMoney),
           InpPanelX, InpPanelY,
           InpPanelW, BtnH(),
           C'40,90,140', clrWhite, 10);

   // Label resultado
   MakeBtn(LBL_RESULT,
           "-",
           InpPanelX, InpPanelY + BtnH() + 3,
           InpPanelW, BtnH(),
           C'25,25,25', clrWhite, 12);
}

void MakeBtn(string name, string text,
             int x, int y, int w, int h,
             color bg, color fg, int fontSize)
{
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER,       CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,    x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,    y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,        w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,        h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,      bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR,        fg);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,     fontSize);
   ObjectSetString (0, name, OBJPROP_FONT,         "Arial Bold");
   ObjectSetString (0, name, OBJPROP_TEXT,         text);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrDimGray);
   ObjectSetInteger(0, name, OBJPROP_BACK,         false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,   false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,       true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER,       1000);
}

void SetLabel(string text)
{
   if(ObjectFind(0, LBL_RESULT) >= 0)
      ObjectSetString(0, LBL_RESULT, OBJPROP_TEXT, text);
}

void DrawHLine(string name, double price, color clr, ENUM_LINE_STYLE style, int width)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetDouble (0, name, OBJPROP_PRICE,      price);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE,      style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      width);
   ObjectSetInteger(0, name, OBJPROP_BACK,       true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
}

void ClearLines()
{
   if(ObjectFind(0, LINE_FOLLOW) >= 0) ObjectDelete(0, LINE_FOLLOW);
   if(ObjectFind(0, LINE_ENTRY ) >= 0) ObjectDelete(0, LINE_ENTRY );
   if(ObjectFind(0, LINE_SL    ) >= 0) ObjectDelete(0, LINE_SL    );
}

void Cleanup()
{
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--)
   {
      string n = ObjectName(0, i, -1, -1);
      if(StringFind(n, PFX) == 0) ObjectDelete(0, n);
   }
}