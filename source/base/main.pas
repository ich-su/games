unit main;

interface

uses 
  t_mProject;

var
  MngProject: tMngProject;

procedure Run;

implementation

uses
  Windows, Messages, SysUtils,
  misc, c_strings;

procedure Run;

  function VerifyRun: boolean;

    function FindNextWnd(StartHWND: HWND; AString: string): HWND;
    var Buffer: array[0..255] of char;
    begin
      Result:=StartHWND;
      repeat
        Result:=FindWindowEx(0, Result, nil, nil);
        GetWindowText(Result, Buffer, SizeOf(Buffer));
        if StrPos(StrUpper(Buffer), pChar(UpperCase(AString))) <> nil then break;
      until Result = 0;
    end;

  var h: integer;
  begin
    h:=FindNextWnd(0, Format(caption_Format, [ProjectTitle, '']));
    Result:=h = 0;
    if not Result then PostMessage(h, wm_prj_BringToFront , 0, 0);
  end;

begin
  InitFormats;

  if VerifyRun then
    try
      MngProject:=tMngProject.Create;

      if MngProject.Init then begin
        MngProject.Run;
        MngProject.Done;
      end;

    finally
      MngProject.Free
    end;
end;

end.

