//+------------------------------------------------------------------+
//|                                      General circulation EMA.mq4 |
//|                                  Copyright 2023-2023, n_hiyoshi. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "2023_04, n_hiyoshi."
#property description "三本EMAで自動売買するEA"

#define MAGICMA 20131111
// ユーザー入力値
input double Lots = 0.1;
input double MaximumRisk = 0.02; // 余剰証拠金 * MaximumRisk / 1000 = lot
input double DecreaseFactor = 3;
input int MovingPeriod1 = 5;
input int MovingShift1 = 6;
input int MovingPeriod2 = 21;
input int MovingShift2 = 6;
input int MovingPeriod3 = 55;
input int MovingShift3 = 6;
input int SL = 100;
input double SLAtrRanege = 1.0;

/**
 * @brief メイン処理
 *
 */
void OnTick()
{
    // 　begin 速度計測
    // static ulong _sum = 0; // 合計
    // static int _count = -10; // カウント
    // ulong _start = GetMicrosecondCount(); // 開始時刻

    //--- check for history and trading
    if (Bars < 100 || IsTradeAllowed() == false) return;
    //--- calculate open orders by current symbol
    if (CalculateCurrentOrders(Symbol()) == 0)
        CheckForOpen();
    else
        CheckForClose();
    //---

    // 　end 速度計測
    // if (_count >= 0) _sum += GetMicrosecondCount() - _start;
    // _count++;
    // if (_count == 100) {
    //     Print("100 ticks = ", _sum, " μs");
    //     ExpertRemove();
    // }
}

/**
 * @brief Calculate open positions
 *
 * @param symbol
 * @return int
 */
int CalculateCurrentOrders(string symbol)
{
    int buys = 0, sells = 0;
    //---
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
 * @brief Calculate optimal lot size
 *
 * @return double
 */
double LotsOptimized()
{
    double lot = Lots;
    int orders = HistoryTotal(); // history orders total
    int losses = 0; // number of losses orders without a break
    //--- select lot size
    // 現在アカウントの余剰証拠金 * MaximumRisk / 1000
    lot = NormalizeDouble(AccountFreeMargin() * MaximumRisk / 1000.0, 1);
    //--- calcuulate number of losses orders without a break
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
    //--- return lot size
    if (lot < 0.01) lot = 0.01;
    return (lot);
}

/**
 * @brief Check for open order conditions
 *
 */
void CheckForOpen()
{
    int res;
    //--- go trading only for first tiks of new bar
    if (Volume[0] > 1) return;
    //--- get Moving Average
    MovingAverage3Line ma1(PERIOD_CURRENT);
    MovingAverage3Line ma_prev(PERIOD_CURRENT, 1);

    ENUM_TIMEFRAMES timeframe1;
    ENUM_TIMEFRAMES timeframe2;
    switch (_Period) {
        case PERIOD_M1:
            timeframe1 = PERIOD_M5;
            timeframe2 = PERIOD_M15;
            break;
        case PERIOD_M5:
            timeframe1 = PERIOD_M15;
            timeframe2 = PERIOD_M30;
            break;
        case PERIOD_M15:
            timeframe1 = PERIOD_M30;
            timeframe2 = PERIOD_H1;
            break;
        case PERIOD_M30:
            timeframe1 = PERIOD_H1;
            timeframe2 = PERIOD_H4;
            break;
        case PERIOD_H1:
            timeframe1 = PERIOD_H4;
            timeframe2 = PERIOD_D1;
            break;
        case PERIOD_H4:
            timeframe1 = PERIOD_D1;
            timeframe2 = PERIOD_W1;
            break;
        case PERIOD_D1:
            timeframe1 = PERIOD_W1;
            timeframe2 = PERIOD_W1;
            break;
        default:
            timeframe1 = PERIOD_CURRENT;
            timeframe2 = PERIOD_CURRENT;
            break;
    }

    MovingAverage3Line ma2(timeframe1);
    MovingAverage3Line ma3(timeframe2);

    BollingerBands bb(PERIOD_CURRENT);
    Rsi rsi(PERIOD_CURRENT);

    /** sell entry ***************************************************************************************************************/
    double sl;
    // if (ma_prev.IsBuyClose() && ma1.IsSelEntry() && ma2.IsDownTorrend() && ma3.IsDownTorrend() && bb.IsSelEntry() && rsi.IsSelEntry()) {
    if (ma_prev.IsStage6() && ma1.IsSelEntry() && ma2.IsDownTorrend() && ma3.IsDownTorrend()) {
        // if (bb.IsSelEntry() && rsi.IsSelEntry()) {
        sl = SL == 0 ? Bid + NormalizeDouble(getAtr() * SLAtrRanege, 5) : Bid + SL * Point;
        // sl = Bid + NormalizeDouble(getAtr() * 2.5, 5);

        // OrderSend( symbol, ordertype, lots[0.01単位], price, slippage[0.1pips],stoploss,takeprofit,comment,magic,expiration,arrow_color);
        res = OrderSend(Symbol(), OP_SELL, LotsOptimized(), Bid, 3, sl, 0, "", MAGICMA, 0, Red);
        return;
    }
    /** buy entry ***************************************************************************************************************/
    // if (ma_prev.IsSelClose() && ma1.IsBuyEntry() && ma2.IsUpTorrend() && ma3.IsUpTorrend() && bb.IsBuyEntry() && rsi.IsBuyEntry()) {
    if (ma_prev.IsStage3() && ma1.IsBuyEntry() && ma2.IsUpTorrend() && ma3.IsUpTorrend()) {
        // if (bb.IsBuyEntry() && rsi.IsBuyEntry()) {
        sl = SL == 0 ? Ask - NormalizeDouble(getAtr() * SLAtrRanege, 5) : Ask - SL * Point;
        // sl = Ask - NormalizeDouble(getAtr() * 2.5, 5);
        res = OrderSend(Symbol(), OP_BUY, LotsOptimized(), Ask, 3, sl, 0, "", MAGICMA, 0, Blue);
        // error handling !!MQLではtry catchが使えない
        if (res == -1) {
            int error_code = GetLastError();
            printf("Order error. [code:%d]%s", error_code, ErrorDescription(error_code));
        }
        return;
    }
}

/**
 * @brief Check for close order conditions
 *
 */
void CheckForClose()
{
    //--- go trading only for first tiks of new bar
    if (Volume[0] > 1) return;
    //--- get Moving Average

    MovingAverage3Line ma(PERIOD_CURRENT);
    BollingerBands bb(PERIOD_CURRENT);
    Rsi rsi(PERIOD_CURRENT);
    //---
    for (int i = 0; i < OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) break;
        if (OrderMagicNumber() != MAGICMA || OrderSymbol() != Symbol()) continue;
        //--- check order type
        if (OrderType() == OP_BUY) {
            if (ma.IsBuyClose() || (bb.IsBuyClose() && rsi.IsBuyClose())) {
                // if (bb.IsBuyClose() && rsi.IsBuyClose()) {
                if (!OrderClose(OrderTicket(), OrderLots(), Bid, 3, White)) Print("OrderClose error ", GetLastError());
            }
            break;
        }
        if (OrderType() == OP_SELL) {
            if (ma.IsSelClose() || (bb.IsSelClose() && rsi.IsSelClose())) {
                // if (bb.IsSelClose() && rsi.IsSelClose()) {
                if (!OrderClose(OrderTicket(), OrderLots(), Ask, 3, White)) Print("OrderClose error ", GetLastError());
            }
            break;
        }
    }
    //---
}

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
    double _ma1, _ma2, _ma3, _ma_prev;

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
    bool IsBuyEntry() { return Bid < _3sigma_lower; };
    bool IsBuyClose() { return Ask > _2sigma_lower; };
    bool IsSelEntry() { return Ask > _3sigma_upper; };
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
