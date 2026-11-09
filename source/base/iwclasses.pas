unit iwclasses;

interface

type
  tIWControl = string;
  
  tMngA = class
    public
      function OnControl(ASender: tObject; AControl: tIWControl): boolean; virtual;
  end;

function IWControlAssigned(AControl: tIWControl): boolean; 

implementation

function IWControlAssigned; begin
  Result:=length(AControl) > 0
end;

function tMngA.OnControl; begin
  Result:=true
end;

end.

