object frmWallSwimList: TfrmWallSwimList
  Left = 504
  Top = 112
  Width = 296
  Height = 449
  Caption = 'Wall swims:'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDefaultPosOnly
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lvWallSwims: TListView
    Left = 0
    Top = 0
    Width = 288
    Height = 403
    Align = alClient
    Columns = <
      item
        Caption = 'Room X'
      end
      item
        Caption = 'Room Y'
      end
      item
        Caption = 'X1'
        Width = 40
      end
      item
        Caption = 'Y1'
        Width = 40
      end
      item
        Caption = 'X2'
        Width = 40
      end
      item
        Caption = 'Y2'
        Width = 40
      end>
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
    OnChange = lvWallSwimsChange
    OnColumnClick = lvWallSwimsColumnClick
    OnCompare = lvWallSwimsCompare
    OnDblClick = lvWallSwimsDblClick
  end
  object sbMain: TStatusBar
    Left = 0
    Top = 403
    Width = 288
    Height = 19
    Panels = <>
    SimplePanel = True
  end
end
