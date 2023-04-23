/**
 * @file MovingAverage3Line.mqh
 * @author fxowl (javajava0708@gmail.com)
 * @brief
 * @version 0.1
 * @date 2023-04-23
 *
 * @copyright Copyright (c) 2023
 *
 */

/**
 * @brief
 *
 */
class BollingerBands {
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