object MainForm: TMainForm
  Left = 188
  Top = 223
  Width = 963
  Height = 769
  Caption = 'NLDSnakeImage Demo - [And just another example...]'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    947
    733)
  PixelsPerInch = 96
  TextHeight = 13
  object StopButton: TButton
    Left = 7
    Top = 7
    Width = 92
    Height = 25
    Caption = 'Stop animation'
    TabOrder = 0
    OnClick = StopButtonClick
  end
  object Thanks: TStaticText
    Left = 83
    Top = 350
    Width = 780
    Height = 33
    Alignment = taCenter
    Anchors = []
    AutoSize = False
    Caption = 'Thanks for trying!'
    Color = 486837
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 11523813
    Font.Height = -24
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabOrder = 1
    Transparent = False
    Visible = False
  end
end
