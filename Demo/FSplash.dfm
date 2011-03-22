object SplashForm: TSplashForm
  Left = 521
  Top = 381
  BorderStyle = bsNone
  Caption = 'SplashForm'
  ClientHeight = 480
  ClientWidth = 640
  Color = 15793132
  Font.Charset = DEFAULT_CHARSET
  Font.Color = 12288
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 16
  object Manual: TStaticText
    Left = 14
    Top = 448
    Width = 113
    Height = 20
    Caption = 'Click to skip intro...'
    TabOrder = 0
    Transparent = False
    OnClick = SnakeClick
  end
  object Timer: TTimer
    Interval = 28000
    OnTimer = TimerTimer
    Left = 7
    Top = 7
  end
end
