object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'MainForm'
  ClientHeight = 546
  ClientWidth = 541
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object FilterLabel: TLabel
    AlignWithMargins = True
    Left = 3
    Top = 352
    Width = 535
    Height = 13
    Align = alBottom
    Caption = 'Filter by window style'
    ExplicitWidth = 104
  end
  object MainListBox: TListBox
    Left = 0
    Top = 0
    Width = 541
    Height = 349
    Align = alClient
    DoubleBuffered = True
    ItemHeight = 13
    ParentDoubleBuffered = False
    TabOrder = 0
  end
  object IncludeFilterPanel: TFlowPanel
    AlignWithMargins = True
    Left = 10
    Top = 400
    Width = 521
    Height = 17
    Margins.Left = 10
    Margins.Top = 5
    Margins.Right = 10
    Margins.Bottom = 5
    Align = alBottom
    Alignment = taLeftJustify
    BevelEdges = [beBottom]
    BevelOuter = bvNone
    TabOrder = 1
  end
  object ExcludeFilterPanel: TFlowPanel
    AlignWithMargins = True
    Left = 10
    Top = 373
    Width = 521
    Height = 17
    Margins.Left = 10
    Margins.Top = 5
    Margins.Right = 10
    Margins.Bottom = 5
    Align = alBottom
    Alignment = taLeftJustify
    BevelOuter = bvNone
    TabOrder = 2
  end
  object EnumeratePanel: TPanel
    Left = 0
    Top = 499
    Width = 541
    Height = 47
    Align = alBottom
    BevelEdges = [beTop]
    BevelKind = bkSoft
    BevelOuter = bvNone
    TabOrder = 3
    object EnumerateButton: TButton
      Left = 113
      Top = 0
      Width = 428
      Height = 45
      Align = alClient
      Caption = 'Enumerate windows'
      Default = True
      TabOrder = 0
      OnClick = EnumerateButtonClick
    end
    object Panel1: TPanel
      Left = 0
      Top = 0
      Width = 113
      Height = 45
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 1
      object AutoUpdateCheckBox: TCheckBox
        Left = 3
        Top = 16
        Width = 97
        Height = 17
        Caption = 'Auto update'
        TabOrder = 0
        OnClick = AutoUpdateCheckBoxClick
      end
    end
  end
  object OptionsPanel: TPanel
    Left = 0
    Top = 422
    Width = 541
    Height = 77
    Align = alBottom
    Alignment = taLeftJustify
    BevelEdges = [beTop]
    BevelKind = bkSoft
    BevelOuter = bvNone
    TabOrder = 4
    object Label1: TLabel
      Left = 3
      Top = 8
      Width = 76
      Height = 13
      Caption = 'Further Options'
    end
    object OptionsFlowPanel: TFlowPanel
      AlignWithMargins = True
      Left = 113
      Top = 3
      Width = 425
      Height = 69
      Margins.Left = 113
      Align = alTop
      AutoSize = True
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitTop = 2
      object FilterHiddenWindowsCheckBox: TCheckBox
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 152
        Height = 17
        Caption = 'Filter hidden windows'
        TabOrder = 4
      end
      object FilterOverlappedWindowsCheckBox: TCheckBox
        AlignWithMargins = True
        Left = 161
        Top = 3
        Width = 152
        Height = 17
        Caption = 'Filter overlapped windows'
        TabOrder = 0
      end
      object OnlyCurrendVDCheckBox: TCheckBox
        AlignWithMargins = True
        Left = 3
        Top = 26
        Width = 202
        Height = 17
        Caption = 'Only current virtual desktop (Win 10)'
        Checked = True
        State = cbChecked
        TabOrder = 2
      end
      object FilterSelfCheckBox: TCheckBox
        AlignWithMargins = True
        Left = 211
        Top = 26
        Width = 152
        Height = 17
        Caption = 'Filter this window'
        TabOrder = 1
      end
      object FilterCloakedWindowsCheckBox: TCheckBox
        AlignWithMargins = True
        Left = 3
        Top = 49
        Width = 152
        Height = 17
        Caption = 'Filter cloaked windows'
        TabOrder = 3
      end
      object FilterMonitorCheckBox: TCheckBox
        AlignWithMargins = True
        Left = 161
        Top = 49
        Width = 152
        Height = 17
        Caption = 'Only current monitor'
        TabOrder = 5
      end
    end
  end
  object AutoUpdateTimer: TTimer
    Enabled = False
    Interval = 100
    OnTimer = AutoUpdateTimerTimer
    Left = 80
    Top = 504
  end
end
