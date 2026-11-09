unit i_classes;

interface

uses Classes, Contnrs;



const
  slex_B      = '#';
  slex_Open   = '(';
  slex_Close  = ')';
  slex_Sep    = ',';
  slex_Ex_Set = ['"', ''''];

  slex_Names: array[0..2] of string = ('set', 'get', 'file');



type
  tExList = class(tList)
    protected
      FOwnsObjects: boolean;

      procedure Notify(Ptr: pointer; Action: TListNotification); override;

    public
      constructor Create; overload;
      constructor Create(AOwnsObjects: boolean); overload;
      function Cut(Index: integer): pointer;
      procedure Swap(Index1, Index2: integer);

      property OwnsObjects: Boolean read FOwnsObjects write FOwnsObjects;
  end;

  tSortedList = class(tExList)
    private
      FDuplicatesSorted: boolean;

    protected
      constructor Create; overload;
      constructor Create(ADuplicatesSorted: boolean); overload;

      function Compare(AClass1, AClass2: pointer): integer; virtual; abstract;
      procedure QuickSort(L, R: integer); virtual;

    public
      function Find(AClass: pointer; var Index: integer): boolean;
      function FindSorted(AClass: pointer; var Index: integer): boolean;
      procedure Sort; reintroduce; 
      function AddSorted(AClass: pointer): integer;

      property DuplicatesSorted: boolean read FDuplicatesSorted write FDuplicatesSorted;
  end;


  PValueList = ^tValueList;
  tValueList = array[0..MaxListSize - 1] of integer;

  tIntegerList = class(tObject)
    private
      FList: PValueList;
      FCount: integer;
      FCapacity: integer;
      FDuplicatesSorted: boolean;

    protected
      function Get(Index: integer): integer;
      procedure Grow; virtual;
      procedure Put(Index: integer; AValue: integer);
      procedure SetCapacity(NewCapacity: integer);
      procedure SetCount(NewCount: integer);

      function Compare(AValue1, AValue2: integer): integer; virtual;
      procedure QuickSort(L, R: integer); virtual;

    public
      constructor Create; overload;
      constructor Create(ADuplicatesSorted: boolean); overload;
      destructor Destroy; override;

      function Add(AValue: integer): integer;
      procedure Clear; virtual;
      procedure Delete(Index: integer);
      class procedure Error(const Msg: string; Data: integer); overload; virtual;
      class procedure Error(Msg: PResStringRec; Data: integer); overload;
      procedure Exchange(Index1, Index2: integer);
      function Expand: tIntegerList;
      function First: integer;
      function IndexOf(AValue: integer): integer;
      procedure Insert(Index: integer; AValue: integer);
      function Last: integer;
      procedure Move(CurIndex, NewIndex: integer);
      function Remove(AValue: integer): integer;

      procedure Sort;
      function Find(AValue: integer; var Index: integer): boolean;
      function FindSorted(AValue: integer; var Index: integer): boolean;
      function AddSorted(AValue: integer): integer;

      procedure Assign(Source: tIntegerList);

      property Capacity: integer read FCapacity write SetCapacity;
      property Count: integer read FCount write SetCount;
      property Values[Index: integer]: integer read Get write Put; default;
      property List: PValueList read FList;
      property DuplicatesSorted: boolean read FDuplicatesSorted write FDuplicatesSorted default false;
  end;


  
  tDoubleString = class
    protected
      FString1, FString2: string;

    public
      constructor Create(AString1, AString2: string);

      property String1: string read FString1;
      property String2: string read FString2 write FString2;
  end;

  tDoubleStringList = class(tSortedList)
    protected
      function Compare(AClass1, AClass2: pointer): integer; override;
      function GetDString(AIndex: integer): tDoubleString;

    public
      function FindSortedStr(s: string; var Index: integer): boolean;

      property DString[Index: integer]: tDoubleString read GetDString; default;
  end;



  tStringListEx = class(tStringList)
    public
      function LoadFromFileEx(const FileName: string; AVars: tDoubleStringList = nil; ASLEX: tStringList = nil): boolean; virtual;
  end;

implementation

uses Consts, rxStrUtils, RTLConsts, i_sys, i_str, SysUtils;

constructor tExList.Create; begin
  inherited Create;
  FOwnsObjects:=true;
end;

constructor tExList.Create(AOwnsObjects: boolean); begin
  inherited Create;
  FOwnsObjects:=AOwnsObjects;
end;

procedure tExList.Notify; begin
  if FOwnsObjects then
    if Action = lnDeleted then tObject(Ptr).Free;

  inherited Notify(Ptr, Action);
end;

function tExList.Cut;
var b: boolean;
begin
  Result:=Items[Index];
  b:=FOwnsObjects;
  FOwnsObjects:=false;
  try
    Delete(Index)
  finally
    FOwnsObjects:=b
  end
end;

procedure tExList.Swap;
var
  b: boolean;
  p: pointer;
begin
  b:=FOwnsObjects;
  FOwnsObjects:=false;
  try
    p:=Items[Index1];
    Items[Index1]:=Items[Index2];
    Items[Index2]:=p
  finally
    FOwnsObjects:=b
  end
end;



constructor tSortedList.Create; begin
  inherited Create;
  FDuplicatesSorted:=false;
end;

constructor tSortedList.Create(ADuplicatesSorted: boolean); begin
  inherited Create;
  FDuplicatesSorted:=ADuplicatesSorted;
end;

function tSortedList.Find; begin
  Index:=IndexOf(AClass);
  Result:=Index <> -1
end;

function tSortedList.FindSorted;
var L, H, I, C: integer;
begin
  Result:=false;
  L:=0;
  H:=Count - 1;
  while L <= H do begin
    I:=(L + H) shr 1;
    C:=Compare(List^[I], AClass);
    if C < 0 then L:=I + 1
    else begin
      H:=I - 1;
      if C = 0 then begin
        Result:=true;
        L:=I;
      end;
    end;
  end;
  Index:=L;
end;

procedure tSortedList.QuickSort;
var
  I, J: integer;
  P, T: pointer;
begin
  repeat
    I:=L;
    J:=R;
    P:=List^[(L + R) shr 1];
    repeat
      while Compare(List^[I], P) < 0 do inc(I);
      while Compare(List^[J], P) > 0 do dec(J);
      if I <= J then begin
        T:=List^[I];
        List^[I]:=List^[J];
        List^[J]:=T;
        inc(I);
        dec(J);
      end;
    until I > J;
    if L < J then QuickSort(L, J);
    L:=I;
  until I >= R;
end;
{
procedure tSortedList.Sort;
var SaveOwnsObjects: boolean;
begin
  SaveOwnsObjects:=FOwnsObjects;
  FOwnsObjects:=false;

  QuickSort(0, Count - 1);

  FOwnsObjects:=SaveOwnsObjects;
end;
}
procedure tSortedList.Sort; begin
  QuickSort(0, Count - 1);
end;

function tSortedList.AddSorted; begin
  if not FindSorted(AClass, Result) or FDuplicatesSorted then Insert(Result, AClass)
  else Result:=-1
end;



constructor tIntegerList.Create; begin
  inherited Create;
  FDuplicatesSorted:=false;
end;

constructor tIntegerList.Create(ADuplicatesSorted: boolean); begin
  inherited Create;
  FDuplicatesSorted:=ADuplicatesSorted;
end;

destructor tIntegerList.Destroy; begin
  Clear;
end;

function tIntegerList.Add; begin
  Result:=FCount;
  if Result = FCapacity then Grow;
  FList^[Result]:=AValue;
  inc(FCount);
end;

procedure tIntegerList.Clear; begin
  SetCount(0);
  SetCapacity(0);
end;

procedure tIntegerList.Delete; begin
  if (Index < 0) or (Index >= FCount) then Error(@SListIndexError, Index);
  dec(FCount);
  if Index < FCount then
    System.Move(FList^[Index + 1], FList^[Index], (FCount - Index)*SizeOf(integer));
end;

class procedure tIntegerList.Error(const Msg: string; Data: integer);

  function ReturnAddr: pointer; asm
    MOV EAX,[EBP+4]
  end;

begin
  raise EListError.CreateFmt(Msg, [Data]) at ReturnAddr;
end;

class procedure tIntegerList.Error(Msg: PResStringRec; Data: integer); begin
  tIntegerList.Error(LoadResString(Msg), Data);
end;

procedure tIntegerList.Exchange;
var Temp: integer;
begin
  if (Index1 < 0) or (Index1 >= FCount) then Error(@SListIndexError, Index1);
  if (Index2 < 0) or (Index2 >= FCount) then Error(@SListIndexError, Index2);
  Temp:=FList^[Index1];
  FList^[Index1]:=FList^[Index2];
  FList^[Index2]:=Temp;
end;

function tIntegerList.Expand; begin
  if FCount = FCapacity then Grow;
  Result:=self;
end;

function tIntegerList.First; begin
  Result:=Get(0);
end;

function tIntegerList.Get; begin
  if (Index < 0) or (Index >= FCount) then Error(@SListIndexError, Index);
  Result:=FList^[Index];
end;

procedure tIntegerList.Grow;
var Delta: integer;
begin
  if FCapacity > 64 then Delta:=FCapacity div 4
  else
    if FCapacity > 8 then Delta:=16
    else Delta := 4;
  SetCapacity(FCapacity + Delta);
end;

function tIntegerList.IndexOf; begin
  Result:=0;
  while (Result < FCount) and (FList^[Result] <> AValue) do inc(Result);
  if Result = FCount then Result:=-1;
end;

procedure tIntegerList.Insert; begin
  if (Index < 0) or (Index > FCount) then Error(@SListIndexError, Index);
  if FCount = FCapacity then Grow;
  if Index < FCount then
    System.Move(FList^[Index], FList^[Index + 1], (FCount - Index) * SizeOf(integer));
  FList^[Index]:=AValue;
  inc(FCount);
end;

function tIntegerList.Last; begin
  Result:=Get(FCount - 1);
end;

procedure tIntegerList.Move;
var Temp: integer;
begin
  if CurIndex <> NewIndex then begin
    if (NewIndex < 0) or (NewIndex >= FCount) then Error(@SListIndexError, NewIndex);
    Temp:=Get(CurIndex);
    Delete(CurIndex);
    Insert(NewIndex, Temp);
  end;
end;

procedure tIntegerList.Put; begin
  if (Index < 0) or (Index >= FCount) then Error(@SListIndexError, Index);
  FList^[Index]:=AValue;
end;

function tIntegerList.Remove; begin
  Result:=IndexOf(AValue);
  if Result >= 0 then Delete(Result);
end;

procedure tIntegerList.SetCapacity; begin
  if (NewCapacity < FCount) or (NewCapacity > MaxListSize) then
    Error(@SListCapacityError, NewCapacity);
  if NewCapacity <> FCapacity then begin
    System.ReallocMem(FList, NewCapacity*SizeOf(integer));
    FCapacity:=NewCapacity;
  end;
end;

procedure tIntegerList.SetCount; begin
  if (NewCount < 0) or (NewCount > MaxListSize) then Error(@SListCountError, NewCount);
  if NewCount > FCapacity then SetCapacity(NewCount);
  if NewCount > FCount then
    FillChar(FList^[FCount], (NewCount - FCount) * SizeOf(integer), 0)
  else
//    for i:=FCount - 1 downto NewCount do Delete(i); так было в tList
    if NewCount < FCount then
      FillChar(FList^[NewCount], (FCount - NewCount) * SizeOf(integer), 0);

  FCount:=NewCount;
end;

procedure tIntegerList.Sort; begin
  if (FList <> nil) and (FCount > 0) then QuickSort(0, FCount - 1);
end;

function tIntegerList.Compare; begin
  if AValue1 = AValue2 then Result:=0
  else
    if AValue1 < AValue2 then Result:=-1
    else Result:=1
end;

procedure tIntegerList.QuickSort;
var I, J, P, T: integer;
begin
  repeat
    I:=L;
    J:=R;
    P:=List^[(L + R) shr 1];
    repeat
      while Compare(List^[I], P) < 0 do inc(I);
      while Compare(List^[J], P) > 0 do dec(J);
      if I <= J then begin
        T:=List^[I];
        List^[I]:=List^[J];
        List^[J]:=T;
        inc(I);
        dec(J);
      end;
    until I > J;
    if L < J then QuickSort(L, J);
    L:=I;
  until I >= R;
end;

function tIntegerList.FindSorted;
var L, H, I, C: integer;
begin
  Result:=false;
  L:=0;
  H:=FCount - 1;
  while L <= H do begin
    I:=(L + H) shr 1;
    C:=Compare(FList^[I], AValue);
    if C < 0 then L:=I + 1
    else begin
      H:=I - 1;
      if C = 0 then begin
        Result:=true;
        L:=I;
      end;
    end;
  end;
  Index:=L;
end;

function tIntegerList.Find; begin
  Index:=IndexOf(AValue);
  Result:=Index <> -1
end;

function tIntegerList.AddSorted; begin
  if not FindSorted(AValue, Result) or FDuplicatesSorted then
    Insert(Result, AValue)
end;

procedure tIntegerList.Assign;
var i: integer;
begin
  Clear;
  Capacity:=Source.Count;
  for i:=0 to Source.Count - 1 do Add(Source[i])
end;



constructor tDoubleString.Create; begin
  inherited Create;

  FString1:=AString1;
  FString2:=AString2;
end;

function tDoubleStringList.Compare; begin
  Result:=CompareStrFlags2(tDoubleString(AClass1).String1, tDoubleString(AClass2).String1)
end;

function tDoubleStringList.GetDString; begin
  Result:=Items[AIndex]
end;

function tDoubleStringList.FindSortedStr;
var ds: tDoubleString;
begin
  ds:=tDoubleString.Create(s, '');
  try
    Result:=FindSorted(ds, Index)
  finally
    ds.Free
  end
end;



function tStringListEx.LoadFromFileEx;
var
  RecFiles: tStringList;
  FVars   : tDoubleStringList;

  function _Load(Path, FileName: string; var AResult: string; ASLVars: tStringList): boolean;
  var {sDrive, sPath,} sUNC: string;

    function Remake(s: string; var Res: string): boolean;
    var i, j, len: integer;

      function Scan(ASet: tCharSet): boolean;
      begin
        while (i <= len) and (s[i] in ASet) do inc(i);
        Result:=i <= len
      end;

      function ScanNot(ASet: tCharSet): boolean;
      begin
        while (i <= len) and not (s[i] in ASet) do inc(i);
        Result:=i <= len
      end;

      procedure _add; begin
        Res:=Res + Copy(s, j, i - j);
        j:=i
      end;

      function GoodSlex(name: string; var idx: integer): boolean;
      var i: integer;
      begin
        Result:=false;
        idx:=-1;
        i:=low(slex_Names);

        while (i <= high(slex_Names)) and not Result do begin
          Result:=CompareStrFlags(name, slex_Names[i]);
          if Result then idx:=i
          else inc(i)
        end;
      end;

      function RunSlex(idx: integer; params: tStringList): boolean;
      var
        i, j   : integer;
        s, _res: string;
      begin
        Result:=(params.Count > 0) and (length(params[0]) > 0);

        if Result then
          case idx of
            0: begin // set
              Result:=params.Count = 2;

              if Result then
                if FVars.FindSortedStr(params[0], i) then FVars[i].String2:=params[1]
                else
                  FVars.AddSorted(tDoubleString.Create(params[0], params[1]))
            end;

            1: begin // get
              Result:=params.Count = 1;

              if Result then
                if FVars.FindSortedStr(params[0], i) then Res:=Res + FVars[i].String2
            end;

            2: begin // file
              if ASLVars <> nil then
                for i:=0 to params.Count - 1 do
                  for j:=0 to ASLVars.Count - 1 do
                    params[i]:=ReplaceStr(params[i], slex_B + IntToStr(j), ASLVars[j]);

              s:=params[0];
              if params.Count > 1 then params.Delete(0)
              else params:=nil;

              Result:=_Load({s}Path, s, _res, params);
              if Result then Res:=Res + _res
            end

            else Result:=false
          end;
      end;

      function GetSlex: boolean;
      var
        _res     : string;
        _params  : tStringList;
        k, idx, z: integer;
        b, ex    : boolean;
      begin
        Result:=true;

        inc(i);
        b:=ScanNot([' ', slex_Open]) and GoodSlex(Copy(s, j + 1, i - j - 1), idx);

        if b then begin
          if s[i] = ' ' then b:=Scan([' ']) and (s[i] = slex_Open);

          if b then begin
            _params:=tStringList.Create;

            inc(i);
            k:=i;
            z:=0;

            ex:=false;
            b:=false;
            while (i <= len) and not b do begin

              if s[i] in slex_Ex_Set then ex:=not ex
              else
                if not ex then
                  if s[i] = slex_Open then inc(z)
                  else begin
                    if s[i] = slex_Close then begin
                      b:=z = 0;
                      dec(z)
                    end;

                    if ((s[i] = slex_Sep) and (z = 0)) or b then begin
                      _params.Add(DelRSpace(Copy(s, k, i - k)));
                      k:=i + 1;
                    end
                  end;

              inc(i)
            end;

            k:=0;
            while (k < _params.Count) and b do begin
              b:=Remake(_params[k], _res);
              if b then _params[k]:=_res;
              inc(k)
            end;

            if b then begin
              Result:=RunSlex(idx, _params);
              b:=Result;
            end;

            _params.Free
          end
        end;

        if b then j:=i
        else _add
      end;

    var b: boolean;
    begin
      i:=1;
      j:=i;
      len:=length(s);
      SetLength(Res, 0);
      
      Result:=true;
      while (i <= len) and Result do begin
        b:=ScanNot([slex_B]);
        _add;
        if b then Result:=GetSlex;
      end
    end;

  var
    sl  : tStringList;
    i   : integer;

  begin
{
    sDrive:=ExtractFileDrive(FileName);
    sPath:=NormalPath(ExtractFilePath(FileName));
    FileName:=ExtractFileName(FileName);

    if not ((length(sDrive) > 0) or
            ((length(sPath) > 0) and
             ((sPath[1] = '\') or (sPath[1] = '/')))) then sPath:=NormalPath(Path + sPath);

    sUNC:=ExpandUNCFileName(sPath + FileName);
}
    sUNC:=ExpandUNCFileNameEx(Path, FileName);

    Result:=true;
    i:=0;
    while (i < RecFiles.Count) and Result do
      if CompareStrFlags(RecFiles[i], sUNC) then Result:=false // фиг, а не зацикливание!
      else inc(i);

    if Result then begin
      RecFiles.Add(sUNC);
      sl:=tStringList.Create;

      try
        try
          sl.LoadFromFile(sUNC);
          Result:=Remake(sl.Text, AResult);

        except
          Result:=false
        end;

      finally
        sl.Free;
        RecFiles.Delete(RecFiles.Count - 1);
      end
    end
  end;


var
  s, exResult: string;
  i          : integer;
  bCreateVars: boolean;
begin
  RecFiles:=tStringList.Create;

  bCreateVars:=AVars = nil;
  if bCreateVars then FVars:=tDoubleStringList.Create
  else FVars:=AVars;

  BeginUpdate;

  try
    s:=ExpandUNCFileName(FileName);
    SetLength(exResult, 0);
    Result:=_Load(ExtractFilePath(s), ExtractFileName(s), exResult, ASLEX);

    if Result then begin
      Text:=exResult;

      for i:=Count - 1 downto 0 do
        if length(DelRSpace(Strings[i])) = 0 then Delete(i);
    end;

  finally
    EndUpdate;

    if bCreateVars then FVars.Free;
    RecFiles.Free
  end;
end;


end.

