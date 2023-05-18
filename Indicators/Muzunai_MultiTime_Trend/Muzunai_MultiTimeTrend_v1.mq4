/**
 * @file Muzunai_MultiTimeTrend_v1.mqh
 * @author fxowl (javajava0708@gmail.com)
 * @brief
 * @version 1.1
 * @date 2023-05-15
 *
 * @copyright Copyright (c) 2023
 *
 */
#property copyright "2023_05, FXOWL."
#property link "https://github.com/FXOWL/mt4-autotrade"
#property version "1.1"
#property strict

#include <Generic/HashMap.mqh>

#property indicator_chart_window

static const double VERSION = 1.1;
static const string TIMESTAMP = (string)TimeCurrent();
static const string INDICATOR_BASENAME = "Muzunai";
static const string INDICATOR_NAME =
    INDICATOR_BASENAME + "_Ver" + (string)VERSION + " - id" + (string)WindowsTotal() + StringSubstr(TIMESTAMP, StringLen(TIMESTAMP) - 1);

/** ユーザー設定項目 **************************************************************************************************/
input string BASE_SETTING_GROUP = ""; // ↓** 基本設定項目 **↓
// トレンドを確認する通貨ペアを入力する
input string I_CURRENCY_PAIRS = "USDJPY,EURUSD,GBPUSD,AUDUSD,USDCAD,USDCNH,USDCHF,EURGBP"; // 表示通貨ペア(カンマ区切り)
string currency_pairs[]; // スプレッドしたI_CURRENCY_PAIRSの通貨ペアを格納する

input string DISPLAY_SETTING_GROUP = ""; // ↓** 表示設定項目 **↓
enum MUZUNAI_CORNER
{
    LEFT_UPPER = CORNER_LEFT_UPPER, // 左上
    LEFT_LOWER = CORNER_LEFT_LOWER // 左下
};
// メモ 3,4は表示順序が反転するため今は対応しない
input MUZUNAI_CORNER I_CORNER = CORNER_LEFT_LOWER; // トレンドテーブル表示位置
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
        // _3sigma_upper = iBands(symbol, period, 20, 3, 0, PRICE_CLOSE, MODE_UPPER, 0);
        _2sigma_upper = iBands(symbol, period, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 0);
        _1sigma_upper = iBands(symbol, period, 20, 1, 0, PRICE_CLOSE, MODE_UPPER, 0);
        _middle = iBands(symbol, period, 20, 1, 0, PRICE_CLOSE, MODE_MAIN, 0);
        _1sigma_lower = iBands(symbol, period, 20, 1, 0, PRICE_CLOSE, MODE_LOWER, 0);
        _2sigma_lower = iBands(symbol, period, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 0);
        // _3sigma_lower = iBands(symbol, period, 20, 3, 0, PRICE_CLOSE, MODE_LOWER, 0);
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

int OnInit()
{
    int count = StringSplit(I_CURRENCY_PAIRS, ',', currency_pairs);
    for (int i = 0; i < count; i++) {
        double result = MarketInfo(currency_pairs[i], MODE_TRADEALLOWED);
        if (result == 0) {
            Print("|入力値エラー|I_CURRENCY_PAIRS[" + currency_pairs[i] + "]が入力されたため、処理を中断しました。|");
            return (INIT_PARAMETERS_INCORRECT);
        }
    }

    InitStrToTimeframeMap();
    IndicatorShortName(INDICATOR_NAME);
    int windex = WindowFind(INDICATOR_NAME);
    Print("debug windex" + (string)windex);

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

CHashMap<string, TrendSignal *> curency_signal_map;
void OnDeinit(const int reason)
{
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

            MuzunaiSignal *signal = new MuzunaiSignal(currency_pair, timeframe);

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
