//+------------------------------------------------------------------+
//|                                                  BandsCustom.mq4 |
//|                                      Copyright 2023-2023, fxowl. |
//|                                                          http:// |
//+------------------------------------------------------------------+
#property copyright "2005-2014, MetaQuotes Software Corp."
// #property link "http://www.mql4.com"
#property description "Custom Default Bollinger Bands."
#property strict

#include <MovingAverages.mqh>

#property indicator_chart_window
#property indicator_buffers 7
#property indicator_color1 clrOrangeRed // middle band
#property indicator_color2 clrDarkOrange // upper band1
#property indicator_color3 clrDarkGoldenrod // upper band2
#property indicator_color4 clrDarkKhaki // upper band3
#property indicator_color5 clrDarkOrange // lower band1
#property indicator_color6 clrDarkGoldenrod // lower band2
#property indicator_color7 clrDarkKhaki // lower band3

//--- indicator parameters
input int InpBandsPeriod = 20; // Bands Period
input int InpBandsShift = 0; // Bands Shift
input double InpBandsDeviations1 = 1.0; // Bands Deviations1
input double InpBandsDeviations2 = 2.0; // Bands Deviations2
input double InpBandsDeviations3 = 3.0; // Bands Deviations3

//--- buffers
double ExtMovingBuffer[];
double ExtUpperBuffer1[];
double ExtUpperBuffer2[];
double ExtUpperBuffer3[];
double ExtLowerBuffer1[];
double ExtLowerBuffer2[];
double ExtLowerBuffer3[];
double ExtStdDevBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
{
    //--- 1 additional buffer used for counting.
    IndicatorBuffers(8);
    IndicatorDigits(Digits);
    //--- middle line
    SetIndexStyle(0, DRAW_LINE);
    SetIndexBuffer(0, ExtMovingBuffer);
    SetIndexShift(0, InpBandsShift);
    SetIndexLabel(0, "Bands SMA");
    //--- upper band
    SetIndexStyle(1, DRAW_LINE);
    SetIndexBuffer(1, ExtUpperBuffer1);
    SetIndexShift(1, InpBandsShift);
    SetIndexLabel(1, "Bands Upper1");

    SetIndexStyle(2, DRAW_LINE);
    SetIndexBuffer(2, ExtUpperBuffer2);
    SetIndexShift(2, InpBandsShift);
    SetIndexLabel(2, "Bands Upper2");

    SetIndexStyle(3, DRAW_LINE);
    SetIndexBuffer(3, ExtUpperBuffer3);
    SetIndexShift(3, InpBandsShift);
    SetIndexLabel(3, "Bands Upper3");

    //--- lower band
    SetIndexStyle(4, DRAW_LINE);
    SetIndexBuffer(4, ExtLowerBuffer1);
    SetIndexShift(4, InpBandsShift);
    SetIndexLabel(4, "Bands Lower1");

    SetIndexStyle(5, DRAW_LINE);
    SetIndexBuffer(5, ExtLowerBuffer2);
    SetIndexShift(5, InpBandsShift);
    SetIndexLabel(5, "Bands Lower2");

    SetIndexStyle(6, DRAW_LINE);
    SetIndexBuffer(6, ExtLowerBuffer3);
    SetIndexShift(6, InpBandsShift);
    SetIndexLabel(6, "Bands Lower3");
    //--- work buffer
    SetIndexBuffer(7, ExtStdDevBuffer);
    //--- check for input parameter
    if (InpBandsPeriod <= 0) {
        Print("Wrong input parameter Bands Period=", InpBandsPeriod);
        return (INIT_FAILED);
    }
    //---
    SetIndexDrawBegin(0, InpBandsPeriod + InpBandsShift);
    SetIndexDrawBegin(1, InpBandsPeriod + InpBandsShift);
    SetIndexDrawBegin(2, InpBandsPeriod + InpBandsShift);
    SetIndexDrawBegin(3, InpBandsPeriod + InpBandsShift);
    SetIndexDrawBegin(4, InpBandsPeriod + InpBandsShift);
    SetIndexDrawBegin(5, InpBandsPeriod + InpBandsShift);
    SetIndexDrawBegin(6, InpBandsPeriod + InpBandsShift);
    //--- initialization done
    return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Bollinger Bands                                                  |
//+------------------------------------------------------------------+
int OnCalculate(
    const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[],
    const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]
)
{
    int i, pos;
    //---
    if (rates_total <= InpBandsPeriod || InpBandsPeriod <= 0) return (0);
    //--- counting from 0 to rates_total
    ArraySetAsSeries(ExtMovingBuffer, false);
    ArraySetAsSeries(ExtUpperBuffer1, false);
    ArraySetAsSeries(ExtUpperBuffer2, false);
    ArraySetAsSeries(ExtUpperBuffer3, false);
    ArraySetAsSeries(ExtLowerBuffer1, false);
    ArraySetAsSeries(ExtLowerBuffer2, false);
    ArraySetAsSeries(ExtLowerBuffer3, false);
    ArraySetAsSeries(ExtStdDevBuffer, false);
    ArraySetAsSeries(close, false);
    //--- initial zero
    if (prev_calculated < 1) {
        for (i = 0; i < InpBandsPeriod; i++) {
            ExtMovingBuffer[i] = EMPTY_VALUE;
            ExtUpperBuffer1[i] = EMPTY_VALUE;
            ExtUpperBuffer2[i] = EMPTY_VALUE;
            ExtUpperBuffer3[i] = EMPTY_VALUE;
            ExtLowerBuffer1[i] = EMPTY_VALUE;
            ExtLowerBuffer2[i] = EMPTY_VALUE;
            ExtLowerBuffer3[i] = EMPTY_VALUE;
        }
    }

    //--- starting calculation
    if (prev_calculated > 1)
        pos = prev_calculated - 1;
    else
        pos = 0;
    //--- main cycle
    for (i = pos; i < rates_total && !IsStopped(); i++) {
        // Print("debug" + i);
        //--- middle line
        ExtMovingBuffer[i] = SimpleMA(i, InpBandsPeriod, close);
        //--- calculate and write down StdDev
        ExtStdDevBuffer[i] = StdDev_Func(i, close, ExtMovingBuffer, InpBandsPeriod);
        //--- upper line
        ExtUpperBuffer1[i] = ExtMovingBuffer[i] + InpBandsDeviations1 * ExtStdDevBuffer[i];
        ExtUpperBuffer2[i] = ExtMovingBuffer[i] + InpBandsDeviations2 * ExtStdDevBuffer[i];
        ExtUpperBuffer3[i] = ExtMovingBuffer[i] + InpBandsDeviations3 * ExtStdDevBuffer[i];
        //--- lower line
        ExtLowerBuffer1[i] = ExtMovingBuffer[i] - InpBandsDeviations1 * ExtStdDevBuffer[i];
        ExtLowerBuffer2[i] = ExtMovingBuffer[i] - InpBandsDeviations2 * ExtStdDevBuffer[i];
        ExtLowerBuffer3[i] = ExtMovingBuffer[i] - InpBandsDeviations3 * ExtStdDevBuffer[i];
    }

    //---- OnCalculate done. Return new prev_calculated.
    return (rates_total);
}
//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StdDev_Func(int position, const double &price[], const double &MAprice[], int period)
{
    //--- variables
    double StdDev_dTmp = 0.0;
    //--- check for position
    if (position >= period) {
        //--- calcualte StdDev
        for (int i = 0; i < period; i++) StdDev_dTmp += MathPow(price[position - i] - MAprice[position], 2);
        StdDev_dTmp = MathSqrt(StdDev_dTmp / period);
    }
    //--- return calculated value
    return (StdDev_dTmp);
}
//+------------------------------------------------------------------+
