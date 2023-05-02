/**
 * @note ここで定義されているENUMは、MT5のTradeクラスで使用されているENUMを踏襲しています。
 * 現時点で分かっているMT4で使用できない定数に関してはコメントアウトしています。
 */

enum ENUM_TRADE_REQUEST_ACTIONS //
{
    TRADE_ACTION_DEAL, // 指定されたパラメータ（成行注文）の即時実行のために約定注文を出します。 //
    TRADE_ACTION_PENDING, // 指定された条件（未決注文）で実行するために取引注文を出します。 //
    TRADE_ACTION_SLTP, // 保有中ポジションの決済逆指値及び決済指値を変更します。 //
    TRADE_ACTION_MODIFY, // 以前の注文のパラメータを変更します。 //
    TRADE_ACTION_REMOVE, // 以前の未決注文を削除します。 //
    TRADE_ACTION_CLOSE_BY // 反対ポジションの決済。 //
};

/**
 * @brief 証拠金計算モード
 *
 */
enum ENUM_ACCOUNT_MARGIN_MODE
{
    // 『ネッティング』モード（1つのシンボルに対し、1つのポジションのみ）におけるポジション計算時に市場外市場の為に使用されます。
    // 商品種別をベースに証拠金の計算が行われます(SYMBOL_TRADE_CALC_MODE)。 //
    ACCOUNT_MARGIN_MODE_RETAIL_NETTING,

    // 株式市場で使用されます。商品設定で指定された割引に基づいて証拠金が計算されます。
    // 割引はブローカーによって設定されますが、取引所が決めた額よりも低くなることはありません。
    ACCOUNT_MARGIN_MODE_EXCHANGE,

    // 株式市場外の独立したポジション計算時（『ヘッジング』は一つのシンボルに対し複数のポジションを保有することができる）に使用されます。
    // 商品種別(SYMBOL_TRADE_CALC_MODE)に基づき、ヘッジ対象証拠金のサイズを考慮して(SYMBOL_MARGIN_HEDGED)証拠金の計算が行われます。 //
    ACCOUNT_MARGIN_MODE_RETAIL_HEDGING
};

/**
 * @brief 注文充填タイプ
 *
 */
enum ENUM_ORDER_TYPE_FILLING
{
    /** 注文は指定されたボリュームでのみ実行できます。
     * 必要な量の金融商品が現在市場で入手できない場合、注文は実行されません。
     * 必要なボリュームは、いくつかの利用可能なオファーで構成できます。
     * FOK注文を使用する可能性は、取引サーバで決定されます。*/
    ORDER_FILLING_FOK,
    /**トレーダーは、注文に示された量の範囲内で市場で最大限に利用可能な量で取引を実行することに同意します。
     * リクエストを完全に満たすことができない場合、利用可能なボリュームでの注文が実行され、残りのボリュームはキャンセルされます。
     * IOC注文を使用する可能性は、取引サーバで決定されます。*/
    ORDER_FILLING_IOC,
    /** BoC注文は、注文が板情報でのみ発注でき、すぐに実行できないことを前提としています。発注時にすぐに約定できる場合、注文はキャンセルされます。
     * 実際、BOCのポリシーは、発注された注文の価格が現在の市場よりも悪くなることを保証しています。BoC注文はパッシブ取引を実装するために使用されるため、注文が出されてもすぐには実行されず、現在の流動性には影響しません。
     * 指値注文と逆指値注文のみがサポートされています(ORDER_TYPE_BUY_LIMIT 、ORDER_TYPE_SELL_LIMIT、ORDER_TYPE_BUY_STOP_LIMIT、
     * ORDER_TYPE_SELL_STOP_LIMIT)。*/
    ORDER_FILLING_BOC,
    /** 部分的な実行の場合、残りのボリュームのある注文はキャンセルされず、さらに処理されます。
     * 成行実行モード(成行実行— SYMBOL_TRADE_EXECUTION_MARKET)では、リターン注文は許可されていません。 //
     */
    ORDER_FILLING_RETURN
};

/**
 * @brief 注文ライフタイム
 *
 */
enum ENUM_ORDER_TYPE_TIME
{
    ORDER_TIME_GTC, // GTC注文（キャンセルするまで有効）
    ORDER_TIME_DAY, // 現在の取引日のみ有効である注文
    ORDER_TIME_SPECIFIED, // 有効期限まで有効な注文
    ORDER_TIME_SPECIFIED_DAY // 注文が指定された日の 23:59:59
                             // まで有効となります。この時刻が取引セッション外である場合は、注文は最も近い取引時間中に満了します
};

/**
 * @brief
 * MQL4で定義済み列挙型
 * ACCOUNT_MARGIN_MODE以下はMQL4では未定義なので独自実装する
 */
// enum ENUM_ACCOUNT_INFO_INTEGER
// {

//     // {
//     //     ACCOUNT_LOGIN, // 口座番号
//     //     ACCOUNT_TRADE_MODE, // 口座取引モード
//     //     ACCOUNT_LEVERAGE, // 口座レバレッジ
//     // ACCOUNT_LIMIT_ORDERS, // アクティブな未決注文の最大許容数
//     // ACCOUNT_MARGIN_SO_MODE, // 許容された最小証拠金を設定するモード
//     // ACCOUNT_TRADE_ALLOWED, // 現在の口座で許可された取引
//     // ACCOUNT_TRADE_EXPERT, // エキスパートアドバイザーで許可された取引
//     ACCOUNT_MARGIN_MODE, // 証拠金計算モード
//     ACCOUNT_CURRENCY_DIGITS, // 取引結果を正確に表示するために必要な口座通貨の小数点以下の桁数
//     ACCOUNT_FIFO_CLOSE // FIFOルールによってのみポジションを決済できることを示します
// };