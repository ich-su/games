unit misc;

interface

uses
  Messages, Classes;

const
  prj_Prefix: string = {$I ..\_version\prefix_projects.};

  wm_prj_BringToFront = wm_User + 1;


var
  screen_Width,
  screen_Height,
  screen_Left,
  screen_Top,
  screen_PPI         : integer;

const
  auto_CellSize      : integer = 20; // рекомендуемое значение для разрешения auto_StartHeight
  auto_FontSize      : integer = 10; // рекомендуемое значение для auto_StartPPI
  auto_SmallFontSize : integer = 8;

    auto_StartHeight = 768;
    auto_StartPPI    = 96;


  logNone     = pointer(0); _logNone = 0;
  logBold     = pointer(1); _logBold = 1;
  logLine     = pointer(2); _logLine = 2;
  logLinePrev = pointer(4); _logLinePrev = 4;

procedure InitFormats;
function ProjectTitle: string;

procedure log(AString: string; AParam: pointer = logNone);
procedure log_err(AString: string);

function min_max(AVar: integer; AMin, AMax: integer): integer;

function GetSpecialPath(ACSIDL: word): string;
function GetFilesMask(AMask: string; ANames: tStringList; ADir: boolean = false): boolean;

implementation

uses
  Windows, SysUtils, ShlObj,
  vars, i_str,
  c_project, c_strings, main;


procedure InitFormats; begin
  DecimalSeparator:='.';

  DateSeparator:='.';
//  DateFullYear:=true;
  ShortDateFormat:='dd.MM.yyyy';
  LongDateFormat:='dd MMMM yyyy ''г.''';
  TwoDigitYearCenturyWindow:=50;

  TimeSeparator:=':';
  ShortTimeFormat:='hh:mm';
  LongTimeFormat:='hh:mm:ss';
end;

procedure log; begin
  Variables.AddToLog(AString);
  
  if MngProject.AboutLogEnabled then
    MngProject.AboutLog.AddObject(AString, AParam)
end;

procedure log_err; begin
  Variables.Error(AString);
end;

function min_max; begin
  if AVar > AMax then Result:=AMax
  else
    if AVar < AMin then Result:=AMin
    else Result:=AVar
end;

function ProjectTitle; begin
  Result:=prj_Prefix + prj_Name
end;

function GetSpecialPath;
var a: array[0..MAX_PATH] of char;
begin
  if SHGetSpecialFolderPath(0, a, ACSIDL, true) then Result:=a
  else Result:=''
end;

function GetFilesMask;
var SearchRec: tSearchRec;
begin
  Result:=true;
  try
    if FindFirst(AMask, faAnyFile, SearchRec) = 0 then begin
      repeat
        if not (ADir xor (SearchRec.Attr and faDirectory > 0)) then ANames.Add(ExtractFileName(SearchRec.Name));
        Result:=IOResult = 0 // or = 18; по памяти :)
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
  except
    Result:=false
  end
end;

end.

