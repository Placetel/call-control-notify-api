object RESTServerPlacetelWin: TRESTServerPlacetelWin
  Left = 271
  Top = 114
  Caption = 'Webservice Placetel'
  ClientHeight = 385
  ClientWidth = 1046
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object IncomingLogLB: TListBox
    Left = 0
    Top = 0
    Width = 1046
    Height = 385
    Style = lbOwnerDrawFixed
    Align = alClient
    TabOrder = 0
    OnDrawItem = IncomingLogLBDrawItem
    OnKeyDown = IncomingLogLBKeyDown
    ExplicitWidth = 1042
    ExplicitHeight = 384
  end
  object RESTServer: TIdHTTPServer
    Active = True
    Bindings = <>
    DefaultPort = 8080
    OnAfterBind = RESTServerAfterBind
    OnCommandGet = RESTServerCommandGet
    Left = 72
    Top = 56
  end
end
