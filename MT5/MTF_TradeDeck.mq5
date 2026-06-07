//+------------------------------------------------------------------+
//|                         MTF TradeDeck                            |
//|                       Custom Indicator for MT5                   |
//+------------------------------------------------------------------+
#property copyright   ""
#property version     "1.00"
#property description "Multi-timeframe trading dashboard: right-side MTF"
#property description "candles, trend/H-line cross alerts, session boxes,"
#property description "symbol switcher, lot calculator and PnL panel."
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

// ====================================================================
// INPUTS
// ====================================================================
input group "Layout"
input int InpGap         = 10;  // Offset from last bar (bars)
input int InpCandleW     = 1;   // Candle body width (bars) - match chart bar density
input int InpCandleSpace = 0;   // Spacing between candles (bars) - match chart bar density
input int InpGroupSpace  = 5;   // Spacing between groups

input group "Timeframes (up to 5)"
input bool             InpTF1En = true;
input ENUM_TIMEFRAMES  InpTF1   = PERIOD_M5;
input int              InpTF1N  = 60;   // Candles for TF1

input bool             InpTF2En = true;
input ENUM_TIMEFRAMES  InpTF2   = PERIOD_M15;
input int              InpTF2N  = 60;   // Candles for TF2

input bool             InpTF3En = true;
input ENUM_TIMEFRAMES  InpTF3   = PERIOD_H1;
input int              InpTF3N  = 60;   // Candles for TF3

input bool             InpTF4En = true;
input ENUM_TIMEFRAMES  InpTF4   = PERIOD_H4;
input int              InpTF4N  = 60;   // Candles for TF4

input bool             InpTF5En = false;
input ENUM_TIMEFRAMES  InpTF5   = PERIOD_D1;
input int              InpTF5N  = 60;   // Candles for TF5

input group "Style"
input color  InpBullCol      = clrWhite;    // Bull candle body color
input color  InpBearCol      = clrBlack;    // Bear candle body color
input color  InpWickCol      = clrBlack;    // Wick & border color
input color  InpLabelCol     = clrSilver;   // TF label color
input bool   InpScaleToChart = true;        // Stretch each group to fill chart height
input double InpScaleMargin  = 0.05;        // Top/bottom margin (0.0 - 0.4)

input group "Alert"
input string InpAlertSound = "alert.wav";  // Sound file (in MT5 Sounds folder)

input group "Panel Sizing (single source of truth)"
input int              InpPanelW         = 343;    // Total panel width (px) - all button widths/heights derived from this
input int              InpSymBtnSpacing  = 3;      // Spacing between buttons (px)

input group "Alert Button - standalone position (used only when symbol bar is OFF)"
input ENUM_BASE_CORNER InpBtnCorner = CORNER_LEFT_LOWER;  // Corner anchor
input int InpBtnX = 12;   // X distance from corner (px)
input int InpBtnY = 30;   // Y distance from corner (px)

input group "Symbol Bar (from Market Watch)"
input bool             InpShowSymBar     = true;   // Show symbol switcher row
input ENUM_BASE_CORNER InpSymBarCorner   = CORNER_LEFT_UPPER;
input int              InpSymBarX        = 0;      // X distance (px) - 0 = flush with chart edge
input int              InpSymBarY        = 150;    // Y distance (px) - leaves room for MT5 trade panel
input int              InpSymMaxCount    = 20;     // Max symbols to show
input color            InpSymBtnBg       = C'55,65,75';     // Inactive symbol bg (slate) - distinct from alert/risk/PnL
input color            InpSymBtnBgActive = C'200,140,30';   // Active symbol bg (amber) - distinct from alert green
input color            InpSymBtnText     = clrWhite;

input group "Lot Calculator"
input bool   InpLotCalcEnabled = true;          // Enable lot calculator panel
input double InpRiskPercent    = 1.0;           // Risk % of balance (RISK% button)
input double InpRiskMoney      = 100.0;         // Risk fixed money (RISK$ button, account ccy)
input color  InpLotBtnBg       = C'40,90,140';  // Lot button background
input color  InpLotBtnText     = clrWhite;      // Lot button text
input color  InpRiskFollowCol  = clrGold;       // Color of the line that follows the mouse
input color  InpRiskEntryCol   = clrBlue; // Entry line color (after first click)
input color  InpRiskSLCol      = clrRed;  // Stop-loss line color (after second click)

input group "Hotkeys"
input bool InpHotkeyEnabled = true;   // Enable keyboard shortcuts (chart must be focused)
input int  InpKeyNextSym       = 40;  // Next symbol primary key (40=Down)
input int  InpKeyNextSym2      = 9;   // Next symbol alt key (9=Tab, 0=off)
input int  InpKeyPrevSym       = 38;  // Previous symbol primary key (38=Up)
input int  InpKeyPrevSym2      = 0;   // Previous symbol alt key (0=off, 33=PgUp)
input int  InpKeyToggleAlerts  = 65;  // Toggle alerts ON/OFF (65=A, 0=off)

input group "Watermark"
input bool             InpWmEnabled   = false;               // Show watermark
input bool             InpWmCentered  = false;               // Center watermark on chart (overrides corner)
input string           InpWmText      = "";                 // Custom text (top line, blank = only show pair+TF)
input ENUM_BASE_CORNER InpWmCorner    = CORNER_RIGHT_LOWER; // Anchor corner (when not centered)
input int              InpWmX         = 20;                 // X distance from corner (px)
input int              InpWmY         = 40;                 // Y distance from corner (px)
input color            InpWmColor     = C'250,250,250';     // Watermark color (near-white)
input int              InpWmMainSize  = 112;                // Title (line 1) font size
input int              InpWmSubSize   = 56;                 // Pair+TF (line 2) font size
input int              InpWmLineGap   = 80;                 // Vertical gap between title and pair (px, centered mode)
input string           InpWmFont      = "Arial Bold";

input group "Refresh"
input int InpTimerSeconds = 2;     // MTF redraw interval (seconds)

input group "Session Boxes"
input bool   InpSessEnabled    = true;  // Draw Forex session boxes
input int    InpSessHistoryDays= 10;    // History days to draw
input bool   InpSessFill       = true;  // Fill boxes
input bool   InpSessInBack     = true;  // Draw boxes behind price

input group "Session Times (broker server time, 24h)"
input int    InpSydneyStart = 22; // Sydney start hour
input int    InpSydneyEnd   = 7;  // Sydney end hour (wraps if < start)
input int    InpTokyoStart  = 0;  // Tokyo start hour
input int    InpTokyoEnd    = 9;  // Tokyo end hour
input int    InpLondonStart = 8;  // London start hour
input int    InpLondonEnd   = 13; // London end hour (ends when NY opens)
input int    InpNYStart     = 13; // New York start hour
input int    InpNYEnd       = 17; // New York end hour (first 4 hours after open)

input group "Session Toggles & Colors"
input bool   InpShowSydney = false;
input color  InpSydneyCol  = clrMediumPurple;
input bool   InpShowTokyo  = false;
input color  InpTokyoCol   = clrLightSalmon;
input bool   InpShowLondon = true;
input color  InpLondonCol  = C'220,220,220';   // London = light gray, just a touch darker than NY
input bool   InpShowNY     = true;
input color  InpNYCol      = C'235,235,235';  // NY = very light gray

// ====================================================================
// GLOBALS
// ====================================================================
const string PFX      = "MTFRS_";
const string BTN_ARM  = PFX + "btn";
const string BTN_CLEAR_LINES = PFX + "btn_clear";
const string BTN_SCROLL_END  = PFX + "btn_scroll_end";
const string SYM_PFX  = PFX + "sym_";
const string SESS_PFX = PFX + "sess_";
const string WM_MAIN  = PFX + "wm_main";
const string WM_SUB   = PFX + "wm_sub";
const string BTN_LOT_PCT   = PFX + "lot_pct";
const string BTN_LOT_MONEY = PFX + "lot_money";
const string LBL_LOT       = PFX + "lot_lbl";
const string BTN_PNL       = PFX + "pnl";
const string LINE_LOT_FOLLOW = PFX + "lot_follow";
const string LINE_LOT_ENTRY  = PFX + "lot_entry";
const string LINE_LOT_SL     = PFX + "lot_sl";

#define LOT_IDLE         0
#define LOT_AWAIT_ENTRY  1
#define LOT_AWAIT_SL     2
#define LOT_MODE_PCT     0
#define LOT_MODE_MONEY   1

struct SessionDef
{
   string name;
   int    startH;
   int    endH;
   color  col;
   bool   enabled;
};

SessionDef g_sessions[4];

bool      g_armed = true;
datetime  g_lastChartBarTime = 0;
long      g_trendCharts[];
string    g_trendNames[];
int       g_trendSides[];
string    g_lastSymList = "";
int       g_keyNextDown  = 0;
int       g_keyNext2Down = 0;
int       g_keyPrevDown  = 0;
int       g_keyPrev2Down = 0;
int       g_lotState = LOT_IDLE;
int       g_lotMode  = LOT_MODE_PCT;
double    g_lotEntry = 0.0;
double    g_lotSL    = 0.0;
double    g_lotLast  = 0.0;
uint      g_lotStartedAtMs = 0;
uint      g_lotEntrySetAtMs = 0;
int       g_appliedPanelW   = 0;   // Cached InpPanelW; OnTimer rebuilds if it ever drifts.
int       g_appliedSpacing  = 0;

// ====================================================================
// LIFECYCLE
// ====================================================================
int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, "MTF TradeDeck");
   CleanupAllMyObjects();
   BuildSessionDefs();
   CreateAlertButton();
   CreateClearLinesButton();
   BuildSymbolBar();
   CreateLotPanel();
   DrawSessionBoxes();
   DrawWatermark();
   g_appliedPanelW  = InpPanelW;
   g_appliedSpacing = InpSymBtnSpacing;
   EventSetTimer(MathMax(1, InpTimerSeconds));
   ChartRedraw();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
   CleanupAllMyObjects();
   ChartRedraw();
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   PollKeyboard();
   CheckTrendLineCrosses();
   if(rates_total > 0)
   {
      datetime cur = time[rates_total - 1];
      if(prev_calculated == 0 || cur != g_lastChartBarTime)
      {
         g_lastChartBarTime = cur;
         DrawMTFAll();
         ChartRedraw();
      }
   }
   return rates_total;
}

void OnTimer()
{
   PollKeyboard();
   // Safety net: if InpPanelW or spacing changed without a fresh OnInit firing
   // (e.g. some MT5 reload paths), rebuild the panel so the new sizes show up.
   if(g_appliedPanelW != InpPanelW || g_appliedSpacing != InpSymBtnSpacing)
   {
      g_appliedPanelW  = InpPanelW;
      g_appliedSpacing = InpSymBtnSpacing;
      CreateAlertButton();
      CreateClearLinesButton();
      BuildSymbolBar();
      CreateLotPanel();
      g_lastSymList = CurrentSymListSnapshot();
   }
   EnsureAlertButton();
   EnsureClearLinesButton();
   RefreshSymbolBar();
   CheckTrendLineCrosses();
   DrawMTFAll();
   DrawSessionBoxes();
   DrawWatermark();
   UpdateAlertButton();
   UpdatePnLButton();
   ChartRedraw();
}

void OnChartEvent(const int    id,
                  const long   &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(id == CHARTEVENT_CHART_CHANGE)
   {
      DrawMTFAll();
      ChartRedraw();
      return;
   }

   if(id == CHARTEVENT_KEYDOWN)
   {
      int kc = (int)lparam;
      // ESC cancels an in-progress lot measurement regardless of hotkey toggle.
      if(kc == 27 && g_lotState != LOT_IDLE) { CancelLotMeasurement(); return; }
      if(!InpHotkeyEnabled) return;
      if((InpKeyNextSym  != 0 && kc == InpKeyNextSym ) ||
         (InpKeyNextSym2 != 0 && kc == InpKeyNextSym2)) { CycleSymbol(+1); return; }
      if((InpKeyPrevSym  != 0 && kc == InpKeyPrevSym ) ||
         (InpKeyPrevSym2 != 0 && kc == InpKeyPrevSym2)) { CycleSymbol(-1); return; }
      if(InpKeyToggleAlerts != 0 && kc == InpKeyToggleAlerts) { ToggleAlerts(); return; }
      return;
   }

   // Mouse move: while measuring, draw a follower h-line at the cursor's price.
   if(id == CHARTEVENT_MOUSE_MOVE)
   {
      if(g_lotState != LOT_IDLE)
         HandleLotMouseMove((int)lparam, (int)dparam);
      return;
   }

   // Plain chart click: while measuring, capture entry/SL price.
   if(id == CHARTEVENT_CLICK)
   {
      if(g_lotState != LOT_IDLE)
         HandleLotChartClick((int)lparam, (int)dparam);
      return;
   }

   if(id != CHARTEVENT_OBJECT_CLICK) return;

   if(sparam == BTN_ARM)
   {
      ToggleAlerts();
      ObjectSetInteger(0, BTN_ARM, OBJPROP_STATE, false);
      return;
   }

   if(sparam == BTN_CLEAR_LINES)
   {
      ObjectSetInteger(0, BTN_CLEAR_LINES, OBJPROP_STATE, false);
      ClearAllUserLines();
      return;
   }

   if(sparam == BTN_LOT_PCT)
   {
      ObjectSetInteger(0, BTN_LOT_PCT, OBJPROP_STATE, false);
      if(g_lotState != LOT_IDLE) CancelLotMeasurement();
      else                       StartLotMeasurement(LOT_MODE_PCT);
      return;
   }
   if(sparam == BTN_LOT_MONEY)
   {
      ObjectSetInteger(0, BTN_LOT_MONEY, OBJPROP_STATE, false);
      if(g_lotState != LOT_IDLE) CancelLotMeasurement();
      else                       StartLotMeasurement(LOT_MODE_MONEY);
      return;
   }
   if(sparam == BTN_PNL)
   {
      // Read-only readout - just unstick the click and ignore.
      ObjectSetInteger(0, BTN_PNL, OBJPROP_STATE, false);
      return;
   }
   if(sparam == LBL_LOT)
   {
      // Click on the result label -> reset (clears lines + status).
      ObjectSetInteger(0, LBL_LOT, OBJPROP_STATE, false);
      g_lotLast = 0;
      ClearLotLines();
      CancelLotMeasurement();
      return;
   }

   if(StringFind(sparam, SYM_PFX) == 0)
   {
      string sym = StringSubstr(sparam, StringLen(SYM_PFX));
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      if(sym != _Symbol)
         ChartSetSymbolPeriod(0, sym, _Period);
      return;
   }
}

// ====================================================================
// CLEANUP
// ====================================================================
void CleanupAllMyObjects()
{
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--)
   {
      string n = ObjectName(0, i, -1, -1);
      if(StringFind(n, PFX) == 0) ObjectDelete(0, n);
   }
}

void ClearMTFObjects()
{
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--)
   {
      string n = ObjectName(0, i, -1, -1);
      if(StringFind(n, PFX + "g") == 0) ObjectDelete(0, n);
   }
}

// ====================================================================
// PANEL SIZING (everything derived from InpPanelW)
// ====================================================================
// Symbol button: half of total width minus spacing.
int PanelSymBtnW() { return (InpPanelW - InpSymBtnSpacing) / 2; }
// Symbol button height: ~1/8 of total width (keeps proportions across resizes).
int PanelSymBtnH() { return InpPanelW / 8; }
// Alert + RISK buttons: full width (alert) / half (risk), double sym height.
int PanelAlertW()  { return InpPanelW; }
int PanelAlertH()  { return 2 * PanelSymBtnH(); }
int PanelRiskW()   { return PanelSymBtnW(); }
int PanelRiskH()   { return 2 * PanelSymBtnH(); }
// LOT result label: same height as RISK buttons so multi-field result fits.
int PanelLblH()    { return 2 * PanelSymBtnH(); }

// ====================================================================
// ALERT BUTTON (clickable)
// ====================================================================
void CreateAlertButton()
{
   if(ObjectFind(0, BTN_ARM) >= 0) ObjectDelete(0, BTN_ARM);

   // When the symbol bar is on, dock the alert button below the 2-column grid
   // and span both columns. Otherwise honor its own corner/X/Y inputs.
   ENUM_BASE_CORNER corner;
   int x, y, w, h;
   if(InpShowSymBar)
   {
      int count = MathMin(SymbolsTotal(true), InpSymMaxCount);
      int rows  = (count + 1) / 2;   // ceil(count / 2)
      corner = InpSymBarCorner;
      x = InpSymBarX;
      y = InpSymBarY + rows * (PanelSymBtnH() + InpSymBtnSpacing);
      w = PanelAlertW();
      h = PanelAlertH();
   }
   else
   {
      corner = InpBtnCorner;
      x = InpBtnX;
      y = InpBtnY;
      w = PanelAlertW();
      h = PanelAlertH();
   }

   ObjectCreate(0, BTN_ARM, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, BTN_ARM, OBJPROP_CORNER,       corner);
   ObjectSetInteger(0, BTN_ARM, OBJPROP_XDISTANCE,    x);
   ObjectSetInteger(0, BTN_ARM, OBJPROP_YDISTANCE,    y);
   ObjectSetInteger(0, BTN_ARM, OBJPROP_XSIZE,        w);
   ObjectSetInteger(0, BTN_ARM, OBJPROP_YSIZE,        h);
   ObjectSetInteger(0, BTN_ARM, OBJPROP_FONTSIZE,     10);
   ObjectSetString (0, BTN_ARM, OBJPROP_FONT,         "Arial Bold");
   ObjectSetInteger(0, BTN_ARM, OBJPROP_BORDER_COLOR, clrDimGray);
   ObjectSetInteger(0, BTN_ARM, OBJPROP_BACK,         false);
   ObjectSetInteger(0, BTN_ARM, OBJPROP_SELECTABLE,   false);
   ObjectSetInteger(0, BTN_ARM, OBJPROP_HIDDEN,       true);
   ObjectSetInteger(0, BTN_ARM, OBJPROP_ZORDER,       1000);
   UpdateAlertButton();
}

void EnsureAlertButton()
{
   if(ObjectFind(0, BTN_ARM) < 0) CreateAlertButton();
}

// ====================================================================
// CLEAR-LINES BUTTON (wipes user-drawn trend/h-lines on every chart)
// ====================================================================
int PanelClearLinesH() { return PanelSymBtnH(); }

void CreateClearLinesButton()
{
   if(ObjectFind(0, BTN_CLEAR_LINES) >= 0) ObjectDelete(0, BTN_CLEAR_LINES);

   ENUM_BASE_CORNER corner;
   int x, y, w, h;
   if(InpShowSymBar)
   {
      int count = MathMin(SymbolsTotal(true), InpSymMaxCount);
      int rows  = (count + 1) / 2;
      corner = InpSymBarCorner;
      x = InpSymBarX;
      y = InpSymBarY + rows * (PanelSymBtnH() + InpSymBtnSpacing) + PanelAlertH() + InpSymBtnSpacing;
      w = PanelAlertW();
      h = PanelClearLinesH();
   }
   else
   {
      corner = InpBtnCorner;
      x = InpBtnX;
      y = InpBtnY + PanelAlertH() + InpSymBtnSpacing;
      w = PanelAlertW();
      h = PanelClearLinesH();
   }

   ObjectCreate(0, BTN_CLEAR_LINES, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, BTN_CLEAR_LINES, OBJPROP_CORNER,       corner);
   ObjectSetInteger(0, BTN_CLEAR_LINES, OBJPROP_XDISTANCE,    x);
   ObjectSetInteger(0, BTN_CLEAR_LINES, OBJPROP_YDISTANCE,    y);
   ObjectSetInteger(0, BTN_CLEAR_LINES, OBJPROP_XSIZE,        w);
   ObjectSetInteger(0, BTN_CLEAR_LINES, OBJPROP_YSIZE,        h);
   ObjectSetInteger(0, BTN_CLEAR_LINES, OBJPROP_FONTSIZE,     9);
   ObjectSetString (0, BTN_CLEAR_LINES, OBJPROP_FONT,         "Arial Bold");
   ObjectSetString (0, BTN_CLEAR_LINES, OBJPROP_TEXT,         "CLEAR LINES");
   ObjectSetInteger(0, BTN_CLEAR_LINES, OBJPROP_BGCOLOR,      C'120,60,140');
   ObjectSetInteger(0, BTN_CLEAR_LINES, OBJPROP_COLOR,        clrWhite);
   ObjectSetInteger(0, BTN_CLEAR_LINES, OBJPROP_BORDER_COLOR, clrDimGray);
   ObjectSetInteger(0, BTN_CLEAR_LINES, OBJPROP_BACK,         false);
   ObjectSetInteger(0, BTN_CLEAR_LINES, OBJPROP_SELECTABLE,   false);
   ObjectSetInteger(0, BTN_CLEAR_LINES, OBJPROP_HIDDEN,       true);
   ObjectSetInteger(0, BTN_CLEAR_LINES, OBJPROP_ZORDER,       1000);
}

void EnsureClearLinesButton()
{
   if(ObjectFind(0, BTN_CLEAR_LINES) < 0) CreateClearLinesButton();
}

// ====================================================================
// SCROLL-TO-END BUTTON (jumps view to most recent bar without engaging
// MT5's auto-scroll mode - user can pan back freely afterwards)
// ====================================================================
int PanelScrollEndH() { return PanelSymBtnH(); }

// Wipe user-drawn trendlines / h-lines on every open chart so alerts stop
// firing and the user can start drawing from a clean slate. Indicator-owned
// objects (PFX prefix) are left alone.
void ClearAllUserLines()
{
   long chartId = ChartFirst();
   while(chartId >= 0)
   {
      for(int i = ObjectsTotal(chartId, -1, -1) - 1; i >= 0; i--)
      {
         string name = ObjectName(chartId, i, -1, -1);
         if(StringFind(name, PFX) == 0) continue;
         ENUM_OBJECT type = (ENUM_OBJECT)ObjectGetInteger(chartId, name, OBJPROP_TYPE);
         if(type == OBJ_TREND || type == OBJ_HLINE || type == OBJ_TRENDBYANGLE)
            ObjectDelete(chartId, name);
      }
      ChartRedraw(chartId);
      chartId = ChartNext(chartId);
   }
   ResetTrendSides();
}

// ====================================================================
// LOT CALCULATOR
// ====================================================================
void DeleteLotPanel()
{
   if(ObjectFind(0, BTN_LOT_PCT  ) >= 0) ObjectDelete(0, BTN_LOT_PCT  );
   if(ObjectFind(0, BTN_LOT_MONEY) >= 0) ObjectDelete(0, BTN_LOT_MONEY);
   if(ObjectFind(0, LBL_LOT      ) >= 0) ObjectDelete(0, LBL_LOT      );
   if(ObjectFind(0, BTN_PNL      ) >= 0) ObjectDelete(0, BTN_PNL      );
}

void ClearLotLines()
{
   if(ObjectFind(0, LINE_LOT_FOLLOW) >= 0) ObjectDelete(0, LINE_LOT_FOLLOW);
   if(ObjectFind(0, LINE_LOT_ENTRY ) >= 0) ObjectDelete(0, LINE_LOT_ENTRY );
   if(ObjectFind(0, LINE_LOT_SL    ) >= 0) ObjectDelete(0, LINE_LOT_SL    );
}

// Lot panel only docks below the alert button when the symbol bar is on.
// Otherwise we skip rendering it (no good anchor point).
void CreateLotPanel()
{
   DeleteLotPanel();
   if(!InpLotCalcEnabled || !InpShowSymBar) return;

   int count = MathMin(SymbolsTotal(true), InpSymMaxCount);
   int rows  = (count + 1) / 2;
   ENUM_BASE_CORNER corner = InpSymBarCorner;
   int x       = InpSymBarX;
   int wTotal  = PanelAlertW();
   int alertH  = PanelAlertH();
   int btnH    = PanelRiskH();
   int btnW    = PanelRiskW();
   int lblH    = PanelLblH();

   // Y just below alert button + clear-lines button + scroll-end button.
   int y = InpSymBarY + rows * (PanelSymBtnH() + InpSymBtnSpacing) + alertH + InpSymBtnSpacing
         + PanelClearLinesH() + InpSymBtnSpacing;

   // RISK % button
   ObjectCreate (0, BTN_LOT_PCT, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, BTN_LOT_PCT, OBJPROP_CORNER,     corner);
   ObjectSetInteger(0, BTN_LOT_PCT, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, BTN_LOT_PCT, OBJPROP_YDISTANCE,  y);
   ObjectSetInteger(0, BTN_LOT_PCT, OBJPROP_XSIZE,      btnW);
   ObjectSetInteger(0, BTN_LOT_PCT, OBJPROP_YSIZE,      btnH);
   ObjectSetInteger(0, BTN_LOT_PCT, OBJPROP_BGCOLOR,    InpLotBtnBg);
   ObjectSetInteger(0, BTN_LOT_PCT, OBJPROP_COLOR,      InpLotBtnText);
   ObjectSetInteger(0, BTN_LOT_PCT, OBJPROP_FONTSIZE,   10);
   ObjectSetString (0, BTN_LOT_PCT, OBJPROP_FONT,       "Arial Bold");
   ObjectSetString (0, BTN_LOT_PCT, OBJPROP_TEXT,       StringFormat("%.2f%%", InpRiskPercent));
   ObjectSetInteger(0, BTN_LOT_PCT, OBJPROP_BORDER_COLOR, clrDimGray);
   ObjectSetInteger(0, BTN_LOT_PCT, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, BTN_LOT_PCT, OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0, BTN_LOT_PCT, OBJPROP_ZORDER,     1000);

   // RISK $ button
   ObjectCreate (0, BTN_LOT_MONEY, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, BTN_LOT_MONEY, OBJPROP_CORNER,     corner);
   ObjectSetInteger(0, BTN_LOT_MONEY, OBJPROP_XDISTANCE,  x + btnW + InpSymBtnSpacing);
   ObjectSetInteger(0, BTN_LOT_MONEY, OBJPROP_YDISTANCE,  y);
   ObjectSetInteger(0, BTN_LOT_MONEY, OBJPROP_XSIZE,      btnW);
   ObjectSetInteger(0, BTN_LOT_MONEY, OBJPROP_YSIZE,      btnH);
   ObjectSetInteger(0, BTN_LOT_MONEY, OBJPROP_BGCOLOR,    InpLotBtnBg);
   ObjectSetInteger(0, BTN_LOT_MONEY, OBJPROP_COLOR,      InpLotBtnText);
   ObjectSetInteger(0, BTN_LOT_MONEY, OBJPROP_FONTSIZE,   10);
   ObjectSetString (0, BTN_LOT_MONEY, OBJPROP_FONT,       "Arial Bold");
   ObjectSetString (0, BTN_LOT_MONEY, OBJPROP_TEXT,       StringFormat("$%.0f", InpRiskMoney));
   ObjectSetInteger(0, BTN_LOT_MONEY, OBJPROP_BORDER_COLOR, clrDimGray);
   ObjectSetInteger(0, BTN_LOT_MONEY, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, BTN_LOT_MONEY, OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0, BTN_LOT_MONEY, OBJPROP_ZORDER,     1000);

   // Result label (rendered as a static button so it stays visible & styled)
   y += btnH + InpSymBtnSpacing;
   ObjectCreate (0, LBL_LOT, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, LBL_LOT, OBJPROP_CORNER,     corner);
   ObjectSetInteger(0, LBL_LOT, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, LBL_LOT, OBJPROP_YDISTANCE,  y);
   ObjectSetInteger(0, LBL_LOT, OBJPROP_XSIZE,      wTotal);
   ObjectSetInteger(0, LBL_LOT, OBJPROP_YSIZE,      lblH);
   ObjectSetInteger(0, LBL_LOT, OBJPROP_BGCOLOR,    C'30,30,30');
   ObjectSetInteger(0, LBL_LOT, OBJPROP_COLOR,      clrWhite);
   ObjectSetInteger(0, LBL_LOT, OBJPROP_FONTSIZE,   13);
   ObjectSetString (0, LBL_LOT, OBJPROP_FONT,       "Arial Bold");
   ObjectSetString (0, LBL_LOT, OBJPROP_TEXT,       (g_lotLast > 0 ? StringFormat("LOT %.2f", g_lotLast) : "-"));
   ObjectSetInteger(0, LBL_LOT, OBJPROP_BORDER_COLOR, clrDimGray);
   ObjectSetInteger(0, LBL_LOT, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, LBL_LOT, OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0, LBL_LOT, OBJPROP_ZORDER,     1000);

   // Open-position PnL readout (refreshed every timer tick by UpdatePnLButton).
   y += lblH + InpSymBtnSpacing;
   ObjectCreate (0, BTN_PNL, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, BTN_PNL, OBJPROP_CORNER,       corner);
   ObjectSetInteger(0, BTN_PNL, OBJPROP_XDISTANCE,    x);
   ObjectSetInteger(0, BTN_PNL, OBJPROP_YDISTANCE,    y);
   ObjectSetInteger(0, BTN_PNL, OBJPROP_XSIZE,        wTotal);
   ObjectSetInteger(0, BTN_PNL, OBJPROP_YSIZE,        lblH);
   ObjectSetInteger(0, BTN_PNL, OBJPROP_BGCOLOR,      C'20,20,20');
   ObjectSetInteger(0, BTN_PNL, OBJPROP_COLOR,        clrWhite);
   ObjectSetInteger(0, BTN_PNL, OBJPROP_FONTSIZE,     13);
   ObjectSetString (0, BTN_PNL, OBJPROP_FONT,         "Arial Bold");
   ObjectSetString (0, BTN_PNL, OBJPROP_TEXT,         "0.00");
   ObjectSetInteger(0, BTN_PNL, OBJPROP_BORDER_COLOR, clrDimGray);
   ObjectSetInteger(0, BTN_PNL, OBJPROP_SELECTABLE,   false);
   ObjectSetInteger(0, BTN_PNL, OBJPROP_HIDDEN,       true);
   ObjectSetInteger(0, BTN_PNL, OBJPROP_ZORDER,       1000);
   UpdatePnLButton();
}

// Update the open-position PnL readout. Blue bg = profit, red bg = loss,
// dark bg = flat. Text always white.
void UpdatePnLButton()
{
   if(ObjectFind(0, BTN_PNL) < 0) return;
   double pnl = AccountInfoDouble(ACCOUNT_PROFIT);
   color  bg  = (pnl > 0) ? C'40,90,140' : (pnl < 0 ? C'180,40,40' : C'20,20,20');
   ObjectSetString (0, BTN_PNL, OBJPROP_TEXT,    StringFormat("%.2f", pnl));
   ObjectSetInteger(0, BTN_PNL, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, BTN_PNL, OBJPROP_COLOR,   clrWhite);
}

void UpdateLotStatus(string text)
{
   if(ObjectFind(0, LBL_LOT) >= 0)
      ObjectSetString(0, LBL_LOT, OBJPROP_TEXT, text);
}

void DrawHLine(string name, double price, color clr, ENUM_LINE_STYLE style, int width)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetDouble (0, name, OBJPROP_PRICE,      price);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE,      style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      width);
   // BACK=true keeps the line behind chart objects so the panel buttons stay
   // crisp on top of it (otherwise the H-line would visually cross the buttons).
   ObjectSetInteger(0, name, OBJPROP_BACK,       true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
}

double NormalizeLot(double rawLot)
{
   double vmin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double vstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(vstep > 0) rawLot = MathFloor(rawLot / vstep) * vstep;
   if(rawLot < vmin) rawLot = vmin;
   if(rawLot > vmax) rawLot = vmax;
   return rawLot;
}

double CalculateLot(double entry, double sl, double riskMoney)
{
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double dist     = MathAbs(entry - sl);
   if(tickVal <= 0 || tickSize <= 0 || dist <= 0) return 0.0;
   double lossPerLot = (dist / tickSize) * tickVal;
   if(lossPerLot <= 0) return 0.0;
   return NormalizeLot(riskMoney / lossPerLot);
}

void StartLotMeasurement(int mode)
{
   g_lotMode  = mode;
   g_lotState = LOT_AWAIT_ENTRY;
   g_lotEntry = 0;
   g_lotSL    = 0;
   g_lotStartedAtMs = GetTickCount();
   ClearLotLines();
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   // Pre-draw the follower line at current bid so it is visible immediately,
   // before the user moves the mouse (some setups don't send MOUSE_MOVE until motion).
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid > 0.0) DrawHLine(LINE_LOT_FOLLOW, bid, InpRiskFollowCol, STYLE_DOT, 4);
   UpdateLotStatus("ENTRY");
   ChartRedraw();
}

void CancelLotMeasurement()
{
   g_lotState = LOT_IDLE;
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
   if(ObjectFind(0, LINE_LOT_FOLLOW) >= 0) ObjectDelete(0, LINE_LOT_FOLLOW);
   UpdateLotStatus(g_lotLast > 0 ? StringFormat("LOT %.2f", g_lotLast) : "-");
   ChartRedraw();
}

void HandleLotMouseMove(int xPx, int yPx)
{
   if(g_lotState == LOT_IDLE) return;
   datetime t; double price; int sub;
   if(!ChartXYToTimePrice(0, xPx, yPx, sub, t, price)) return;
   DrawHLine(LINE_LOT_FOLLOW, price, InpRiskFollowCol, STYLE_DOT, 4);
   ChartRedraw();
}

void HandleLotChartClick(int xPx, int yPx)
{
   if(g_lotState == LOT_IDLE) return;
   // Ignore the spurious chart-click that fires from the SAME mouse click that
   // triggered the RISK button (MT5 fires OBJECT_CLICK + CHART_CLICK on a button hit).
   if(g_lotState == LOT_AWAIT_ENTRY && GetTickCount() - g_lotStartedAtMs  < 150) return;
   if(g_lotState == LOT_AWAIT_SL    && GetTickCount() - g_lotEntrySetAtMs < 150) return;

   datetime t; double price; int sub;
   if(!ChartXYToTimePrice(0, xPx, yPx, sub, t, price)) return;

   if(g_lotState == LOT_AWAIT_ENTRY)
   {
      g_lotEntry = price;
      DrawHLine(LINE_LOT_ENTRY, price, InpRiskEntryCol, STYLE_SOLID, 4);
      g_lotState = LOT_AWAIT_SL;
      g_lotEntrySetAtMs = GetTickCount();
      UpdateLotStatus("STOP");
   }
   else if(g_lotState == LOT_AWAIT_SL)
   {
      g_lotSL = price;
      DrawHLine(LINE_LOT_SL, price, InpRiskSLCol, STYLE_SOLID, 4);

      double risk = (g_lotMode == LOT_MODE_PCT)
                  ? AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0
                  : InpRiskMoney;
      double lot  = CalculateLot(g_lotEntry, g_lotSL, risk);
      g_lotLast = lot;
      double pts = MathAbs(g_lotEntry - g_lotSL) / _Point;
      UpdateLotStatus(StringFormat("%.2f  %.0f", lot, pts));

      g_lotState = LOT_IDLE;
      ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
      ClearLotLines();   // wipe entry/SL/follow once the lot has been computed
   }
   ChartRedraw();
}

// ====================================================================
// SYMBOL BAR (Market Watch switcher)
// ====================================================================
void DeleteSymbolButtons()
{
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--)
   {
      string n = ObjectName(0, i, -1, -1);
      if(StringFind(n, SYM_PFX) == 0) ObjectDelete(0, n);
   }
}

void BuildSymbolBar()
{
   DeleteSymbolButtons();
   if(!InpShowSymBar) return;

   int total = SymbolsTotal(true);
   int count = MathMin(total, InpSymMaxCount);

   int btnW = PanelSymBtnW();
   int btnH = PanelSymBtnH();

   for(int i = 0; i < count; i++)
   {
      string sym = SymbolName(i, true);
      string btn = SYM_PFX + sym;

      // 2-column grid: even index = left column, odd = right column.
      int col = i % 2;
      int row = i / 2;
      int x = InpSymBarX + col * (btnW + InpSymBtnSpacing);
      int y = InpSymBarY + row * (btnH + InpSymBtnSpacing);

      // If this is the last symbol AND it would land alone in its row
      // (odd total, lefthand column), stretch it to fill the full bar width.
      bool isOrphanLast = (i == count - 1) && (count % 2 == 1);
      int  thisBtnW     = isOrphanLast ? PanelAlertW() : btnW;

      ObjectCreate(0, btn, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, btn, OBJPROP_CORNER,       InpSymBarCorner);
      ObjectSetInteger(0, btn, OBJPROP_XDISTANCE,    x);
      ObjectSetInteger(0, btn, OBJPROP_YDISTANCE,    y);
      ObjectSetInteger(0, btn, OBJPROP_XSIZE,        thisBtnW);
      ObjectSetInteger(0, btn, OBJPROP_YSIZE,        btnH);
      ObjectSetInteger(0, btn, OBJPROP_FONTSIZE,     9);
      ObjectSetString (0, btn, OBJPROP_FONT,         "Arial Bold");
      ObjectSetString (0, btn, OBJPROP_TEXT,         sym);
      ObjectSetInteger(0, btn, OBJPROP_BORDER_COLOR, clrDimGray);
      ObjectSetInteger(0, btn, OBJPROP_BACK,         false);
      ObjectSetInteger(0, btn, OBJPROP_SELECTABLE,   false);
      ObjectSetInteger(0, btn, OBJPROP_HIDDEN,       true);
      ObjectSetInteger(0, btn, OBJPROP_ZORDER,       999);
      ObjectSetInteger(0, btn, OBJPROP_COLOR,        InpSymBtnText);
      ObjectSetInteger(0, btn, OBJPROP_BGCOLOR, sym == _Symbol ? InpSymBtnBgActive : InpSymBtnBg);
   }
}

string CurrentSymListSnapshot()
{
   int count = MathMin(SymbolsTotal(true), InpSymMaxCount);
   string s = "";
   for(int i = 0; i < count; i++) s += SymbolName(i, true) + ";";
   return s;
}

void UpdateSymbolBarHighlight()
{
   int count = MathMin(SymbolsTotal(true), InpSymMaxCount);
   for(int i = 0; i < count; i++)
   {
      string sym = SymbolName(i, true);
      string btn = SYM_PFX + sym;
      if(ObjectFind(0, btn) < 0) continue;
      ObjectSetInteger(0, btn, OBJPROP_BGCOLOR, sym == _Symbol ? InpSymBtnBgActive : InpSymBtnBg);
   }
}

void RefreshSymbolBar()
{
   if(!InpShowSymBar) { DeleteSymbolButtons(); return; }
   string snapshot = CurrentSymListSnapshot();
   if(snapshot != g_lastSymList)
   {
      g_lastSymList = snapshot;
      BuildSymbolBar();
      // Row count changed -> reposition the alert button, clear-lines button, scroll-end button, and lot panel below the new grid.
      CreateAlertButton();
      CreateClearLinesButton();
      CreateLotPanel();
   }
   else
   {
      UpdateSymbolBarHighlight();
   }
}

void CycleSymbol(int direction)
{
   int total = SymbolsTotal(true);
   if(total <= 0) return;
   int currentIdx = -1;
   for(int i = 0; i < total; i++)
   {
      if(SymbolName(i, true) == _Symbol) { currentIdx = i; break; }
   }
   int nextIdx = (currentIdx < 0) ? 0 : ((currentIdx + direction) % total + total) % total;
   string nextSym = SymbolName(nextIdx, true);
   if(nextSym != "" && nextSym != _Symbol)
      ChartSetSymbolPeriod(0, nextSym, _Period);
}

// Map a Windows virtual key code to its TERMINAL_KEYSTATE_* enum value.
// Returns 0 if the key isn't pollable (only navigation/control keys are).
int VKToKeystate(int vk)
{
   switch(vk)
   {
      case 9:  return TERMINAL_KEYSTATE_TAB;
      case 13: return TERMINAL_KEYSTATE_ENTER;
      case 27: return TERMINAL_KEYSTATE_ESCAPE;
      case 33: return TERMINAL_KEYSTATE_PAGEUP;
      case 34: return TERMINAL_KEYSTATE_PAGEDOWN;
      case 35: return TERMINAL_KEYSTATE_END;
      case 36: return TERMINAL_KEYSTATE_HOME;
      case 37: return TERMINAL_KEYSTATE_LEFT;
      case 38: return TERMINAL_KEYSTATE_UP;
      case 39: return TERMINAL_KEYSTATE_RIGHT;
      case 40: return TERMINAL_KEYSTATE_DOWN;
      case 45: return TERMINAL_KEYSTATE_INSERT;
      case 46: return TERMINAL_KEYSTATE_DELETE;
   }
   return 0;
}

// Read the rising edge (released -> pressed) of a single VK code via TERMINAL_KEYSTATE.
// Updates the previous-state ref. Returns true on rising edge.
bool KeyRisingEdge(int vk, int &prevState)
{
   if(vk == 0) return false;
   int ks = VKToKeystate(vk);
   if(ks == 0) return false;
   long raw = TerminalInfoInteger((ENUM_TERMINAL_INFO_INTEGER)ks);
   int pressed = (int)(raw & 0x8000);
   bool fired = (pressed != 0 && prevState == 0);
   prevState = pressed;
   return fired;
}

// Poll keyboard via global keystate. Fires on rising edge for each configured key.
void PollKeyboard()
{
   if(!InpHotkeyEnabled) return;
   if(KeyRisingEdge(InpKeyNextSym , g_keyNextDown ))  { CycleSymbol(+1); return; }
   if(KeyRisingEdge(InpKeyNextSym2, g_keyNext2Down))  { CycleSymbol(+1); return; }
   if(KeyRisingEdge(InpKeyPrevSym , g_keyPrevDown ))  { CycleSymbol(-1); return; }
   if(KeyRisingEdge(InpKeyPrevSym2, g_keyPrev2Down))  { CycleSymbol(-1); return; }
}

void UpdateAlertButton()
{
   if(ObjectFind(0, BTN_ARM) < 0) return;
   ObjectSetString (0, BTN_ARM, OBJPROP_TEXT,    g_armed ? "ALERT ON" : "ALERT OFF");
   ObjectSetInteger(0, BTN_ARM, OBJPROP_BGCOLOR, g_armed ? C'30,150,80' : C'180,40,40');
   ObjectSetInteger(0, BTN_ARM, OBJPROP_COLOR,   clrWhite);
}

void ToggleAlerts()
{
   g_armed = !g_armed;
   if(g_armed) ResetTrendSides();
   UpdateAlertButton();
   ChartRedraw();
}

// ====================================================================
// TREND LINE / HLINE CROSS DETECTION
// ====================================================================
double GetLineYAtTime(long chartId, string name, ENUM_OBJECT type, datetime t)
{
   if(type == OBJ_HLINE)
      return ObjectGetDouble(chartId, name, OBJPROP_PRICE, 0);

   if(type == OBJ_TREND || type == OBJ_TRENDBYANGLE)
   {
      datetime t1 = (datetime)ObjectGetInteger(chartId, name, OBJPROP_TIME, 0);
      datetime t2 = (datetime)ObjectGetInteger(chartId, name, OBJPROP_TIME, 1);
      double   p1 = ObjectGetDouble (chartId, name, OBJPROP_PRICE, 0);
      double   p2 = ObjectGetDouble (chartId, name, OBJPROP_PRICE, 1);
      long dt12 = (long)t2 - (long)t1;
      if(dt12 == 0) return p1;
      long dt = (long)t - (long)t1;
      return p1 + (p2 - p1) * (double)dt / (double)dt12;
   }
   return EMPTY_VALUE;
}

int FindTrendIdx(long chartId, const string name)
{
   for(int i = 0; i < ArraySize(g_trendNames); i++)
      if(g_trendCharts[i] == chartId && g_trendNames[i] == name) return i;
   return -1;
}

void ResetTrendSides()
{
   ArrayResize(g_trendCharts, 0);
   ArrayResize(g_trendNames, 0);
   ArrayResize(g_trendSides, 0);
}

void RemoveTrendAt(int i)
{
   int n = ArraySize(g_trendNames);
   for(int j = i; j < n - 1; j++)
   {
      g_trendCharts[j] = g_trendCharts[j+1];
      g_trendNames[j]  = g_trendNames[j+1];
      g_trendSides[j]  = g_trendSides[j+1];
   }
   ArrayResize(g_trendCharts, n - 1);
   ArrayResize(g_trendNames,  n - 1);
   ArrayResize(g_trendSides,  n - 1);
}

// Drop tracked entries whose line was deleted or whose chart was closed.
// ChartSymbol() returns "" for an invalid/closed chart id.
void PruneDeletedLines()
{
   for(int i = ArraySize(g_trendNames) - 1; i >= 0; i--)
   {
      if(ChartSymbol(g_trendCharts[i]) == "" ||
         ObjectFind(g_trendCharts[i], g_trendNames[i]) < 0)
         RemoveTrendAt(i);
   }
}

void CheckTrendLineCrosses()
{
   if(!g_armed) { PruneDeletedLines(); return; }

   datetime now = TimeCurrent();

   long chartId = ChartFirst();
   while(chartId >= 0)
   {
      string sym = ChartSymbol(chartId);
      if(sym != "")
      {
         double bid = SymbolInfoDouble(sym, SYMBOL_BID);
         if(bid > 0.0)
         {
            int total = ObjectsTotal(chartId, -1, -1);
            for(int i = 0; i < total; i++)
            {
               string name = ObjectName(chartId, i, -1, -1);
               if(StringFind(name, PFX) == 0) continue;
               ENUM_OBJECT type = (ENUM_OBJECT)ObjectGetInteger(chartId, name, OBJPROP_TYPE);
               if(type != OBJ_TREND && type != OBJ_HLINE && type != OBJ_TRENDBYANGLE) continue;

               double y = GetLineYAtTime(chartId, name, type, now);
               if(y == EMPTY_VALUE) continue;

               int currentSide = (bid > y) ? 1 : ((bid < y) ? -1 : 0);
               int idx = FindTrendIdx(chartId, name);

               if(idx == -1)
               {
                  int n = ArraySize(g_trendNames);
                  ArrayResize(g_trendCharts, n + 1);
                  ArrayResize(g_trendNames,  n + 1);
                  ArrayResize(g_trendSides,  n + 1);
                  g_trendCharts[n] = chartId;
                  g_trendNames[n]  = name;
                  g_trendSides[n]  = currentSide;
               }
               else
               {
                  int prevSide = g_trendSides[idx];
                  if(prevSide != 0 && currentSide != 0 && prevSide != currentSide)
                  {
                     FireAlert(chartId, sym, name, type, y, bid);
                     g_armed = false;
                     UpdateAlertButton();
                     ChartRedraw();
                     g_trendSides[idx] = currentSide;
                     PruneDeletedLines();
                     return;
                  }
                  g_trendSides[idx] = currentSide;
               }
            }
         }
      }
      chartId = ChartNext(chartId);
   }
   PruneDeletedLines();
}

void FireAlert(long chartId, string symbol, string lineName, ENUM_OBJECT type, double y, double bid)
{
   PlaySound(InpAlertSound);
   // Log to Experts tab instead of Alert(), which would pop a modal that steals focus.
   string typeStr = (type == OBJ_HLINE) ? "HLine" : "Trend";
   PrintFormat("%s cross on %s: \"%s\" @ %.5f (bid %.5f)",
               typeStr, symbol, lineName, y, bid);
}

// ====================================================================
// MTF RIGHT-SIDE CANDLES
// ====================================================================
string TfToString(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "1m";
      case PERIOD_M2:  return "2m";
      case PERIOD_M3:  return "3m";
      case PERIOD_M4:  return "4m";
      case PERIOD_M5:  return "5m";
      case PERIOD_M6:  return "6m";
      case PERIOD_M10: return "10m";
      case PERIOD_M12: return "12m";
      case PERIOD_M15: return "15m";
      case PERIOD_M20: return "20m";
      case PERIOD_M30: return "30m";
      case PERIOD_H1:  return "1h";
      case PERIOD_H2:  return "2h";
      case PERIOD_H3:  return "3h";
      case PERIOD_H4:  return "4h";
      case PERIOD_H6:  return "6h";
      case PERIOD_H8:  return "8h";
      case PERIOD_H12: return "12h";
      case PERIOD_D1:  return "1D";
      case PERIOD_W1:  return "1W";
      case PERIOD_MN1: return "1M";
   }
   return EnumToString(tf);
}

void DrawMTFAll()
{
   ClearMTFObjects();
   datetime lastBarT = iTime(_Symbol, _Period, 0);
   if(lastBarT == 0) return;
   long secPerBar = PeriodSeconds(_Period);
   if(secPerBar <= 0) return;
   datetime anchorT = lastBarT + (datetime)secPerBar; // right edge of current bar

   // Always use the custom input colors (ignore chart style).
   color bullC = InpBullCol;
   color bearC = InpBearCol;

   // Resolve chart's visible price range for vertical scaling
   double chartMax = ChartGetDouble(0, CHART_PRICE_MAX);
   double chartMin = ChartGetDouble(0, CHART_PRICE_MIN);
   if(chartMax <= chartMin) { chartMax = 1.0; chartMin = 0.0; }

   long curOffset = InpGap;
   if(InpTF1En) curOffset = DrawMTFGroup(curOffset, anchorT, secPerBar, 1, InpTF1, InpTF1N, bullC, bearC, chartMin, chartMax) + InpGroupSpace;
   if(InpTF2En) curOffset = DrawMTFGroup(curOffset, anchorT, secPerBar, 2, InpTF2, InpTF2N, bullC, bearC, chartMin, chartMax) + InpGroupSpace;
   if(InpTF3En) curOffset = DrawMTFGroup(curOffset, anchorT, secPerBar, 3, InpTF3, InpTF3N, bullC, bearC, chartMin, chartMax) + InpGroupSpace;
   if(InpTF4En) curOffset = DrawMTFGroup(curOffset, anchorT, secPerBar, 4, InpTF4, InpTF4N, bullC, bearC, chartMin, chartMax) + InpGroupSpace;
   if(InpTF5En) curOffset = DrawMTFGroup(curOffset, anchorT, secPerBar, 5, InpTF5, InpTF5N, bullC, bearC, chartMin, chartMax) + InpGroupSpace;
}

long DrawMTFGroup(long startOffset, datetime anchorT, long secPerBar,
                  int groupId, ENUM_TIMEFRAMES tf, int n,
                  color bullC, color bearC,
                  double chartMin, double chartMax)
{
   if(n <= 0) return startOffset;
   MqlRates rates[];
   int copied = CopyRates(_Symbol, tf, 0, n, rates);
   if(copied <= 0) return startOffset;
   ArraySetAsSeries(rates, false);

   // Compute this group's price range to map onto the chart's visible range
   double groupMin =  DBL_MAX;
   double groupMax = -DBL_MAX;
   for(int i = 0; i < copied; i++)
   {
      if(rates[i].high > groupMax) groupMax = rates[i].high;
      if(rates[i].low  < groupMin) groupMin = rates[i].low;
   }
   double srcRange = groupMax - groupMin;
   double margin   = MathMax(0.0, MathMin(0.4, InpScaleMargin)) * (chartMax - chartMin);
   double tgtMin   = chartMin + margin;
   double tgtMax   = chartMax - margin;
   double tgtRange = tgtMax - tgtMin;
   bool   doScale  = InpScaleToChart && srcRange > 0.0 && tgtRange > 0.0;

   double maxHighOut = -DBL_MAX;
   long   offset     = startOffset;
   for(int i = 0; i < copied; i++)
   {
      datetime leftT  = anchorT + (datetime)(offset * secPerBar);
      datetime rightT = leftT   + (datetime)(InpCandleW * secPerBar);
      datetime midT   = leftT   + (datetime)((InpCandleW * secPerBar) / 2);

      double oo = rates[i].open;
      double hh = rates[i].high;
      double ll = rates[i].low;
      double cc = rates[i].close;
      if(doScale)
      {
         oo = tgtMin + (oo - groupMin) / srcRange * tgtRange;
         hh = tgtMin + (hh - groupMin) / srcRange * tgtRange;
         ll = tgtMin + (ll - groupMin) / srcRange * tgtRange;
         cc = tgtMin + (cc - groupMin) / srcRange * tgtRange;
      }

      double bodyTop = MathMax(oo, cc);
      double bodyBot = MathMin(oo, cc);
      bool   isBull  = rates[i].close >= rates[i].open;
      color  bodyCol = isBull ? bullC : bearC;
      color  wickC   = InpWickCol;

      string bodyName   = StringFormat("%sg%d_b%d", PFX, groupId, i);
      string borderName = StringFormat("%sg%d_e%d", PFX, groupId, i);
      string wickUName  = StringFormat("%sg%d_wu%d", PFX, groupId, i);
      string wickLName  = StringFormat("%sg%d_wl%d", PFX, groupId, i);

      // Filled body (OBJ_RECTANGLE fill color = OBJPROP_COLOR when FILL=true)
      ObjectCreate     (0, bodyName, OBJ_RECTANGLE, 0, leftT, bodyTop, rightT, bodyBot);
      ObjectSetInteger (0, bodyName, OBJPROP_COLOR,      bodyCol);
      ObjectSetInteger (0, bodyName, OBJPROP_FILL,       true);
      ObjectSetInteger (0, bodyName, OBJPROP_BACK,       false);
      ObjectSetInteger (0, bodyName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger (0, bodyName, OBJPROP_HIDDEN,     true);

      // Outline (no fill) on top, drawn in wick/border color
      ObjectCreate     (0, borderName, OBJ_RECTANGLE, 0, leftT, bodyTop, rightT, bodyBot);
      ObjectSetInteger (0, borderName, OBJPROP_COLOR,      wickC);
      ObjectSetInteger (0, borderName, OBJPROP_FILL,       false);
      ObjectSetInteger (0, borderName, OBJPROP_WIDTH,      1);
      ObjectSetInteger (0, borderName, OBJPROP_BACK,       false);
      ObjectSetInteger (0, borderName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger (0, borderName, OBJPROP_HIDDEN,     true);

      // Split wick into upper (high -> bodyTop) and lower (bodyBot -> low) so it
      // doesn't show through the body (OBJ_RECTANGLE fill is semi-transparent).
      ObjectCreate     (0, wickUName, OBJ_TREND, 0, midT, hh, midT, bodyTop);
      ObjectSetInteger (0, wickUName, OBJPROP_COLOR,      wickC);
      ObjectSetInteger (0, wickUName, OBJPROP_WIDTH,      1);
      ObjectSetInteger (0, wickUName, OBJPROP_RAY_RIGHT,  false);
      ObjectSetInteger (0, wickUName, OBJPROP_RAY_LEFT,   false);
      ObjectSetInteger (0, wickUName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger (0, wickUName, OBJPROP_HIDDEN,     true);

      ObjectCreate     (0, wickLName, OBJ_TREND, 0, midT, bodyBot, midT, ll);
      ObjectSetInteger (0, wickLName, OBJPROP_COLOR,      wickC);
      ObjectSetInteger (0, wickLName, OBJPROP_WIDTH,      1);
      ObjectSetInteger (0, wickLName, OBJPROP_RAY_RIGHT,  false);
      ObjectSetInteger (0, wickLName, OBJPROP_RAY_LEFT,   false);
      ObjectSetInteger (0, wickLName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger (0, wickLName, OBJPROP_HIDDEN,     true);

      if(hh > maxHighOut) maxHighOut = hh;
      offset += InpCandleW + InpCandleSpace;
   }

   string lblName = StringFormat("%sg%d_lbl", PFX, groupId);
   long groupSpan = copied * (InpCandleW + InpCandleSpace) - InpCandleSpace;
   datetime labelT = anchorT + (datetime)((startOffset + groupSpan / 2) * secPerBar);
   ObjectCreate    (0, lblName, OBJ_TEXT, 0, labelT, maxHighOut);
   ObjectSetString (0, lblName, OBJPROP_TEXT,       TfToString(tf));
   ObjectSetInteger(0, lblName, OBJPROP_COLOR,      InpLabelCol);
   ObjectSetInteger(0, lblName, OBJPROP_ANCHOR,     ANCHOR_LOWER);
   ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE,   9);
   ObjectSetInteger(0, lblName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, lblName, OBJPROP_HIDDEN,     true);

   return offset;
}

// ====================================================================
// FOREX SESSION BOXES
// ====================================================================
void BuildSessionDefs()
{
   g_sessions[0].name="Sydney"; g_sessions[0].startH=InpSydneyStart; g_sessions[0].endH=InpSydneyEnd;
   g_sessions[0].col=InpSydneyCol; g_sessions[0].enabled=InpShowSydney;

   g_sessions[1].name="Tokyo";  g_sessions[1].startH=InpTokyoStart;  g_sessions[1].endH=InpTokyoEnd;
   g_sessions[1].col=InpTokyoCol;  g_sessions[1].enabled=InpShowTokyo;

   g_sessions[2].name="London"; g_sessions[2].startH=InpLondonStart; g_sessions[2].endH=InpLondonEnd;
   g_sessions[2].col=InpLondonCol; g_sessions[2].enabled=InpShowLondon;

   g_sessions[3].name="NY";     g_sessions[3].startH=InpNYStart;     g_sessions[3].endH=InpNYEnd;
   g_sessions[3].col=InpNYCol;     g_sessions[3].enabled=InpShowNY;
}

void ClearSessionObjects()
{
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--)
   {
      string n = ObjectName(0, i, -1, -1);
      if(StringFind(n, SESS_PFX) == 0) ObjectDelete(0, n);
   }
}

datetime DayStart(datetime t)
{
   MqlDateTime mt; TimeToStruct(t, mt);
   mt.hour=0; mt.min=0; mt.sec=0;
   return StructToTime(mt);
}

void SessionRange(const SessionDef &s, datetime dayBase, datetime &t0, datetime &t1)
{
   t0 = dayBase + (datetime)s.startH * 3600;
   if(s.endH > s.startH)
      t1 = dayBase + (datetime)s.endH * 3600;
   else
      t1 = dayBase + 86400 + (datetime)s.endH * 3600;  // wraps past midnight
}

bool RangeHighLow(datetime t0, datetime t1, double &hi, double &lo)
{
   int i0 = iBarShift(_Symbol, _Period, t0, false);
   int i1 = iBarShift(_Symbol, _Period, t1, false);
   if(i0 < 0 || i1 < 0) return false;

   int from = MathMin(i0, i1);
   int to   = MathMax(i0, i1);
   int count = to - from + 1;
   if(count <= 0) return false;

   double highs[], lows[];
   if(CopyHigh(_Symbol, _Period, from, count, highs) <= 0) return false;
   if(CopyLow (_Symbol, _Period, from, count, lows ) <= 0) return false;

   hi = highs[ArrayMaximum(highs)];
   lo = lows [ArrayMinimum(lows )];
   return (hi > 0 && lo > 0 && hi >= lo);
}

void DrawSessionBox(string name, datetime t0, datetime t1, double hi, double lo, color col)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, t0, hi, t1, lo);
   else
   {
      ObjectMove(0, name, 0, t0, hi);
      ObjectMove(0, name, 1, t1, lo);
   }
   ObjectSetInteger(0, name, OBJPROP_COLOR,        col);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,      col);
   ObjectSetInteger(0, name, OBJPROP_FILL,         InpSessFill);
   ObjectSetInteger(0, name, OBJPROP_BACK,         InpSessInBack);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,        1);
   ObjectSetInteger(0, name, OBJPROP_STYLE,        STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,   false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,       true);
}

void DrawSessionBoxes()
{
   ClearSessionObjects();
   if(!InpSessEnabled) return;

   // Use the latest of TimeCurrent / TimeTradeServer / last-bar-time as "now".
   // TimeCurrent can stall when the symbol hasn't ticked recently, which would
   // otherwise let an in-progress session slip past the check.
   datetime tc       = TimeCurrent();
   datetime ts       = TimeTradeServer();
   datetime lastBarT = iTime(_Symbol, _Period, 0);
   datetime now      = tc;
   if(ts       > now) now = ts;
   if(lastBarT > now) now = lastBarT;
   if(now == 0) return;

   datetime today0 = DayStart(now);

   for(int d = InpSessHistoryDays; d >= 0; --d)
   {
      datetime base = today0 - (datetime)d * 86400;

      for(int s = 0; s < ArraySize(g_sessions); ++s)
      {
         if(!g_sessions[s].enabled) continue;

         datetime t0, t1;
         SessionRange(g_sessions[s], base, t0, t1);
         if(t1 <= t0) continue;
         // Skip any session window that is not fully closed in the past.
         if(t0 >= now) continue;   // hasn't started
         if(t1 >  now) continue;   // hasn't ended
         // Don't draw boxes that extend past the last loaded bar of the chart.
         if(lastBarT > 0 && t1 > lastBarT) continue;

         double hi, lo;
         if(!RangeHighLow(t0, t1, hi, lo)) continue;

         string id = SESS_PFX + g_sessions[s].name + "_" + IntegerToString((long)base);
         DrawSessionBox(id, t0, t1, hi, lo, g_sessions[s].col);
      }
   }
}

// ====================================================================
// WATERMARK (TradingView-style: custom text + symbol/period below)
// ====================================================================
ENUM_ANCHOR_POINT AnchorForCorner(ENUM_BASE_CORNER c)
{
   switch(c)
   {
      case CORNER_LEFT_UPPER:  return ANCHOR_LEFT_UPPER;
      case CORNER_RIGHT_UPPER: return ANCHOR_RIGHT_UPPER;
      case CORNER_LEFT_LOWER:  return ANCHOR_LEFT_LOWER;
      case CORNER_RIGHT_LOWER: return ANCHOR_RIGHT_LOWER;
   }
   return ANCHOR_LEFT_UPPER;
}

void DeleteWatermark()
{
   if(ObjectFind(0, WM_MAIN) >= 0) ObjectDelete(0, WM_MAIN);
   if(ObjectFind(0, WM_SUB ) >= 0) ObjectDelete(0, WM_SUB );
}

void DrawWatermark()
{
   DeleteWatermark();
   if(!InpWmEnabled) return;

   string mainText = InpWmText;
   StringTrimLeft(mainText);
   StringTrimRight(mainText);
   bool hasMain = (StringLen(mainText) > 0);

   string subText = _Symbol + ", " + TfToString(_Period);

   ENUM_BASE_CORNER  corner;
   ENUM_ANCHOR_POINT anchor;
   int mainX, mainY, subX, subY;

   if(InpWmCentered)
   {
      // Center on chart using pixel dimensions; ANCHOR_CENTER aligns label to its midpoint.
      int cw = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
      int ch = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
      // Account for actual rendered glyph height (bold fonts ~= 1.7x font size).
      int mainHalf = (InpWmMainSize * 17) / 20;  // ~= 0.85 * size
      int subHalf  = (InpWmSubSize  * 17) / 20;
      int vGap     = MathMax(0, InpWmLineGap);    // visible gap between the two lines
      corner = CORNER_LEFT_UPPER;
      anchor = ANCHOR_CENTER;
      mainX  = cw / 2;
      subX   = cw / 2;
      if(hasMain)
      {
         mainY = ch / 2 - (mainHalf + vGap / 2);
         subY  = ch / 2 + (subHalf  + vGap / 2);
      }
      else
      {
         // No title: center the sub line on the chart.
         // Optical adjustment: ANCHOR_CENTER aligns bounding-box center, but bold
         // fonts include descender space, so caps-dominant text like "USDJPY"
         // appears low. Nudge up ~25% of font size to align the optical center.
         mainY = ch / 2;
         subY  = ch / 2 - InpWmSubSize / 4;
      }
   }
   else
   {
      corner = InpWmCorner;
      anchor = AnchorForCorner(InpWmCorner);
      bool isLower = (InpWmCorner == CORNER_LEFT_LOWER || InpWmCorner == CORNER_RIGHT_LOWER);
      // With "lower" corners: Y grows upward, so sub at small Y, main above (larger Y).
      // With "upper" corners: Y grows downward, so main at small Y, sub below (larger Y).
      mainX = InpWmX;
      subX  = InpWmX;
      if(hasMain)
      {
         mainY = isLower ? (InpWmY + InpWmSubSize + 8) : InpWmY;
         subY  = isLower ? InpWmY                       : (InpWmY + InpWmMainSize + 8);
      }
      else
      {
         // No title: place sub at the configured offset, no extra gap.
         mainY = InpWmY;
         subY  = InpWmY;
      }
   }

   // Main custom text (skipped when title is empty)
   if(hasMain)
   {
      ObjectCreate(0, WM_MAIN, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, WM_MAIN, OBJPROP_CORNER,     corner);
      ObjectSetInteger(0, WM_MAIN, OBJPROP_ANCHOR,     anchor);
      ObjectSetInteger(0, WM_MAIN, OBJPROP_XDISTANCE,  mainX);
      ObjectSetInteger(0, WM_MAIN, OBJPROP_YDISTANCE,  mainY);
      ObjectSetString (0, WM_MAIN, OBJPROP_TEXT,       mainText);
      ObjectSetInteger(0, WM_MAIN, OBJPROP_COLOR,      InpWmColor);
      ObjectSetInteger(0, WM_MAIN, OBJPROP_FONTSIZE,   InpWmMainSize);
      ObjectSetString (0, WM_MAIN, OBJPROP_FONT,       InpWmFont);
      ObjectSetInteger(0, WM_MAIN, OBJPROP_BACK,       true);
      ObjectSetInteger(0, WM_MAIN, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, WM_MAIN, OBJPROP_HIDDEN,     true);
      ObjectSetInteger(0, WM_MAIN, OBJPROP_ZORDER,     0);
   }

   // Sub text: symbol + period
   ObjectCreate(0, WM_SUB, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, WM_SUB, OBJPROP_CORNER,     corner);
   ObjectSetInteger(0, WM_SUB, OBJPROP_ANCHOR,     anchor);
   ObjectSetInteger(0, WM_SUB, OBJPROP_XDISTANCE,  subX);
   ObjectSetInteger(0, WM_SUB, OBJPROP_YDISTANCE,  subY);
   ObjectSetString (0, WM_SUB, OBJPROP_TEXT,       subText);
   ObjectSetInteger(0, WM_SUB, OBJPROP_COLOR,      InpWmColor);
   ObjectSetInteger(0, WM_SUB, OBJPROP_FONTSIZE,   InpWmSubSize);
   ObjectSetString (0, WM_SUB, OBJPROP_FONT,       InpWmFont);
   ObjectSetInteger(0, WM_SUB, OBJPROP_BACK,       true);
   ObjectSetInteger(0, WM_SUB, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, WM_SUB, OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0, WM_SUB, OBJPROP_ZORDER,     0);
}
