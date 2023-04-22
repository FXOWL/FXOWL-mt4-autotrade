//+------------------------------------------------------------------+
//|                                      General circulation EMA.mq4 |
//|                                      Copyright 2023-2023, fxowl. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+

/****************************************************************************************************
 * @file MovingAverage3Line.mq4
 * @author fxowl (https://twitter.com/UraRust)
 * @brief 移動平均線(EMA)で自動売買するEAです。
 * mt4標準のMAのEAをベースにカスタムしています。
 * 短期EMAが中期、長期EMAを上に抜けたら買い、短期EMAが中期、長期EMAを下に抜けたら売ります。
 * 決済はトレンドが終了したタイミングで決済します。
 * ロスカットはSLに設定した値で行います。
 * SLの値が0の場合は、「発注時の価格　+(-)（発注時のATRの値　×　SLAtrRanege）」でロスカットを設定します。
 *
 * 現在検証が十分に行われていなので、本番環境で稼働させる場合は自己責任でお願いします。
 *
 * @version 0.1
 * @date 2023-04-19
 *
 * @copyright Copyright (c) 2023
 *****************************************************************************************************/

#include <stderror.mqh>
#include <stdlib.mqh>

#property copyright "2023_04, fxowl."
#property description "移動平均線(EMA)で自動売買するEAです。"

#define MAGICMA 20230419
// ユーザー入力値
input double Lots = 0.1;
input double MaximumRisk = 0.02; // 余剰証拠金 * MaximumRisk / 1000 = lot
input double DecreaseFactor = 3; // 連敗時にロット数を減少する係数
input int MovingPeriod1 = 5; // 短期EMA期間
input int MovingShift1 = 6; // 短期EMA表示移動
input int MovingPeriod2 = 21; // 中期EMA期間
input int MovingShift2 = 6; // 中期EMA表示移動
input int MovingPeriod3 = 55; // 長期EMA期間
input int MovingShift3 = 6; // 長期EMA表示移動
input int SL = 100; // ストップロス
input double SLAtrRanege = 1.0; // SLが0の場合は、発注時ATR×設定値でロスカット

/**
 * @brief メイン処理
 *
 */
void OnTick()
{
    // 　バーが100未満、自動売買が許可されていない場合は処理を中断
    if (Bars < 100 || IsTradeAllowed() == false) return;

    if (CalculateCurrentOrders(Symbol()) == 0)
        // ポジションを持っていない場合は発注
        CheckForOpen();
    else
        // ポジションがある場合は決済
        CheckForClose();
}

/**
 * @brief 保有しているポジション数を返す
 *
 * @param symbol
 * @return int
 */
int CalculateCurrentOrders(string symbol)
{
    int buys = 0, sells = 0;
    // 保有しているポジションをチェック
    for (int i = 0; i < OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) break;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MAGICMA) {
            if (OrderType() == OP_BUY) buys++;
            if (OrderType() == OP_SELL) sells++;
        }
    }
    //--- return orders volume
    if (buys > 0)
        return (buys);
    else
        return (-sells);
}

/**
 * @brief 取引履歴の損失数を基に、ロット数を最適化する
 * @return double
 */
double LotsOptimized()
{
    double lot = Lots;
    int orders = HistoryTotal();
    int losses = 0; // 損失を出しているポジション数

    // 現在アカウントの余剰証拠金 * MaximumRisk / 1000
    lot = NormalizeDouble(AccountFreeMargin() * MaximumRisk / 1000.0, 1);

    // ロットの減少調整数値が0以上
    if (DecreaseFactor > 0) {
        for (int i = orders - 1; i >= 0; i--) {
            if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false) {
                Print("Error in history!");
                break;
            }
            if (OrderSymbol() != Symbol() || OrderType() > OP_SELL) continue;
            // 現在選択中の注文の損益がプラスなら終了
            if (OrderProfit() > 0) break;
            // 現在選択中の注文の損益がマイナスなら加算
            if (OrderProfit() < 0) losses++;
        }
        if (losses > 1) lot = NormalizeDouble(lot - lot * losses / DecreaseFactor, 1);
    }

    // オリジナルは0.1lot以下は0.1に設定されていた
    //  最小ロット数はユーザーが設定できるように変更しても良いかも
    //  if (lot < 0.1) lot = 0.1;

    return (lot);
}

/**
 * @brief 発注処理
 *
 */
void CheckForOpen()
{
    // 新しいバーの最初のティックのみトレードする
    if (Volume[0] > 1) return;

    MovingAverage3Line ma1(PERIOD_CURRENT);
    MovingAverage3Line ma_prev(PERIOD_CURRENT, 1);
    MovingAverage3Line ma2(getNextHigherTimeFrame(_Period));
    MovingAverage3Line ma3(get2NextHigherTimeFrame(_Period));

    BollingerBands bb(PERIOD_CURRENT);
    Rsi rsi(PERIOD_CURRENT);

    int res;
    double sl;
    // TODO:発注送信に失敗した場合のリトライをどうするか？
    /** sell entry ***************************************************************************************************************/
    // if (ma_prev.IsBuyClose() && ma1.IsSelEntry() && ma2.IsDownTorrend() && ma3.IsDownTorrend() && bb.IsSelEntry() && rsi.IsSelEntry()) {
    if (ma_prev.IsStage6() && ma1.IsSelEntry() && ma2.IsDownTorrend() && ma3.IsDownTorrend()) {
        // if (bb.IsSelEntry() && rsi.IsSelEntry()) {
        sl = SL == 0 ? Bid + NormalizeDouble(getAtr() * SLAtrRanege, 5) : Bid + SL * Point;

        // OrderSend( symbol, ordertype, lots[0.01単位], price, slippage[0.1pips],stoploss,takeprofit,comment,magic,expiration,arrow_color);
        res = OrderSend(Symbol(), OP_SELL, LotsOptimized(), Bid, 3, sl, 0, "", MAGICMA, 0, Red);
        // error handling !!MQLではtry catchは使えない
        if (res == -1) ErrorLog(GetLastError(), "Sell OrderSend error.");
        return;
    }
    /** buy entry ***************************************************************************************************************/
    // if (ma_prev.IsSelClose() && ma1.IsBuyEntry() && ma2.IsUpTorrend() && ma3.IsUpTorrend() && bb.IsBuyEntry() && rsi.IsBuyEntry()) {
    if (ma_prev.IsStage3() && ma1.IsBuyEntry() && ma2.IsUpTorrend() && ma3.IsUpTorrend()) {
        // if (bb.IsBuyEntry() && rsi.IsBuyEntry()) {
        sl = SL == 0 ? Ask - NormalizeDouble(getAtr() * SLAtrRanege, 5) : Ask - SL * Point;

        res = OrderSend(Symbol(), OP_BUY, LotsOptimized(), Ask, 3, sl, 0, "", MAGICMA, 0, Blue);
        if (res == -1) ErrorLog(GetLastError(), "Buy OrderSend error.");

        return;
    }
}

/**
 * @brief 決済処理
 */
void CheckForClose()
{
    // 新しいバーの最初のティックのみトレードする
    if (Volume[0] > 1) return;

    MovingAverage3Line ma(PERIOD_CURRENT);
    BollingerBands bb(PERIOD_CURRENT);
    Rsi rsi(PERIOD_CURRENT);

    // ポジションの存在チェック
    for (int i = 0; i < OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) break;
        if (OrderMagicNumber() != MAGICMA || OrderSymbol() != Symbol()) continue;
        // TODO:発注送信に失敗した場合のリトライをどうするか？WebRequestの場合も考慮する必要がありそう。
        /** buy close ***************************************************************************************************************/
        if (OrderType() == OP_BUY) {
            if (ma.IsBuyClose() || (bb.IsBuyClose() && rsi.IsBuyClose())) {
                if (!OrderClose(OrderTicket(), OrderLots(), Bid, 3, White)) ErrorLog(GetLastError(), "Buy OrderClose error. ");
            }
            break;
        }
        /** sell close ***************************************************************************************************************/
        if (OrderType() == OP_SELL) {
            if (ma.IsSelClose() || (bb.IsSelClose() && rsi.IsSelClose())) {
                if (!OrderClose(OrderTicket(), OrderLots(), Ask, 3, White)) ErrorLog(GetLastError(), "Sell OrderClose error. ");
            }
            break;
        }
    }
}

ENUM_TIMEFRAMES getNextHigherTimeFrame(int timeframe)
{
    ENUM_TIMEFRAMES result;
    switch (timeframe) {
        case PERIOD_M1:
            result = PERIOD_M5;
            break;
        case PERIOD_M5:
            result = PERIOD_M15;
            break;
        case PERIOD_M15:
            result = PERIOD_M30;
            break;
        case PERIOD_M30:
            result = PERIOD_H1;
            break;
        case PERIOD_H1:
            result = PERIOD_H4;
            break;
        case PERIOD_H4:
            result = PERIOD_D1;
            break;
        case PERIOD_D1:
            result = PERIOD_W1;
            break;
        default:
            result = PERIOD_CURRENT;
            break;
    }
    return result;
};

ENUM_TIMEFRAMES get2NextHigherTimeFrame(int timeframe)
{
    ENUM_TIMEFRAMES result;
    switch (timeframe) {
        case PERIOD_M1:
            result = PERIOD_M15;
            break;
        case PERIOD_M5:
            result = PERIOD_M30;
            break;
        case PERIOD_M15:
            result = PERIOD_H1;
            break;
        case PERIOD_M30:
            result = PERIOD_H4;
            break;
        case PERIOD_H1:
            result = PERIOD_D1;
            break;
        case PERIOD_H4:
            result = PERIOD_W1;
            break;
        case PERIOD_D1:
            result = PERIOD_W1;
            break;
        default:
            result = PERIOD_CURRENT;
            break;
    }
    return result;
};

void ErrorLog(int error_code, string message)
{
    string err_type = error_code <= 150 ? "server error" : "MQL error";
    printf("&s [%s code:%d]%s", message, err_type, error_code, ErrorDescription(error_code));
}

/**
 * @brief トレンドシグナルのインターフェース
 * @note 実装クラスでinterfaceを複数継承するとエラーとなる。
 * MQLでinterface複数継承できな場合は削除する。
 */
interface TrendSignal {
    bool IsUpTorrend();
    bool IsDownTorrend();
};
interface TradeSignal {
    bool IsBuyEntry();
    bool IsBuyClose();
    bool IsSelEntry();
    bool IsSelClose();
};
class MovingAverage3Line : public TradeSignal {
   private:
    double _ma1, _ma2, _ma3;

   public:
    MovingAverage3Line(ENUM_TIMEFRAMES timeframe, int shift = 0)
    {
        _ma1 = iMA(NULL, timeframe, MovingPeriod1, MovingShift1, MODE_EMA, PRICE_CLOSE, shift);
        _ma2 = iMA(NULL, timeframe, MovingPeriod2, MovingShift2, MODE_EMA, PRICE_CLOSE, shift);
        _ma3 = iMA(NULL, timeframe, MovingPeriod3, MovingShift3, MODE_EMA, PRICE_CLOSE, shift);
    };
    // ~MovingAverage3Line();
    bool IsStage1() { return _ma1 > _ma2 && _ma1 > _ma3 && _ma2 > _ma3; }; // 短期>中期>長期
    bool IsStage2() { return _ma1 < _ma2 && _ma1 > _ma3 && _ma2 > _ma3; }; // 中期>短期>長期
    bool IsStage3() { return _ma1 < _ma2 && _ma1 < _ma3 && _ma2 > _ma3; }; // 中期>長期>短期
    bool IsStage4() { return _ma1 < _ma2 && _ma1 < _ma3 && _ma2 < _ma3; }; // 長期>中期>短期
    bool IsStage5() { return _ma1 > _ma2 && _ma1 < _ma3 && _ma2 < _ma3; }; // 長期>短期>中期
    bool IsStage6() { return _ma1 > _ma2 && _ma1 > _ma3 && _ma2 < _ma3; }; // 短期>長期>中期
    bool IsUpTorrend() { return IsStage6() || IsStage1() || IsStage2(); };
    bool IsDownTorrend() { return IsStage3() || IsStage4() || IsStage5(); };
    bool IsBuyEntry() { return IsStage1(); };
    bool IsBuyClose() { return IsStage2(); };
    bool IsSelEntry() { return IsStage4(); };
    bool IsSelClose() { return IsStage5(); };
};

class BollingerBands : public TradeSignal {
   private:
    double _2sigma_upper, _2sigma_lower;
    double _3sigma_upper, _3sigma_lower;

   public:
    BollingerBands(ENUM_TIMEFRAMES timeframe)
    {
        // iBands(通貨ペア,時間軸,平均期間,標準偏差,バンドシフト,適用価格,ラインインデックス,シフト)
        _2sigma_upper = iBands(NULL, timeframe, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 1);
        _2sigma_lower = iBands(NULL, timeframe, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 1);
        _3sigma_upper = iBands(NULL, timeframe, 20, 3, 0, PRICE_CLOSE, MODE_UPPER, 1);
        _3sigma_lower = iBands(NULL, timeframe, 20, 3, 0, PRICE_CLOSE, MODE_LOWER, 1);
    };
    // ~BollingerBands();

    // MQLでは価格の比較は、売り買いどちらもBidが基準となっていることに注意
    bool IsBuyEntry() { return Bid < _3sigma_lower; };
    bool IsBuyClose() { return Bid > _2sigma_lower; };
    bool IsSelEntry() { return Bid > _3sigma_upper; };
    bool IsSelClose() { return Bid < _2sigma_lower; };
};

class Rsi : public TradeSignal {
   private:
    double _lower_limit, _upper_limit;
    double _rsi;

   public:
    Rsi(ENUM_TIMEFRAMES timeframe)
    {
        _lower_limit = 30;
        _upper_limit = 70;
        // iRSI(通貨ペア,時間軸,平均期間,適用価格,シフト)
        _rsi = iRSI(NULL, timeframe, 14, PRICE_CLOSE, 1);
    };
    // ~Rsi();
    bool IsBuyEntry() { return _rsi <= _lower_limit; };
    bool IsBuyClose() { return _rsi >= _upper_limit; };
    bool IsSelEntry() { return _rsi >= _upper_limit; };
    bool IsSelClose() { return _rsi <= _lower_limit; };
};

double getAtr()
{
    return iATR(
        NULL, // 通貨ペア
        _Period, // 時間軸
        20, // 平均期間
        1 // シフト
    );
};
