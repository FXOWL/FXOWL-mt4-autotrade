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
 * @example
 * MovingAverage3Line* createMovingAverage3Line(int timeframe, int shift = 0)
 * {
 *     return new MovingAverage3Line(
 *         iMA(NULL, timeframe, MovingPeriod1, MovingShift1, MODE_EMA, PRICE_CLOSE, shift),
 *         iMA(NULL, timeframe, MovingPeriod2, MovingShift2, MODE_EMA, PRICE_CLOSE, shift),
 *         iMA(NULL, timeframe, MovingPeriod3, MovingShift3, MODE_EMA, PRICE_CLOSE, shift)
 *     );
 * };
 */
class MovingAverage3Line {
   private:
    double _short, _middle, _long;

   public:
    MovingAverage3Line(double short_line, double middle_line, double long_line)
    {
        _short = short_line;
        _middle = middle_line;
        _long = long_line;
    };
    // ~MovingAverage3Line();
    double shortValue() { return _short; };
    double middleValue() { return _short; };
    double longValue() { return _short; };

    bool IsStage1() { return _short > _middle && _short > _long && _middle > _long; }; // 短期>中期>長期
    bool IsStage2() { return _short < _middle && _short > _long && _middle > _long; }; // 中期>短期>長期
    bool IsStage3() { return _short < _middle && _short < _long && _middle > _long; }; // 中期>長期>短期
    bool IsStage4() { return _short < _middle && _short < _long && _middle < _long; }; // 長期>中期>短期
    bool IsStage5() { return _short > _middle && _short < _long && _middle < _long; }; // 長期>短期>中期
    bool IsStage6() { return _short > _middle && _short > _long && _middle < _long; }; // 短期>長期>中期
    bool IsUpTorrend() { return IsStage6() || IsStage1() || IsStage2(); };
    bool IsDownTorrend() { return IsStage3() || IsStage4() || IsStage5(); };
    bool IsBuyEntry() { return IsStage1(); };
    bool IsBuyClose() { return IsStage2(); };
    bool IsSelEntry() { return IsStage4(); };
    bool IsSelClose() { return IsStage5(); };
};
