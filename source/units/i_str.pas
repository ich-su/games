unit i_str;

interface

uses Windows, Classes;

const
  c_chTest  = 'W';
  c_chKav   = '"';
  c_chZpt   = ',';
  c_chSpace = ' ';
  c_chSlash = '\';

  c_s1310 = #13#10;

type
  tChgFlags = (cfNone, cfUpper, cfLower);
  tCharSet = set of char;

function NormalPath(s: string): string;
function CurrentPathName(s: string): string;
function MergeStr(s1, s2: string): string;
procedure AddStr(var SDest: string; SAdd: string; chSep: string = c_chSpace; bSep: boolean = false);

function UpperStr(s: string): string;
function LowerStr(s: string): string;
function UpperChar(ch: char): char;
function LowerChar(ch: char): char;

function CompareStrLen(S1, S2: string; len: integer; CaseSens: boolean = false): boolean;
function CompareStrBegin(s, sSmall: string; CaseSens: boolean = false): boolean;
function CompareStrBeginKav(s, sSmall: string; CaseSens: boolean = false): boolean;
function CompareStrKav(S1, S2: string; CaseSens: boolean = false): integer;
function CompareStrFlags(S1, S2: string; CaseSens: boolean = false): boolean;
function CompareStrFlags2(S1, S2: string; CaseSens: boolean = false): integer;
function CompareStrInSList(SList: tStringList; Index1, Index2: integer; CaseSens: boolean = false): integer;

function DelSpaceOne(s: string): string;
function DeleteZptBeginEnd(s: string): string;
function DeleteSubStr(s, sSub: string): string;
function DeleteCharEnd(s: string; ch: char): string;
function DeleteCharBegin(s: string; ch: char): string;
function ChangeChar(s: string; chSourse, chDest: char): string;
procedure ChangeCharProc(var s: string; chSourse, chDest: char);
function DeleteReturns(s: string; sReturn: string = c_s1310): string;
function EquBeginStrs(SL: tStringList; CaseSens: boolean = false): string;

function SLToStr(SL: tStringList; CountCharInLastLine: integer = MaxInt): string;
procedure StrToSL(s: string; SL: tStringList; Sep: string; ADelRSpace: boolean = false);
function StrToFirstLeters(s: string; ChgFlags: tChgFlags = cfUpper): string;

procedure RemoveRemInSList(SL: tStringList; ARemoveEmpty: boolean = false);

function StrToCodes(s: string; ANo: tCharSet): string;

function IntToStrKByte(ASize: integer): string;
function GenerateFileName(Ext: string): string;

function ListToString(AList: tStringList; ASeparator: string = '`'): string;
procedure StringToList(AString: string; AList: tStringList; ASeparator: string = '`'; AMaxLineCount: integer = MaxInt);

function StrEx(AString: string; AFill: char; AMaxLen: integer; ABegin: boolean = true): string;


implementation

uses Forms, rxStrUtils, SysUtils;



{$L DB4_SCompare.obj}
Function StrCompareExtW(Str1, Str2: PChar; CLength: Integer; CaseSensitive: Boolean): Integer; external;



function NormalPath; begin
  if (length(s) > 0) and (s[length(s)] <> c_chSlash) then Result:=s + c_chSlash
  else Result:=s
end;

function CurrentPathName; begin
  Result:=NormalPath(GetCurrentDir) + s
end;

function MergeStr; begin
  if length(s1) > 0 then Result:=s1 + c_chZpt + c_chSpace + s2
  else Result:=s2
end;

procedure AddStr; begin
  if length(SAdd) > 0 then begin
    if (length(SDest) > 0) or bSep then SDest:=SDest + chSep;
    SDest:=SDest + SAdd
  end
end;

function UpperChar; begin
  if ((ch >= 'a') and (ch <= 'z')) or
     ((ch >= 'а') and (ch <= 'я')) then ch:=char(byte(ch) - 32)
  else
    if ch = 'ё' then ch:='Ё';

  Result:=ch
end;

function LowerChar; begin
  if ((ch >= 'A') and (ch <= 'Z')) or
     ((ch >= 'А') and (ch <= 'Я')) then ch:=char(byte(ch) + 32)
  else
    if ch = 'Ё' then ch:='ё';

  Result:=ch
end;

function UpperStr;
var i: integer;
begin
  for i:=1 to length(s) do
    if ((s[i] >= 'a') and (s[i] <= 'z')) or
       ((s[i] >= 'а') and (s[i] <= 'я')) then s[i]:=char(byte(s[i]) - 32)
    else
      if s[i] = 'ё' then s[i]:='Ё';

  Result:=s
end;

function LowerStr;
var i: integer;
begin
  for i:=1 to length(s) do
    if ((s[i] >= 'A') and (s[i] <= 'Z')) or
       ((s[i] >= 'А') and (s[i] <= 'Я')) then s[i]:=char(byte(s[i]) + 32)
    else
      if s[i] = 'Ё' then s[i]:='ё';

  Result:=s
end;

{ эмуляция колюхиной функции, использовать при глюках
Function StrCompareExtW(S1, S2: String; CLength: Integer; CaseSensitive: Boolean): Integer;
var i, l1, l2: integer;
begin
  if CLength = 0 then begin
    l1:=length(S1);
    l2:=length(S2)
  end
  else begin
    l1:=CLength;
    l2:=CLength;
  end;

  if CaseSensitive then i:=0
  else i:=NORM_IGNORECASE;

  Result:=CompareString(LOCALE_USER_DEFAULT, i, pChar(S1), l1, pChar(S2), l2) - 2
end;
}
function CompareStrLen; begin
  if (length(S1) < len) or (length(S2) < len) then Result:=false
  else Result:=StrCompareExtW(PChar(S1), PChar(S2), len, CaseSens) = 0;
end;

function CompareStrBegin; begin
  Result:=CompareStrLen(s, sSmall, length(sSmall), CaseSens)
end;

function CompareStrBeginKav; begin
  if (length(s) > 0) and (s[1] = c_chKav) then
    Result:=CompareStrBegin(Copy(s, 2, length(s) - 1), sSmall, CaseSens)
  else Result:=CompareStrBegin(s, sSmall, CaseSens)
end;

function CompareStrKav;
var i1, i2: byte;
begin
  i1:=byte((length(S1) > 0) and (S1[1] = c_chKav));
  i2:=byte((length(S2) > 0) and (S2[1] = c_chKav));

  Result:=StrCompareExtW(pChar(integer(PChar(S1)) + i1),
                         pChar(integer(PChar(S2)) + i2),
                         0, CaseSens);
end;

function CompareStrFlags2; begin
  Result:=StrCompareExtW(PChar(S1), PChar(S2), 0, CaseSens)
end;

function CompareStrFlags; begin
  Result:=StrCompareExtW(PChar(S1), PChar(S2), 0, CaseSens) = 0
end;

function CompareStrInSList; begin
  Result:=CompareStrKav(SList[Index1], SList[Index2], CaseSens)
end;



function DelSpaceOne; begin
  Result:=DelRSpace(DelSpace1(s))
end;

function DeleteZptBeginEnd;
var b, e: integer;
begin
  if length(s) = 0 then SetLength(Result, 0)
  else begin
    b:=1; e:=length(s);
    while (s[b] = c_chZpt) or (s[b] = c_chSpace) do inc(b);
    while (s[e] = c_chZpt) or (s[e] = c_chSpace) do dec(e);
    if e > b then Result:=Copy(s, b, e - b + 1)
    else SetLength(Result, 0)
  end
end;

function DeleteSubStr;
var ps: integer;
begin
  Result:=s;
  repeat
    ps:=Pos(sSub, Result);
    if ps > 0 then Delete(Result, ps, length(sSub))
  until ps = 0;
end;

function DeleteCharEnd;
var e: integer;
begin
  e:=length(s);
  while (e > 0) and (s[e] = ch) do dec(e);
  if e > 0 then Result:=Copy(s, 1, e)
  else SetLength(Result, 0)
end;

function DeleteCharBegin;
var b: integer;
begin
  b:=0;
  while (b <= length(s)) and (s[b] = ch) do inc(b);
  if b <= length(s) then Result:=Copy(s, b, MaxInt)
  else SetLength(Result, 0)
end;

function ChangeChar;
var i: integer;
begin
  Result:=s;
  for i:=1 to length(s) do
    if Result[i] = chSourse then Result[i]:=chDest
end;

procedure ChangeCharProc;
var i: integer;
begin
  for i:=1 to length(s) do
    if s[i] = chSourse then s[i]:=chDest
end;

function DeleteReturns;
var ps: integer;
begin
  repeat
    ps:=Pos(sReturn, s);
    if ps > 0 then
      s:=Copy(s, 1, ps - 1) + c_chSpace + Copy(s, ps + 2, length(s) - ps - 1)
  until ps = 0;

  Result:=s
end;


function SLToStr;
var i: integer;
begin
  SetLength(Result, 0);
  for i:=0 to SL.Count - 1 do begin
    if i > 0 then Result:=Result + c_chSpace;
    if i = SL.Count - 1 then
      Result:=Result + Copy(SL[i], 1, CountCharInLastLine)
    else Result:=Result + SL[i];
  end;
end;

procedure StrToSL;
var
  i : integer;
  s2: string;
begin
  repeat
    i:=Pos(Sep, s);
    if i = 0 then i:=length(s) + 1;

    s2:=Copy(s, 1, i - 1);
    if ADelRSpace then s2:=DelRSpace(s2);
    SL.Add(s2);
    
    Delete(s, 1, i + length(Sep) - 1);
  until length(s) = 0
end;

function StrToFirstLeters;
var i: integer;
begin
  s:=DelSpaceOne(s);
  SetLength(Result, 0);
  while length(s) > 0 do begin
    case ChgFlags of
      cfUpper: Result:=Result + UpperChar(s[1]);
      cfLower: Result:=Result + LowerChar(s[1]);
      else Result:=Result + s[1]; // cfNone
    end;
    i:=Pos(c_chSpace, s);
    if i = 0 then break
    else Delete(s, 1, i);
  end;
end;

procedure RemoveRemInSList;
var
  i: integer;
  s: string;
begin
  i:=0;
  while i < SL.Count do begin
    s:=DelSpaceOne(SL[i]);
    if ((length(s) = 0) and ARemoveEmpty) or
       ((length(s) > 1) and (Copy(s, 1, 2) = '//')) then SL.Delete(i)
    else inc(i)
  end
end;

function StrToCodes;
var i: integer;
begin
  SetLength(Result, 0);
  for i:=1 to length(s) do
    if s[i] in ANo then Result:=Result + s[i]
    else Result:=Result + Dec2Hex(byte(s[i]), 2)
end;

function IntToStrKByte; begin
  if ASize < 1024 then Result:=IntToStr(ASize) + ' байт'
  else Result:=Format('%1.1f Кбайт', [ASize / 1024])
end;

function GenerateFileName;
var
  Present: TDateTime;
  Year, Month, Day, Hour, Min, Sec, MSec: Word;

  function TenTo36Char(val: byte): char; begin
    if val in [0..9] then TenTo36Char:=char(byte('0')+val)
    else TenTo36Char:=char(byte('a')+val-10)
  end;

  function TenTo36Str(val, ps: integer): string;
  var
    s: string;
    m,d : integer;
  begin
    s:='';
    d:=val;
    repeat
      m:=d mod 36;
      d:=d div 36;
      s:=s+TenTo36Char(m)
    until d = 0;
    while length(s) < ps do s:='0'+s;
    TenTo36Str:=s;
  end;

begin
  Present:= Now;
  DecodeDate(Present, Year, Month, Day);
  DecodeTime(Present, Hour, Min, Sec, MSec);
  Result:='$' + TenTo36Char(Year mod 10) + TenTo36Char(Month) + TenTo36Char(Day) +
    TenTo36Char(Hour) + TenTo36Str(Min,2) + TenTo36Str(Sec,2) + Ext
end;

function EquBeginStrs;
var
  i, j: integer;
  b   : boolean;
begin
  case SL.Count of
    0: SetLength(Result, 0);
    1: Result:=SL[0]
    else begin
      i:=1;
      b:=true;
      while b do begin
        j:=0;
        while b and (j < SL.Count) do begin
          if CaseSens then b:=sl[0][i] = sl[j][i]
          else b:=LowerChar(sl[0][i]) = LowerChar(sl[j][i]);
          inc(j)
        end;

        if b then inc(i)
      end;

      Result:=Copy(sl[0], 1, i - 1);
    end
  end;


{
  i:=1;
  b:=true;
  while b and (length(s1) >= i) and (length(s2) >= i) do begin
    if CaseSens then b:=s1[i] = s2[i]
    else b:=LowerChar(s1[i]) = LowerChar(s2[i]);

    if b then inc(i)
  end;

  Result:=Copy(s1, 1, i - 1);
}
end;

function ListToString;
var i: integer;
begin
  if AList.Count > 0 then Result:=AList[0]
  else SetLength(Result, 0);

  for i:=1 to AList.Count - 1 do
    Result:=Result + ASeparator + AList[i]
end;

procedure StringToList;
var i: integer;
begin
  AList.Clear;
  repeat
    i:=Pos(ASeparator, AString);
    if i = 0 then i:=length(AString) + 1;
    AList.Add(Copy(AString, 1, i - 1));
    System.Delete(AString, 1, i)
  until (AList.Count > AMaxLineCount) or (length(AString) = 0)
end;

function StrEx;
var s: string;
begin
  s:=MakeStr(AFill, AMaxLen - length(AString));
  if ABegin then Result:=s + AString
  else Result:=AString + s
end;

end.

