unit f_MainA;

interface

uses
  Windows, Classes, Messages,
  c_strings, misc, f_A, Controls, jpeg;

const
  mf_Top   : integer = 32;
  mf_Left  : integer = 32;

var
  mf_Width : integer;
  mf_Height: integer;

type
  TFMainA = class(TFA)
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

    protected
      function Vrf(PtrValue: pointer): boolean;
      procedure M_prj_BringToFront(var AMessage: tMessage); message wm_prj_BringToFront;
      procedure WMMOVING(var AMessage: tMessage); message WM_MOVING;

    public
      procedure RegistryVars; virtual;
  end;

implementation

{$R *.dfm}

uses
  Forms,
  vars, cons,
  main;

procedure TFMainA.RegistryVars; begin
  with Variables do begin
    RegistryInteger(vn_mf_Top, mf_Top, self, Vrf);
    RegistryInteger(vn_mf_Left, mf_Left, self, Vrf);
    RegistryInteger(vn_mf_Width, mf_Width, nil, nil, true);
    RegistryInteger(vn_mf_Height, mf_Height, nil, nil, true);
  end;
end;

function TFMainA.Vrf; begin
  Result:=true;

  if PtrValue = @mf_Top then Top:=mf_Top else
  if PtrValue = @mf_Left then Left:=mf_Left;
  if (PtrValue = @mf_Top) or (PtrValue = @mf_Left) then Console.NormalizeSize;
end;

procedure TFMainA.FormCloseQuery(Sender: TObject; var CanClose: Boolean); begin
  inherited;

  CanClose:=true;
  MngProject.BeforeTerminate;
end;

procedure TFMainA.FormCreate(Sender: TObject); begin
  inherited;

  Left:=mf_Left;
  Top:=mf_Top;
end;

procedure TFMainA.FormResize(Sender: TObject); begin
  inherited;

  mf_Width:=Width;
  mf_Height:=Height;
end;

procedure TFMainA.WMMOVING; begin
  inherited;

  mf_Left:=pRect(AMessage.LParam).Left;
  mf_Top:=pRect(AMessage.LParam).Top
end;

procedure TFMainA.M_prj_BringToFront; begin
  MngProject.BringToFront
end;

initialization
  mf_Top:=mf_Top + Screen.WorkAreaTop;
  mf_Left:=mf_Left + Screen.WorkAreaLeft;
end.

