
/**
 * @brief ロットクラス
 *
 */
class Lot {
   private:
    CAccountInfo* m_account;
    double m_value, m_currency_unit;
    string m_symbol;
    bool Valid(double value);

   public:
    Lot(const double value, CAccountInfo& a)
    {
        m_account = &a;
        m_currency_unit = 1000.0;
        if (!Valid(value)) {
            // SetUserError(ERR_USER_ERROR_FIRST);
            ErrorLog(ERR_USER_ERROR_FIRST, "Lotクラスのコンストラクタの引数に不正な値が代入されました。");
            return;
        }
        m_value = value;
    };
    bool CheckMaxLot(double lot);
    double Value();
    string ToString();
    void Optimize(const double maximum_risk);
};
bool Lot::Valid(const double value)
{
    if (value >= 0.01 || value < NormalizeDouble(m_account.FreeMargin() / m_currency_unit, 1)) {
        return true;
    }
    return false;
};
bool Lot::CheckMaxLot(double lot) { return lot < NormalizeDouble(m_account.FreeMargin() / m_currency_unit, 1); };
double Lot::Value() { return m_value; }
string Lot::ToString() { return (string)m_value; }

/**
 * @brief 余剰証拠金($)と引数の値を基にロット数を最適化する
 *
 * @param maximum_risk
 */
void Lot::Optimize(const double maximum_risk)
{
    if (maximum_risk < 0.01 || maximum_risk > 1) return;

    // 現在アカウントの余剰証拠金 * MaximumRisk / 1000
    double lots = NormalizeDouble(m_account.FreeMargin() * maximum_risk / m_currency_unit, 2);
    // TODO ブローカーごとにロットの最大値が違うと思うので後で調査し修正する
    m_value = lots > 99 ? 99 : lots;
}
