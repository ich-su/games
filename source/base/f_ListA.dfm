inherited FListA: TFListA
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  ClientHeight = 299
  ClientWidth = 490
  Color = clWindow
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  ExplicitWidth = 496
  ExplicitHeight = 327
  PixelsPerInch = 96
  TextHeight = 13
  object LabelTitle: TLabel
    Left = 12
    Top = 12
    Width = 174
    Height = 13
    Caption = #1042#1099#1073#1077#1088#1080#1090#1077' '#1082#1072#1090#1072#1083#1086#1075' '#1088#1072#1089#1087#1086#1083#1086#1078#1077#1085#1080#1103':'
  end
  object Grid: TDrawGrid
    Left = 12
    Top = 64
    Width = 453
    Height = 169
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    ColCount = 1
    DefaultRowHeight = 40
    DefaultDrawing = False
    FixedCols = 0
    RowCount = 1
    FixedRows = 0
    Options = []
    ScrollBars = ssVertical
    TabOrder = 0
    OnDblClick = GridDblClick
    OnDrawCell = GridDrawCell
    OnKeyDown = GridKeyDown
  end
  object ButtonOk: TBitBtn
    Left = 12
    Top = 256
    Width = 93
    Height = 25
    Default = True
    ModalResult = 1
    TabOrder = 1
    OnClick = ButtonOkClick
  end
  object ButtonCancel: TBitBtn
    Left = 111
    Top = 256
    Width = 93
    Height = 25
    ModalResult = 2
    TabOrder = 2
  end
end
