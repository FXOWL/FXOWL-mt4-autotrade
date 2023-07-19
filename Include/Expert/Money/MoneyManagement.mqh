#include <TradeForMT4/AccountInfo.mqh>

/**
 * @brief 資金管理クラス
 *
 */
class MoneyManagement {
   private:
    double _maximum_risk; // リスクにさらす余剰証拠金の割合(前日の基準)
    CAccountInfo _account_info;

   public:
    MoneyManagement(double maximum_risk) { _maximum_risk = maximum_risk; };
    double CalculateTodayProfit();
    bool IsTradeAllow();
};

/**
 * @brief　今日の取引の利益を算出する
 *
 * @return double
 */
double MoneyManagement::CalculateTodayProfit()
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

/**
 * @brief 余剰証拠金を基に、トレードを許可するかを判断する。
 *
 * @return bool
 */
bool MoneyManagement::IsTradeAllow()
{
    double today_profit = CalculateTodayProfit();

    // 前日の余剰証拠金を基に算出した1日あたりの損失上限額
    const static double daily_loss_limit = (_account_info.FreeMargin() - today_profit) * _maximum_risk;

    return (daily_loss_limit + today_profit) > 0;
}