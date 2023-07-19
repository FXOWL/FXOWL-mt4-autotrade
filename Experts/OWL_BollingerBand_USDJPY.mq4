/**
 * @file OWL_BollingerBand_USDJPY.mq4
 *
 *
 *
 * @author fxowl(javajava0708@gmail.com)
 * @brief
 * @version 0.1
 * @date 2023-07-03
 *
 * @copyright Copyright (c) 2023
 *
 */

#property copyright "2023_07, FXOWL."
#property version "1.00"
#property strict
#property description "日本時間の16-21時に時間帯にBBでトレードするEA"

#include <EAStrategy/BollingerBands.mqh>
#include <Tools/DateTimeExt.mqh>
#include <TradeForMT4/AccountInfo.mqh>
#include <stderror.mqh>
#include <stdlib.mqh>

input int MAGICMA = 20230703; // マジックナンバー
// input double InpTakeProfit = 50.0; // 利益確定幅(pips)
// input double InpLossCut = 20.0; // 損切確定幅(pips)
input int I_SLIPPAGE = 4; // スリッページ上限
input double I_SPREADLIMIT = 10; // スプレッド上限
input double I_LOTS = 0.01; // ロット数固定値（0.01=1000通貨）
input double I_TRADE_MAXIMUMRISK = 0.1; // ロット数(余剰証拠金の何パーセントをロットに割り当てる。最大値1。0の場合は固定値)
input double I_DAILY_FREEMARGIN_RISK_RATIO = 0.05; // 一日の余剰証拠金のリスク率　最小値0.01-最大値１

// TRADING_START_TIMEからTRADING_AFTER_HOURS後迄トレードを許可する
const static int TRADING_START_TIME = 16;
const static int TRADING_AFTER_HOURS = 6;
const static double SL_MAGNIFICATION = 1.5; // SLの倍率(エントリー時のH4のATRの値が基準となる)
const static double TP_MAGNIFICATION = 3.0; // TPの倍率(エントリー時のH4のATRの値が基準となる)
double spread;
CAccountInfo account;
// MoneyManagement money_manager(I_DAILY_FREEMARGIN_RISK_RATIO);

int OnInit() { return (INIT_SUCCEEDED); }

void OnTick()
{
    bool allow_trading = true;

    // 取引を行う時間
    CDateTimeExt dt_local;
    dt_local.DateTime(TimeLocal());
    dt_local.Hour(TRADING_START_TIME);
    dt_local.Min(0);
    dt_local.Sec(0);
    CDateTimeExt dt_srv1 = dt_local.ToMtServerStruct();
    CDateTimeExt dt_srv2 = dt_local.ToMtServerStruct();
    dt_srv2.HourInc(TRADING_AFTER_HOURS);
    allow_trading &= dt_srv1.DateTime() <= Time[1] && dt_srv2.DateTime() > Time[1];

    // allow_trading &= money_manager.IsTradeAllow();
    allow_trading &= checkSpred(I_SPREADLIMIT);
    allow_trading &= CalculateCurrentOrders() == 0;
    if (allow_trading) CheckForOpen();
}

/**
 * @brief トレード時のスプレッドが設定した値を超えていないかをチェック
 *
 * @return bool
 */
bool checkSpred(double spredLimit)
{
    if (GetSpread() < spredLimit) return true;

    Print(
        "市場のスプレッド値が上限値を超えています。| 設定値:" + (string)spredLimit + "pips | 発注時スプレッド:" + (string)GetSpread() +
        "pips"
    );
    return false;
}

/** 現在のスプレッド値を取得する
 * @brief Get the Spread object
 * MarketInfo(NULL, MODE_SPREAD)と同じ結果だが、MarketInfoはブローカーから受信するため遅延することがある。
 * スキャル等の場合はこのメソッドの仕様を推奨する
 * @return double
 */
double GetSpread()
{
    // ブローカーの価格の桁数が2桁・4桁の場合
    // return (Ask - Bid) / (Point * 10);
    // ブローカーの価格の桁数が3桁・5桁の場合
    // double res = Ask - Bid;
    // Print("debug Ask - Bid" + (string)res); //0.008
    // Print("debug Point" + (string)Point); //0.001
    return (Ask - Bid) / Point;
}

double calculateTodayProfit()
{
    int total = OrdersHistoryTotal();
    double todayProfit = 0.0;
    datetime todayStart = iTime(_Symbol, PERIOD_D1, 0); // 当日の開始時刻を取得
    for (int i = total - 1; i >= 0; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false) continue;

        datetime closeTime = OrderCloseTime();
        if (closeTime < todayStart) break;
        double profit = OrderProfit();
        todayProfit += profit;
    }
    return todayProfit;
}

void CheckForOpen()
{
    Lot* lot = new Lot(I_LOTS, account);
    lot.Optimize(I_TRADE_MAXIMUMRISK);

    MuzunaiSignal* signal_M15 = new MuzunaiSignal(Symbol(), PERIOD_M5);
    MuzunaiSignal* signal_H1 = new MuzunaiSignal(Symbol(), PERIOD_H1);
    MuzunaiSignal* signal_H4 = new MuzunaiSignal(Symbol(), PERIOD_H4);
    MuzunaiSignal* signal_D1 = new MuzunaiSignal(Symbol(), PERIOD_D1);
    int ticket_no;

    double atr = iATR(NULL, PERIOD_H1, 20, 0);
    double sl, tp;
    double sl_range = NormalizeDouble(atr * SL_MAGNIFICATION, 5);
    double tp_range = NormalizeDouble(atr * TP_MAGNIFICATION, 5);

    if (signal_M15.IsTouch2SigmaLower() && signal_H1.IsUpTrend() && signal_H4.IsUpTrend()) {
        // if (signal_M15.IsTouch2SigmaLower() && signal_H1.IsUpTrend() && signal_H4.IsUpTrend() && signal_D1.IsUpTrend()) {
        sl = Ask - sl_range;
        tp = Ask + tp_range;
        ticket_no = OrderSend(Symbol(), OP_BUY, lot.Value(), Ask, I_SLIPPAGE, sl, tp, "", MAGICMA, 0, Red);
    }

    if (signal_M15.IsTouch2SigmaUpper() && signal_H1.IsDownTrend() && signal_H4.IsDownTrend()) {
        // if (signal_M15.IsTouch2SigmaUpper() && signal_H1.IsDownTrend() && signal_H4.IsDownTrend() && signal_D1.IsDownTrend()) {
        sl = Bid + sl_range;
        tp = Ask - tp_range;
        ticket_no = OrderSend(Symbol(), OP_SELL, lot.Value(), Bid, I_SLIPPAGE, sl, tp, "", MAGICMA, 0, Blue);
    }
    delete lot;
    delete signal_M15;
    delete signal_H1;
    delete signal_H4;
    delete signal_D1;
}

int CalculateCurrentOrders()
{
    int positions = 0;
    for (int i = 0; i < OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) break;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MAGICMA) {
            positions++;
        }
    }

    return positions;
}

void ErrorLog(int error_code, string message)
{
    string err_type = error_code <= 150 ? "server error" : "MQL error";
    printf("&s [%s code:%d]%s", message, err_type, error_code, ErrorDescription(error_code));
};

BollingerBands* createBollingerBands(ENUM_TIMEFRAMES timeframe) { return new BollingerBands(timeframe); };

class MuzunaiSignal {
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
    bool IsTouch2SigmaUpper() { return _close > _1sigma_upper; };
    bool IsTouch2SigmaLower() { return _close < _1sigma_lower; };
};

/**
 * @brief ロットクラス
 *
 */
class Lot {
   private:
    CAccountInfo* m_account;
    double m_value, m_currency_unit;
    string m_symbol;
    bool Valid(double value);

   public:
    Lot(const double value, CAccountInfo& a)
    {
        m_account = &a;
        m_currency_unit = 1000.0;
        if (!Valid(value)) {
            // SetUserError(ERR_USER_ERROR_FIRST);
            ErrorLog(ERR_USER_ERROR_FIRST, "Lotクラスのコンストラクタの引数に不正な値が代入されました。");
            return;
        }
        m_value = value;
    };
    bool CheckMaxLot(double lot);
    double Value();
    string ToString();
    void Optimize(const double maximum_risk);
};
bool Lot::Valid(const double value)
{
    if (value >= 0.01 || value < NormalizeDouble(m_account.FreeMargin() / m_currency_unit, 1)) {
        return true;
    }
    return false;
};
bool Lot::CheckMaxLot(double lot) { return lot < NormalizeDouble(m_account.FreeMargin() / m_currency_unit, 1); };
double Lot::Value() { return m_value; }
string Lot::ToString() { return (string)m_value; }

/**
 * @brief 余剰証拠金($)と引数の値を基にロット数を最適化する
 *
 * @param maximum_risk
 */
void Lot::Optimize(const double maximum_risk)
{
    if (maximum_risk < 0.01 || maximum_risk > 1) return;

    // 現在アカウントの余剰証拠金 * MaximumRisk / 1000
    double lots = NormalizeDouble(m_account.FreeMargin() * maximum_risk / m_currency_unit, 2);
    // TODO ブローカーごとにロットの最大値が違うと思うので後で調査し修正する
    m_value = lots > 99 ? 99 : lots;
}
