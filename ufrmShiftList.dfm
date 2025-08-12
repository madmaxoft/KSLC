object frmShiftList: TfrmShiftList
  Left = 468
  Top = 233
  Width = 492
  Height = 275
  ActiveControl = lvShifts
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeToolWin
  Caption = 'All Shifts:'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object lvShifts: TListView
    Left = 0
    Top = 0
    Width = 484
    Height = 248
    Align = alClient
    Columns = <
      item
        Caption = 'From RoomX'
      end
      item
        Caption = 'From RoomY'
      end
      item
        Caption = 'From X'
      end
      item
        Caption = 'From Y'
      end
      item
        Caption = 'To Room X'
      end
      item
        Caption = 'To Room Y'
      end
      item
        Caption = 'To X'
      end
      item
        Caption = 'To Y'
      end
      item
        Caption = 'Index'
      end>
    ColumnClick = False
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    PopupMenu = pmShift
    TabOrder = 0
    ViewStyle = vsReport
  end
  object pmShift: TPopupMenu
    Left = 88
    Top = 72
    object pmiGotoTo: TMenuItem
      Caption = 'Go to "To"'
      Default = True
      OnClick = pmiGotoToClick
    end
    object pmiGotoFrom: TMenuItem
      Caption = 'Go to "From"'
      OnClick = pmiGotoFromClick
    end
  end
end
