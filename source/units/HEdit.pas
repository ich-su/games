unit HEdit;

interface

uses StdCtrls, Controls, Messages;

type
  tHEdit = class(tEdit)
    private
      FOnCNKeyDown: tKeyEvent;

    protected
      procedure CNKeyDown(var M: TWMKeyDown); message CN_KeyDown;

    published
      property OnCNKeyDown: tKeyEvent read FOnCNKeyDown write FOnCNKeyDown;
  end;

procedure Register;

implementation

uses Classes, i_sys;

procedure tHEdit.CNKeyDown; begin
  with M do begin
    if Assigned(FOnCNKeyDown) then FOnCNKeyDown(self, CharCode, GetShiftState);
    if CharCode <> 0 then inherited
  end
end;

procedure Register; begin
  RegisterComponents('ich', [THEdit]);
end;

end.

