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
    bool IsSummertimeForBackTest();
    CDateTimeExt CDateTimeExt::SummertimeStartDate();
    CDateTimeExt CDateTimeExt::SummertimeEndDate();
    int TimeGmtOffsetOfMtSrv();

   public:
    datetime ToMtServerDateTime();
    CDateTimeExt ToMtServerStruct();
    CDateTimeExt AtEndOfMonth();
    string ToStrings(string separate);
    bool Eq(const MqlDateTime &value);
    bool Eq(const datetime value);
    bool Gt(const MqlDateTime &value);
    bool Gt(const datetime value);
    bool Gte(const MqlDateTime &value);
    bool Gte(const datetime value);
    bool Lt(const MqlDateTime &value);
    bool Lt(const datetime value);
    bool Lte(const MqlDateTime &value);
    bool Lte(const datetime value);
    bool Between(const MqlDateTime &start, const MqlDateTime &end);
    bool Between(const datetime start, const datetime end);
    bool IsSunday() { return TimeDayOfWeek(this.DateTime()) == 0; };
    bool IsMonday() { return TimeDayOfWeek(this.DateTime()) == 1; };
    bool IsTuesday() { return TimeDayOfWeek(this.DateTime()) == 2; };
    bool IsWednesday() { return TimeDayOfWeek(this.DateTime()) == 3; };
    bool IsThursday() { return TimeDayOfWeek(this.DateTime()) == 4; };
    bool IsFriday() { return TimeDayOfWeek(this.DateTime()) == 5; };
    bool IsSaturday() { return TimeDayOfWeek(this.DateTime()) == 6; };
    bool IsGotoday() { return TimeDay(this.DateTime()) % 5 == 0; };
    void Debug();
    CDateTimeExt DateTime(const datetime value);
    CDateTimeExt Date(const datetime value);
    CDateTimeExt Sec(const int value);
    CDateTimeExt Min(const int value);
    CDateTimeExt Hour(const int value);
    CDateTimeExt Day(const int value);
    CDateTimeExt Mon(const int value);
    CDateTimeExt Year(const int value);
};

/**
 * @brief バックテストでの夏時間を判定する。
 * 3月第2日曜日午前2時〜11月第1日曜日午前2時の期間内の場合はTrueを返す
 *
 * @return bool
 */
bool CDateTimeExt::IsSummertimeForBackTest()
{
    datetime start_date = CDateTimeExt::SummertimeStartDate().DateTime();
    datetime end_date = CDateTimeExt::SummertimeEndDate().DateTime();

    return this.DateTime() >= start_date && this.DateTime() <= end_date ? true : false;
}

/**
 * @brief ローカル日時の年のサマータイム開始日時を返す
 *
 * @return CDateTimeExt
 */
CDateTimeExt CDateTimeExt::SummertimeStartDate()
{
    CDateTimeExt start_date;
    TimeToStruct(TimeLocal(), start_date);
    start_date.Mon(3);
    start_date.Day(1);

    int start_day_of_week = TimeDayOfWeek(start_date.DateTime());

    int start_day = (start_day_of_week == 0) ? 8 : 6 - start_day_of_week + 8;

    start_date.DayInc(start_day);
    start_date.Hour(2);
    start_date.Min(0);
    start_date.Sec(0);
    return start_date;
}

/**
 * @brief ローカル日時の年のサマータイム終了日時を返す
 *
 * @return CDateTimeExt
 */
CDateTimeExt CDateTimeExt::SummertimeEndDate()
{
    CDateTimeExt end_date;
    TimeToStruct(TimeLocal(), end_date);
    end_date.Mon(11);
    end_date.Day(1);
    int end_day_of_week = TimeDayOfWeek(end_date.DateTime());

    int end_day = (end_day_of_week == 0) ? 1 : 6 - end_day_of_week + 1;

    end_date.DayInc(end_day);
    end_date.Hour(2);
    end_date.Min(0);
    end_date.Sec(0);
    return end_date;
}

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
        // strategy testではサマータイムの判定が常に冬時間(0)が返されてしまう
        deviation = IsSummertimeForBackTest() ? gmt3 : gmt2;
    }
    else {
        // サーバー時刻とローカル時刻で数秒ずれてしまうため時間単位に戻してから丸めて修正
        const double offset = double(TimeGMT() - TimeCurrent());
        deviation = int(round(offset / sec_of_hour));
    }

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
 * @brief 月末日を取得する
 *
 * @return CDateTimeExt
 */
CDateTimeExt CDateTimeExt::AtEndOfMonth()
{
    Day(DaysInMonth());
    DateTime(this);

    if (day_of_week == SATURDAY) DayDec(1);
    if (day_of_week == SUNDAY) DayDec(2);

    return this;
}

string CDateTimeExt::ToStrings(string separate = "/")
{
    return (string)this.year + separate + (string)this.mon + separate + (string)this.day + " " + (string)this.hour + ":" +
           (string)this.min + ":" + (string)this.sec;
};

/**
 * @brief value と等しいか
 *
 */
bool CDateTimeExt::Eq(const datetime value) { return this.DateTime() == value; }
bool CDateTimeExt::Eq(const MqlDateTime &value) { return this.Eq(StructToTime(value)); }

/**
 * @brief value より大きいか？
 *
 */
bool CDateTimeExt::Gt(const datetime value) { return this.DateTime() > value; }
bool CDateTimeExt::Gt(const MqlDateTime &value) { return this.Gt(StructToTime(value)); }

/**
 * @brief value 以上か？
 *
 */
bool CDateTimeExt::Gte(const datetime value) { return this.DateTime() >= value; }
bool CDateTimeExt::Gte(const MqlDateTime &value) { return this.Gte(StructToTime(value)); }

/**
 * @brief value 未満か？
 *
 */
bool CDateTimeExt::Lt(const datetime value) { return this.DateTime() < value; }
bool CDateTimeExt::Lt(const MqlDateTime &value) { return this.Lt(StructToTime(value)); }

/**
 * @brief value 以下か？
 *
 */
bool CDateTimeExt::Lte(const datetime value) { return this.DateTime() <= value; }
bool CDateTimeExt::Lte(const MqlDateTime &value) { return this.Lte(StructToTime(value)); }

/**
 * @brief start と end の期間内か？
 *
 */
bool CDateTimeExt::Between(const datetime start, const datetime end) { return this.DateTime() >= start && this.DateTime() <= end; }
bool CDateTimeExt::Between(const MqlDateTime &start, const MqlDateTime &end)
{
    return this.Between(StructToTime(start), StructToTime(end));
}

void CDateTimeExt::Debug() { Print("Debug CDateTimeExt |" + (string)ToStrings("-")); }

/** これより以下はDatetime構造体の関数でメソッドチェーンが出来ないため、構造体を返すようにオーバーライドしている */
CDateTimeExt CDateTimeExt::DateTime(const datetime value)
{
    CDateTime::DateTime(value);
    return this;
}

CDateTimeExt CDateTimeExt::Date(const datetime value)
{
    CDateTime::Date(value);
    return this;
}

CDateTimeExt CDateTimeExt::Sec(const int value)
{
    CDateTime::Sec(value);
    return this;
}

CDateTimeExt CDateTimeExt::Min(const int value)
{
    CDateTime::Min(value);
    return this;
}

CDateTimeExt CDateTimeExt::Hour(const int value)
{
    CDateTime::Hour(value);
    return this;
}

CDateTimeExt CDateTimeExt::Day(const int value)
{
    CDateTime::Day(value);
    return this;
}

CDateTimeExt CDateTimeExt::Mon(const int value)
{
    CDateTime::Mon(value);
    return this;
}

CDateTimeExt CDateTimeExt::Year(const int value)
{
    CDateTime::Year(value);
    return this;
}