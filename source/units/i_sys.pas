unit i_sys;

interface

uses
  Windows, ShellAPI, Controls, Classes, Graphics, Forms;

const
  c_chMonney    = '''';
  MonneyName    : string = ' руб.';
  ArrayFormat   : string = '[%s]';
  ArraySeparator: char   = ',';

type
  pbyte     = ^byte;
  pword     = ^word;
  pinteger  = ^integer;
  plongint  = ^longint;
  pboolean  = ^boolean;
  pColor    = ^tColor;
  psingle   = ^single;
  pextended = ^extended;
  pcurrency = ^currency;

  tByte     = array[0..MaxInt div sizeof(byte) - 1] of byte;
  tByteCh   = array[0..MaxInt div sizeof(byte) - 1] of char;
  tWord     = array[0..MaxInt div sizeof(word) - 1] of word;
  tInteger  = array[0..MaxInt div sizeof(integer) - 1] of integer;
  tLongInt  = array[0..MaxInt div sizeof(longint) - 1] of longint;
  tBoolean  = array[0..MaxInt div sizeof(boolean) - 1] of boolean;
  ttColor   = array[0..MaxInt div sizeof(tColor) - 1] of tColor;
  tSingle   = array[0..MaxInt div sizeof(single) - 1] of single;
  tExtended = array[0..MaxInt div sizeof(extended) - 1] of extended;
  tCurrency = array[0..MaxInt div sizeof(currency) - 1] of currency;

const
  fsbBold      = 1;
  fsbItalic    = 2;
  fsbUnderLine = 4;
  fsbStrikeout = 8;

function IntToStrLen(i, Len: integer): string;
function StrToIntVrf(s: string; var Value: integer): boolean;
function StrToFloatVrf(s: string; var Value: extended): boolean;
function StrToSingleVrf(s: string; var Value: single): boolean;
function StrToDoubleVrf(s: string; var Value: double): boolean;
//function StrToColorVrf(s: string; var Value: tColor): boolean;
function StrToDateVrf(s: string; var Value: tDate): boolean;
function CurrToStrMonney(c: currency; ANeedMName: boolean = true): string;
function ArrayStr(const s: string): string;

function FontStylesToByte(fs: tFontStyles): byte;
function ByteToFontStyles(b: byte): tFontStyles;
function ByteFontStylesName(b: byte): string;

function NoEmptySList(SL: tStringList): boolean;

function HiInt(i: integer): word;
function LoInt(i: integer): word;
function Sign(Value: integer): integer;

function CompareInteger(Value1, Value2: integer): integer;
function CompareDouble(Value1, Value2: double): integer;
function CompareDate(Date1, Date2: tDate): integer;
function ComparePointer(Item1, Item2: pointer): Integer;
function CompareBool(Bool1, Bool2: boolean): integer;
function CompareColor(c1, c2: tColor): boolean;

function ExpandYear(AYear: word): word;

function IsNT: boolean;
procedure GetWindowsVersion(var AMajor, AMinor: integer);
function GetWindowsVersionEx: tOSVersionInfo;

function GetShiftState: TShiftState;
procedure ShellEx(s: string);
function ExecuteExeFile(AExeFileName, ACommandLine, ARunPath: string; AWait: boolean): boolean;

function ExpandUncFileNameEx(var Path: string; var WFileName: string): string;
function LoadImageFromFile(AFileName: string; AGraphic: tGraphic): boolean;

const
  sys_Max: integer = 32767;


implementation

uses
  SysUtils, Jpeg,
  rxGif,
  i_str;


function IntToStrLen; begin
  Result:=IntToStr(i);
  while length(Result) < Len do Result:='0' + Result;
end;

function StrToIntVrf;
var temp: integer;
begin
  temp:=Value;
  try
    Value:=StrToInt(s);
    Result:=true;
  except
    Result:=false;
    Value:=temp
  end;
end;

function StrToFloatVrf;
var temp: extended;
begin
  temp:=Value;
  try
    Value:=StrToFloat(s);
    Result:=true;
  except
    Result:=false;
    Value:=temp
  end;
end;

function StrToSingleVrf;
var temp: extended;
begin
  try
    temp:=StrToFloat(s);
    Value:=temp;
    Result:=true;
  except
    Result:=false;
  end;
end;

function StrToDoubleVrf;
var temp: extended;
begin
  try
    temp:=StrToFloat(s);
    Value:=temp;
    Result:=true;
  except
    Result:=false;
  end;
end;
{
function StrToColorVrf;
var temp: tColor;
begin
  temp:=Value;
  try
    Value:=RxStringToColor(s);
    Result:=true;
  except
    Result:=false;
    Value:=temp
  end;
end;
}
function StrToDateVrf;
var
  temp   : tDate;
  y, m, d: word;
begin
  temp:=Value;
  try
    Value:=StrToDate(s);
    Result:=true;
  except
    Result:=false;
    Value:=temp
  end;

  if Result and (length(s) < length(ShortDateFormat) - 1) then begin
    DecodeDate(Value, y, m, d);
    Value:=EncodeDate(ExpandYear(y - (y div 100)*100), m, d);
  end
end;

function CurrToStrMonney;
var
  i  : integer;
  tmp: currency;
  ch : string;

  function FracToStr(c: currency): string;
  var i: integer;
  begin
    if c = 0 then SetLength(Result, 0)
    else begin
      Result:=CurrToStr(c);
      i:=Pos(DecimalSeparator, Result);
      if i > 0 then Delete(Result, 1, i - 1)
    end
  end;

begin
  Result:=CurrToStr(trunc(c));
  tmp:=frac(c);
  if (length(Result) > 0) and (Result[1] = '-') then begin
    Delete(Result, 1, 1);
    ch:='-'
  end
  else SetLength(ch, 0);

  i:=1;
  while length(Result) >= 3*i + (i - 1) + 1 do begin
    Insert(c_chMonney, Result, length(Result) - 3*i - (i - 1) + 1);
    inc(i)
  end;

  if ANeedMName and ((length(Result) > 0) or (tmp > 0)) and (length(MonneyName) > 0) then
    Result:=ch + Result + FracToStr(tmp) + MonneyName
end;

function NoEmptySList; begin
  Result:=(SL.Count > 1) or
          ((SL.Count = 1) and
           (length(SL[0]) > 0));
end;

function ByteToFontStyles; begin
  Result:=[];
  if b and fsbBold > 0 then Result:=Result + [fsBold];
  if b and fsbItalic > 0 then Result:=Result + [fsItalic];
  if b and fsbUnderLine > 0 then Result:=Result + [fsUnderline];
  if b and fsbStrikeout > 0 then Result:=Result + [fsStrikeout];
end;

function FontStylesToByte; begin
  Result:=byte(fs);
end;

function ByteFontStylesName; begin
  SetLength(Result, 0);

  if b and fsbBold > 0 then Result:=MergeStr(Result, 'жирный');
  if b and fsbItalic > 0 then Result:=MergeStr(Result, 'курсив');
  if b and fsbUnderLine > 0 then Result:=MergeStr(Result, 'подчеркнутый');
  if b and fsbStrikeout > 0 then Result:=MergeStr(Result, 'зачеркнутый');

  if length(Result) = 0 then Result:='нормальный';
  Result:=ArrayStr(Result)
end;

function ArrayStr; begin
  if Pos(ArraySeparator, s) > 0 then Result:=Format(ArrayFormat, [s])
  else Result:=s
end;

function HiInt; begin
  Result:=word(i shr 16);
end;

function LoInt; begin
  Result:=word(i and $FFFF);
end;

function Sign; begin
  if Value < 0 then Result:=-1
  else
    if Value > 0 then Result:=1
    else Result:=0
end;


function CompareInteger; begin
  if Value1 = Value2 then Result:=0
  else
    if Value1 < Value2 then Result:=-1
    else Result:=1
end;

function CompareDouble; begin
  if Value1 = Value2 then Result:=0
  else
    if Value1 < Value2 then Result:=-1
    else Result:=1
end;

function CompareDate; begin
  if Date1 = Date2 then Result:=0
  else
    if Date1 < Date2 then Result:=-1
    else Result:=1
end;

function CompareBool; begin
  if Bool1 = Bool2 then Result:=0
  else
    if Bool1 < Bool2 then Result:=-1
    else Result:=1
end;

function ComparePointer; begin
  Result:=CompareInteger(integer(Item1), integer(Item2))
end;

function CompareColor; begin
  Result:=ColorToRGB(c1) = ColorToRGB(c2)
end;


function GetShiftState; begin
  Result:=[];
  if GetKeyState(VK_SHIFT) < 0 then Include(Result, ssShift);
  if GetKeyState(VK_CONTROL) < 0 then Include(Result, ssCtrl);
  if GetKeyState(VK_MENU) < 0 then Include(Result, ssAlt);
end;

function IsNT; begin
  Result:=Win32Platform = VER_PLATFORM_WIN32_NT
end;

procedure GetWindowsVersion;
var v: tOSVersionInfo;
begin
  v.dwOSVersionInfoSize:=SizeOf(tOSVersionInfo);
  GetVersionEx(v);
  AMajor:=v.dwMajorVersion;
  AMinor:=v.dwMinorVersion
end;

function GetWindowsVersionEx: tOSVersionInfo; begin
  Result.dwOSVersionInfoSize:=SizeOf(tOSVersionInfo);
  GetVersionEx(Result);
end;

procedure ShellEx;
var C: tCursor;
begin
  C:=Screen.Cursor;
  Screen.Cursor:=crHourGlass;
  ShellExecute(Application.Handle, 'open', pChar(s), nil, nil, SW_SHOW {0});
  Screen.Cursor:=C;
end;

function ExpandYear;
var y, y2, v: word;
begin
  if AYear < 100 then begin
    DecodeDate(Date, y, y2, v);
    v:=(y div 100)*100;
    y2:=y - v;
    if y2 >= AYear then Result:=v + AYear
    else Result:=(v - 100) + AYear
  end
  else Result:=AYear
end;

function ExpandUncFileNameEx;
var sDrive, s: string;
begin
  s:=Path;

  sDrive:=ExtractFileDrive(WFileName);
  Path:=NormalPath(ExtractFilePath(WFileName));
  WFileName:=ExtractFileName(WFileName);

  if not ((length(sDrive) > 0) or
          ((length(Path) > 0) and
           ((Path[1] = '\') or (Path[1] = '/')))) then Path:=NormalPath(s + Path);

  Result:=ExpandUNCFileName(Path + WFileName);
end;

function ExecuteExeFile;
var
  SI      : tStartupInfo;
  PI      : tProcessInformation;
  hProcess: LongBool;
  ecode   : cardinal;
  s       : string;
begin
  FillChar(SI, sizeof(SI), 0);
  SI.wShowWindow:=SW_NORMAL;
  SI.dwFlags:=STARTF_USESHOWWINDOW;
  SI.cb:=sizeof(SI);

  s:='"' + AExeFileName + '"';
  if length(ACommandLine) > 0 then s:=s + ' ' + ACommandLine + ' ';

  hProcess:=
    CreateProcess(nil, pChar(s),
                  nil, nil, false,
                  CREATE_SEPARATE_WOW_VDM or NORMAL_PRIORITY_CLASS,
                  nil, pChar(ARunPath), SI, PI);

  Result:=hProcess;
  if Result and AWait then begin

    Result:=WaitForSingleObject(PI.hProcess, INFINITE) <> WAIT_FAILED;
    if Result then begin
      GetExitCodeProcess(PI.hProcess, ecode);
      Result:=ecode = 0
    end;
  end
end;

function LoadImageFromFile;
var
  f  : tFileStream;
  G  : tGraphic;
  buf: string[10];
begin
  Result:=FileExists(AFileName);
  if Result then begin
    f:=tFileStream.Create(AFileName, fmOpenRead);
    try
      try
        f.Read(buf[1], 10);
        buf[0]:=#10;
      except
        Result:=false
      end;
    finally
      f.Free
    end;

    if Result then begin
      G:=nil;

      if UpperStr(Copy(buf, 1, 2)) = 'BM' then G:=tBitMap.Create
      else
        if UpperStr(Copy(buf, 1, 3)) = 'GIF' then G:=tGIFImage.Create
        else
          if (UpperStr(Copy(buf, 7, 10)) = 'JFIF') or (UpperStr(Copy(buf, 7, 10)) = 'EXIF') then G:=tJpegImage.Create
          else Result:=false;

      try
        try
          if Result then G.LoadFromFile(AFileName);
        except
          Result:=false
        end;

        if Result then tBitMap(AGraphic).Assign(G);

      finally
        if G <> nil then G.Free;
      end
    end
  end
end;

initialization
  if isNT then sys_Max:=MaxInt
end.

