object dlgInstalledLevelList: TdlgInstalledLevelList
  Left = 368
  Top = 179
  Width = 772
  Height = 536
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'Installed Levels:'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poDefaultPosOnly
  OnKeyPress = FormKeyPress
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pMain: TPanel
    Left = 0
    Top = 0
    Width = 764
    Height = 484
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 0
    DesignSize = (
      764
      484)
    object lWorlds: TLabel
      Left = 4
      Top = 4
      Width = 89
      Height = 13
      Caption = 'Choose a level:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lvWorld: TListView
      Left = 8
      Top = 24
      Width = 749
      Height = 453
      Anchors = [akLeft, akTop, akRight, akBottom]
      Columns = <
        item
          Caption = 'Folder'
          Width = 250
        end
        item
          Caption = 'Level Name'
          Width = 150
        end
        item
          Caption = 'Author'
          Width = 150
        end>
      ColumnClick = False
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
      OnDblClick = tlOKClick
    end
  end
  object pTl: TPanel
    Left = 0
    Top = 484
    Width = 764
    Height = 25
    Align = alBottom
    BevelOuter = bvLowered
    TabOrder = 1
    object tlOK: TThinIcoButton
      Left = 1
      Top = 1
      Width = 344
      Height = 23
      Align = alLeft
      Caption = '&OK'
      OnClick = tlOKClick
    end
    object tlCancel: TThinIcoButton
      Left = 345
      Top = 1
      Width = 418
      Height = 23
      Align = alClient
      Caption = '&Cancel'
      OnClick = tlCancelClick
    end
  end
end
