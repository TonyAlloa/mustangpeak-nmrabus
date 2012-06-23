object Form1: TForm1
  Left = 661
  Top = 124
  Width = 682
  Height = 586
  Caption = 'mPascal ACDI String Editor'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    674
    559)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 48
    Width = 63
    Height = 13
    Caption = 'Manufacturer'
  end
  object Label2: TLabel
    Left = 16
    Top = 80
    Width = 57
    Height = 13
    Caption = 'Node Name'
  end
  object Label3: TLabel
    Left = 16
    Top = 112
    Width = 84
    Height = 13
    Caption = 'Hardware Version'
  end
  object Label4: TLabel
    Left = 16
    Top = 144
    Width = 80
    Height = 13
    Caption = 'Software Version'
  end
  object Label5: TLabel
    Left = 16
    Top = 225
    Width = 93
    Height = 13
    Caption = 'User Defined Name'
  end
  object Label6: TLabel
    Left = 16
    Top = 257
    Width = 118
    Height = 13
    Caption = 'User Defined Description'
  end
  object LabelMfgInfoVer: TLabel
    Left = 16
    Top = 16
    Width = 122
    Height = 13
    Caption = 'Manufacturer Info Version'
  end
  object LabelUserInfoVersion: TLabel
    Left = 32
    Top = 193
    Width = 101
    Height = 13
    Caption = 'LabelUserInfoVersion'
  end
  object EditMfg: TEdit
    Left = 160
    Top = 40
    Width = 280
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
    OnChange = EditMfgChange
  end
  object EditName: TEdit
    Left = 160
    Top = 72
    Width = 280
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 2
    OnChange = EditNameChange
  end
  object EditHWVersion: TEdit
    Left = 160
    Top = 104
    Width = 280
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 3
    OnChange = EditHWVersionChange
  end
  object EditSWVersion: TEdit
    Left = 160
    Top = 136
    Width = 280
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 4
    OnChange = EditSWVersionChange
  end
  object EditUserDefinedName: TEdit
    Left = 160
    Top = 217
    Width = 280
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 6
    OnChange = EditUserDefinedNameChange
  end
  object EditUserDefinedDesc: TEdit
    Left = 160
    Top = 249
    Width = 280
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 7
    OnChange = EditUserDefinedDescChange
  end
  object RichEdit1: TRichEdit
    Left = 16
    Top = 352
    Width = 650
    Height = 187
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 10
  end
  object ButtonGenerateCode: TButton
    Left = 16
    Top = 297
    Width = 137
    Height = 25
    Caption = 'Generate Code'
    TabOrder = 8
    OnClick = ButtonGenerateCodeClick
  end
  object ButtonDecompile: TButton
    Left = 168
    Top = 297
    Width = 137
    Height = 25
    Caption = 'Decompile'
    TabOrder = 9
    OnClick = ButtonDecompileClick
  end
  object EditMfgInfoVer: TEdit
    Left = 160
    Top = 8
    Width = 48
    Height = 21
    TabOrder = 0
    Text = '1'
    OnExit = EditMfgInfoVerExit
    OnKeyPress = EditMfgInfoVerKeyPress
  end
  object EditUserInfoVer: TEdit
    Left = 160
    Top = 185
    Width = 48
    Height = 21
    TabOrder = 5
    Text = '1'
  end
  object GroupBox1: TGroupBox
    Left = 449
    Top = 30
    Width = 214
    Height = 289
    Anchors = [akTop, akRight]
    Caption = 'Counts (Including nulls)'
    TabOrder = 11
    object Bevel1: TBevel
      Left = 5
      Top = 128
      Width = 204
      Height = 49
    end
    object Bevel2: TBevel
      Left = 5
      Top = 184
      Width = 204
      Height = 65
    end
    object LabelMfgLen: TLabel
      Left = 15
      Top = 17
      Width = 6
      Height = 13
      Caption = '0'
    end
    object LabelNodeNameLen: TLabel
      Left = 15
      Top = 49
      Width = 6
      Height = 13
      Caption = '0'
    end
    object LabelHardwareLen: TLabel
      Left = 15
      Top = 80
      Width = 6
      Height = 13
      Caption = '0'
    end
    object LabelSoftwareLen: TLabel
      Left = 15
      Top = 112
      Width = 6
      Height = 13
      Caption = '0'
    end
    object LabelUserName: TLabel
      Left = 15
      Top = 193
      Width = 6
      Height = 13
      Caption = '0'
    end
    object LabelUserDesc: TLabel
      Left = 15
      Top = 225
      Width = 6
      Height = 13
      Caption = '0'
    end
    object Label13: TLabel
      Left = 6
      Top = 257
      Width = 55
      Height = 13
      Caption = 'Total Count'
    end
    object LabelTotalCount: TLabel
      Left = 70
      Top = 257
      Width = 6
      Height = 13
      Caption = '0'
    end
    object Label15: TLabel
      Left = 111
      Top = 136
      Width = 90
      Height = 13
      Caption = 'OpenLCB Limits'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object LabelMaxDesc: TLabel
      Left = 181
      Top = 225
      Width = 15
      Height = 13
      Caption = '40'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object LabelUserMaxChar: TLabel
      Left = 181
      Top = 193
      Width = 15
      Height = 13
      Caption = '20'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object LabelMaxMfg: TLabel
      Left = 181
      Top = 153
      Width = 15
      Height = 13
      Caption = '64'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label19: TLabel
      Left = 77
      Top = 153
      Width = 92
      Height = 13
      Caption = '(Recommended)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object LabelMfgSubTotal: TLabel
      Left = 15
      Top = 153
      Width = 6
      Height = 13
      Caption = '0'
    end
    object Label21: TLabel
      Left = 15
      Top = 137
      Width = 43
      Height = 13
      Caption = 'SubTotal'
    end
  end
  object CheckBoxACDI: TCheckBox
    Left = 32
    Top = 328
    Width = 97
    Height = 17
    Caption = 'For Virtual Node ACDI'
    TabOrder = 12
  end
end
