unit save;

interface

uses
  Classes;

type
  tGameSave = class(tMemoryStream)
    public
      procedure Save(AValue: byte); overload;
      procedure Save(AValue: word); overload;
      procedure Save(AValue: integer); overload;
      procedure Save(AValue: cardinal); overload;
      procedure Save(AValue: boolean); overload;
      procedure Save(AValue: tDateTime); overload;
      procedure Save(AValue: extended); overload;
      procedure Save(AValue: string); overload;
      procedure Save(AValue: tStringList); overload;

      procedure Load(var AValue: byte); overload;
      procedure Load(var AValue: word); overload;
      procedure Load(var AValue: integer); overload;
      procedure Load(var AValue: cardinal); overload;
      procedure Load(var AValue: boolean); overload;
      procedure Load(var AValue: tDateTime); overload;
      procedure Load(var AValue: extended); overload;
      procedure Load(var AValue: string); overload;
      procedure Load(var AValue: tStringList); overload;
  end;

implementation

procedure tGameSave.Save(AValue: byte); begin
  Write(AValue, sizeof(AValue));
end;

procedure tGameSave.Save(AValue: word); begin
  Write(AValue, sizeof(AValue));
end;

procedure tGameSave.Save(AValue: integer); begin
  Write(AValue, sizeof(AValue));
end;

procedure tGameSave.Save(AValue: cardinal); begin
  Write(AValue, sizeof(AValue));
end;

procedure tGameSave.Save(AValue: boolean); begin
  Write(AValue, sizeof(AValue));
end;

procedure tGameSave.Save(AValue: tDateTime); begin
  Write(AValue, sizeof(AValue));
end;

procedure tGameSave.Save(AValue: extended); begin
  Write(AValue, sizeof(AValue));
end;

procedure tGameSave.Save(AValue: string); begin
  Save(length(AValue));
  if length(AValue) > 0 then Write(AValue[1], length(AValue));
end;

procedure tGameSave.Save(AValue: tStringList);
var i: integer;
begin
  Save(AValue.Count);
  for i:=0 to AValue.Count - 1 do Save(AValue[i])
end;



procedure tGameSave.Load(var AValue: byte); begin
  Read(AValue, sizeof(AValue));
end;

procedure tGameSave.Load(var AValue: word); begin
  Read(AValue, sizeof(AValue));
end;

procedure tGameSave.Load(var AValue: integer); begin
  Read(AValue, sizeof(AValue));
end;

procedure tGameSave.Load(var AValue: cardinal); begin
  Read(AValue, sizeof(AValue));
end;

procedure tGameSave.Load(var AValue: boolean); begin
  Read(AValue, sizeof(AValue));
end;

procedure tGameSave.Load(var AValue: tDateTime); begin
  Read(AValue, sizeof(AValue));
end;

procedure tGameSave.Load(var AValue: extended); begin
  Read(AValue, sizeof(AValue));
end;

procedure tGameSave.Load(var AValue: string);
var l: integer;
begin
  Load(l);
  if l > 0 then begin
    SetLength(AValue, l);
    Read(AValue[1], l)
  end
end;

procedure tGameSave.Load(var AValue: tStringList);
var
  s   : string;
  i, c: integer;
begin
  Load(c);
  for i:=0 to c - 1 do begin
    Load(s);
    AValue.Add(s)
  end
end;

end.

