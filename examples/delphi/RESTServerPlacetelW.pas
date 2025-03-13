unit RESTServerPlacetelW;

interface

uses
  System.SysUtils, System.Variants, Types, System.Classes, Controls, Forms, StdCtrls, Graphics,
  IdContext, IdCustomHTTPServer,  IdBaseComponent, IdHTTPServer, IdComponent, IdCustomTCPServer;

type
  TCallRecord = record
    event      : string;
    CallFrom   : string;
    CallTo     : string;
    HangupType : string;
    duration   : Integer;
    direction  : string;
    peer       : string;
    callID     : string;
  end;

type
  TRESTServerPlacetelWin = class(TForm)
    RESTServer: TIdHTTPServer;
    IncomingLogLB: TListBox;
    function  GetCallRecord(ARequestInfo: TIdHTTPRequestInfo): TCallRecord;
    procedure RESTServerCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure IncomingLogLBDrawItem(Control: TWinControl; Index: Integer; Rect: TRect;  State: TOwnerDrawState);
    procedure IncomingLogLBKeyDown(Sender: TObject; var Key: Word; Shift:  TShiftState);
    procedure HandlePlacetelCallRoutingHTTPRequest(ARequestInfo: TIdHTTPRequestInfo;  AResponseInfo: TIdHTTPResponseInfo);
    function  HandlePlacetelCallRoutingEvent(aCall: TCallRecord): string;
    procedure RESTServerAfterBind(Sender: TObject);
  private
    procedure Log( aLogObject : TObject); overload;
    procedure Log( aText : String); overload;
    procedure Log( aText : String;  aLogObject : TObject); overload;
    { Private-Deklarationen }
  public
    function  HandleIncomingCallEvent(aCall : TCallRecord) : string;
    procedure HandleOutgoingCallEvent(aCall : TCallRecord);
    procedure HandleAcceptedEvent(aCall : TCallRecord);
    procedure HandleHungUpEvent(aCall : TCallRecord);
    { Public-Deklarationen }
  end;

const
  RejectString : string = '<?xml version="1.0" encoding="UTF-8"?><Response><Reject /></Response>';
  RejectBusyString : string = '<?xml version="1.0" encoding="UTF-8"?><Response><Reject reason="busy" /></Response>';
  HangUpString : string = '<?xml version="1.0" encoding="UTF-8"?><Response><Hangup /></Response>';

var
  RESTServerPlacetelWin: TRESTServerPlacetelWin;

implementation

{$R *.dfm}

uses
  System.Hash, ClipBrd;

const
  HMacKey  : string = '1234';
  threaded : boolean = true;
  RESTResourceCallRouting : string = '/PlacetelCallRoutingEvent';

function TRESTServerPlacetelWin.HandleIncomingCallEvent(aCall: TCallRecord): string;
begin
  // do some routing stuff

  //  if aCall.CallFrom = 'BlockedPhoneNumber' then exit(RejectString);
  //
  //  result :=  ' <?xml version="1.0" encoding="UTF-8"?>          ' +
  //             '   <Response>                                    ' +
  //             '    <Forward>                                    ' +
  //             '        <Target ringtime="30">                   ' +
  //             '            <Number>7777abcdefg@fpbx.de</Number> ' +
  //             '            <Number>022129191999</Number>        ' +
  //             '        </Target>                                ' +
  //             '        <Target ringtime="45">                   ' +
  //             '            <Number>7777xyzabcd@fpbx.de</Number> ' +
  //             '            <Number>7777aabbccd@fpbx.de</Number> ' +
  //             '            <Number>022199998560</Number>        ' +
  //             '        </Target>                                ' +
  //             '     </Forward>                                  ' +
  //             '   </Response>                                   ';
end;


procedure TRESTServerPlacetelWin.HandleAcceptedEvent(aCall: TCallRecord);
begin
  // Do something when a call was accepted
end;

procedure TRESTServerPlacetelWin.HandleHungUpEvent(aCall: TCallRecord);
begin
  // Do something when a call was hung up
end;

procedure TRESTServerPlacetelWin.HandleOutgoingCallEvent(aCall: TCallRecord);
begin
  // Do something when someone is calling outside
end;




{$REGION 'Logging Types'}

type TLogPlacetelEvent = class(TObject)
  protected
    Date      : TDateTime;
    Payload   : string;
    Signature : string;
  public
    constructor Create(aPayload, aSignature : string);  reintroduce;
end;

type TLogError = class(TObject)
  protected
    Date  : TDateTime;
    Error : string;
  public
    constructor Create(aError : string); reintroduce;
end;

type TLog = class(TObject)
  protected
    Date  : TDateTime;
    Text : string;
  public
    constructor Create(aText : string); reintroduce;
end;

type TLogAnswer = class(TObject)
  protected
    Date : TDateTime;
    Text : string;
  public
    constructor Create(aText : string); reintroduce;
end;

{$ENDREGION}


{$REGION 'REST Server Handling'}

function TRESTServerPlacetelWin.HandlePlacetelCallRoutingEvent(aCall: TCallRecord): string;
begin
  result := '<?xml version="1.0" encoding="UTF-8"?><response>OK</response>';

  if aCall.event =  'IncomingCall' then
  begin
    result :=  HandleIncomingCallEvent(aCall);
    exit;
  end;

  if aCall.event =  'OutgoingCall' then
  begin
    HandleOutgoingCallEvent(aCall);
    exit;
  end;

  if aCall.event =  'CallAccepted' then
  begin
    HandleAcceptedEvent(aCall);
    exit;
  end;

  if aCall.event =  'HungUp'       then
  begin
   HandleHungUpEvent(aCall);
   exit;
  end;

  raise Exception.CreateFmt('HandlePlacetelCallRoutingEvent : Event konnte keiner Unterfunktion zusortiert werden. (Event: "%s")', [aCall.event]);
end;

function TRESTServerPlacetelWin.GetCallRecord(ARequestInfo: TIdHTTPRequestInfo) : TCallRecord;
begin
  result.callID     :=  ARequestInfo.Params.Values['call_id'];
  result.event      :=  ARequestInfo.Params.Values['event'];
  result.CallFrom   :=  ARequestInfo.Params.Values['from'];
  result.CallTo     :=  ARequestInfo.Params.Values['to'];
  result.direction  :=  ARequestInfo.Params.Values['direction'];
  result.peer       :=  ARequestInfo.Params.Values['peer'];
  result.HangupType :=  ARequestInfo.Params.Values['type'];
  if  ARequestInfo.Params.Values['duration'] <> ''
    then result.duration := StrToInt( ARequestInfo.Params.Values['duration'] );
end;

procedure TRESTServerPlacetelWin.HandlePlacetelCallRoutingHTTPRequest(ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  Payload : string;
  Signature : string;
  aCallRec : TCallRecord;
begin
  Payload   := ARequestInfo.UnparsedParams;
  Signature := ARequestInfo.RawHeaders.Values['X-PLACETEL-SIGNATURE'];
  Log( TLogPlacetelEvent.Create(Payload, Signature) );

  try
    if THashSHA2.GetHMAC(Payload,  HMacKey) <> Signature
      then raise Exception.Create('Wrong signature! Signature in the request header does not match the calculated signature from palyoad and HMAC secret.') ;

    aCallRec := GetCallRecord(ARequestInfo);
    AResponseInfo.ContentText := HandlePlacetelCallRoutingEvent(aCallRec) ;
    AResponseInfo.ContentType := 'application/xml';
    AResponseInfo.ResponseNo  := 200;
    Log( TLogAnswer.Create(AResponseInfo.ContentText) );
  except
    on e : Exception do
    begin
      AResponseInfo.ResponseNo  := 500;
      AResponseInfo.ContentType := 'application/xml';
      AResponseInfo.ContentText := format('<?xml version="1.0" encoding="UTF-8"?><error>%s</error>',[e.Message]);
      Log( TLogError.Create(e.Message) );
    end;
  end;
end;

procedure TRESTServerPlacetelWin.RESTServerCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  if ( ARequestInfo.URI.toLower = RESTResourceCallRouting.ToLower ) and (ARequestInfo.CommandType = hcPOST) then
  begin
    if threaded
      then HandlePlacetelCallRoutingHTTPRequest(ARequestInfo, AResponseInfo)
      else TThread.Synchronize(nil,
                                procedure
                                begin
                                  HandlePlacetelCallRoutingHTTPRequest(ARequestInfo, AResponseInfo);
                                end);
  end;
end;

{$ENDREGION}


{$REGION 'Logging'}

procedure TRESTServerPlacetelWin.RESTServerAfterBind(Sender: TObject);
var
   i : integer;
begin
  LOG( 'REST Server startet...' );
  for i := 0 to RESTServer.Bindings.Count - 1
    do LOG( Format('Listening  IP: %s Port: %d', [RESTServer.Bindings.items[i].IP, RESTServer.Bindings.items[i].Port] ) );

  if RESTServer.Bindings.Count > 0 then
  begin
    LOG( '.......' );
    Log(Format('API URL Endpoint: "http://%s:%d%s"     API HMAC secret: "%s"   ', [RESTServer.Bindings.items[0].IP, RESTServer.Bindings.items[0].Port, RESTResourceCallRouting, HMacKey]));
    LOG( '.......' );
  end;
end;



procedure TRESTServerPlacetelWin.IncomingLogLBDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
begin
  var c := IncomingLogLB.Canvas;

  c.Brush.Color := clWindow;
  c.FillRect(Rect);

  c.Font.Color := clWindowText;
  c.MoveTo(Rect.Left, Rect.Top);


  var aObject := IncomingLogLB.Items.Objects[index];
  if aObject is  TLogPlacetelEvent then
  begin
    c.Font.Color := clBlue;
    c.TextOut(c.PenPos.X, Rect.Top + 1, DateTimeToStr(TLogPlacetelEvent(aObject).date)+'  ');

    c.Font.Color := clWindowText;
    c.TextOut(c.PenPos.X, Rect.Top + 1, TLogPlacetelEvent(aObject).Payload+'  ');

    c.Font.Color := $BBBBBB;
    c.TextOut(c.PenPos.X, Rect.Top + 1, 'sig: '+TLogPlacetelEvent(aObject).Signature);
  end
   else
  if aObject is TLogError then
  begin
    c.Font.Color := clBlue;
    c.TextOut(c.PenPos.X, Rect.Top + 1, DateTimeToStr(TLogError(aObject).date)+'  ');

    c.Font.Color := clMaroon;
    c.TextOut(c.PenPos.X, Rect.Top + 1, TLogError(aObject).Error);
  end
   else
  if aObject is TLog then
  begin
    c.Font.Color := clBlue;
    c.TextOut(c.PenPos.X, Rect.Top + 1, DateTimeToStr(TLog(aObject).date)+'  ');

    c.Font.Color := clWindowText;
    c.TextOut(c.PenPos.X, Rect.Top + 1, TLog(aObject).text);
  end
   else
  if aObject is TLogAnswer then
  begin
    c.Font.Color := clBlue;
    c.TextOut(c.PenPos.X, Rect.Top + 1, DateTimeToStr(TLogAnswer(aObject).date)+'  ');

    c.Font.Color := clGreen;
    c.TextOut(c.PenPos.X, Rect.Top + 1, TLogAnswer(aObject).Text);
  end
   else
  begin
    c.Font.Color := clWindowText;
    c.TextOut(c.PenPos.X, Rect.Top + 1, IncomingLogLB.Items[Index] );
  end;


end;

procedure TRESTServerPlacetelWin.IncomingLogLBKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   // Strg + C
  if (Shift = [ssCtrl])  and (Key = 67)
    then Clipboard.AsText := IncomingLogLB.Items[IncomingLogLB.ItemIndex];

end;

procedure TRESTServerPlacetelWin.Log(aLogObject: TObject);
begin
  Log('',aLogObject);
end;

procedure TRESTServerPlacetelWin.Log(aText: String);
begin
  Log(aText, TLog.Create(aText));
end;

procedure TRESTServerPlacetelWin.Log(aText: String; aLogObject: TObject);
begin
  TThread.Synchronize(nil,
      procedure
      begin
        var scrolling := (IncomingLogLB.ItemIndex = IncomingLogLB.Count-1);

        IncomingLogLB.AddItem(aText, aLogObject );
        if IncomingLogLB.Count > 200 then
        begin
          if IncomingLogLB.Items.Objects[0] <> nil
            then IncomingLogLB.Items.Objects[0].Free;
          IncomingLogLB.Items.Delete(0);
        end;

        if scrolling then IncomingLogLB.ItemIndex := IncomingLogLB.Count-1
      end);
end;

{ TLogError }

constructor TLogError.Create(aError: string);
begin
  Date := now;
  Error := aError;
end;

{ TLogPlacetelEvent }

constructor TLogPlacetelEvent.Create(aPayload, aSignature: string);
begin
  date := now;
  Payload := aPayload;
  Signature:= aSignature;
end;

{ TLogAnswer }

constructor TLogAnswer.Create(aText: string);
begin
  Date := now;
  Text := aText;
end;

{ TLog }

constructor TLog.Create(aText: string);
begin
  Date := now;
  Text := aText;
end;


{$ENDREGION}


end.
