object frmShiftsToHere: TfrmShiftsToHere
  Left = 899
  Top = 239
  Width = 347
  Height = 260
  BorderIcons = [biSystemMenu, biMaximize]
  BorderStyle = bsSizeToolWin
  Caption = 'Shifts To Here:'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDefaultPosOnly
  PixelsPerInch = 96
  TextHeight = 13
  object lvShifts: TListView
    Left = 0
    Top = 0
    Width = 339
    Height = 233
    Align = alClient
    Columns = <
      item
        Caption = 'From RoomX'
        Width = 80
      end
      item
        Caption = 'From RoomY'
        Width = 80
      end
      item
        Caption = 'From X'
      end
      item
        Caption = 'From Y'
      end
      item
        Caption = 'Index'
      end>
    ColumnClick = False
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
    OnDblClick = lvShiftsDblClick
  end
end
