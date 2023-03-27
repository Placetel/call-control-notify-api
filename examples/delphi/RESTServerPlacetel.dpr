program RESTServerPlacetel;

uses
  Vcl.Forms,
  RESTServerPlacetelW in 'RESTServerPlacetelW.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TRESTServerPlacetelWin, RESTServerPlacetelWin);
  Application.Run;
end.
