/**
 * @file 3EMA_MultiTime.mqh
 * @author fxowl (javajava0708@gmail.com)
 * @brief
 * @version 1.0
 * @date 2023-05-26
 *
 * @copyright Copyright (c) 2023
 *
 */
#property copyright "2023_05, FXOWL."
#property link "https://github.com/FXOWL/mt4-autotrade"
#property version "1.1"
#property strict

#include <EAStrategy/MovingAverage.mqh>
#include <Generic/HashMap.mqh>

#property indicator_chart_window

static const double VERSION = 1.0;
static const string TIMESTAMP = (string)TimeCurrent();
static const string INDICATOR_BASENAME = "3EMA_MultiTime";
static const string INDICATOR_NAME =
    INDICATOR_BASENAME + "_Ver" + (string)VERSION + " - id" + (string)WindowsTotal() + StringSubstr(TIMESTAMP, StringLen(TIMESTAMP) - 1);

/** ユーザー設定項目 **************************************************************************************************/
input string BASE_SETTING_GROUP = ""; // ↓** 基本設定項目 **↓
// トレンドを確認する通貨ペアを入力する
input int I_FAST_PERIOD = 5; // 短期EMA期間
input int I_FAST_SHIFT = 0; // 短期EMA表示移動
input int I_MIDDLE_PERIOD = 20; // 中期EMA期間
input int I_MIDDLE_SHIFT = 0; // 中期EMA表示移動
input int I_LONG_PERIOD = 40; // 長期EMA期間
input int I_LONG_SHIFT = 0; // 長期EMA表示移動
input string I_CURRENCY_PAIRS = "USDJPY,EURUSD,GBPUSD,AUDUSD,USDCAD,USDCHF,EURGBP"; // 表示通貨ペア(カンマ区切り)
string currency_pairs[]; // スプレッドしたI_CURRENCY_PAIRSの通貨ペアを格納する

input string DISPLAY_SETTING_GROUP = ""; // ↓** 表示設定項目 **↓
enum DISPLAY_CORNER
{
    LEFT_UPPER = CORNER_LEFT_UPPER, // 左上
    LEFT_LOWER = CORNER_LEFT_LOWER // 左下
};
// メモ 3,4は表示順序が反転するため今は対応しない
input DISPLAY_CORNER I_CORNER = CORNER_LEFT_LOWER; // トレンドテーブル表示位置
input color I_TIMEFRAME_COLOR = clrRed; // 時間軸の文字色
input color I_CURRENCYPAIR_COLOR = clrGold; // 通貨ペアの文字色
input color I_ARROW_NORMAL_COLOR = clrGray; // 「↑」シンボルの色
input color I_ARROW_UP_COLOR = clrRed; // 「→」シンボルの色
input color I_ARROW_DOWN_COLOR = clrBlue; // 「↓」シンボルの色

/** 表示の基本設定 **************************************************************************************************/
// トレンドを表示する時間軸の項目名
string periodStrings[9] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1", "W1", "MN1"};
// string periodStrings[] = {"M5", "M15", "H1", "H4", "D1"};
// トレンドテーブル
static const string COLUMN_BASENAME = "Col_";
static const int HORIZONTAL_HEADER_DISTANCE = 70; // 一列目の水平方向の幅
static const int HORIZONTAL_DISTANCE = 20; // セルの水平方向の幅
static const int VERTICAL_DISTANCE = 20; // セルの垂直方向の幅

// 表示文字
static const string FONT_DEFAULT = "Arial";
static const int FONT_SIZE = 8;

// シンボル表示
static const string FONT_DECORATION_SYMBOL = "Wingdings 3"; // アローの表示で使用する装飾記号
static const int SYMBOLCODE_ARROW_UP = 219; // 「Wingdings 3」では163,199,219のいずれかを使用する
static const int SYMBOLCODE_ARROW_DOWN = 220; // 「Wingdings 3」では164,200,220のいずれかを使用する
static const int SYMBOLCODE_NO_SIGNAL = 218;
static const int SYMBOL_SIZE = 10;

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

/**
 * @brief 入力値を検証する
 *
 * @return true
 * @return false
 */
bool InputValidation()
{
    int count = StringSplit(I_CURRENCY_PAIRS, ',', currency_pairs);
    for (int i = 0; i < count; i++) {
        double result = MarketInfo(currency_pairs[i], MODE_TRADEALLOWED);
        if (result == 0) {
            Print("|入力値エラー|I_CURRENCY_PAIRS[" + currency_pairs[i] + "]が入力されたため、処理を中断しました。|");
            return false;
        }
    }
    return true;
}

int OnInit()
{
    if (InputValidation() == false) return (INIT_PARAMETERS_INCORRECT);

    InitStrToTimeframeMap();
    IndicatorShortName(INDICATOR_NAME);
    int windex = WindowFind(INDICATOR_NAME);
    Print("debug windex" + (string)windex);

    if (ObjectCreate("3EMA", OBJ_LABEL, windex, 0, 0)) {
        ObjectSet("3EMA", OBJPROP_XDISTANCE, 20); // 横軸
        ObjectSet("3EMA", OBJPROP_YDISTANCE, VERTICAL_DISTANCE); // 縦軸
        ObjectSet("3EMA", OBJPROP_CORNER, I_CORNER); // オブジェクトの画面表示位置
        ObjectSetText("3EMA", "3EMA", FONT_SIZE, FONT_DEFAULT, Gray);
    }
    // ヘッダー行を作成
    for (int x = 0; x < ArraySize(periodStrings); x++) {
        string header_name = COLUMN_BASENAME + (string)x;
        if (ObjectCreate(header_name, OBJ_LABEL, windex, 0, 0)) {
            ObjectSet(header_name, OBJPROP_XDISTANCE, (HORIZONTAL_DISTANCE * x) + HORIZONTAL_HEADER_DISTANCE); // 横軸
            ObjectSet(header_name, OBJPROP_YDISTANCE, VERTICAL_DISTANCE); // 縦軸
            ObjectSet(header_name, OBJPROP_CORNER, I_CORNER); // オブジェクトの画面表示位置
            ObjectSetText(header_name, periodStrings[x], FONT_SIZE, FONT_DEFAULT, I_TIMEFRAME_COLOR);
        }
    }

    for (int y = 0; y < ArraySize(currency_pairs); y++) {
        // ヘッダー列を作成
        string currency_pair = currency_pairs[y];
        if (ObjectCreate(currency_pair, OBJ_LABEL, windex, 0, 0)) {
            ObjectSet(currency_pair, OBJPROP_XDISTANCE, 20);
            ObjectSet(currency_pair, OBJPROP_YDISTANCE, ((y + 1) * VERTICAL_DISTANCE) + VERTICAL_DISTANCE);
            ObjectSet(currency_pair, OBJPROP_CORNER, I_CORNER);
            ObjectSetText(currency_pair, currency_pair, FONT_SIZE, FONT_DEFAULT, I_CURRENCYPAIR_COLOR);
        }
        // トレンドシグナルアイコンを初期化する
        for (int x = 0; x < ArraySize(periodStrings); x++) {
            string unique_key = CreateCurrencySignalMapKey(currency_pair, x);
            if (ObjectCreate(unique_key, OBJ_LABEL, windex, 0, 0)) {
                ObjectSet(unique_key, OBJPROP_XDISTANCE, (HORIZONTAL_DISTANCE * x) + HORIZONTAL_HEADER_DISTANCE);
                ObjectSet(unique_key, OBJPROP_YDISTANCE, ((y + 1) * VERTICAL_DISTANCE) + VERTICAL_DISTANCE);
                ObjectSet(unique_key, OBJPROP_CORNER, I_CORNER);
                ObjectSetText(unique_key, CharToStr(SYMBOLCODE_NO_SIGNAL), SYMBOL_SIZE, FONT_DECORATION_SYMBOL, clrGray);
            }
        }
    }
    return (INIT_SUCCEEDED);
}

CHashMap<string, MovingAverage3Line *> curency_signal_map;
void OnDeinit(const int reason)
{
    ObjectDelete("3EMA");
    for (int x = 0; x < ArraySize(periodStrings); x++) {
        string header_name = COLUMN_BASENAME + (string)x;
        ObjectDelete(header_name);
    }

    for (int y = 0; y < ArraySize(currency_pairs); y++) {
        string currency_pair = currency_pairs[y];
        ObjectDelete(currency_pair);
        for (int x = 0; x < ArraySize(periodStrings); x++) {
            string unique_key = CreateCurrencySignalMapKey(currency_pair, x);
            ObjectDelete(unique_key);
            curency_signal_map.Remove(unique_key);
        }
    }
    return;
}

MovingAverage3Line *createMovingAverage3Line(string symbol, int timeframe, int shift = 0)
{
    return new MovingAverage3Line(
        iMA(symbol, timeframe, I_FAST_PERIOD, I_FAST_SHIFT, MODE_EMA, PRICE_CLOSE, shift),
        iMA(symbol, timeframe, I_MIDDLE_PERIOD, I_MIDDLE_SHIFT, MODE_EMA, PRICE_CLOSE, shift),
        iMA(symbol, timeframe, I_LONG_PERIOD, I_LONG_SHIFT, MODE_EMA, PRICE_CLOSE, shift)
    );
};

int OnCalculate(
    const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[],
    const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]
)
{
    int windex = WindowFind(INDICATOR_NAME);

    ENUM_TIMEFRAMES timeframe;
    for (int currency_no = 0; currency_no < ArraySize(currency_pairs); currency_no++) {
        string currency_pair = currency_pairs[currency_no];
        // Print("Debug currency_pair:" + currency_pair);
        for (int period_num = 0; period_num < ArraySize(periodStrings); period_num++) {
            str_timeframe_map.TryGetValue(periodStrings[period_num], timeframe);

            MovingAverage3Line *signal = createMovingAverage3Line(currency_pair, timeframe, 1);

            string unique_key = CreateCurrencySignalMapKey(currency_pair, period_num);
            curency_signal_map.Add(unique_key, signal);

            if (signal.IsUpTrend()) {
                ObjectSetText(unique_key, CharToStr(SYMBOLCODE_ARROW_UP), SYMBOL_SIZE, FONT_DECORATION_SYMBOL, I_ARROW_UP_COLOR);
            }
            else if (signal.IsDownTrend()) {
                ObjectSetText(unique_key, CharToStr(SYMBOLCODE_ARROW_DOWN), SYMBOL_SIZE, FONT_DECORATION_SYMBOL, I_ARROW_DOWN_COLOR);
            }
            else {
                ObjectSetText(unique_key, CharToStr(SYMBOLCODE_NO_SIGNAL), SYMBOL_SIZE, FONT_DECORATION_SYMBOL, I_ARROW_NORMAL_COLOR);
            }
        }
    }
    return (rates_total);
}
