unit f_A;

interface

uses
  Windows, Messages, Forms;

type
  tHActivateEvent = procedure(ASender: tObject; AMessage: tWMActivate) of object;
  tNCHITTESTEvent = procedure(var AMessage: tWMNCHITTEST) of object;

  TFA = class(TForm)
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);

    protected
      FOnHActivate: tHActivateEvent;
      FOnNCHITTEST: tNCHITTESTEvent;

      procedure OnActivateEx(AMessage: tWMActivate); virtual;
      procedure OnNCHITTESTSelf(var AMessage: tWMNCHitTest); virtual;

      procedure WMACTIVATE(var AMessage: tWMActivate); message WM_ACTIVATE;
      procedure WMNCHITTEST(var AMessage: tWMNCHitTest); message WM_NCHITTEST;

    public
      property OnHActivate: tHActivateEvent read FOnHActivate write FOnHActivate;
      property OnNCHITTEST: tNCHITTESTEvent read FOnNCHITTEST write FOnNCHITTEST;
  end;

implementation

{$R *.dfm}

uses
  SysUtils,
  c_strings, misc;

procedure TFA.FormDestroy(Sender: TObject); begin
  log(Format(log_frm_Free, [Caption]))
end;

procedure TFA.FormShow(Sender: TObject); begin
  log(Format(log_frm_Create, [Caption]))
end;

procedure TFA.OnActivateEx; begin
end;

procedure TFA.OnNCHITTESTSelf;
var p: tPoint;
begin
  p.X:=AMessage.XPos;
  p.Y:=AMessage.YPos;
  p:=ScreenToClient(p);

  if p.Y >= 0 then AMessage.Result:=htCaption;
end;

procedure TFA.WMACTIVATE; begin
  if Assigned(FOnHActivate) then FOnHActivate(self, AMessage)
  else OnActivateEx(AMessage);

  inherited;
end;

procedure TFA.WMNCHITTEST; begin
  inherited;

  if Assigned(FOnNCHITTEST) then FOnNCHITTEST(AMessage)
  else OnNCHITTESTSelf(AMessage);
end;

end.

