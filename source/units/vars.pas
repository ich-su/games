{$I defines.inc}

unit vars;

interface

uses
  Classes, Graphics, Messages,
{$IFDEF PULSE}
  WSL,
{$ELSE}
  Mutex,
{$ENDIF}
  i_sys, i_classes, pc;



const
  var_log_Need    : boolean = true; // надо ли .log-файл
  var_log_FileName: string  = '.log';
  var_cfg_FileName: string  = 'vars.cfg';
  var_cfg_AutoExec: string  = 'autoexec.cfg';
  var_CommandName : string  = 'cmd.exe'; // 'command.com';
  var_log_MaxSize : integer = 2000;

  var_CommandKey         = ' /c ';

  c_bStyleDef            = 255;
  c_sColorDef            = '--------';
  c_chMinus              = '-';

  var_Open               = '{';
  var_Close              = '}';
  var_SaveVar            = '%s = %s;';
  var_Const              = 'const';

  vn_var_Clear           = 'clear';
  vn_var_Exec            = 'exec';
  vn_var_Save            = 'savecfg';
  vn_var_List            = 'list';
  vn_var_Echo            = 'echo';
  vn_var_EchoEx          = 'echoex';
  vn_var_Msg             = 'msg';
  vn_var_Error           = 'error';
  vn_var_Command         = 'command';

  vn_var_cfg_FileName    = 'var_cfg_FileName';
  vn_var_cfg_AutoExec    = 'var_cfg_AutoExec';
  vn_var_log_FileName    = 'var_log_FileName';
  vn_var_log_MaxSize     = 'var_log_MaxSize';
  vn_var_CommandName     = 'var_CommandName';
  vn_var_Version         = 'var_Version';

{$IFDEF PULSE}
  vn_pc_Version          = 'pc_Version';
{$ELSE}
  vn_pc_Version          = 'esl_Version';
{$ENDIF}

{$IFDEF LANGENG}
  ms_var_Load            : string = 'loading <%s>';
  ms_var_ErrorLoad       : string = 'error loading <%s>';
  ms_var_Save            : string = 'saving <%s>';
  ms_var_ErrorSave       : string = 'error saving <%s>';
  ms_var_InitVariables   : string = 'init';
  ms_var_NoVars          : string = 'no variables found';
  ms_var_Param           : string = 'executing command line <%s>';
{$ELSE}
  ms_var_Load            : string = 'загрузка <%s>';
  ms_var_ErrorLoad       : string = 'ошибка загрузки <%s>';
  ms_var_Save            : string = 'сохранение <%s>';
  ms_var_ErrorSave       : string = 'ошибка сохранения <%s>';
  ms_var_InitVariables   : string = 'инициализация';
  ms_var_NoVars          : string = 'таких переменных нет';
  ms_var_Param           : string = 'исполнение параметров запуска <%s>';
{$ENDIF}
  ms_var_Is              = '%s = %s';

  var_MarkInit           = -2;
  var_MaxTranslateTime   = 10000;

  msg_Warning            = 'Warning';
  msg_Error              = 'Error';
  msg_Information        = 'Info';
  msg_Confirmation       = 'Confirm';
  msg_Custom             = 'Custom';

  msg_Yes                = 'Yes';
  msg_No                 = 'No';
  msg_OK                 = 'OK';
  msg_Cancel             = 'Cancel';
  msg_Abort              = 'Abort';
  msg_Retry              = 'Retry';
  msg_Ignore             = 'Ignore';
  msg_All                = 'All';
  msg_NoToAll            = 'NoToAll';
  msg_YesToAll           = 'YesToAll';
  msg_Help               = 'Help';
  msg_None               = 'None';

  wm_LogChange           = wm_User + 1000;

  MinFloat               = 1e-16; 

type
  tLogType = (ltNormal, ltError);

const
  arLogTypeChar: array[tLogType] of char = (c_chMinus, 'e');

type
  tConAppFuncOnChange = procedure;
  tFuncOnSaveConfig   = procedure(AList: tStringList) of object;

  tVariables = class(tVarRegistrator)
    private
      FPref          : string;
      FLog           : tStringList;
      FOnChange      : tIntegerList;
      FCompiler      : tCompiler;
      FMutex         : tMutexObject;
      FRipLog        : boolean;
      FIDLogState    : cardinal;
      FConAppOnChange: tConAppFuncOnChange;
      FOnSaveConfig  : array of tFuncOnSaveConfig;

    protected
      function GetLogSize: integer;
      function GetLogLine(Index: integer): string;
      function GetLogMark(Index: integer): integer;

      procedure ExecOnLogChangeIndex(AIndex: integer);
      procedure ExecOnLogChange;

      function WholeLogFileName: string;
      procedure TruncateLog;
      function LoadLogFile: boolean;
      function SaveLogFile: boolean;

      function WholleStr(s: string; AType: tLogType = ltNormal): string;
      function WholleStrEx(s: string; AColor: tColor = -1; AStyle: byte = c_bStyleDef): string;
      function AddStringToLog(s: string): integer;
      function TranslateString(s: string; AMaxTime: integer = var_MaxTranslateTime): boolean;


      function Exec(AFileName: string): boolean;
      function Save(AFileName: string): boolean;
      procedure Echo(AEcho: string);
      procedure EchoEx(AEcho: string; AColor: tColor; AStyle: Integer);
      procedure ListToLog(AName: string; ATabl: boolean);
      function Command(ACommand: string; AWait: boolean): boolean;
      function Msg(AText, ACaption, AButtons: string; AIdHelp: integer): string;


      function Vrf_LogMaxSize(PtrValue: pointer): boolean;

    public
      constructor Create(APref: string);
      destructor Destroy; override;

      procedure BeforeRunApp;

      function LoadConfig(AFileName: string): boolean;
      function SaveConfig(AFileName: string): boolean;
      function LoadAutoExec(AFileName: string): boolean;
      function Input(s: string): boolean;
      function TranslateParam: boolean;

      function SaveToFile(FileName: string; APref: string = ''): boolean;
      function LoadFromFile(FileName: string; ACompiler: tCompiler; APref: string = ''; AMaxTime: integer = var_MaxTranslateTime): boolean;

      procedure VerifyOpenClose(AList: tStringList);
      function ConstToStr(AConst: string; AVType: VariableType): string;
      procedure GetConfigsStrings(AStrings: tStrings);

      procedure AddMarkToLog(AMark: integer);
      function AddToLog(s: string; AType: tLogType = ltNormal): integer;
      function AddToLogEx(s: string; AColor: tColor = -1; AStyle: byte = c_bStyleDef): integer;
      function Error(s: string): integer;
      procedure ClearLog;

      procedure SetOnLogChange(AHandle: cardinal);
      procedure SetOnLogChangeConApp(AFunc: tConAppFuncOnChange);
      procedure SetOnSaveConfig(AFunc: tFuncOnSaveConfig);

      procedure LogLineEx(Index: integer; var AResult, ATime: string; var AType: tLogType; var AColor: tColor; var AStyle: byte);

      property Mutex: tMutexObject read FMutex;
      property IDLogState: cardinal read FIDLogState; // write FIDLogState;

      property LogSize: integer read GetLogSize;
      property LogLine[Index: integer]: string read GetLogLine;
      property LogMark[Index: integer]: integer read GetLogMark;
  end;

var
  Variables   : tVariables;
  var_WorkPath,
  var_ExePath : string;

implementation

uses
  Windows, SysUtils, Consts, Forms, Dialogs, Controls, Math,
  rxStrUtils,
  i_str;

constructor tVariables.Create; begin
  FMutex:=tMutexObject.Create;
  FPref:=APref;
  FConAppOnChange:=nil;

  inherited Create;

  FIDLogState:=0;
  FRipLog:=false;

  FOnChange:=tIntegerList.Create;
  FLog:=tStringList.Create;
  FCompiler:=tCompiler.Create(self); //, FPref);

  var_log_FileName:=ChangeFileExt(ExtractFileName(Application.ExeName), var_log_FileName);

  RegistryNatural (vn_var_log_MaxSize,  var_log_MaxSize,  self, Vrf_LogMaxSize);
  RegistryString  (vn_var_log_FileName, var_log_FileName, self, nil, true);
  RegistryString  (vn_var_cfg_FileName, var_cfg_FileName, self, nil, true);
  RegistryString  (vn_var_cfg_AutoExec, var_cfg_AutoExec, self, nil, true);
  RegistryString  (vn_var_CommandName,  var_CommandName,  self);

  RegistryFunction(vn_var_Error,   @tVariables.Error,     self, vtNatural, [vtString]);
  RegistryFunction(vn_var_Clear,   @tVariables.ClearLog,  self, vtVoid,    []);
  RegistryFunction(vn_var_Exec,    @tVariables.Exec,      self, vtBool,    [vtString]);
  RegistryFunction(vn_var_Save,    @tVariables.Save,      self, vtBool,    [vtString]);
  RegistryFunction(vn_var_Echo,    @tVariables.Echo,      self, vtVoid,    [vtString]);
  RegistryFunction(vn_var_EchoEx,  @tVariables.EchoEx,    self, vtVoid,    [vtString, vtColor, vtNatural]);
  RegistryFunction(vn_var_List,    @tVariables.ListToLog, self, vtVoid,    [vtString, vtBool]);
  RegistryFunction(vn_var_Command, @tVariables.Command,   self, vtBool,    [vtString, vtBool]);

  RegistryFunction(vn_var_Msg,     @tVariables.Msg,       self, vtString,  [vtString, vtString, vtString, vtNatural]);

  RegistryString  (vn_pc_Version, pcVersion, self, nil, true);

  LoadLogFile;

  AddStringToLog('');
  AddToLogEx(DateToStr(Date) + ', ' + TimeToStr(Time) + ' ' + ms_var_InitVariables, -1, fsbBold);
  AddMarkToLog(var_MarkInit);
end;

destructor tVariables.Destroy; begin
  SaveLogFile;

  FLog.Free;
  FCompiler.Free;
  FOnChange.Free;
  FMutex.Free;

  inherited Destroy;
end;

procedure tVariables.BeforeRunApp; begin
  FRipLog:=true;
end;

function tVariables.WholeLogFileName: string; begin
  Result:=var_WorkPath{var_ExePath} + var_log_FileName;
end;

function tVariables.LoadLogFile; begin
  if not var_log_Need then Result:=true
  else
    try
      FLog.LoadFromFile(WholeLogFileName);
      TruncateLog;
      Result:=true;
    except
      Result:=false;
    end
end;

function tVariables.SaveLogFile; begin
  if not var_log_Need then Result:=true
  else
    try
      FLog.SaveToFile(WholeLogFileName);
      Result:=true;
    except
      Result:=false;
    end
end;

procedure tVariables.TruncateLog; begin
  if FRipLog then
    with FLog do
      while Count > var_log_MaxSize do Delete(0);
      
  ExecOnLogChange;
end;



function tVariables.TranslateParam;
var
  i: integer;
  s: string;
  c: char;
begin
  FMutex.WaitForObjectFull;

  Result:=true;
  s:=DelRSpace(CmdLine);
  if length(s) > 0 then begin

    if s[1] = '"' then c:='"'
    else c:=' ';

    i:=2;
    while (i <= length(s)) and (s[i] <> c) do inc(i);
    Delete(s, 1, i);
    s:=DelRSpace(s);

    if length(s) > 0 then begin
      AddToLog(Format(FPref + ms_var_Param, [s]));
      Result:=TranslateString(s)
    end
  end;

  FMutex.ReleaseObjectFull;
end;

function tVariables.TranslateString;
var SL: tStringList;
begin
  SL:=tStringList.Create;
  try
    SL.Add(s);
    VerifyOpenClose(SL);
    Result:=FCompiler.Translate(SL, true, true, AMaxTime);
  finally
    SL.Free
  end
end;

function tVariables.Input;
var i: integer;
begin
  FMutex.WaitForObjectFull;

  s:=DelRSpace(s);
  Result:=SearchVar(s, i) and (VType[i] <> vtFunction);
  if Result then AddToLog(Format(ms_var_Is, [Name[i], ConstToStr(Value[i], VType[i])]))
  else Result:=TranslateString(s, -1);

  FMutex.ReleaseObjectFull;
end;

function tVariables.ConstToStr; begin
  if AVType = vtString then Result:='''' + CompiledStr(AConst) + ''''
  else Result:=AConst
end;

procedure tVariables.GetConfigsStrings;
var
  i, j  : integer;
  sl_add: tStringList;
begin
  for i:=0 to Count - 1 do
    if not IsConst[i] and (VType[i] <> vtFunction) then
      AStrings.Add(Format(var_SaveVar, [Name[i], ConstToStr(Value[i], VType[i])]));

  if length(FOnSaveConfig) > 0 then begin
    sl_add:=tStringList.Create;
    try
      for i:=low(FOnSaveConfig) to high(FOnSaveConfig) do begin
        sl_add.Clear;
        FOnSaveConfig[i](sl_add);
        if sl_add.Count > 0 then begin
          if (AStrings.Count > 0) and (length(AStrings[AStrings.Count - 1]) > 0) then AStrings.Add('');
          for j:=0 to sl_add.Count - 1 do AStrings.Add(sl_add[j]); // AStrings.Add(sl_add.Text)
        end
      end;
    finally
      sl_add.Free
    end
  end
end;

function tVariables.SaveToFile;
var sl: tStringList;
begin
  FMutex.WaitForObjectFull;

  sl:=tStringList.Create;
  try
    GetConfigsStrings(sl);
    try
      sl.SaveToFile(FileName);
      AddToLog(Format(APref + ms_var_Save, [FileName]));
      Result:=true;
    except
      Error(Format(APref + ms_var_ErrorSave, [FileName]));
      Result:=false
    end
  finally
    sl.Free;
  end;

  FMutex.ReleaseObjectFull;
end;

function tVariables.LoadFromFile;
var SL: tStringList;
begin
  FMutex.WaitForObjectFull;

  SL:=tStringList.Create;
  try
    try
      SL.LoadFromFile(FileName);
      AddToLog(Format(APref + ms_var_Load, [FileName]));
      Result:=true;
    except
      Error(Format(APref + ms_var_ErrorLoad, [FileName]));
      Result:=false
    end;

    if Result then begin
      VerifyOpenClose(SL);
      ACompiler.Translate(SL, false, true, AMaxTime)
    end;

  finally
    SL.Free;
  end;

  FMutex.ReleaseObjectFull;
end;

procedure tVariables.VerifyOpenClose;
var
  i, j : integer;
  nado,
  loop : boolean;
begin
  nado:=true;
  loop:=true;

  i:=0;
  while loop and (i < AList.Count) do begin
    j:=1;
    while loop and (j <= length(AList[i])) do begin
      loop:=AList[i][j] = ' ';
      if not loop then nado:=AList[i][j] <> var_Open;
      inc(j)
    end;
    inc(i)
  end;

  if nado then
    if AList.Count > 0 then begin
      AList[0]:=var_Open + ' ' + AList[0];
      AList[AList.Count - 1]:=AList[AList.Count - 1] + ' ' + var_Close;
    end
    else begin
      AList.Insert(0, var_Open);
      AList.Add(var_Close);
    end
end;

function tVariables.WholleStr; begin
  if length(s) = 0 then SetLength(Result, 0)
  else begin
    Result:=DateToStr(Date) + c_chSpace +
            TimeToStr(Time) + c_chSpace +
            arLogTypeChar[AType] +
            MakeStr(c_chMinus, 9) +
            c_chSpace + s
  end
end;

function tVariables.WholleStrEx;
var sTemp: string;
begin
  if length(s) = 0 then SetLength(Result, 0)
  else begin
    sTemp:=c_chMinus;

    if AStyle > 15 then sTemp:=sTemp + c_chMinus
    else sTemp:=sTemp + IntToHex(AStyle, 1);

    if AColor = -1 then sTemp:=sTemp + c_sColorDef
    else sTemp:=sTemp + IntToHex(AColor, 8);

    Result:=DateToStr(Date) + c_chSpace +
            TimeToStr(Time) + c_chSpace +
            sTemp + c_chSpace + s
  end
end;

procedure tVariables.LogLineEx;
var
  ps1, ps2: integer;
  sTemp, s: string;
  i       : tLogType;
begin
  FMutex.WaitForObject;

  s:=FLog[Index];
  ps1:=NPos(c_chSpace, s, 2);
  ps2:=NPos(c_chSpace, s, 3);
  if (ps1 <> 0) and (ps2 <> 0) and (ps2 - ps1 = 11) then begin
    ATime:=Copy(s, 0, ps1 - 1);
    AResult:=Copy(s, ps2 + 1, MaxInt);

    sTemp:=Copy(s, ps1 + 1, 1);
    AType:=ltNormal;
    for i:=Low(arLogTypeChar) to High(arLogTypeChar) do
      if sTemp = arLogTypeChar[i] then begin
        AType:=i;
        break;
      end;

    try
      sTemp:=Copy(s, ps1 + 2, 1);
      if sTemp = c_chMinus then AStyle:=c_bStyleDef
      else AStyle:=Hex2Dec(sTemp);
    except
      AStyle:=c_bStyleDef
    end;

    try
      sTemp:=Copy(s, ps1 + 3, 8);
      if sTemp = c_sColorDef then AColor:=-1
      else AColor:=Hex2Dec(sTemp);
    except
      AColor:=-1;
    end
  end
  else begin
    AResult:=s;
    AColor:=-1;
    AStyle:=c_bStyleDef
  end;

  FMutex.ReleaseObject;
end;

function tVariables.AddStringToLog;
var
  f : TextFile;
  fn: string;
begin
  FMutex.WaitForObjectFull;

  if var_log_MaxSize > 0 then begin

    if FRipLog then
      while FLog.Count >= var_log_MaxSize do FLog.Delete(0);

    Result:=FLog.Add(s);
    ExecOnLogChange;

    if var_log_Need then begin
      fn:=WholeLogFileName;
      AssignFile(f, fn);

      try
        if FileExists(fn) then Append(f)
        else ReWrite(f);

        if IOResult = 0 then begin
          WriteLn(f, s);
          if IOResult = 0 then begin
            Flush(f);
            IOResult;
          end;
          CloseFile(f);
        end

      except
      end
    end
  end
  else Result:=-1;

  FMutex.ReleaseObjectFull;
end;

function tVariables.AddToLog; begin
  Result:=AddStringToLog(WholleStr(s, AType))
end;

function tVariables.AddToLogEx; begin
  Result:=AddStringToLog(WholleStrEx(s, AColor, AStyle))
end;

procedure tVariables.AddMarkToLog; begin
  FMutex.WaitForObjectFull;

  if FLog.Count > 0 then
    FLog.Objects[FLog.Count - 1]:=pointer(AMark);

  FMutex.ReleaseObjectFull;
end;

function tVariables.GetLogMark; begin
  FMutex.WaitForObject;

  Result:=integer(FLog.Objects[Index]);

  FMutex.ReleaseObject;
end;

function tVariables.Error; begin
  Result:=AddToLog(s, ltError)
end;

procedure tVariables.ClearLog; begin
  FMutex.WaitForObjectFull;

  FLog.Clear;
  ExecOnLogChange;

  FMutex.ReleaseObjectFull;
end;

function tVariables.GetLogSize; begin
  FMutex.WaitForObject;

  Result:=FLog.Count;

  FMutex.ReleaseObject;
end;

function tVariables.GetLogLine;
var
  cl: tColor;
  st: byte;
  lt: tLogType;
  s : string;
begin
  LogLineEx(Index, Result, s, lt, cl, st)
end;

procedure tVariables.ExecOnLogChangeIndex; begin
  PostMessage(FOnChange[AIndex], wm_LogChange, 0, 0);
end;

procedure tVariables.ExecOnLogChange;
var i: integer;
begin
  inc(FIDLogState); // FIDLogState:=GetTickCount;
  
  for i:=0 to FOnChange.Count - 1 do ExecOnLogChangeIndex(i);
  if Assigned(FConAppOnChange) then FConAppOnChange
end;

procedure tVariables.SetOnLogChange; begin
  FMutex.WaitForObjectFull;
  ExecOnLogChangeIndex(FOnChange.Add(AHandle));
  FMutex.ReleaseObjectFull;
end;

procedure tVariables.SetOnLogChangeConApp; begin
  FMutex.WaitForObjectFull;
  FConAppOnChange:=AFunc;
  FMutex.ReleaseObjectFull;
end;

procedure tVariables.SetOnSaveConfig; begin
  FMutex.WaitForObjectFull;
  SetLength(FOnSaveConfig, length(FOnSaveConfig) + 1);
  FOnSaveConfig[high(FOnSaveConfig)]:=AFunc;
  FMutex.ReleaseObjectFull;
end;

function tVariables.LoadConfig; begin
  Result:=LoadFromFile(AFileName, FCompiler, FPref);
end;

function tVariables.LoadAutoExec; begin
  Result:=true;
  if FileExists(AFileName) then
    Result:=LoadFromFile(AFileName, FCompiler, FPref);
end;

function tVariables.SaveConfig; begin
  Result:=SaveToFile(AFileName, FPref);
end;



function tVariables.Vrf_LogMaxSize; begin
  Result:=true;
  TruncateLog
end;

function tVariables.Exec;
var Compiler: tCompiler;
begin
  Compiler:=tCompiler.Create(self);
  try
    Result:=LoadFromFile(AFileName, Compiler, '', -1);
  finally
    Compiler.Free
  end
end;

function tVariables.Save; begin
  Result:=SaveToFile(AFileName)
end;

procedure tVariables.Echo; begin
  AddToLog(AEcho)
end;

procedure tVariables.EchoEx; begin
  AddToLogEx(AEcho, AColor, AStyle)
end;

procedure tVariables.ListToLog;
const dl = 2;
var
  b, j, bAdd: boolean;
  i,
  max_Name,
  max_Type,
  max_Flag  : integer;
  s, s1     : string;

begin
  b:=length(AName) = 0;
  max_Name:=0;
  max_Type:=0;
  max_Flag:=0;
  bAdd:=false;

  for j:=not ATabl to true do begin
    for i:=0 to Count - 1 do
      if b or CompareStrBegin(Name[i], AName) then begin

        if IsConst[i] then s:=var_Const
        else SetLength(s, 0);

        if not j then begin
          max_Name:=Max(max_Name, length(Name[i]));
          max_Type:=Max(max_Type, length(VTypeToStr(VType[i])));
          max_Flag:=Max(max_Flag, length(s));
        end
        else begin
          bAdd:=true;

          if VType[i] <> vtFunction then s1:=' = ' + ConstToStr(Value[i], VType[i])
          else SetLength(s1, 0);

          if ATabl then
            AddToLog(LeftStr(Name[i], max_Name) +
                     LeftStr(s, max_Flag) +
                     LeftStr(VTypeToStr(VType[i]), max_Type) + s1)
          else begin
            if length(s) > 0 then s:=s + ', ';
            AddToLog(Name[i] + ' (' + s + VTypeToStr(VType[i]) + ')' + s1)
          end
        end
      end;

    if not j then begin
      max_Name:=max_Name + dl;
      max_Type:=max_Type + dl;
      if max_Flag > 0 then max_Flag:=max_Flag + dl
    end
  end;

  if not bAdd then AddToLog(ms_var_NoVars)
end;

function tVariables.Command;
var
  SI      : tStartupInfo;
  PI      : tProcessInformation;
  hProcess: LongBool;
  res     : cardinal;
begin
  Result:=length(ACommand) > 0;
  if Result then begin

    FillChar(SI, sizeof(SI), 0);
    SI.wShowWindow:=SW_NORMAL;
    SI.dwFlags:=STARTF_USESHOWWINDOW;
    SI.cb:=sizeof(SI);

    hProcess:=
      CreateProcess(nil, pChar(var_CommandName + var_CommandKey + ACommand),
                    nil, nil, false,
                    CREATE_SEPARATE_WOW_VDM or NORMAL_PRIORITY_CLASS,
                    nil, pChar(CurrentPathName('')), SI, PI);

    Result:=hProcess;
    if Result then
      if AWait then begin
        Result:=(WaitForSingleObject(PI.hProcess, INFINITE) <> WAIT_FAILED);
        GetExitCodeProcess(PI.hProcess, res);
        if Result then Result:=res = 0;
      end
  end
end;

function tVariables.Msg;
const
  CapCount = 5;
  CapStrs: array[0..CapCount - 1] of string =
           (msg_Warning, msg_Error, msg_Information, msg_Confirmation, msg_Custom);
  CapCode: array[0..CapCount - 1] of tMsgDlgType =
           (mtWarning, mtError, mtInformation, mtConfirmation, mtCustom);

  ButCount = 11;
  ButStrs: array[0..ButCount - 1] of string =
           (msg_OK, msg_Cancel, msg_Abort, msg_Retry, msg_Ignore, msg_Yes,
            msg_No, msg_All, msg_NoToAll, msg_YesToAll, msg_Help);
  ButCode: array[0..ButCount - 1] of tMsgDlgBtn =
           (mbOK, mbCancel, mbAbort, mbRetry, mbIgnore, mbYes, mbNo,
            mbAll, mbNoToAll, mbYesToAll, mbHelp);
var
  mdt : tMsgDlgType;
  mdb : tMsgDlgButtons;
  i   : integer;
  s   : string;
begin
  mdt:=mtInformation;
  for i:=0 to CapCount - 1 do
    if CompareStrFlags(CapStrs[i], DelRSpace(ACaption)) then begin
      mdt:=CapCode[i];
      break
    end;

  mdb:=[];
  AButtons:=DelSpaceOne(AButtons);
  while length(AButtons) > 0 do begin

    i:=Pos(' ', AButtons);
    if i = 0 then i:=length(AButtons) + 1;
    s:=Copy(AButtons, 1, i - 1);
    Delete(AButtons, 1, i);

    for i:=0 to ButCount - 1 do
      if CompareStrFlags(ButStrs[i], s) then begin
        mdb:=mdb + [ButCode[i]];
        break
      end;
  end;

  i:=MessageDlg(AText, mdt, mdb, AIdHelp);
  if i = mrNone then Result:=msg_None
  else Result:=ButStrs[i - 1]
end;

initialization
  var_WorkPath:=NormalPath(GetCurrentDir);
  var_ExePath:=NormalPath(ExtractFilePath(Application.ExeName));
end.

