#include <Tools/DateTime.mqh>
/**
 * @file Date.mqh
 * @author fxowl (javajava0708@gmail.com)
 * @brief CDateTimeを拡張
 * @version 0.1
 * @date 2023-04-27
 *
 * @copyright Copyright (c) 2023
 *
 * @example
 *  CDateTimeExt dt_local;
 *  dt_local.DateTime(TimeLocal());
 *  dt_local.Hour(12);
 *  CDateTimeExt dt_srv = dt_local.ToMtServerStruct();
 *
 */
struct CDateTimeExt : public CDateTime
{
   private:
    int TimeGmtOffsetOfMtSrv();

   public:
    datetime ToMtServerDateTime();
    CDateTimeExt ToMtServerStruct();
    string ToStrings();
    bool Equals(/*MqlDateTime value*/);
    void Debug();
};

/**
 * @brief MT4サーバーとローカルPCのシステム時刻のオフセット値を取得する
 *
 * @return datetime
 */
int CDateTimeExt::TimeGmtOffsetOfMtSrv()
{
    static int gmt2 = -2;
    static int gmt3 = -3;
    int sec_of_hour = 60 * 60;
    int deviation;
    if (IsTesting()) {
        // TODO strategy testでサマータイムの判定が常に冬時間(0)が返されてしまう
        deviation = TimeDaylightSavings() == 0 ? gmt2 : gmt3;
    }
    else {
        // サーバー時刻とローカル時刻で数秒ずれてしまうため時間単位に戻してから丸めて修正
        const double offset = double(TimeGMT() - TimeCurrent());
        deviation = int(round(offset / sec_of_hour));
    }
    Print("TimeGMTOffsetOfMTSrv:" + string(offset / sec_of_hour));
    return deviation * sec_of_hour;
}

/**
 * @brief ローカルのシステム時刻からMT4サーバーの時刻に変換し、DateTime型で返却する
 *
 * @return datetime
 */
datetime CDateTimeExt::ToMtServerDateTime() { return DateTime() - (TimeGmtOffsetOfMtSrv() - TimeGMTOffset()); }

/**
 * @brief ローカルのシステム時刻からMT4サーバーの時刻に変換し、CDateTimeExt(MqlDateTime)型で返却する
 *
 * @return CDateTimeExt
 */
CDateTimeExt CDateTimeExt::ToMtServerStruct()
{
    CDateTimeExt dt;
    TimeToStruct(ToMtServerDateTime(), dt);
    return dt;
}

/**
 * @brief
 *
 * @return string
 */
// string ToStrings() {}

/**
 * @brief 日付を比較する
 *
 */
// bool Equals(/*MqlDateTime value*/) {}
// bool LessThan(/*MqlDateTime value*/) {}
// bool GreaterThan(/*MqlDateTime value*/) {}

void CDateTimeExt::Debug()
{
    Print(
        "Debug CDate |" + (string)year + "/" + (string)mon + "/" + (string)day + " " + (string)hour + ":" + (string)min + ":" + (string)sec
    );
}
