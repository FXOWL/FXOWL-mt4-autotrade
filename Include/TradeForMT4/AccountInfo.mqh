//|                                                  AccountInfo.mqh |
//|                   Copyright 2009-2020, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Object.mqh>
#include <TradeForMT4\Enums.mqh>
#include <stderror.mqh>
#include <stdlib.mqh>

//+------------------------------------------------------------------+
//| Class CAccountInfo.                                              |
//| Appointment: Class for access to account info.                   |
//|              Derives from class CObject.                         |
//+------------------------------------------------------------------+
class CAccountInfo : public CObject {
   public:
    CAccountInfo(void);
    ~CAccountInfo(void);

    //--- fast access methods to the integer account propertyes
    long Login(void) const;
    ENUM_ACCOUNT_TRADE_MODE TradeMode(void) const;
    string TradeModeDescription(void) const;
    long Leverage(void) const;
    ENUM_ACCOUNT_STOPOUT_MODE StopoutMode(void) const;
    string StopoutModeDescription(void) const;
    // ENUM_ACCOUNT_MARGIN_MODE MarginMode(void);
    // string MarginModeDescription(void) const;
    bool TradeAllowed(void) const;
    bool TradeExpert(void) const;
    int LimitOrders(void) const;

    //--- fast access methods to the double account propertyes
    double Balance(void) const;
    double Credit(void) const;
    double Profit(void) const;
    double Equity(void) const;
    double Margin(void) const;
    double FreeMargin(void) const;
    double MarginLevel(void) const;
    double MarginCall(void) const;
    double MarginStopOut(void) const;

    //--- fast access methods to the string account propertyes
    string Name(void) const;
    string Server(void) const;
    string Currency(void) const;
    string Company(void) const;

    //--- access methods to the API MQL5 functions
    long InfoInteger(const ENUM_ACCOUNT_INFO_INTEGER prop_id) const;
    double InfoDouble(const ENUM_ACCOUNT_INFO_DOUBLE prop_id) const;
    string InfoString(const ENUM_ACCOUNT_INFO_STRING prop_id) const;

    //--- checks
    double OrderProfitCheck(
        const string symbol, const ENUM_ORDER_TYPE trade_operation, const double volume, const double price_open, const double price_close
    ) const;
    double MarginCheck(const string symbol, const ENUM_ORDER_TYPE trade_operation, const double volume, const double price) const;
    double FreeMarginCheck(const string symbol, const ENUM_ORDER_TYPE trade_operation, const double volume, const double price) const;
    double MaxLotCheck(const string symbol, const ENUM_ORDER_TYPE trade_operation, const double price, const double percent = 100) const;
};

/**
 * @brief Construct a new CAccountInfo::CAccountInfo object
 *
 */
CAccountInfo::CAccountInfo(void) {}

/**
 * @brief Destroy the CAccountInfo::CAccountInfo object
 *
 */
CAccountInfo::~CAccountInfo(void) {}

/**
 * @brief 口座番号を取得する
 *
 * @return long
 */
long CAccountInfo::Login(void) const { return (AccountInfoInteger(ACCOUNT_LOGIN)); }

/**
 * @brief 取引モードを取得
 *
 * @return ENUM_ACCOUNT_TRADE_MODE
 */
ENUM_ACCOUNT_TRADE_MODE CAccountInfo::TradeMode(void) const { return ((ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE)); }

/**
 * @brief 取引モードを文字列として取得します
 *
 * @return string
 */
string CAccountInfo::TradeModeDescription(void) const
{
    string str;

    switch (TradeMode()) {
        case ACCOUNT_TRADE_MODE_DEMO:
            str = "Demo trading account";
            break;
        case ACCOUNT_TRADE_MODE_CONTEST:
            str = "Contest trading account";
            break;
        case ACCOUNT_TRADE_MODE_REAL:
            str = "Real trading account";
            break;
        default:
            str = "Unknown trade account";
    }

    return (str);
}
/**
 * @brief 与えられたレバレッジの額を取得する
 *
 * @return long
 */
long CAccountInfo::Leverage(void) const { return (AccountInfoInteger(ACCOUNT_LEVERAGE)); }

/**
 * @brief 口座ストップアウトのモードを取得する
 *
 * @return ENUM_ACCOUNT_STOPOUT_MODE
 */
ENUM_ACCOUNT_STOPOUT_MODE CAccountInfo::StopoutMode(void) const
{
    return ((ENUM_ACCOUNT_STOPOUT_MODE)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE));
}

/**
 * @brief 口座ストップアウトのモードの説明を取得します
 *
 * @return string
 */
string CAccountInfo::StopoutModeDescription(void) const
{
    string str;
    //---
    switch (StopoutMode()) {
        case ACCOUNT_STOPOUT_MODE_PERCENT:
            str = "Level is specified in percentage";
            break;
        case ACCOUNT_STOPOUT_MODE_MONEY:
            str = "Level is specified in money";
            break;
        default:
            str = "Unknown stopout mode";
    }
    //---
    return (str);
}
// //+------------------------------------------------------------------+
// //| Get the property value "ACCOUNT_MARGIN_MODE"                     |
// //+------------------------------------------------------------------+
// ENUM_ACCOUNT_MARGIN_MODE CAccountInfo::MarginMode(void) const
// {
//     return ((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE));
// }
// //+------------------------------------------------------------------+
// //| Get the property value "ACCOUNT_MARGIN_MODE" as string           |
// //+------------------------------------------------------------------+
// string CAccountInfo::MarginModeDescription(void) const
// {
//     string str;
//     //---
//     switch (MarginMode()) {
//         case ACCOUNT_MARGIN_MODE_RETAIL_NETTING:
//             str = "Netting";
//             break;
//         case ACCOUNT_MARGIN_MODE_EXCHANGE:
//             str = "Exchange";
//             break;
//         case ACCOUNT_MARGIN_MODE_RETAIL_HEDGING:
//             str = "Hedging";
//             break;
//         default:
//             str = "Unknown margin mode";
//     }
//     //---
//     return (str);
// }

/**
 * @brief 取引許可のフラグを取得
 *
 * @return bool
 */
bool CAccountInfo::TradeAllowed(void) const { return ((bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)); }

/**
 * @brief 自動売買許可のフラグを取得する
 *
 * @return bool
 */
bool CAccountInfo::TradeExpert(void) const { return ((bool)AccountInfoInteger(ACCOUNT_TRADE_EXPERT)); }

/**
 * @brief 未決注文の最大限を取得する
 *
 * @return int
 */
int CAccountInfo::LimitOrders(void) const { return ((int)AccountInfoInteger(ACCOUNT_LIMIT_ORDERS)); }

/**
 * @brief 口座の残高を取得
 *
 * @return double
 */
double CAccountInfo::Balance(void) const { return (AccountInfoDouble(ACCOUNT_BALANCE)); }

/**
 * @brief 与えられたクレジットの額を取得
 *
 * @return double
 */
double CAccountInfo::Credit(void) const { return (AccountInfoDouble(ACCOUNT_CREDIT)); }

/**
 * @brief 口座の現在の利益の額を取得
 *
 * @return double
 */
double CAccountInfo::Profit(void) const { return (AccountInfoDouble(ACCOUNT_PROFIT)); }

/**
 * @brief 口座の現在の有効証拠金の額を取得（未決済の取引による未確定利益と損失を含む）
 *
 * @return double
 */
double CAccountInfo::Equity(void) const { return (AccountInfoDouble(ACCOUNT_EQUITY)); }

/**
 * @brief 口座の現在の必要証拠金の額を取得する
 *
 * @return double
 */
double CAccountInfo::Margin(void) const { return (AccountInfoDouble(ACCOUNT_MARGIN)); }

/**
 * @brief 口座の現在の余剰証拠金の額を取得する
 *
 * @return double
 */
double CAccountInfo::FreeMargin(void) const { return (AccountInfoDouble(ACCOUNT_MARGIN_FREE)); }

/**
 * @brief 証拠金維持率(%)を取得する
 *
 * @return double
 */
double CAccountInfo::MarginLevel(void) const { return (AccountInfoDouble(ACCOUNT_MARGIN_LEVEL)); }

/**
 * @brief 預金のための証拠金のレベルを取得する
 *
 * @return double
 */
double CAccountInfo::MarginCall(void) const { return (AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL)); }

/**
 * @brief ストップアウトのための証拠金のレベルを取得する
 *
 * @return double
 */
double CAccountInfo::MarginStopOut(void) const { return (AccountInfoDouble(ACCOUNT_MARGIN_SO_SO)); }

/**
 * @brief アカウント名を取得する
 *
 * @return string
 */
string CAccountInfo::Name(void) const { return (AccountInfoString(ACCOUNT_NAME)); }

/**
 * @brief アカウントサーバー名を取得する
 *
 * @return string
 */
string CAccountInfo::Server(void) const { return (AccountInfoString(ACCOUNT_SERVER)); }

/**
 * @brief アカウント通貨を取得する
 *
 * @return string
 */
string CAccountInfo::Currency(void) const { return (AccountInfoString(ACCOUNT_CURRENCY)); }

/**
 * @brief アカウントを提供した会社名を取得する
 *
 * @return string
 */
string CAccountInfo::Company(void) const { return (AccountInfoString(ACCOUNT_COMPANY)); }

// //+------------------------------------------------------------------+
// //| Access functions AccountInfoInteger(...)                         |
// //+------------------------------------------------------------------+
long CAccountInfo::InfoInteger(const ENUM_ACCOUNT_INFO_INTEGER prop_id) const { return (AccountInfoInteger(prop_id)); }

// //+------------------------------------------------------------------+
// //| Access functions AccountInfoDouble(...)                          |
// //+------------------------------------------------------------------+
double CAccountInfo::InfoDouble(const ENUM_ACCOUNT_INFO_DOUBLE prop_id) const { return (AccountInfoDouble(prop_id)); }

// //+------------------------------------------------------------------+
// //| Access functions AccountInfoString(...)                          |
// //+------------------------------------------------------------------+
string CAccountInfo::InfoString(const ENUM_ACCOUNT_INFO_STRING prop_id) const { return (AccountInfoString(prop_id)); }

// //+------------------------------------------------------------------+
// //| Access functions OrderCalcProfit(...).                            |
// //| INPUT:  name            - symbol name,                           |
// //|         trade_operation - trade operation,                       |
// //|         volume          - volume of the opening position,        |
// //|         price_open      - price of the opening position,         |
// //|         price_close     - price of the closing position.         |
// //+------------------------------------------------------------------+
double CAccountInfo::OrderProfitCheck(
    const string symbol, const ENUM_ORDER_TYPE trade_operation, const double volume, const double price_open, const double price_close
) const
{
    double profit = EMPTY_VALUE;
    //---
    if (!OrderCalcProfit(trade_operation, symbol, volume, price_open, price_close, profit)) return (EMPTY_VALUE);
    //---
    return (profit);
}

// //+------------------------------------------------------------------+
// //| Access functions OrderCalcMargin(...).                           |
// //| INPUT:  name            - symbol name,                           |
// //|         trade_operation - trade operation,                       |
// //|         volume          - volume of the opening position,        |
// //|         price           - price of the opening position.         |
// //+------------------------------------------------------------------+
double CAccountInfo::MarginCheck(const string symbol, const ENUM_ORDER_TYPE trade_operation, const double volume, const double price) const
{
    double margin = EMPTY_VALUE;

    if (!OrderCalcMargin(trade_operation, symbol, volume, price, margin)) return (EMPTY_VALUE);

    return (margin);
}

//+------------------------------------------------------------------+
//| Access functions OrderCalcMargin(...).                           |
//| INPUT:  name            - symbol name,                           |
//|         trade_operation - trade operation,                       |
//|         volume          - volume of the opening position,        |
//|         price           - price of the opening position.         |
//+------------------------------------------------------------------+
double CAccountInfo::FreeMarginCheck(const string symbol, const ENUM_ORDER_TYPE trade_operation, const double volume, const double price)
    const
{
    return (FreeMargin() - MarginCheck(symbol, trade_operation, volume, price));
}

//+------------------------------------------------------------------+
//| Access functions OrderCalcMargin(...).                           |
//| INPUT:  name            - symbol name,                           |
//|         trade_operation - trade operation,                       |
//|         price           - price of the opening position,         |
//|         percent         - percent of available margin [1-100%].   |
//+------------------------------------------------------------------+
double CAccountInfo::MaxLotCheck(const string symbol, const ENUM_ORDER_TYPE trade_operation, const double price, const double percent) const
{
    double margin = 0.0;
    //--- checks
    if (symbol == "" || price <= 0.0 || percent < 1 || percent > 100) {
        Print("CAccountInfo::MaxLotCheck invalid parameters");
        return (0.0);
    }
    //--- calculate margin requirements for 1 lot
    if (!OrderCalcMargin(trade_operation, symbol, 1.0, price, margin) || margin < 0.0) {
        Print("CAccountInfo::MaxLotCheck margin calculation failed");
        return (0.0);
    }

    if (margin == 0.0) // for pending orders
        return (SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX));
    //--- calculate maximum volume
    double volume = NormalizeDouble(FreeMargin() * percent / 100.0 / margin, 2);
    //--- normalize and check limits
    double stepvol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    if (stepvol > 0.0) volume = stepvol * MathFloor(volume / stepvol);

    double minvol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    if (volume < minvol) volume = 0.0;

    double maxvol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    if (volume > maxvol) volume = maxvol;
    //--- return volume
    return (volume);
}

/** ここから下はMT5の関数を踏襲している ************************************************************************************/

/**
 * @brief
 * 指定された取引サイズ、価格、および注文タイプに基づいて、トレードの必要なマージンを計算する。
 *
 * @param trade_operation
 * @param symbol
 * @param volume
 * @param price
 * @param margin
 * @return true
 * @return false
 * @see https://www.mql5.com/ja/docs/trading/ordercalcmargin
 */
bool OrderCalcMargin(ENUM_ORDER_TYPE action, string symbol, double volume, double price, double& margin)
{
    double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double contract_size = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double margin_mode = (double)SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);

    double margin_req = volume * contract_size * price / margin_mode;
    if (action == OP_SELL) {
        margin = margin_req / tick_value * tick_size;
        return true;
    }
    else {
        margin = margin_req;
        return true;
    }

    return false;
}

/**
 * @brief 渡されたパラメータに基づいて、現在の銘柄での現在の口座の利益を計算します。
 * これは、取引操作の結果の事前評価のために使用されます。値は口座の預金通貨で返されます
 *
 * @param action
 * @param symbol
 * @param volume
 * @param price_open
 * @param price_close
 * @param profit
 * @return true
 * @return false
 * @see https://www.mql5.com/ja/docs/trading/ordercalcprofit
 */
bool OrderCalcProfit(ENUM_ORDER_TYPE action, string symbol, double volume, double price_open, double price_close, double& profit)
{
    profit = NULL;
    if (action == OP_BUY || action == OP_BUYLIMIT || action == OP_BUYSTOP) {
        profit = (price_close - price_open) * volume * MarketInfo(symbol, MODE_TICKVALUE) / MarketInfo(symbol, MODE_POINT);
        return true;
    }
    else if (action == OP_SELL || action == OP_SELLLIMIT || action == OP_SELLSTOP) {
        profit = (price_open - price_close) * volume * MarketInfo(symbol, MODE_TICKVALUE) / MarketInfo(symbol, MODE_POINT);
        return true;
    }
    return false;
}
