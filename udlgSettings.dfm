object dlgSettings: TdlgSettings
  Left = 426
  Top = 129
  Width = 480
  Height = 283
  BorderIcons = [biSystemMenu]
  Caption = 'Settings:'
  Color = clBtnFace
  Constraints.MinHeight = 110
  Constraints.MinWidth = 80
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pGameFolder: TPanel
    Left = 0
    Top = 0
    Width = 472
    Height = 57
    Align = alTop
    BevelOuter = bvLowered
    TabOrder = 0
    DesignSize = (
      472
      57)
    object Label1: TLabel
      Left = 4
      Top = 4
      Width = 147
      Height = 13
      Caption = 'Knytt Stories game folder:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object eKSDir: TEdit
      Left = 12
      Top = 24
      Width = 329
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
    object tlBrowseKSDir: TThinIcoButton
      Left = 344
      Top = 22
      Width = 122
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '&Browse...'
      Glyph.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000000000000000000000000
        80000080000000808000800000008000800080800000C0C0C000808080000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00DDDDDDDDDDDD
        DDDDDDDDDDDDDDDDDDDDDDD0000000000000DD33333333333300DD3F7B7B7777
        7300D3FBB7B7B7777030D3FBBBBB7B7730303FBBBB7BB7B70B303FBBBBBB7B7B
        0B30333333333333B730D3FBBBBBBBBB7B30D3FBBBBBBBFFFFF0D3FBBBBBF333
        333DDD3FFFFF3DDDDDDDDDD33333DDDDDDDDDDDDDDDDDDDDDDDD}
      OnClick = tlBrowseKSDirClick
    end
  end
  object pTl: TPanel
    Left = 0
    Top = 230
    Width = 472
    Height = 26
    Align = alBottom
    BevelOuter = bvLowered
    TabOrder = 1
    object tlOK: TThinIcoButton
      Left = 1
      Top = 1
      Width = 299
      Height = 24
      Align = alClient
      Caption = '&OK'
      OnClick = tlOKClick
    end
    object tlCancel: TThinIcoButton
      Left = 300
      Top = 1
      Width = 171
      Height = 24
      Align = alRight
      Caption = '&Cancel'
      OnClick = tlCancelClick
    end
  end
  object pWebUpdate: TPanel
    Left = 0
    Top = 57
    Width = 472
    Height = 173
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 2
    DesignSize = (
      472
      173)
    object Label2: TLabel
      Left = 4
      Top = 4
      Width = 31
      Height = 13
      Caption = 'Web:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object chbAllowWebVersionCheck: TCheckBox
      Left = 12
      Top = 24
      Width = 450
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Check for new versions on the web'
      TabOrder = 0
      OnClick = chbAllowWebVersionCheckClick
    end
    object chbAllowWebStats: TCheckBox
      Left = 12
      Top = 44
      Width = 450
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Allow statistics collection'
      TabOrder = 1
    end
    object mStatPlea: TMemo
      Left = 36
      Top = 68
      Width = 425
      Height = 93
      Anchors = [akLeft, akTop, akRight, akBottom]
      BevelInner = bvNone
      BevelKind = bkTile
      BorderStyle = bsNone
      Color = clBtnFace
      Lines.Strings = (
        
          'Please do allow statistics collection if possible. This way the ' +
          'authors of KSLC will know '
        
          'how many people actually do use the program (so that we don'#39't ma' +
          'ke a program for '
        'nobody ;)'
        ''
        
          'The only statistics collected are KSLC version number and level ' +
          'name being edited.')
      TabOrder = 2
    end
  end
end
