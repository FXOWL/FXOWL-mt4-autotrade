/**
 * @file Muzunai_MultiTimeTrend_v1.mqh
 * @author fxowl (javajava0708@gmail.com)
 * @brief
 * @version 1.0
 * @date 2023-05-15
 *
 * @copyright Copyright (c) 2023
 *
 */
#property copyright "2023_05, FXOWL."
#property link "https://github.com/FXOWL/mt4-autotrade"
#property version "1.00"
#property strict

#include <Generic/HashMap.mqh>

// #property indicator_separate_window
#property indicator_chart_window

string periodStrings[] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1", "W1", "MN1"};
// string periodStrings[] = {"M5", "M15", "H1", "H4", "D1"};
CHashMap<string, ENUM_TIMEFRAMES> str_timeframe_map;
void InitStrToTimeframeMap()
{
    str_timeframe_map.Add("M1", PERIOD_M1);
    str_timeframe_map.Add("M5", PERIOD_M5);
    str_timeframe_map.Add("M15", PERIOD_M15);
    str_timeframe_map.Add("M30", PERIOD_M30);
    str_timeframe_map.Add("H1", PERIOD_H1);
    str_timeframe_map.Add("H4", PERIOD_H4);
    str_timeframe_map.Add("D1", PERIOD_D1);
    str_timeframe_map.Add("W1", PERIOD_W1);
    str_timeframe_map.Add("MN1", PERIOD_MN1);
}

string currencies[];
input string currency_pairs = "USDJPY,EURUSD,GBPUSD,AUDUSD,USDCAD,USDCNH,USDCHF,EURGBP"; // 表示通貨ペア(カンマ区切り)

static const double VERSION = 0.1;
static const string TIMESTAMP = (string)TimeCurrent();
static const string INDICATOR_BASENAME = "Muzunai";
static const string INDICATOR_NAME =
    INDICATOR_BASENAME + "_Ver" + (string)VERSION + " - id" + (string)WindowsTotal() + StringSubstr(TIMESTAMP, StringLen(TIMESTAMP) - 1);

// トレンド一覧表基本設定
static const string col_header_basename = "Col_Header";
static const string field_header_basename = "field_Header";
static const int CORNER = 0; // 画面の表示位置 0=左上 1=右上 2=左下 3=右下
static const int VERTICAL_DISTANCE = 20;
static const int HORIZONTAL_HEADER_DISTANCE = 70; // 一列目の水平幅
static const int HORIZONTAL_DISTANCE = 20;
static const int SYMBOLCODE_ARROW_UP = 219; // 「Wingdings 3」では163,199,219のいずれかを使用する
static const int SYMBOLCODE_ARROW_DOWN = 220; // 「Wingdings 3」では164,200,220のいずれかを使用する
static const int SYMBOLCODE_NO_SIGNAL = 218;
static const int FONT_SIZE = 8;
static const int SYMBOL_SIZE = 10;

/**
 * @brief マップのキーを作成する
 * Mapをネスト出来なかったので、Keyで以下の構造を表現している
 * CHashMap<string(通貨ペア名), CHashMap<string(), TrendSignal *>>
 *
 * @param currency_pair 通貨ペア名
 * @param period_no periodStringsの配列番号
 * @return string
 */
string CreateCurrencySignalMapKey(string currency_pair, int period_no) { return currency_pair + "_" + (string)period_no; }

interface TrendSignal {
    bool IsUpTrend();
    bool IsDownTrend();
};

class MuzunaiSignal : public TrendSignal {
    // class MuzunaiSignal : public CObject {
    string _symbol;
    ENUM_TIMEFRAMES _period;
    double _close, _middle, _1sigma_upper, _1sigma_lower, _2sigma_upper, _2sigma_lower, _3sigma_upper, _3sigma_lower;

   public:
    MuzunaiSignal(string symbol, ENUM_TIMEFRAMES period)
    {
        _close = iClose(symbol, period, 0);
        _symbol = symbol;
        _3sigma_upper = iBands(symbol, period, 20, 3, 0, PRICE_CLOSE, MODE_UPPER, 0);
        _2sigma_upper = iBands(symbol, period, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 0);
        _1sigma_upper = iBands(symbol, period, 20, 1, 0, PRICE_CLOSE, MODE_UPPER, 0);
        _middle = iBands(symbol, period, 20, 1, 0, PRICE_CLOSE, MODE_MAIN, 0);
        _1sigma_lower = iBands(symbol, period, 20, 1, 0, PRICE_CLOSE, MODE_LOWER, 0);
        _2sigma_lower = iBands(symbol, period, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 0);
        _3sigma_lower = iBands(symbol, period, 20, 3, 0, PRICE_CLOSE, MODE_LOWER, 0);
    };
    // ~MuzunaiSignal(){};
    // 終値が1σ超過の場合は上昇トレンドと判定する
    bool IsUpTrend() { return _close > _1sigma_upper; }
    // 終値が-1σ未満の場合は下降トレンドと判定する
    bool IsDownTrend() { return _close < _1sigma_lower; }
    // 　終値が0σ超過、且つ、2σ未満の場合買い(下位足で使用すること)
    bool IsBuyEntry() { return _close < _2sigma_upper && _close > _middle; };
    // 　終値が0σ未満、且つ、-2σ超過の場合売り(下位足で使用すること)
    bool IsSellEntry() { return _close > _2sigma_lower && _close < _middle; };
    // 終値が1σ未満で買いポジションをクローズ
    bool IsBuyClose() { return _close < _1sigma_upper; };
    // 終値が-1σ以上で売りポジションをクローズ
    bool IsSellClose() { return _close > _1sigma_lower; };
};

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    int count = StringSplit(currency_pairs, ',', currencies);
    for (int i = 0; i < count; i++) {
        double result = MarketInfo(currencies[i], MODE_TRADEALLOWED);
        if (result == 0) {
            Print(
                "|入力値エラー|currency_pairsに、トレードが許可されていない通貨ペア[" + currencies[i] +
                "]が入力されたため、処理を中断しました。|"
            );
            return (INIT_PARAMETERS_INCORRECT);
        }
    }

    InitStrToTimeframeMap();
    IndicatorShortName(INDICATOR_NAME);
    int windex = WindowFind(INDICATOR_NAME);
    Print("debug windex" + (string)windex);

    // ヘッダー行を作成
    for (int x = 0; x < ArraySize(periodStrings); x++) {
        string header_name = "Col_Header" + (string)x;
        if (ObjectCreate(header_name, OBJ_LABEL, windex, 0, 0)) {
            ObjectSet(header_name, OBJPROP_XDISTANCE, (HORIZONTAL_DISTANCE * x) + HORIZONTAL_HEADER_DISTANCE); // 横軸
            ObjectSet(header_name, OBJPROP_YDISTANCE, VERTICAL_DISTANCE); // 縦軸
            ObjectSet(header_name, OBJPROP_CORNER, CORNER); // オブジェクトの画面表示位置
            ObjectSetText(header_name, periodStrings[x], FONT_SIZE, "Arial", clrRed);
        }
    }

    for (int y = 0; y < ArraySize(currencies); y++) {
        // ヘッダー列を作成
        string currency_pair = currencies[y];
        if (ObjectCreate(currency_pair, OBJ_LABEL, windex, 0, 0)) {
            ObjectSet(currency_pair, OBJPROP_XDISTANCE, 20);
            ObjectSet(currency_pair, OBJPROP_YDISTANCE, ((y + 1) * VERTICAL_DISTANCE) + VERTICAL_DISTANCE);
            ObjectSetText(currency_pair, currency_pair, FONT_SIZE, "Arial", clrRed);
        }
        // トレンドシグナルアイコンを初期化する
        for (int x = 0; x < ArraySize(periodStrings); x++) {
            string unique_key = CreateCurrencySignalMapKey(currency_pair, x);
            if (ObjectCreate(unique_key, OBJ_LABEL, windex, 0, 0)) {
                ObjectSet(unique_key, OBJPROP_XDISTANCE, (HORIZONTAL_DISTANCE * x) + HORIZONTAL_HEADER_DISTANCE);
                ObjectSet(unique_key, OBJPROP_YDISTANCE, ((y + 1) * VERTICAL_DISTANCE) + VERTICAL_DISTANCE);
                ObjectSet(unique_key, OBJPROP_CORNER, CORNER);
                ObjectSetText(unique_key, CharToStr(SYMBOLCODE_NO_SIGNAL), SYMBOL_SIZE, "Wingdings 3", clrGray);
            }
        }
    }

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    // ObjectsDeleteAll();

    for (int x = 0; x < ArraySize(periodStrings); x++) {
        string header_name = "Col_Header" + (string)x;
        ObjectDelete(header_name);
    }

    for (int y = 0; y < ArraySize(currencies); y++) {
        string currency_pair = currencies[y];
        ObjectDelete(currency_pair);
        for (int x = 0; x < ArraySize(periodStrings); x++) {
            string unique_key = CreateCurrencySignalMapKey(currency_pair, x);
            ObjectDelete(unique_key);
            curency_signal_map.Remove(unique_key);
        }
    }
    return;
}

CHashMap<string, TrendSignal *> curency_signal_map;

int OnCalculate(
    const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[],
    const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]
)
{
    int windex = WindowFind(INDICATOR_NAME);

    ENUM_TIMEFRAMES timeframe;
    for (int currency_no = 0; currency_no < ArraySize(currencies); currency_no++) {
        string currency_pair = currencies[currency_no];
        // Print("Debug currency_pair:" + currency_pair);
        for (int period_num = 0; period_num < ArraySize(periodStrings); period_num++) {
            str_timeframe_map.TryGetValue(periodStrings[period_num], timeframe);

            MuzunaiSignal *signal = new MuzunaiSignal(currency_pair, timeframe);

            string unique_key = CreateCurrencySignalMapKey(currency_pair, period_num);
            curency_signal_map.Add(unique_key, signal);

            if (signal.IsUpTrend()) {
                ObjectSetText(unique_key, CharToStr(SYMBOLCODE_ARROW_UP), SYMBOL_SIZE, "Wingdings 3", clrRed);
            }
            else if (signal.IsDownTrend()) {
                ObjectSetText(unique_key, CharToStr(SYMBOLCODE_ARROW_DOWN), SYMBOL_SIZE, "Wingdings 3", clrBlue);
            }
            else {
                ObjectSetText(unique_key, CharToStr(SYMBOLCODE_NO_SIGNAL), SYMBOL_SIZE, "Wingdings 3", clrGray);
            }
        }
    }

    return (rates_total);
}
