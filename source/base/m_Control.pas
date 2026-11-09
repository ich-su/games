unit m_Control;

interface

uses
  Windows, Classes, Forms, Controls,
  i_classes, i_str, iwclasses;

const
  crl_MaxTime: integer = 5000;

type
  tMngControl = class;
  tIWKey = string;

  tMouseAction = (maDown, maUp, maMove);
  tMCMouseEvent = procedure(ASender: tObject; AAction: tMouseAction; AX, AY, AX2, AY2: integer; AButton: tMouseButton; AShift: tShiftState) of object;

  tControlInfo = class
    protected
      FOwner: tMngControl;
      FControl: tIWControl;

    public
      constructor Create(AOwner: tMngControl; AControl: tIWControl);

      function Exec(ASender: tObject): boolean; virtual;
      function log_Add: string; virtual;
      function cfg_Add: string; virtual;

      property Owner: tMngControl read FOwner;
      property Control: tIWControl read FControl;
  end;

  tControlMng = class(tControlInfo)
    protected
      FMng: tMngA;

    public
      constructor Create(AOwner: tMngControl; AControl: tIWControl; AMng: tMngA);

      function Exec(ASender: tObject): boolean; override;

      property Mng: tMngA read FMng;
  end;

  tControlAlias = class(tControlInfo)
    protected
      FExecControl: tIWControl;

    public
      constructor Create(AOwner: tMngControl; AControl, AExecControl: tIWControl);

      function Exec(ASender: tObject): boolean; override;
      function log_Add: string; override;

      property ExecControl: tIWControl read FExecControl;
  end;

  tControlEsl = class(tControlInfo)
    protected
      FEslText: tStrings;

      function GetEslString: string;
      procedure SetEslString(AEslString: string);

    public
      constructor Create(AOwner: tMngControl; AControl: tIWControl; AEslString: string); overload;
      constructor Create(AOwner: tMngControl; AControl: tIWControl; AEslText: tStrings); overload;
      destructor Destroy; override;

      function Exec(ASender: tObject): boolean; override;
      function log_Add: string; override;
      function cfg_Add: string; override;

      property EslString: string read GetEslString write SetEslString;
      property EslText: tStrings read FEslText;
  end;

  tBind = class
    protected
      FKey    : tIWKey;
      FControl: tIWControl;

      procedure SetKey(AKey: tIWKey);
      procedure SetControl(AControl: tIWControl);

    public
      constructor Create(AKey: tIWKey; AControl: tIWControl);

      property Key: tIWKey read FKey write SetKey;
      property Control: tIWControl read FControl write FControl;
  end;

  tControlInfoList = class(tSortedList)
    protected
      function Compare(AClass1, AClass2: pointer): integer; override;
      function GetItem(AIndex: integer): tControlInfo;

    public
      function FindSortedStr(AControl: string; var Index: integer): boolean;

      property Items[Index: integer]: tControlInfo read GetItem; default;
  end;

  tBindList = class(tSortedList)
    protected
      function Compare(AClass1, AClass2: pointer): integer; override;
      function GetItem(AIndex: integer): tBind;

    public
      function FindSortedStr(AKey: string; var Index: integer): boolean;

      property Items[Index: integer]: tBind read GetItem; default;
  end;

  tSourceForm = class
    protected
      FForm                : tForm;
      FSaveOnKeyDown       : tKeyEvent;
      FSaveOnMouseDown,
      FSaveOnMouseUp       : tMouseEvent;
      FSaveOnMouseWheelDown,
      FSaveOnMouseWheelUp  : tMouseWheelUpDownEvent;
      FSaveOnMouseMove     : tMouseMoveEvent;

    public
      constructor Create(AForm: tForm; AMngControl: tMngControl);
      destructor Destroy; override;

      procedure CallSaveOnKeyDown(ASender: tObject; var AKey: word; AShift: tShiftState);
      procedure CallSaveOnMouseDown(ASender: tObject; AButton: tMouseButton; AShift: tShiftState; AX, AY: Integer);
      procedure CallSaveOnMouseUp(ASender: tObject; AButton: tMouseButton; AShift: tShiftState; AX, AY: Integer);
      procedure CallSaveOnMouseWheelDown(ASender: tObject; AShift: tShiftState; AMousePos: tPoint; var Handled: boolean);
      procedure CallSaveOnMouseWheelUp(ASender: tObject; AShift: tShiftState; AMousePos: tPoint; var Handled: boolean);

      property Form: tForm read FForm;
  end;

  tSourceFormList = class(tList)
    protected
      function GetItem(AIndex: integer): tSourceForm;

    public
      property Items[Index: integer]: tSourceForm read GetItem; default;

      function Find(AForm: tForm; var Index: integer): boolean;
  end;

  tRectControl = class
    protected
      FX, FY, FWidth, FHeight: integer;
      FControl               : tIWControl;

    public
      constructor Create(AX, AY, AWidth, AHeight: integer; AControl: tIWControl);

      property X: integer read FX;
      property Y: integer read FY;
      property Width: integer read FWidth;
      property Height: integer read FHeight;
      property Control: tIWControl read FControl;
  end;

  tRectControlList = class(tExList)
    protected
      function GetItem(AIndex: integer): tRectControl;

    public
      property Items[Index: integer]: tRectControl read GetItem; default;
  end;

  tMngControl = class(tMngA)
    protected
      FControlInfoList : tControlInfoList;
      FBindList        : tBindList;
      FSourceFormList  : tSourceFormList;
      FRectControls    : tRectControlList;
      FOnMouseEvent    : tMCMouseEvent;

      FMouseDownX,
      FMouseDownY      : integer;

      procedure OnFormsKeyDown(ASender: tObject; var AKey: word; AShift: tShiftState);
      procedure OnFormsMouseDown(ASender: tObject; AButton: tMouseButton; AShift: tShiftState; AX, AY: integer);
      procedure OnFormsMouseUp(ASender: tObject; AButton: tMouseButton; AShift: tShiftState; AX, AY: integer);
      procedure OnFormsMouseWheelDown(ASender: tObject; AShift: tShiftState; AMousePos: tPoint; var Handled: boolean);
      procedure OnFormsMouseWheelUp(ASender: tObject; AShift: tShiftState; AMousePos: tPoint; var Handled: boolean);
      procedure OnFormsMouseMove(ASender: tObject; AShift: tShiftState; AX, AY: integer);

      procedure _FormsMouseWheel(AWheelUp: boolean; ASender: tObject; AShift: tShiftState; AMousePos: tPoint; var Handled: boolean);

      function VrfKey(AKey: tIWKey): boolean;
      procedure AddShiftToIWKey(var AKey: tIWKey; AShift: tShiftState);
      procedure CallIWKey(AKey: tIWKey);
      function CallIWControl(AControl: tIWControl): boolean;
      function KeyToIWKey(AKey: word; AShift: tShiftState): tIWKey;
      function MouseButtonToIWKey(AButton: tMouseButton; AShift: tShiftState): tIWKey;
      function MouseWheelToIWKey(AWheelUp: boolean; AShift: tShiftState): tIWKey;
      procedure AddToVariablesConfig(AList: tStringList);

      procedure Binds;
      procedure Controls;

    public
      constructor Create;
      destructor Destroy; override;

      procedure RegistryControl(AMng: tMngA; AControl: tIWControl; ADefaultKey: tIWKey);
      procedure RegistryAlias(AControl, AExecControl: tIWControl);
      procedure AddSource(AForm: tForm);

      procedure Bind(AKey: tIWKey; AControl: tIWControl);
      procedure UnBind(AKey: tIWKey);
      procedure UnBindAll;

      function FindControl(AControl: string): boolean; // для внешних классов
      function ControlToAlias(AExecControl: string): string;

      procedure ClearRectControls;
      procedure AddRectControl(AX, AY, AWidth, AHeight: integer; AControl: tIWControl);
      function FindRectConrol(AX, AY: integer; var AIndex: integer): boolean;

      procedure Control(AControl: tIWControl; AEslString: string);
      procedure DelControl(AControl: tIWControl);
      procedure DelControlAll;

      procedure iLog(AList: tStringList);

      property OnMouseEvent: tMCMouseEvent read FOnMouseEvent write FOnMouseEvent;
 end;

implementation

uses
  SysUtils, Menus, Consts,
  RxStrUtils,
  vars, pc, c_strings, misc;

function IWKeyAssigned(AKey: tIWKey): boolean; begin
  Result:=length(AKey) > 0
end;



constructor tControlInfo.Create; begin
  inherited Create;

  FOwner:=AOwner;
  FControl:=lowerstr(AControl);
end;

function tControlInfo.Exec; begin
  Result:=true
end;

function tControlInfo.log_Add; begin
  SetLength(Result, 0)
end;

function tControlInfo.cfg_Add; begin
  SetLength(Result, 0)
end;



constructor tControlMng.Create; begin
  inherited Create(AOwner, AControl);
  FMng:=AMng;
end;

function tControlMng.Exec; begin
  Result:=Mng.OnControl(ASender, Control)
end;



constructor tControlAlias.Create; begin
  inherited Create(AOwner, AControl);
  FExecControl:=AExecControl;
end;

function tControlAlias.Exec; begin
  Result:=FOwner.CallIWControl(FExecControl)
end;

function tControlAlias.log_Add; begin
  Result:=Format(log_ctrl_ControlAlias, [FExecControl])
end;



constructor tControlEsl.Create(AOwner: tMngControl; AControl: tIWControl; AEslString: string); begin
  inherited Create(AOwner, AControl);

  FEslText:=tStringList.Create;
  SetEslString(AEslString);
end;

constructor tControlEsl.Create(AOwner: tMngControl; AControl: tIWControl; AEslText: tStrings); begin
  inherited Create(AOwner, AControl);

  FEslText:=tStringList.Create;
  FEslText.Assign(AEslText);
end;

destructor tControlEsl.Destroy; begin
  FEslText.Free;
  inherited
end;

function tControlEsl.GetEslString; begin
  Result:=FEslText.Text
end;

procedure tControlEsl.SetEslString; begin
  FEslText.Text:='{ ' + AEslString + ' }'
end;

function tControlEsl.Exec;
var c: tCompiler;
begin
  c:=tCompiler.Create(Variables);
  try
    Result:=c.Translate(EslText, true, false, crl_MaxTime)
  finally
    c.Free
  end
end;

function tControlEsl.log_Add; begin
  Result:=Copy(EslString, 1, length(EslString) - 2)
end;

function tControlEsl.cfg_Add; begin
  Result:=Format(cfg_ctrl_control, [Variables.ConstToStr(Control, vtString),
                                    Variables.ConstToStr(Copy(EslString, 3, length(EslString) - 6), vtString)])
end;



constructor tBind.Create; begin
  inherited Create;

  Key:=AKey;
  Control:=AControl
end;

procedure tBind.SetKey; begin
  FKey:=lowerstr(AKey);
end;

procedure tBind.SetControl; begin
  FControl:=lowerstr(AControl);
end;



function tControlInfoList.Compare; begin
  Result:=CompareStrFlags2(tControlInfo(AClass1).Control, tControlInfo(AClass2).Control);
end;

function tControlInfoList.GetItem; begin
  Result:=Get(AIndex);
end;

function tControlInfoList.FindSortedStr;
var ci: tControlInfo;
begin
  ci:=tControlInfo.Create(nil, AControl);
  try
    Result:=FindSorted(ci, Index)
  finally
    ci.Free
  end;
end;



function tBindList.Compare; begin
  Result:=CompareStrFlags2(tBind(AClass1).Key, tBind(AClass2).Key);
end;

function tBindList.GetItem; begin
  Result:=Get(AIndex);
end;

function tBindList.FindSortedStr;
var b: tBind;
begin
  b:=tBind.Create(AKey, '');
  try
    Result:=FindSorted(b, Index)
  finally
    b.Free
  end;
end;



constructor tSourceForm.Create; begin
  inherited Create;

  FForm:=AForm;

  FSaveOnKeyDown:=FForm.OnKeyDown;
  FSaveOnMouseDown:=FForm.OnMouseDown;
  FSaveOnMouseUp:=FForm.OnMouseUp;
  FSaveOnMouseWheelDown:=FForm.OnMouseWheelDown;
  FSaveOnMouseWheelUp:=FForm.OnMouseWheelUp;
  FSaveOnMouseMove:=FForm.OnMouseMove;

  FForm.OnKeyDown:=AMngControl.OnFormsKeyDown;
  FForm.OnMouseDown:=AMngControl.OnFormsMouseDown;
  FForm.OnMouseUp:=AMngControl.OnFormsMouseUp;
  FForm.OnMouseWheelDown:=AMngControl.OnFormsMouseWheelDown;
  FForm.OnMouseWheelUp:=AMngControl.OnFormsMouseWheelUp;
  FForm.OnMouseMove:=AMngControl.OnFormsMouseMove;
end;

destructor tSourceForm.Destroy; begin
  FForm.OnKeyDown:=FSaveOnKeyDown;
  FForm.OnMouseDown:=FSaveOnMouseDown;
  FForm.OnMouseUp:=FSaveOnMouseUp;
  FForm.OnMouseWheelDown:=FSaveOnMouseWheelDown;
  FForm.OnMouseWheelUp:=FSaveOnMouseWheelUp;
  FForm.OnMouseMove:=FSaveOnMouseMove;

  inherited
end;

procedure tSourceForm.CallSaveOnKeyDown; begin
  if Assigned(FSaveOnKeyDown) then
    FSaveOnKeyDown(ASender, AKey, AShift);
end;

procedure tSourceForm.CallSaveOnMouseDown; begin
  if Assigned(FSaveOnMouseDown) then
    FSaveOnMouseDown(ASender, AButton, AShift, AX, AY);
end;

procedure tSourceForm.CallSaveOnMouseUp; begin
  if Assigned(FSaveOnMouseUp) then
    FSaveOnMouseUp(ASender, AButton, AShift, AX, AY);
end;

procedure tSourceForm.CallSaveOnMouseWheelDown; begin
  if Assigned(FSaveOnMouseDown) then
    FSaveOnMouseWheelDown(ASender, AShift, AMousePos, Handled);
end;

procedure tSourceForm.CallSaveOnMouseWheelUp; begin
  if Assigned(FSaveOnMouseWheelUp) then
    FSaveOnMouseWheelUp(ASender, AShift, AMousePos, Handled);
end;

function tSourceFormList.GetItem; begin
  Result:=Get(AIndex);
end;

function tSourceFormList.Find; begin
  Result:=false;
  Index:=0;
  while not Result and (Index < Count) do begin
    Result:=AForm = Items[Index].Form;
    if not Result then inc(Index)
  end;
end;



constructor tRectControl.Create; begin
  inherited Create;

  FX:=AX;
  FY:=AY;
  FWidth:=AWidth;
  FHeight:=AHeight;
  FControl:=AControl
end;

function tRectControlList.GetItem; begin
  Result:=Get(AIndex)
end;



constructor tMngControl.Create; begin
  inherited;

  FControlInfoList:=tControlInfoList.Create;
  FBindList:=tBindList.Create;
  FSourceFormList:=tSourceFormList.Create;
  FRectControls:=tRectControlList.Create;
  FOnMouseEvent:=nil;

  with Variables do begin
    RegistryFunction(vn_ctrl_Binds,         @tMngControl.Binds,         self, vtVoid, []);
    RegistryFunction(vn_ctrl_UnbindAll,     @tMngControl.UnBindAll,     self, vtVoid, []);
    RegistryFunction(vn_ctrl_Bind,          @tMngControl.Bind,          self, vtVoid, [vtString, vtString]);
    RegistryFunction(vn_ctrl_Unbind,        @tMngControl.UnBind,        self, vtVoid, [vtString]);

    RegistryFunction(vn_ctrl_Controls,      @tMngControl.Controls,      self, vtVoid, []);
//    RegistryFunction(vn_ctrl_Control,       @tMngControl.Control,       self, vtVoid, [vtString, vtString]);
//    RegistryFunction(vn_ctrl_DelControl,    @tMngControl.DelControl,    self, vtVoid, [vtString]);
//    RegistryFunction(vn_ctrl_DelControlAll, @tMngControl.DelControlAll, self, vtVoid, []);

//    RegistryInteger (vn_ctrl_MaxTime, crl_MaxTime, self);

    SetOnSaveConfig(AddToVariablesConfig);
  end;
end;

destructor tMngControl.Destroy; begin
  FRectControls.Free;
  FSourceFormList.Free;
  FBindList.Free;
  FControlInfoList.Free;

  inherited;
end;

procedure tMngControl.RegistryControl;
var i: integer;
begin
  if not FControlInfoList.FindSortedStr(AControl, i) then begin
    FControlInfoList.AddSorted(tControlMng.Create(self, AControl, AMng));
    if IWKeyAssigned(ADefaultKey) then Bind(ADefaultKey, AControl);
  end
end;

procedure tMngControl.RegistryAlias;
var i: integer;
begin
  if not FControlInfoList.FindSortedStr(AControl, i) then
    FControlInfoList.AddSorted(tControlAlias.Create(self, AControl, AExecControl));
end;

procedure tMngControl.AddShiftToIWKey;
var s: string;
begin
  if ssShift in AShift then s:=SmkcShift
  else SetLength(s, 0);
  if ssCtrl in AShift then s:=s + SmkcCtrl;
  if ssAlt in AShift then s:=s + SmkcAlt;

  AKey:=DelSpace(lowerstr(s + AKey));
end;

function tMngControl.KeyToIWKey; begin
  case AKey of
     19: Result:=keyname_pause;
     91: Result:=keyname_win1;
     93: Result:=keyname_win2;
    144: Result:=keyname_numlock;
    186: Result:=';';
    188: Result:=',';
    190: Result:='.';
    191: Result:='/';
    192: Result:='`';
    219: Result:='[';
    221: Result:=']';
    222: Result:='''';
    else Result:=ShortCutToText(ShortCut(AKey, []))
  end;

  if (AKey = vk_Shift) and (ssShift in AShift) then exclude(AShift, ssShift);
  if (AKey = vk_Control) and (ssCtrl in AShift) then exclude(AShift, ssCtrl);
  if (AKey = vk_Menu) and (ssAlt in AShift) then exclude(AShift, ssAlt);

  AddShiftToIWKey(Result, AShift);
end;

function tMngControl.MouseButtonToIWKey; begin
  case AButton of
    mbLeft: Result:=keyname_mouseleft;
    mbRight: Result:=keyname_mouseright;
    mbMiddle: Result:=keyname_mousemiddle;
    else SetLength(Result, 0)
  end;

  AddShiftToIWKey(Result, AShift);
end;

function tMngControl.MouseWheelToIWKey; begin
  if AWheelUp then Result:=keyname_mousewheelup
  else Result:=keyname_mousewheeldown;

  AddShiftToIWKey(Result, AShift);
end;

function tMngControl.VrfKey; begin
  Result:=IWKeyAssigned(AKey);
end;

procedure tMngControl.Bind;
var i: integer;
begin
  if not VrfKey(AKey) then log_err(Format(log_ctrl_err_InvalidKey, [AKey]))
  else
    if not IWControlAssigned(AControl) then log_err(Format(log_ctrl_err_InvalidControl, [AControl]))
    else
      if not FControlInfoList.FindSortedStr(AControl, i) then log_err(Format(log_ctrl_err_InvalidControl, [AControl]))
      else
        if FBindList.FindSortedStr(AKey, i) then FBindList[i].Control:=AControl
        else FBindList.AddSorted(tBind.Create(AKey, AControl))
end;

procedure tMngControl.UnBind;
var i: integer;
begin
  if FBindList.FindSortedStr(AKey, i) then FBindList.Delete(i)
end;

procedure tMngControl.UnBindAll; begin
  FBindList.Clear;
end;

procedure tMngControl.Control;
var i: integer;
begin
  AEslString:=DelRSpace(AEslString);

  if not IWControlAssigned(AControl) then log_err(Format(log_ctrl_err_InvalidControl, [AControl]))
  else
    if length(AEslString) = 0 then log_err(Format(log_ctrl_err_InvalidEslString, [AEslString]))
    else
      if not FControlInfoList.FindSortedStr(AControl, i) then
        FControlInfoList.AddSorted(tControlEsl.Create(self, AControl, AEslString))
      else
        if FControlInfoList[i] is tControlEsl then tControlEsl(FControlInfoList[i]).EslString:=AEslString
        else log_err(Format(log_ctrl_err_CannotAssign, [AControl]))
end;

procedure tMngControl.DelControl;
var i: integer;
begin
  if not FControlInfoList.FindSortedStr(AControl, i) then log_err(Format(log_ctrl_err_InvalidControl, [AControl]))
  else
    if FControlInfoList[i] is tControlEsl then FControlInfoList.Delete(i)
    else log_err(Format(log_ctrl_err_CannotDelete, [AControl]))
end;

procedure tMngControl.DelControlAll;
var i: integer;
begin
  i:=FControlInfoList.Count - 1;
  while i >= 0 do begin
    if FControlInfoList[i] is tControlEsl then FControlInfoList.Delete(i);    
    dec(i)
  end;
end;

procedure tMngControl.Binds;
var i: integer;
begin
  for i:=0 to FBindList.Count - 1 do
    log(Format(log_ctrl_Bind, [FBindList[i].Key, FBindList[i].Control]))
end;

procedure tMngControl.Controls;
var
  i, j: integer;
  s   : string;
begin
  for i:=0 to FControlInfoList.Count - 1 do begin
    SetLength(s, 0);
    for j:=0 to FBindList.Count - 1 do
      if FControlInfoList[i].Control = FBindList[j].Control then s:=MergeStr(s, Format(log_ctrl_Str, [FBindList[j].Key]));

    if length(s) > 0 then s:=Format(log_ctrl_Control, [FControlInfoList[i].Control, s])
    else s:=Format(log_ctrl_Str, [FControlInfoList[i].Control]);

    s:=s + ' ' + FControlInfoList[i].log_Add;
    log(s)
  end
end;

procedure tMngControl.AddSource;
var i: integer;
begin
  if not FSourceFormList.Find(AForm, i) then
    FSourceFormList.Add(tSourceForm.Create(AForm, self))
end;

procedure tMngControl.AddToVariablesConfig;
var
  i: integer;
  s: string;
begin
  AList.Add(cfg_ctrl_begin);
  for i:=0 to FBindList.Count - 1 do
    AList.Add(Format(cfg_ctrl_bind, [Variables.ConstToStr(FBindList[i].Key, vtString),
                                     Variables.ConstToStr(FBindList[i].Control, vtString)]));

  for i:=0 to FControlInfoList.Count - 1 do begin
    s:=FControlInfoList[i].cfg_Add;
    if length(s) > 0 then AList.Add(s);
  end
end;

function tMngControl.CallIWControl;
var i: integer;
begin
  Result:=false;
  if FControlInfoList.FindSortedStr(AControl, i) then Result:=FControlInfoList[i].Exec(self)
  else log_err(Format(log_ctrl_err_InvalidControl, [AControl]))
end;

procedure tMngControl.CallIWKey;
var i: integer;
begin
  if IWKeyAssigned(AKey) then
    if FBindList.FindSortedStr(AKey, i) then CallIWControl(FBindList[i].Control)
end;

procedure tMngControl.OnFormsKeyDown;
var
  i: integer;
  k: tIWKey;
begin
  k:=KeyToIWKey(AKey, AShift); // log(inttostr(akey) + ' ' + k); // тест
  CallIWKey(k);

  if (ASender is tForm) and FSourceFormList.Find(tForm(ASender), i) then
    FSourceFormList[i].CallSaveOnKeyDown(ASender, AKey, AShift);
end;

procedure tMngControl.OnFormsMouseDown;
var
  i: integer;
  k: tIWKey;
begin
  FMouseDownX:=AX;
  FMouseDownY:=AY;

  if not FindRectConrol(AX, AY, i) then begin
    k:=MouseButtonToIWKey(AButton, AShift);
    CallIWKey(k);

    if Assigned(FOnMouseEvent) then
      FOnMouseEvent(self, maDown, AX, AY, -1, -1, AButton, AShift);
  end;

  if (ASender is tForm) and FSourceFormList.Find(tForm(ASender), i) then
    FSourceFormList[i].CallSaveOnMouseDown(ASender, AButton, AShift, AX, AY);
end;

procedure tMngControl.OnFormsMouseUp;
var i, j: integer;
begin
  if FindRectConrol(FMouseDownX, FMouseDownY, i) and FindRectConrol(AX, AY, j) and (i = j) then
    CallIWControl(FRectControls[i].Control)
  else
    if Assigned(FOnMouseEvent) then
      FOnMouseEvent(self, maUp, AX, AY, FMouseDownX, FMouseDownY, AButton, AShift);

  if (ASender is tForm) and FSourceFormList.Find(tForm(ASender), i) then
    FSourceFormList[i].CallSaveOnMouseUp(ASender, AButton, AShift, AX, AY);
end;

procedure tMngControl.OnFormsMouseMove; begin
  if Assigned(FOnMouseEvent) then
    FOnMouseEvent(self, maMove, AX, AY, -1, -1, mbLeft, AShift);
end;

procedure tMngControl._FormsMouseWheel;
var
  i: integer;
  k: tIWKey;
begin
  k:=MouseWheelToIWKey(AWheelUp, AShift);
  CallIWKey(k);

  if (ASender is tForm) and FSourceFormList.Find(tForm(ASender), i) then
    if AWheelUp then FSourceFormList[i].CallSaveOnMouseWheelUp(ASender, AShift, AMousePos, Handled)
    else FSourceFormList[i].CallSaveOnMouseWheelDown(ASender, AShift, AMousePos, Handled)
end;

procedure tMngControl.OnFormsMouseWheelDown; begin
  _FormsMouseWheel(false, ASender, AShift, AMousePos, Handled);
end;

procedure tMngControl.OnFormsMouseWheelUp; begin
  _FormsMouseWheel(true, ASender, AShift, AMousePos, Handled);
end;

procedure tMngControl.ClearRectControls; begin
  FRectControls.Clear
end;

procedure tMngControl.AddRectControl; begin
  FRectControls.Add(tRectControl.Create(AX, AY, AWidth, AHeight, AControl));
end;

function tMngControl.FindRectConrol; begin
  AIndex:=0;
  Result:=false;
  while not Result and (AIndex < FRectControls.Count) do
    with FRectControls[AIndex] do begin
      Result:=(AX >= X) and (AX < X + Width) and (AY >= Y) and (AY < Y + Height);
      if not Result then inc(AIndex)
    end;
end;

function tMngControl.FindControl;
var i: integer;
begin
  Result:=FControlInfoList.FindSortedStr(AControl, i);
end;

function tMngControl.ControlToAlias;
var i: integer;
begin
  SetLength(Result, 0);

  for i:=0 to FControlInfoList.Count - 1 do
    if (FControlInfoList[i] is tControlAlias) and
       CompareStrFlags(AExecControl, tControlAlias(FControlInfoList[i]).ExecControl) then begin
         Result:=FControlInfoList[i].Control;
         exit;
       end;
end;

procedure tMngControl.iLog;
var i: integer;
begin
  for i:=0 to FControlInfoList.Count - 1 do
    AList.Add(FControlInfoList[i].Control);
end;

end.

