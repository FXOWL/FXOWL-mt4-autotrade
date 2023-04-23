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

class Rsi {
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
