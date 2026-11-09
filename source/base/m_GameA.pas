{$R backgrounds.res}

unit m_GameA;

interface

uses
  Windows, Messages, Controls, Classes, Graphics, Forms, IniFiles,
  Mutex,
  i_classes, i_timer,
  iwclasses, c_strings, m_Draw, m_Color, m_Control, save, f_A, t_fMain;

const
  save_Version        : string = {$I ..\_version\save.};

  mf_CaptionLive      : boolean = true;

  g_RowCount          : integer = 8;
  g_ColCount          : integer = 8;
  g_CellSize          : integer = 16;

    res_BackCellSize = 20; // размер €чейки в рисунках в ресурсах

  mf_NChitTest        : boolean = true;
  mf_NothingSize      : integer = 8;
  mf_NothingSizeLeft  : integer = 96; // ???
  mf_NothingSizeRight : integer = 70; // ???
  mf_NothingSizeTop   : integer = 0;
  mf_NothingSizeBottom: integer = 0;
  mf_BorderColor      : tColor = clNone;

  g_BackColor         : tColor = clNone;
  g_BorderColor       : tColor = $555555;
  g_NothingSize       : integer = 1;

  g_RowCountMin       : integer = 4;
  g_RowCountMax       : integer = 128;
  g_ColCountMin       : integer = 4;
  g_ColCountMax       : integer = 128;
  g_CellSizeMin       : integer = 4;
  g_CellSizeMax       : integer = 64;

    any_NothingSizeMax: integer = 2048;

  mf_BackColor        : tColor = clBlack;
  g_BackImage         : integer = 3;
  g_BackImageFileName : string = '';
  g_BackImageScaled   : double = 0; // 0.8; // гы!

    go_bis_None    = 0;
    go_bis_Value   = 1;
    go_bis_Default = 2; go_bis_Max = go_bis_Default;

  g_BackImageShift    : integer = go_bis_Default;
  g_BackImageShiftX   : integer = 0;
  g_BackImageShiftY   : integer = 0;

  mf_BackImage        : integer = 1;
  mf_BackImageFileName: string = '';
  mf_BackImageScaled  : double = 1.2;

  any_BackImageMax    : integer = 12; // !!! сколько в ресурсах лежит !!!

    go_def_TimerInterval = 200;
    go_idxMin  = 100;
    gpi_idxMin = 100;

  g_GameObjectCanActiveMaxCount: integer = 1;

    shNone        = 0;
    shLeft        = 1;
    shRight       = 2; shMax = shRight;

    sheNone       = 0;
    sheBottom     = 1;
    sheTop        = 2; sheMax = sheTop;

  show_Enabled                : integer = sheTop;
  show_BoardRect              : boolean = false;

    show_Sep        = '-';
    show_AnotherStr = '.';

  show_Left                   : string = '';
  show_LeftStarted            : string = '.';
  show_Right                  : string = '';
  show_RightStarted           : string = '.';

  show_FontColor              : tColor = $CCCCCC;
  show_ControlFontColor       : tColor = $BBBBBB;
  show_ControlFontColorLight  : tColor = clWhite;
  show_FontName               : string = 'Tahoma';
  show_FontSize               : integer = 8;
  show_FontStyle              : integer = 0;
  show_TextFontColor          : tColor = $555555;
  show_TextFontName           : string = 'Calibri';
  show_TextFontSize           : integer = 7;
  show_TextFontStyle          : integer = 0;

  show_Y                      : integer = 10;
  show_X                      : integer = 8;
  show_VSpace                 : integer = 10;
  show_HSpace                 : integer = 8;

    show_FontSizeMin = 3;
    show_FontSizeMax = 32;
    show_SpaceMin    = 0;
    show_SpaceMax    = 64;

  show_NextGameObjects        : integer = shLeft;  // RegistryNextVars

  show_NextGameObjectsCellSize   : integer = 12;
  show_NextGameObjectsCellSizeMin: integer = 2;
  show_NextGameObjectsCellSizeMax: integer = 32;
  show_NextGameObjectsHSpace     : integer = 4;

  show_Translate              : boolean = true;

  g_NextGameObjectCount       : integer = 3;
  g_NextGameObjectCountMin    : integer = 0;
  g_NextGameObjectCountMax    : integer = 10;

  g_NextGameObjectChangeBoardCountClear: boolean = true;

  NeighbourCell: array[0..3] of tRowColRec =
                 ((row: 1; col: 0), (row: 0; col: -1), (row: -1; col: 0), (row: 0; col: 1));

type
  tGameObjectTimer = tHTimer;
  tCanDrawResult = (cdrYes, cdrNo, cdrWait);
  tMngGameA = class;

  tControlDataMouse = class
    protected
      FRow, FCol,
      FRow2, FCol2: integer;
      FButton     : tMouseButton;
      FShift      : tShiftState;
      FAction     : tMouseAction;

    public
      constructor Create(AAction: tMouseAction; ARow, ACol, ARow2, ACol2: integer; AButton: tMouseButton; AShift: tShiftState);

      property Row: integer read FRow;
      property Col: integer read FCol;
      property Row2: integer read FRow2;
      property Col2: integer read FCol2;
      property Button: tMouseButton read FButton;
      property Shift: tShiftState read FShift;
      property Action: tMouseAction read FAction;
  end;

  tControlItem = class
    protected
      FControl: tIWControl;
      FData   : tObject;

    public
      constructor Create(AControl: tIWControl); overload;
      constructor Create(AControl: tIWControl; AData: tObject); overload;
      destructor Destroy; override;

      property Control: tIWControl read FControl;
      property Data: tObject read FData;
  end;

  tControlBuffer = class(tExList) // каждому игроку/боту по буферу контролов
    protected
      function GetControl(AIndex: integer): tIWControl;
      function GetItem(AIndex: integer): tControlItem;

    public
      property Control[Index: integer]: tIWControl read GetControl; default;
      property Items[Index: integer]: tControlItem read GetItem;

      function Add(AControl: tIWControl): integer; overload;
  end;

  tControlBufferList = class(tExList)
    protected
      function GetItem(AIndex: integer): tControlBuffer;

    public
      procedure DeleteAllControls;

      property Items[Index: integer]: tControlBuffer read GetItem; default;
  end;

  tControlProcessingThread = class(tTHread)
    protected
      FMngGame: tMngGameA;
      FPort   : tHandle;

      procedure Execute; override;

    public
      constructor Create(AMngGame: tMngGameA);
      destructor Destroy; override;

      procedure PostControl(AControl: tIWControl; ABufferNumber: integer = 0); overload;
      procedure PostControl(AControl: tControlItem; ABufferNumber: integer = 0); overload;
  end;

  tElement = class
    protected
      FRow,
      FCol  : integer;
      FParam: cellint;

    public
      constructor Create(ARow, ACol: integer; AParam: cellint);

      property Row: integer read FRow write FRow;
      property Col: integer read FCol write FCol;
      property Param: cellint read FParam write FParam;
  end;

  tElementList = class(tSortedList)
    protected
      function GetItem(AIndex: integer): tElement;
      function Compare(AClass1, AClass2: pointer): integer; override;

    public
      procedure ChangeParams(AParam: cellint);
      function FindRowCol(ARow, ACol: integer; AIsSorted: boolean; var AIndex: integer): boolean;
      procedure Assign(AElements: tElementList);

      property Items[Index: integer]: tElement read GetItem; default;
  end;

  tElementListList = class(tExList)
    protected
      function GetItem(AIndex: integer): tElementList;

    public
      property Items[Index: integer]: tElementList read GetItem; default;
  end;

  tScores = extended;

  tGameObject = class
    protected
      FMngGame  : tMngGameA;
      FCellIndex: cellint;
      FElements : tElementList;
      FLive     : boolean;
      FScores   : tScores;
      FTimer    : tGameObjectTimer;

      function GetCanActive: boolean; virtual;
      function GetTimerInterval: cardinal; virtual;
      function GetTimerControl: tIWControl; virtual;
      function GetStopControl: tIWControl; virtual;

      procedure InitTimer(ATimerUse: boolean);
      procedure OnTimer; virtual;

      function GetTimerActive: boolean;
      procedure SetTimerActive(AActive: boolean);
      procedure __OnTimer(ASender: tObject);

      function CanToDrawCell(ARow, ACol: integer): tCanDrawResult; virtual;
      function CanToDrawCellAll: tCanDrawResult;
      function CanMove(ARow, ACol, NRow, NCol: integer): tCanDrawResult; virtual;
      function CellEmptyAll: boolean;

      procedure ToDraw(ACellIndex: integer = -1);
      procedure FromDraw;

      function InitScores: tScores; virtual;

    public
      constructor Create(AMngGame: tMngGameA; ACellIndex: cellint; ATimerUse: boolean);
      destructor Destroy; override;

      procedure Save(ASave: tGameSave); virtual;
      procedure Load(ASave: tGameSave); virtual;

      procedure Run(AData: tObject = nil); virtual;
      procedure Stop; virtual;
      function OnControl(ASender: tObject; AControl: tIWControl): boolean; virtual; // вызываетс€ MngGame
      function Move(ADRow, ADCol: integer): tCanDrawResult; virtual;
      procedure __DrawNext(ACanvas: tCanvas; ARect: tRect; ACalc: boolean; var AWidth, AHeight: integer); virtual;

      function ItIsYour(ARow, ACol: integer; AIndex, AParam: cellint): boolean;
      function ItIsYourCell(ARow, ACol: integer; AIsSorted: boolean = false): boolean;
      procedure GetMinMaxs(var ARowMin, ARowMax, AColMin, AColMax: integer);

      property Live: boolean read FLive;
      property CanActive: boolean read GetCanActive;
  end;

  tGameObjectList = class(tExList)
    protected
      function GetItem(AIndex: integer): tGameObject;

    public
      property Items[Index: integer]: tGameObject read GetItem; default;

      procedure Save(ASave: tGameSave; AMngGame: tMngGameA);
      procedure Load(ASave: tGameSave; AMngGame: tMngGameA);
  end;

  tGameState = (gsStopped, gsStarted, gsPaused);

  tMngGameA = class(tMngA)
    protected
      FState                   : tGameState;
      FScores                  : tScores;
      FTime                    : tDateTime;

      FMngColor                : tMngColor;
      FMngDraw                 : tMngDraw;

      FControlBuffers          : tControlBufferList;
      FControlProcessing       : tControlProcessingThread;

      FGameObjects,
      FNextGameObjects         : tGameObjectList;
      FGameObjectMouse         : tGameObject;
      FActiveGameObject        : integer;

      FMutex                   : tMutexObject;

      FFormBackImage,
      FFormBackImageFile,
      FBackImage,
      FBackImageShift,
      FBackImageFile           : tBitMap;

      FSaveOnGameFormHAactivate: tHActivateEvent;
      FSaveOnGameFormPaint     : tNotifyEvent;
      FSaveOnGameFormNCHITTEST : tNCHITTESTEvent;

      FTimeSession             : tDateTime;
      FShowY_Left, FShowY_Right: integer; // служебно дл€ __Draw

      FLockChangeGameForm      : boolean;
      FCursorPos               : tPoint;

      FBoardBackImageShiftX,
      FBoardBackImageShiftY    : integer;

      function GetGameForm: tFA; // virtual;
      function GetPlayerControlBuffer: tControlBuffer;

      procedure OnGameFormHActivate(ASender: tObject; AMessage: tWMActivate);
      procedure OnGameFormPaint(ASender: tObject);
      procedure OnMainFormNCHITTEST(var AMessage: tWMNCHITTEST);
      procedure MngControlMouseEvent(ASender: tObject; AAction: tMouseAction; AX, AY, AX2, AY2: integer; AButton: tMouseButton; AShift: tShiftState);

      function tolog_GameInfo: string; virtual;

      procedure Started; virtual;
      procedure Paused; virtual;
      procedure Stopped(AToLog: boolean = true); virtual;
      procedure BeforeStarted; virtual;

      procedure InitGameVars; virtual;
      procedure InitGameVars2; virtual; // вызываетс€ после создани€ формы
      
      procedure RegistryGameVars; virtual;
      procedure RegistryNextGameVars(AvnShowNextGameObjects, AvnShowNextGameObjectsCellSize, AvnGNextGameObjectCount, AvnGNextGameObjectHSpace: string);
      function VrfGameVars(PtrValue: pointer): boolean; virtual;

      procedure ClearTimeScoreEtc; virtual;

      procedure SetBackImage(ABackImageVar: integer; ABackImageScaled: double; ABackImageFile: tBitMap; var ABackImage: tBitMap);
      function VrfBoardBackImageShift(ALeft, ATop: integer): tBitMap;
      procedure ChangeBoardBackImageShift;

      procedure VerifyGameOptions; virtual;
      procedure AddToVariablesConfig(AList: tStringList); virtual;
      procedure GetGameFormSizes(var AWidth, AHeight: integer); virtual;
      function GetGameDrawRect: tRect; virtual;

      function GetTime: tDateTime;
      function GameTimeToStr: string;
      function GameScoreToStr: string;
      function ScoreEnabled: boolean; virtual;

      procedure GameReactionA;
      function GameReaction(AControl: tIWControl; AData: tObject): boolean; virtual;
      function GameLoop: boolean; virtual;
      function MouseReaction(AData: tControlDataMouse): boolean; virtual;
      function RunGameObject(AObject: tGameObject): integer; // -1 = false
      procedure FreeGameObjectMouse; virtual;

      function CreateDefaultGameObject: tGameObject; virtual;
      function IndexToGameObject(AIndex: integer): tGameObject; virtual;
      function GameObjectToIndex(AGameObject: tGameObject): integer; virtual;

      function GetSaveTitle: string;
      procedure SaveGame(ASave: tGameSave); virtual;
      procedure LoadGame(ASave: tGameSave); virtual;
      procedure SaveConfig(ASave: tGameSave; ANeed: boolean);
      procedure LoadConfig(ASave: tGameSave);

      function canvas_TextWidthHeightA(AFontName: string; AFontSize, AFontStyle: integer; AText: string; AWidth: boolean): integer;
      function canvas_TextWidth(AFontName: string; AFontSize, AFontStyle: integer; AText: string): integer;
      function canvas_TextHeight(AFontName: string; AFontSize, AFontStyle: integer; AText: string): integer;

      procedure __Draw; virtual;
      procedure __DrawInfo(ARect: tRect); virtual;
      procedure __DrawNextGameObjects(ARect: tRect); virtual;
      procedure __DrawAfterMngDraw(ACanvas: tCanvas; ARect: tRect); virtual;

      function GetDrawInfoString(var AString: string): boolean; virtual; // = false, если не знаем, что такое AString

      procedure SetGameFormCaption;

      property GameForm: tFA read GetGameForm;
      property PlayerControlBuffer: tControlBuffer read GetPlayerControlBuffer;

    public
      constructor Create;
      destructor Destroy; override;

      function OnControl(ASender: tObject; AControl: tIWControl): boolean; override;

      procedure ChangeGameForm; virtual;
      procedure LockChangeGameForm(ALock: boolean);

      class procedure tolog_MainInfoGame; virtual;
      procedure Init0; virtual; // вызываетс€ сразу после создани€ главной формы
      procedure Init; virtual;

      procedure Start;       // эти функции только дл€ внешних объектов
      procedure Pause;       // их нельз€ вызывать из tMngGameXXX и tGameObjectXXX
      procedure PauseOnly;
      procedure UnPauseOnly;
      procedure Stop;        // если нужно, то пользовать OnControl(self, ctrl_game_Stop) 
      procedure PlayPause;
      procedure NewGame;

      procedure Draw;

      class function ParseLanguage(AIni: tIniFile): boolean; virtual;

      function SaveGameToConfig(AFileName: string; AEx: boolean = false): boolean;
      function LoadGameFromConfig(AFileName: string): boolean;

      function FindGameObject(ARow, ACol: integer; AIndex, AParam: cellint; var AResultIndex: integer): boolean;
      procedure AddScores(AScores: tScores);
      procedure AddParams(AIndex: integer; AParams: array of const); virtual;

      property State: tGameState read FState;

      property MngDraw: tMngDraw read FMngDraw;
      property GameObjects: tGameObjectList read FGameObjects;
      property NextGameObjects: tGameObjectList read FNextGameObjects;
  end;

implementation

uses
  SysUtils, math,
  RxStrUtils,
  i_sys, i_str,
  pc, vars, cons,
  hashcrc,
  main, misc, iwgraphics;



constructor tElement.Create; begin
  inherited Create;

  FRow:=ARow;
  FCol:=ACol;
  FParam:=AParam;
end;



function tElementList.GetItem; begin
  Result:=Get(AIndex)
end;

function tElementList.Compare; begin
  Result:=CompareInteger(tElement(AClass1).Col, tElement(AClass2).Col);
  if Result = 0 then
    Result:=CompareInteger(tElement(AClass1).Row, tElement(AClass2).Row);
end;

procedure tElementList.ChangeParams;
var i: integer;
begin
  for i:=0 to Count - 1 do Items[i].Param:=AParam;
end;

procedure tElementList.Assign;
var i: integer;
begin
  Clear;
  for i:=0 to AElements.Count - 1 do
    Add(tElement.Create(AElements[i].Row, AElements[i].Col, AElements[i].Param))
end;

function tElementList.FindRowCol;
var e: tElement;
begin
  if AIsSorted then begin
    e:=tElement.Create(ARow, ACol, 0);
    try
      Result:=FindSorted(e, AIndex)
    finally
      e.Free
    end
  end
  else begin
    AIndex:=0;
    Result:=false;
    while not Result and (AIndex < Count) do begin
      Result:=(ARow = Items[AIndex].Row) and (ACol = Items[AIndex].Col);
      if not Result then inc(AIndex);
    end
  end
end;



function tElementListList.GetItem; begin
  Result:=Get(AIndex)
end;





constructor tGameObject.Create; begin
  inherited Create;

  FMngGame:=AMngGame;
  FCellIndex:=ACellIndex;
  FElements:=tElementList.Create;
  FScores:=0;
  FLive:=false;

  InitTimer(ATimerUse);
end;

destructor tGameObject.Destroy; begin
  if FTimer <> nil then FTimer.Free;
  FElements.Free;

  inherited;
end;

procedure tGameObject.InitTimer; begin
  if not ATimerUse then FTimer:=nil
  else begin
    FTimer:=tGameObjectTimer.Create;
    FTimer.OnTimer:=__OnTimer;
  end
end;

procedure tGameObject.Save;
var i: integer;
begin
  ASave.Save(FCellIndex);
  ASave.Save(FLive);
  ASave.Save(FScores);

  if FTimer = nil then ASave.Save(false)
  else begin
    ASave.Save(true);
    ASave.Save(FTimer.Interval);
    ASave.Save(FTimer.Enabled);
  end;

  ASave.Save(FElements.Count);
  for i:=0 to FElements.Count - 1 do
    with FElements[i] do begin
      ASave.Save(FRow);
      ASave.Save(FCol);
      ASave.Save(FParam);
    end;
end;

procedure tGameObject.Load;
var
  i, c, _row, _col: integer;
  ti              : cardinal;
  b               : boolean;
  _param          : cellint;
begin
  ASave.Load(FCellIndex);
  ASave.Load(FLive);
  ASave.Load(FScores);

  ASave.Load(b);
  InitTimer(b);

  if b then begin
    ASave.Load(ti); FTimer.Interval:=ti;
    ASave.Load(b); FTimer.Enabled:=b;
  end;

  ASave.Load(c);
  for i:=0 to c - 1 do begin
    ASave.Load(_row);
    ASave.Load(_col);
    ASave.Load(_param);

    FElements.Add(tElement.Create(_row, _col, _param))
  end;
end;

procedure tGameObject.Run; begin
  FScores:=InitScores;
  FLive:=true;

  if FTimer <> nil then begin
    FTimer.Interval:=GetTimerInterval;
    FTimer.Enabled:=true
  end;
end;

procedure tGameObject.Stop; begin
  FLive:=false;
  if FTimer <> nil then FTimer.Enabled:=false;

  FMngGame.AddScores(FScores);
  FMngGame.OnControl(self, GetStopControl);
end;

function tGameObject.OnControl; begin
  Result:=false;
end;

function tGameObject.GetCanActive; begin
  Result:=false
end;

function tGameObject.GetTimerInterval; begin
  Result:=go_def_TimerInterval
end;

function tGameObject.GetTimerControl; begin
  Result:=ctrl_game_obj_Draw
end;

function tGameObject.GetStopControl; begin
  Result:=ctrl_game_obj_GameLoop
end;

procedure tGameObject.OnTimer; begin
  FMngGame.OnControl(self, GetTimerControl);
end;

procedure tGameObject.__OnTimer; begin
  with FMngGame do begin // без with нельз€... либо пользовать MngProject.MngGame
    FMutex.WaitForObjectFull;

    if (State = gsStarted) and tGameObjectTimer(ASender).Enabled and FLive then OnTimer;

    FMutex.ReleaseObjectFull
  end
end;

function tGameObject.GetTimerActive: boolean; begin
  Result:=(FTimer <> nil) and FTimer.Enabled
end;

procedure tGameObject.SetTimerActive; begin
  if (FTimer <> nil) and FLive then FTimer.Enabled:=true
end;

procedure tGameObject.ToDraw;
var i: integer;
begin
  if ACellIndex = -1 then ACellIndex:=FCellIndex;
  for i:=0 to FElements.Count - 1 do
    with FMngGame.MngDraw, FElements[i] do
      if InDraw(Row, Col) then SetCell(Row, Col, ACellIndex, Param)
end;

procedure tGameObject.FromDraw;
var i: integer;
begin
  for i:=0 to FElements.Count - 1 do
    with FMngGame.MngDraw, FElements[i] do
      if InDraw(Row, Col) then ClearCell(Row, Col)
end;

function tGameObject.CanToDrawCell; begin
  if ItIsYourCell(ARow, ACol, false) or (FMngGame.MngDraw.Cell[ARow, ACol].Index = 0) then Result:=cdrYes
  else Result:=cdrNo
//  if FMngGame.MngDraw.Cell[ARow, ACol].Index in [0, FCellIndex] then Result:=cdrYes
//  else Result:=cdrNo
end;

function tGameObject.CanToDrawCellAll;
var i: integer;
begin
  Result:=cdrYes;
  i:=0;
  while (Result <> cdrNo) and (i < FElements.Count) do
    with FElements[i] do begin
      if FMngGame.MngDraw.InDraw(Row, Col) then Result:=CanToDrawCell(Row, Col);
      inc(i)
    end
end;

function tGameObject.CanMove;
var bn: boolean;
begin
  with FMngGame.MngDraw do begin
    bn:=InDraw(NRow, NCol);
    if bn then Result:=CanToDrawCell(NRow, NCol)
    else
      if InDraw(ARow, ACol) then Result:=cdrNo
      else Result:=cdrYes
  end
end;

function tGameObject.CellEmptyAll;
var i: integer;
begin
  Result:=true;
  i:=0;
  while Result and (i < FElements.Count) do
    with FMngGame.MngDraw, FElements[i] do begin
      Result:=not InDraw(Row, Col) or CellEmpty[Row, Col];
      inc(i)
    end
end;

function tGameObject.Move;
var i: integer;
begin
  Result:=cdrYes;
  i:=0;
  while (Result <> cdrNo) and (i < FElements.Count) do
    with FElements[i] do begin
      case CanMove(Row, Col, Row + ADRow, Col + ADCol) of
        cdrNo: Result:=cdrNo;
        cdrWait: if Result = cdrYes then Result:=cdrWait
      end;
      inc(i)
    end;

  if Result = cdrYes then begin
    FromDraw;

    for i:=0 to FElements.Count - 1 do
      with FElements[i] do begin
        Row:=Row + ADRow;
        Col:=Col + ADCol;
      end;

    ToDraw
  end
end;

function tGameObject.ItIsYour;
var i: integer;
begin
  Result:=false;

  if AIndex = FCellIndex then begin
    i:=0;
    while not Result and (i < FElements.Count) do
      with FElements[i] do begin
        Result:=(ACol = Col) and (ARow = Row) and (AParam = Param);
        inc(i)
      end
  end
end;

function tGameObject.ItIsYourCell;
var i: integer;
begin
  Result:=FElements.FindRowCol(ARow, ACol, AIsSorted, i)
end;

procedure tGameObject.GetMinMaxs;
var i: integer;
begin
  ARowMin:=MaxInt;
  ARowMax:=0;
  AColMin:=MaxInt;
  AColMax:=0;

  for i:=0 to FElements.Count - 1 do
    with FElements[i] do begin
      ARowMax:=max(ARowMax, Row);
      ARowMin:=min(ARowMin, Row);
      AColMax:=max(AColMax, Col);
      AColMin:=min(AColMin, Col);
    end;
end;

procedure tGameObject.__DrawNext;
var i, cs, RowMin, RowMax, ColMin, ColMax: integer;
begin
  if FElements.Count = 0 then begin
    AHeight:=0;
    AWidth:=0
  end
  else begin
    GetMinMaxs(RowMin, RowMax, ColMin, ColMax);
    cs:=show_NextGameObjectsCellSize;

    if not ACalc then
      for i:=0 to FElements.Count - 1 do
        with FElements[i] do
          FMngGame.MngDraw.DrawIndex(
            ACanvas,
            rect(ARect.Left + (Col - ColMin)*cs, ARect.Top + (Row - RowMin)*cs,
                 ARect.Left + (Col - ColMin)*cs + cs, ARect.Top + (Row - RowMin)*cs + cs),
            FCellIndex, Param);

    AHeight:=cs*(RowMax - RowMin + 2);
    AWidth:=cs*(ColMax - ColMin + 1)
  end
end;

function tGameObject.InitScores; begin
  Result:=FElements.Count; // а по приколу вот так ;)
end;



function tGameObjectList.GetItem; begin
  Result:=Get(AIndex)
end;

procedure tGameObjectList.Save;
var i: integer;
begin
  ASave.Save(Count);
  for i:=0 to Count - 1 do begin
    ASave.Save(AMngGame.GameObjectToIndex(Items[i]));
    Items[i].Save(ASave);
  end
end;

procedure tGameObjectList.Load;
var
  c, i, j: integer;
  go     : tGameObject;
begin
  ASave.Load(c);
  for i:=0 to c - 1 do begin
    ASave.Load(j);
    go:=AMngGame.IndexToGameObject(j);
    if go <> nil then begin
      go.Load(ASave);
      Add(go)
    end
  end
end;



constructor tControlDataMouse.Create; begin
  inherited Create;

  FRow:=ARow;
  FCol:=ACol;
  FRow2:=ARow2;
  FCol2:=ACol2;
  FButton:=AButton;
  FShift:=AShift;
  FAction:=AAction;
end;



constructor tControlItem.Create(AControl: tIWControl); begin
  inherited Create;

  FControl:=AControl;
  FData:=nil;
end;

constructor tControlItem.Create(AControl: tIWControl; AData: tObject); begin
  inherited Create;

  FControl:=AControl;
  FData:=AData;
end;

destructor tControlItem.Destroy; begin
  if FData <> nil then FData.Free;  
  inherited
end;



function tControlBuffer.GetControl; begin
  Result:=tControlItem(Items[AIndex]).Control
end;

function tControlBuffer.GetItem; begin
  Result:=Get(AIndex)
end;

function tControlBuffer.Add(AControl: tIWControl): integer; begin
  Result:=inherited Add(tControlItem.Create(AControl));
end;



function tControlBufferList.GetItem; begin
  Result:=Get(AIndex);
end;

procedure tControlBufferList.DeleteAllControls;
var i: integer;
begin
  for i:=0 to Count - 1 do Items[i].Clear
end;



constructor tControlProcessingThread.Create; begin
  inherited Create(false);

  FMngGame:=AMngGame;
  FPort:=CreateIoCompletionPort(INVALID_HANDLE_VALUE, 0, 0, 1);
end;

destructor tControlProcessingThread.Destroy; begin
  CloseHandle(FPort);
  inherited;
end;

procedure tControlProcessingThread.PostControl(AControl: tIWControl; ABufferNumber: integer = 0); begin
  PostQueuedCompletionStatus(FPort, ABufferNumber, cardinal(tControlItem.Create(AControl)), nil)
end;

procedure tControlProcessingThread.PostControl(AControl: tControlItem; ABufferNumber: integer = 0); begin
  PostQueuedCompletionStatus(FPort, ABufferNumber, cardinal(AControl), nil)
end;

procedure tControlProcessingThread.Execute;
var
  i : cardinal;
  o : pOverlapped;
  ci: tControlItem;

begin
  while not Terminated do begin
    if GetQueuedCompletionStatus(FPort, i, cardinal(ci), o, 100) then
      with FMngGame do begin

        FMutex.WaitForObjectFull;

        if State = gsStarted then begin
          repeat
            FControlBuffers[i].Add(ci);
          until not GetQueuedCompletionStatus(FPort, i, cardinal(ci), o, 0);

          GameReactionA;
        end;

        FMutex.ReleaseObjectFull;
      end
  end
end;





constructor tMngGameA.Create; begin
  inherited;

  FMutex:=tMutexObject.Create;
  FLockChangeGameForm:=false;

  FControlBuffers:=tControlBufferList.Create;
  FControlBuffers.Add(tControlBuffer.Create); // один игрок есть типа всегда

  FMngColor:=tMngColor.Create;
  FMngDraw:=tMngDraw.Create;
  FGameObjects:=tGameObjectList.Create;
  FNextGameObjects:=tGameObjectList.Create;

  InitGameVars;
  RegistryGameVars;

  ClearTimeScoreEtc;
  
  FBackImage:=tBitMap.Create;
  FBackImageShift:=tBitMap.Create;
  FBackImageFile:=tBitMap.Create;
  FFormBackImage:=tBitMap.Create;
  FFormBackImageFile:=tBitMap.Create;

//  SetBackImage(g_BackImage, g_BackImageScaled, FBackImageFile, FBackImage);
//  SetBackImage(mf_BackImage, mf_BackImageScaled, FFormBackImageFile, FFormBackImage);
  // еще одну!!!

  Stopped(false);

  FControlProcessing:=tControlProcessingThread.Create(self);

  MngDraw.AddCellObject(tCellEmpty.Create);
end;

destructor tMngGameA.Destroy; begin
  FControlProcessing.Free;

  GameForm.OnHActivate:=FSaveOnGameFormHAactivate;
  GameForm.OnPaint:=FSaveOnGameFormPaint;
  GameForm.OnNCHITTEST:=FSaveOnGameFormNCHITTEST;

  FNextGameObjects.Free;
  FGameObjects.Free;
  FMngDraw.Free;
  FMngColor.Free;
  FControlBuffers.Free;

  FFormBackImage.Free;
  FFormBackImageFile.Free;
  FBackImage.Free;
  FBackImageShift.Free;
  FBackImageFile.Free;

  FMutex.Free;

  inherited
end;

procedure tMngGameA.InitGameVars2; begin
end;

procedure tMngGameA.InitGameVars; begin
  g_CellSize:=auto_CellSize;
  show_FontSize:=auto_FontSize;
  show_TextFontSize:=auto_SmallFontSize;

  show_NextGameObjectsCellSize:=min_max(round(g_CellSize/1.8), show_NextGameObjectsCellSizeMin, show_NextGameObjectsCellSizeMax);
  show_NextGameObjectsHSpace:=round(show_NextGameObjectsCellSize/3);

  show_Y:=show_FontSize; // ха-ха
  show_X:=show_TextFontSize;
  show_VSpace:=show_Y;
  show_HSpace:=show_X;
end;

procedure tMngGameA.RegistryGameVars; begin
  with Variables do begin
    RegistryFunction(vn_game_NewGame, @tMngGameA.NewGame, self, vtVoid, []);

    RegistryString(vn_save_Version, save_Version, nil, nil, true);
    RegistryBoolean(vn_mf_NChitTest, mf_NChitTest);
    RegistryBoolean(vn_mf_CaptionLive, mf_CaptionLive, self, VrfGameVars);

    RegistryColor(vn_mf_BackColor, mf_BackColor, self, VrfGameVars);
    RegistryColor(vn_mf_BorderColor, mf_BorderColor, self, VrfGameVars);
    RegistryNatural(vn_mf_NothingSize, mf_NothingSize, self, VrfGameVars);
    RegistryNatural(vn_mf_NothingSizeLeft, mf_NothingSizeLeft, self, VrfGameVars);
    RegistryNatural(vn_mf_NothingSizeRight, mf_NothingSizeRight, self, VrfGameVars);
    RegistryNatural(vn_mf_NothingSizeTop, mf_NothingSizeTop, self, VrfGameVars);
    RegistryNatural(vn_mf_NothingSizeBottom, mf_NothingSizeBottom, self, VrfGameVars);

    RegistryNatural(vn_mf_BackImage, mf_BackImage, self, VrfGameVars);
    RegistryString(vn_mf_BackImageFileName, mf_BackImageFileName, self, VrfGameVars);
    RegistryFloat(vn_mf_BackImageScaled, mf_BackImageScaled, self, VrfGameVars);

    RegistryNatural(vn_g_BackImage, g_BackImage, self, VrfGameVars);
    RegistryString(vn_g_BackImageFileName, g_BackImageFileName, self, VrfGameVars);
    RegistryFloat(vn_g_BackImageScaled, g_BackImageScaled, self, VrfGameVars);

    RegistryNatural(vn_g_BackImageShift, g_BackImageShift, self, VrfGameVars);
    RegistryNatural(vn_g_BackImageShiftX, g_BackImageShiftX, self, VrfGameVars);
    RegistryNatural(vn_g_BackImageShiftY, g_BackImageShiftY, self, VrfGameVars);

    RegistryNatural(vn_g_RowCount, g_RowCount, self, VrfGameVars);
    RegistryNatural(vn_g_ColCount, g_ColCount, self, VrfGameVars);
    RegistryNatural(vn_g_CellSize, g_CellSize, self, VrfGameVars);

    RegistryColor(vn_g_BackColor, g_BackColor, self, VrfGameVars);
    RegistryColor(vn_g_BorderColor, g_BorderColor, self, VrfGameVars);
    RegistryNatural(vn_g_NothingSize, g_NothingSize, self, VrfGameVars);

    RegistryNatural(vn_info_Enabled, show_Enabled, self, VrfGameVars);
    RegistryBoolean(vn_info_BoardRect, show_BoardRect, self, VrfGameVars);

    RegistryColor(vn_info_FontColor, show_FontColor, self, VrfGameVars);
    RegistryColor(vn_info_ControlFontColor, show_ControlFontColor, self, VrfGameVars);
    RegistryColor(vn_info_ControlFontColorLight, show_ControlFontColorLight, self, VrfGameVars);
    RegistryString(vn_info_FontName, show_FontName, self, VrfGameVars);
    RegistryNatural(vn_info_FontSize, show_FontSize, self, VrfGameVars);
    RegistryNatural(vn_info_FontStyle, show_FontStyle, self, VrfGameVars);
    RegistryColor(vn_info_TextFontColor, show_TextFontColor, self, VrfGameVars);
    RegistryString(vn_info_TextFontName, show_TextFontName, self, VrfGameVars);
    RegistryNatural(vn_info_TextFontSize, show_TextFontSize, self, VrfGameVars);
    RegistryNatural(vn_info_TextFontStyle, show_TextFontStyle, self, VrfGameVars);

    RegistryNatural(vn_info_VSpace, show_VSpace, self, VrfGameVars);
    RegistryNatural(vn_info_HSpace, show_HSpace, self, VrfGameVars);
    RegistryNatural(vn_info_Y, show_Y, self, VrfGameVars);
    RegistryNatural(vn_info_X, show_X, self, VrfGameVars);

    RegistryBoolean(vn_info_Translate, show_Translate, self, VrfGameVars);

    RegistryString(vn_info_Left, show_Left, self, VrfGameVars);
    RegistryString(vn_info_LeftStarted, show_LeftStarted, self, VrfGameVars);
    RegistryString(vn_info_Right, show_Right, self, VrfGameVars);
    RegistryString(vn_info_RightStarted, show_RightStarted, self, VrfGameVars);

    RegistryNatural(vn_screen_Width, screen_Width, nil, nil, true);
    RegistryNatural(vn_screen_Height, screen_Height, nil, nil, true);
    RegistryNatural(vn_screen_Left, screen_Left, nil, nil, true);
    RegistryNatural(vn_screen_Top, screen_Top, nil, nil, true);
    RegistryNatural(vn_screen_PPI, screen_PPI, nil, nil, true);

    RegistryNatural(vn_auto_CellSize, auto_CellSize, nil, nil, true);
    RegistryNatural(vn_auto_FontSize, auto_FontSize, nil, nil, true);
    RegistryNatural(vn_auto_SmallFontSize, auto_SmallFontSize, nil, nil, true);

    RegistryFunction(vn_canvas_TextWidth, @tMngGameA.canvas_TextWidth, self, vtInteger,  [vtString, vtInteger, vtInteger, vtString]);
    RegistryFunction(vn_canvas_TextHeight, @tMngGameA.canvas_TextHeight, self, vtInteger,  [vtString, vtInteger, vtInteger, vtString]);


    SetOnSaveConfig(AddToVariablesConfig);
  end;

  with MngProject.MngControl do begin
    RegistryControl(self, ctrl_Play, key_None);
    RegistryControl(self, ctrl_Start, key_Start);

    RegistryControl(self, ctrl_Pause, key_Pause);
    Bind(key_Pause2, ctrl_Pause);
    RegistryControl(self, ctrl_PauseOnly, key_PauseOnly);
    Bind(key_PauseOnly2, ctrl_PauseOnly);
    RegistryControl(self, ctrl_UnPauseOnly, key_None);

    RegistryControl(self, ctrl_Stop, key_Stop);
    RegistryControl(self, ctrl_PlayPause, key_Start2);
    RegistryControl(self, ctrl_NewGame, key_None);

    OnMouseEvent:=MngControlMouseEvent
  end;
end;

procedure tMngGameA.RegistryNextGameVars; begin
  with Variables do begin
    if length(AvnShowNextGameObjects) > 0 then RegistryNatural(AvnShowNextGameObjects, show_NextGameObjects, self, VrfGameVars);
    if length(AvnShowNextGameObjectsCellSize) > 0 then RegistryNatural(AvnShowNextGameObjectsCellSize, show_NextGameObjectsCellSize, self, VrfGameVars);
    if length(AvnGNextGameObjectCount) > 0 then RegistryNatural(AvnGNextGameObjectCount, g_NextGameObjectCount, self, VrfGameVars);
    if length(AvnGNextGameObjectHSpace) > 0 then RegistryNatural(AvnGNextGameObjectHSpace, show_NextGameObjectsHSpace, self, VrfGameVars);
  end
end;

function tMngGameA.VrfGameVars;

  function _SetImageFile(ABackImageFileName: string; ABackImageFile: tBitMap): boolean; begin
    if length(ABackImageFileName) = 0 then ABackImageFile.Assign(nil)
    else
      if LoadImageFromFile(ABackImageFileName, ABackImageFile) then log(Format(ms_var_Load, [ABackImageFileName]))
      else begin
        log_err(Format(ms_var_ErrorLoad, [ABackImageFileName]));
        ABackImageFile.Assign(nil);
      end;

    Result:=true;
  end;

begin
//  if PtrValue = @cl_Back then else

  if (PtrValue = @g_BackImageFileName) or (PtrValue = @g_BackImage) or (PtrValue = @g_BackImageScaled) then begin
    Result:=true;
    if PtrValue = @g_BackImageFileName then Result:=_SetImageFile(g_BackImageFileName, FBackImageFile) else
    if PtrValue = @g_BackImage then Result:=(g_BackImage <= any_BackImageMax) else
    if PtrValue = @g_BackImageScaled then
      Result:=(g_BackImageScaled = 0) or
              ((g_BackImageScaled + MinFloat >= 0.1) and (g_BackImageScaled - MinFloat <= 10));
//    if Result then SetBackImage(g_BackImage, g_BackImageScaled, FBackImageFile, FBackImage);
  end
  else

  if (PtrValue = @mf_BackImageFileName) or (PtrValue = @mf_BackImage) or (PtrValue = @mf_BackImageScaled) then begin
    Result:=true;
    if PtrValue = @mf_BackImageFileName then Result:=_SetImageFile(mf_BackImageFileName, FFormBackImageFile) else
    if PtrValue = @mf_BackImage then Result:=(mf_BackImage <= any_BackImageMax) else
    if PtrValue = @mf_BackImageScaled then
      Result:=(mf_BackImageScaled = 0) or
              ((mf_BackImageScaled + MinFloat >= 0.1) and (mf_BackImageScaled - MinFloat <= 10));
//    if Result then SetBackImage(mf_BackImage, mf_BackImageScaled, FFormBackImageFile, FFormBackImage);
  end
  else

  if (PtrValue = @g_BackImageShift) or (PtrValue = @g_BackImageShiftX) or (PtrValue = @g_BackImageShiftY) then begin
    Result:=g_BackImageShift in [go_bis_None..go_bis_Max];
    if Result then ChangeBoardBackImageShift
  end
  else

  if PtrValue = @mf_CaptionLive then begin
    SetGameFormCaption;
    Result:=true
  end
  else

  if PtrValue = @mf_BackColor then Result:=mf_BackColor <> clNone else

  if (PtrValue = @mf_NothingSize) or (PtrValue = @g_NothingSize) or
     (PtrValue = @mf_NothingSizeLeft) or (PtrValue = @mf_NothingSizeRight) or
     (PtrValue = @mf_NothingSizeTop) or (PtrValue = @mf_NothingSizeBottom) then Result:=integer(PtrValue^) <= any_NothingSizeMax else

  if (PtrValue = @g_RowCount) or (PtrValue = @g_ColCount) then begin
    if PtrValue = @g_RowCount then Result:=g_RowCount in [g_RowCountMin..g_RowCountMax] else
    {if PtrValue = @g_ColCount then }Result:=g_ColCount in [g_ColCountMin..g_ColCountMax];

    if Result and g_NextGameObjectChangeBoardCountClear then FNextGameObjects.Clear
  end
  else

  if PtrValue = @g_CellSize then Result:=g_CellSize in [g_CellSizeMin..g_CellSizeMax] else
  if PtrValue = @g_NextGameObjectCount then Result:=g_NextGameObjectCount in [g_NextGameObjectCountMin..g_NextGameObjectCountMax] else

  if PtrValue = @show_Enabled then Result:=show_Enabled in [sheNone..sheMax] else
  if (PtrValue = @show_FontSize) or (PtrValue = @show_TextFontSize) then Result:=integer(PtrValue^) in [show_FontSizeMin..show_FontSizeMax] else
  if (PtrValue = @show_FontStyle) or (PtrValue = @show_TextFontStyle) then Result:=integer(PtrValue^) in [0..15] else
  if PtrValue = @show_NextGameObjectsCellSize then Result:=show_NextGameObjectsCellSize in [show_NextGameObjectsCellSizeMin..show_NextGameObjectsCellSizeMax] else
  if PtrValue = @show_NextGameObjects then Result:=show_NextGameObjects in [shNone..shMax] else
  if (PtrValue = @show_Y) or (PtrValue = @show_X) then Result:=integer(PtrValue^) < any_NothingSizeMax else
  if (PtrValue = @show_VSpace) or (PtrValue = @show_HSpace) or
     (PtrValue = @show_NextGameObjectsHSpace) then Result:=integer(PtrValue^) in [show_SpaceMin..show_SpaceMax]
  else Result:=true;

  if Result then ChangeGameForm
end;

function tMngGameA.OnControl; begin
  Result:=inherited OnControl(ASender, AControl);

  if IWControlAssigned(AControl) then
    if (AControl = ctrl_Start) or (AControl = ctrl_Play) then Start else
    if AControl = ctrl_Pause then Pause else
    if AControl = ctrl_PauseOnly then PauseOnly else
    if AControl = ctrl_UnPauseOnly then UnPauseOnly else
    if AControl = ctrl_Stop then Stop else
    if AControl = ctrl_PlayPause then PlayPause else
    if AControl = ctrl_NewGame then NewGame
    else
      FControlProcessing.PostControl(AControl);
end;

function tMngGameA.GetGameForm; begin
  Result:=MngProject.MainForm
end;

function tMngGameA.GetPlayerControlBuffer; begin
  Result:=FControlBuffers[0]
end;

procedure tMngGameA.Init0; begin
  InitGameVars2
end;

procedure tMngGameA.Init; begin
  GameForm.DoubleBuffered:=true;

  ChangeGameForm;

  FSaveOnGameFormHAactivate:=GameForm.OnHActivate;
  FSaveOnGameFormPaint:=GameForm.OnPaint;
  FSaveOnGameFormNCHITTEST:=GameForm.OnNCHITTEST;

  GameForm.OnHActivate:=OnGameFormHActivate;
  GameForm.OnPaint:=OnGameFormPaint;
  GameForm.OnNCHITTEST:=OnMainFormNCHITTEST;

  SetGameFormCaption;
end;

function tMngGameA.tolog_GameInfo; begin
  if ScoreEnabled then
    Result:=Format(log_game_StateChange, [Format(log_game_GameInfoTime, [GameTimeToStr]),
                                          Format(log_game_GameInfoScore, [GameScoreToStr])])
  else
    Result:=Format(log_game_GameInfoTime, [GameTimeToStr])
end;

class procedure tMngGameA.tolog_MainInfoGame; begin
end;

procedure tMngGameA.Start; begin
  FMutex.WaitForObjectFull;

  if FState = gsStopped then BeforeStarted;
  if FState <> gsStarted then Started;

  FMutex.ReleaseObjectFull;
end;

procedure tMngGameA.Pause; begin
  FMutex.WaitForObjectFull;

  if FState = gsPaused then Started
  else
    if FState = gsStarted then Paused;

  FMutex.ReleaseObjectFull;
end;

procedure tMngGameA.PauseOnly; begin
  FMutex.WaitForObjectFull;

  if FState = gsStarted then Paused;

  FMutex.ReleaseObjectFull;
end;

procedure tMngGameA.UnPauseOnly; begin
  FMutex.WaitForObjectFull;

  if FState = gsPaused then Started;

  FMutex.ReleaseObjectFull;
end;

procedure tMngGameA.Stop; begin
  FMutex.WaitForObjectFull;

  if FState <> gsStopped then Stopped;

  FMutex.ReleaseObjectFull;
end;

procedure tMngGameA.PlayPause; begin // дл€ навески на одну клавишу
  FMutex.WaitForObjectFull;

  if FState = gsStarted then Paused
  else begin
    if FState = gsStopped then BeforeStarted;
    Started;
  end;

  FMutex.ReleaseObjectFull;
end;

procedure tMngGameA.NewGame; begin
  FMutex.WaitForObjectFull;

  Stop;
  MngDraw.Clear;
  ClearTimeScoreEtc;
  
  FMutex.ReleaseObjectFull;
end;

procedure tMngGameA.ClearTimeScoreEtc; begin
  FTime:=0;
  FScores:=0
end;

procedure tMngGameA.BeforeStarted; begin
  MngDraw.Clear;
  ClearTimeScoreEtc
end;

procedure tMngGameA.Started; begin
  Randomize;
  VerifyGameOptions;

  FTimeSession:=Now;
  FState:=gsStarted;

  SetGameFormCaption;
  log(Format(log_game_StateChange, [log_game_Start, tolog_GameInfo]));
  OnControl(self, ctrl_game_obj_GameLoop);
end;

procedure tMngGameA.Paused; begin
  FTime:=GetTime;
  FState:=gsPaused;

  FreeGameObjectMouse;

  SetGameFormCaption;
  log(Format(log_game_StateChange, [log_game_Pause, tolog_GameInfo]));
  Draw
end;

procedure tMngGameA.Stopped; begin
  FTime:=GetTime;
  FState:=gsStopped;

  FActiveGameObject:=-1;
  FreeGameObjectMouse;
  FNextGameObjects.Clear;
  FGameObjects.Clear;
  MngDraw.UnLock(self);

  SetGameFormCaption;
  if AToLog then begin
    log(Format(log_game_StateChange, [log_game_Stop, tolog_GameInfo]));
    Draw;
  end
end;

function tMngGameA.GetTime; begin
  if FState = gsStarted then Result:=FTime + Now - FTimeSession
  else Result:=FTime;
end;

function tMngGameA.GameTimeToStr; begin
  Result:=TimeToStr(GetTime)
end;

function tMngGameA.GameScoreToStr; begin
  Result:=IntToStr(round(FScores))
end;

function tMngGameA.ScoreEnabled; begin
  Result:=true;
end;

procedure tMngGameA.FreeGameObjectMouse; begin
  if FGameObjectMouse <> nil then begin
    FGameObjectMouse.Free;
    FGameObjectMouse:=nil
  end;
end;

procedure tMngGameA.OnGameFormHActivate; begin
  if AMessage.Active = WA_INACTIVE then begin
    PauseOnly;
    FCursorPos.X:=-1;
    FCursorPos.Y:=-1;
    Draw;
  end;
  if Assigned(FSaveOnGameFormHAactivate) then FSaveOnGameFormHAactivate(ASender, AMessage)
end;

procedure tMngGameA.OnGameFormPaint; begin
  __Draw
end;

procedure tMngGameA.OnMainFormNCHITTEST;
const FPrev: integer = -1;
var
  i   : integer;
  c   : boolean;
  curs: tCursor;
begin
  with AMessage, GameForm do begin
    FCursorPos.X:=XPos;
    FCursorPos.Y:=YPos;
    FCursorPos:=ScreenToClient(FCursorPos);
    c:=MngProject.MngControl.FindRectConrol(FCursorPos.X, FCursorPos.Y, i);

    if mf_NChitTest and (FCursorPos.Y >= 0) and
       (State <> gsStarted) and not c then Result:=htCaption;

    curs:=Cursor;
    if c then Cursor:=crHandPoint
    else Cursor:=crDefault;
    if (show_ControlFontColorLight <> clNone) and ((Cursor <> curs) or (c and (FPrev <> i))) then Draw;
    FPrev:=i
  end;
end;

procedure tMngGameA.MngControlMouseEvent;
var r: tRect;

  procedure _tocell(var A: integer; AMin, ACellCount: integer); begin
    if A >= AMin then begin
      A:=(A - AMin) div g_CellSize;
      if A >= ACellCount then A:=-1
    end
    else A:=-1
  end;

begin
  r:=GetGameDrawRect;

  _tocell(AX, r.Left, g_ColCount);
  _tocell(AY, r.Top, g_RowCount);

  if AAction = maUp then begin
    _tocell(AX2, r.Left, g_ColCount);
    _tocell(AY2, r.Top, g_RowCount);
  end;

  FControlProcessing.PostControl(
    tControlItem.Create(ctrl_game_MouseEvent,
                        tControlDataMouse.Create(AAction, AY, AX, AY2, AX2, AButton, AShift)))
end;

function tMngGameA.VrfBoardBackImageShift;
var
  x, y: integer;
  bm  : tBitMap;
begin
  if g_BackImageShift = go_bis_None then Result:=FBackImage
  else begin
    case g_BackImageShift of
      go_bis_Default: begin
        x:=ALeft mod FBackImage.Width;
        y:=ATop mod FBackImage.Height;
      end;
      else { go_bis_Value: } begin
        x:=g_BackImageShiftX mod FBackImage.Width;
        y:=g_BackImageShiftY mod FBackImage.Height;
      end
    end;

    x:=FBackImage.Width - x;
    y:=FBackImage.height - y;

    if (FBoardBackImageShiftX <> x) or (FBoardBackImageShiftY <> y) then begin
      FBoardBackImageShiftX:=x;
      FBoardBackImageShiftY:=y;

      bm:=tBitMap.Create;
      try
        with bm do begin
          Width:=FBackImage.Width + x;
          Height:=FBackImage.Height + y;
          Canvas.Brush.Style:=bsSolid;
          Canvas.Brush.Bitmap:=FBackImage;
          Canvas.FillRect(rect(x, y, Width, Height));

          FBackImageShift.Width:=FBackImage.Width;
          FBackImageShift.Height:=FBackImage.Height;

          BitBlt(FBackImageShift.Canvas.Handle, 0, 0, FBackImage.Width, FBackImage.Height,
                 Canvas.Handle, x, y, SRCCOPY);
        end
      finally
        bm.Free
      end
    end;

    Result:=FBackImageShift
  end
end;

procedure tMngGameA.ChangeBoardBackImageShift; begin
  FBoardBackImageShiftX:=-1;
  FBoardBackImageShiftY:=-1;
end;

procedure tMngGameA.SetBackImage;
var bm: tBitMap;
begin
  if not ABackImageFile.Empty then begin
    bm:=ABackImageFile;
    if ABackImageScaled = 0 then ABackImageScaled:=1; // 30.11.2018  
  end
  else
    if ABackImageVar <> 0 then begin
      bm:=MngProject.MngResource[Format(res_jpeg_Back, [ABackImageVar])];
      if ABackImageScaled = 0 then ABackImageScaled:=g_CellSize/res_BackCellSize; // 2017 - автоматическое масштабирование фона из ресурсов
    end
    else bm:=nil;

  if (bm = nil) or (ABackImageScaled = 1) then ABackImage.Assign(bm)
  else
    with ABackImage do begin
      Width:=round(bm.Width*ABackImageScaled);
      Height:=round(bm.Height*ABackImageScaled);
      Canvas.StretchDraw(rect(0, 0, Width, Height), bm);
    end;

  if ABackImage = FBackImage then ChangeBoardBackImageShift
end;

function tMngGameA.FindGameObject; begin
  Result:=false;
  AResultIndex:=0;
  while not Result and (AResultIndex < FGameObjects.Count) do begin
    Result:=FGameObjects[AResultIndex].ItIsYour(ARow, ACol, AIndex, AParam);
    if not Result then inc(AResultIndex)
  end;
end;

procedure tMngGameA.AddToVariablesConfig; begin
end;

procedure tMngGameA.VerifyGameOptions; begin
  FControlBuffers.DeleteAllControls;
  MngDraw.VrfGameGrid(g_RowCount, g_ColCount);
end;

function tMngGameA.CreateDefaultGameObject; begin
  Result:=nil
end;

function tMngGameA.IndexToGameObject; begin
  if AIndex = 0 then Result:=tGameObject.Create(self, 0, false)
  else Result:=nil
end;

function tMngGameA.GameObjectToIndex; begin
  if AGameObject is tGameObject then Result:=0
  else Result:=-1
end;

function tMngGameA.GameLoop;
var
  i, l, r   : integer;
  go, gonext: tGameObject;
begin
  Result:=true;

  if (FActiveGameObject <> -1) and not FGameObjects[FActiveGameObject].Live then begin
    // FControlBuffers.DeleteAllControls;
    l:=-1; r:=-1;

    for i:=0 to FGameObjects.Count - 1 do
      if FGameObjects[i].Live and FGameObjects[i].CanActive then
        if i < FActiveGameObject then l:=i
        else begin
          r:=i;
          break;
        end;

    if r <> -1 then FActiveGameObject:=r
    else FActiveGameObject:=l // даже если -1
  end;

  i:=FGameObjects.Count - 1;
  l:=0;
  while i >= 0 do begin
    if not FGameObjects[i].Live then begin
      FGameObjects.Delete(i);
      if (FActiveGameObject <> -1) and (i < FActiveGameObject) then dec(FActiveGameObject)
    end
    else
      if FGameObjects[i].CanActive then inc(l);

    dec(i)
  end;

  if l < g_GameObjectCanActiveMaxCount then begin

    if FNextGameObjects.Count = 0 then go:=CreateDefaultGameObject
    else begin
      go:=FNextGameObjects[0];
      with FNextGameObjects do begin
        OwnsObjects:=false;
        Delete(0);
        OwnsObjects:=true;
      end
    end;

    while FNextGameObjects.Count < g_NextGameObjectCount do begin
      gonext:=CreateDefaultGameObject;
      if gonext <> nil then FNextGameObjects.Add(gonext)
      else break
    end;

    r:=RunGameObject(go);
    if (FActiveGameObject = -1) and (r <> -1) and go.CanActive then FActiveGameObject:=r
  end;
end;

function tMngGameA.GameReaction; begin
  if FActiveGameObject = -1 then Result:=false
  else
    with FGameObjects[FActiveGameObject] do
      Result:=Live and OnControl(self, AControl);
end;

procedure tMngGameA.GameReactionA;
var
  i, j: integer;
  b   : boolean;
  c   : tIWControl;
  d   : tObject;
begin
  b:=false;

  if (FActiveGameObject <> -1) and
     ((FActiveGameObject >= FGameObjects.Count) or
      not FGameObjects[FActiveGameObject].Live or
      not FGameObjects[FActiveGameObject].CanActive) then FActiveGameObject:=-1;

  for i:=0 to FControlBuffers.Count - 1 do begin
    j:=0;
    while j < FControlBuffers[i].Count do begin
      c:=FControlBuffers[i][j];
      d:=FControlBuffers[i].Items[j].Data;

      FControlBuffers[i].Delete(j);

      if State = gsStarted then
        if c = ctrl_game_Stop then begin
          Stop;
          b:=false
        end
        else
          if c = ctrl_game_obj_Draw then b:=true else
          if c = ctrl_game_obj_GameLoop then b:=GameLoop or b else
          if c = ctrl_game_MouseEvent then b:=MouseReaction(tControlDataMouse(d)) or b else
          if GameReaction(c, d) then b:=true;
    end
  end;

  if b then Draw;
end;

function tMngGameA.MouseReaction; begin
  Result:=false
end;

function tMngGameA.RunGameObject; begin
  Result:=-1;
  if AObject <> nil then begin
    AObject.Run;
    if AObject.Live then Result:=FGameObjects.Add(AObject)
    else AObject.Free;
  end
end;

procedure tMngGameA.AddScores; begin
  if ScoreEnabled then FScores:=FScores + AScores;
end;

procedure tMngGameA.AddParams; begin
end;

procedure tMngGameA.GetGameFormSizes;
var _border: integer;
begin
  _border:=2*(byte(mf_BorderColor <> clNone) + byte(g_BorderColor <> clNone));
  AWidth:=g_ColCount*g_CellSize + 2*(mf_NothingSize + g_NothingSize) + mf_NothingSizeLeft + mf_NothingSizeRight + _border;
  AHeight:=g_RowCount*g_CellSize + 2*(mf_NothingSize + g_NothingSize) + mf_NothingSizeTop + mf_NothingSizeBottom + _border;
end;

function tMngGameA.GetGameDrawRect;
var _border, _l, _t: integer;
begin
  _border:=byte(mf_BorderColor <> clNone) + byte(g_BorderColor <> clNone);
  _l:=mf_NothingSize + mf_NothingSizeLeft + g_NothingSize + _border;
  _t:=mf_NothingSize + mf_NothingSizeTop + g_NothingSize + _border;

  Result:=rect(_l, _t, _l + g_ColCount*g_CellSize, _t + g_RowCount*g_CellSize)
end;

procedure tMngGameA.LockChangeGameForm; begin
  FLockChangeGameForm:=ALock;
  if not FLockChangeGameForm then ChangeGameForm
end;

procedure tMngGameA.ChangeGameForm;
var w, h: integer;
begin
  if not FLockChangeGameForm then
    with GameForm do begin
      Color:=mf_BackColor;
      GetGameFormSizes(w, h);
      ClientWidth:=w;
      ClientHeight:=h;

      SetBackImage(g_BackImage, g_BackImageScaled, FBackImageFile, FBackImage);
      SetBackImage(mf_BackImage, mf_BackImageScaled, FFormBackImageFile, FFormBackImage);

      Draw; // ?
      Console.NormalizeSize;
    end;
end;

function tMngGameA.canvas_TextWidthHeightA;
var
  _name: string;
  _size: integer;
  _style: tFontStyles;
begin
  if GameForm = nil then Result:=0
  else
    with GameForm, Canvas, Font do begin
      _name:=Name; // на вс€кслучай
      _size:=Size;
      _style:=Style;

      try
        Name:=AFontName;
        Size:=AFontSize;
        Style:=ByteToFontStyles(AFontStyle);

        if AWidth then Result:=TextWidth(MngProject.GetLngString(AText))
        else Result:=TextHeight(MngProject.GetLngString(AText));

      finally
        Name:=_name;
        Size:=_size;
        Style:=_style;
      end
    end
end;

function tMngGameA.canvas_TextWidth; begin
  Result:=canvas_TextWidthHeightA(AFontName, AFontSize, AFontStyle, AText, true);
end;

function tMngGameA.canvas_TextHeight; begin
  Result:=canvas_TextWidthHeightA(AFontName, AFontSize, AFontStyle, AText, false);
end;

procedure tMngGameA.Draw; begin
  GameForm.Invalidate
end;

procedure tMngGameA.__Draw;
var
  r_tmp, r_form, r_board: tRect;
  b                     : integer;
begin
  with GameForm, Canvas do begin
    r_form:=ClientRect;
    r_board:=GetGameDrawRect;

    if not FFormBackImage.Empty then __BarBitMap(Canvas, r_form, FFormBackImage);
    __Rectangle(Canvas, r_form, mf_BorderColor);

//    if not (((g_NothingSize = 0) and (g_BorderColor = clNone)) or
//            ((g_BorderColor = clNone) and (g_BackColor = mf_BackColor) and FFormBackImage.Empty)) then begin

      b:=byte(g_BorderColor <> clNone) + g_NothingSize;
      r_tmp:=rect(r_board.Left - b, r_board.Top - b, r_board.Right + b, r_board.Bottom + b);

      if g_BackColor <> clNone then __Bar(Canvas, r_tmp, g_BackColor, g_BorderColor)
      else __Rectangle(Canvas, r_tmp, g_BorderColor);
//    end;

    if not FBackImage.Empty then
      __BarBitMap(Canvas, r_board, VrfBoardBackImageShift(r_board.Left, r_board.Top));

    if show_BoardRect then r_tmp:=r_board
    else r_tmp:=r_form;

    if show_Enabled = sheBottom then begin
      __DrawInfo(r_tmp);
      __DrawNextGameObjects(r_tmp);
    end;

    if MngDraw <> nil then begin
      MngDraw.Draw(Canvas, r_board, g_CellSize);
      __DrawAfterMngDraw(Canvas, r_board)
    end;

    if show_Enabled = sheTop then begin
      __DrawInfo(r_tmp);
      __DrawNextGameObjects(r_tmp);
    end;
  end;
end;

function tMngGameA.GetDrawInfoString; begin
  Result:=true;

  if AString = info_Title then AString:=GameForm.Caption
  else
    if AString = info_Time then begin
      AString:=GameTimeToStr;
      if Copy(AString, 1, 3) = '00:' then Delete(AString, 1, 3);
    end
    else
      if AString = info_Scores then
        if ScoreEnabled then AString:=GameScoreToStr
        else
      else Result:=false
end;

procedure tMngGameA.__DrawInfo;

  procedure _dInfo(ARect: tRect; AShowType: integer; AInfo, AInfoStarted: string);
  var sl: tStringList;

    procedure _add(b_idx, e_idx: integer);
    var
      s, s_ctrl, sa: string;
      i, h, hmax,
      w, x, y_  : integer;
      y         : ^integer;
      b_ctrl,
      b_main    : boolean;
      fs, fs_   : tFontStyles;
    begin
      if AShowType <> shNone then begin
        if AShowType = shLeft then begin
          y:=@FShowY_Left;
          x:=ARect.Left + show_X
        end
        else begin
          y:=@FShowY_Right;
          x:=ARect.Right - show_X; // + 1;
        end;

        if b_idx > e_idx then inc(y^, show_VSpace)
        else begin
          hmax:=0;
          for i:=b_idx to e_idx do begin
            s:=lowerstr(sl[i]); // как-то радикальненько
            if length(s) = 0 then break; // хот€ этого тут и не может быть

            fs:=[];
            repeat
              sa:=Copy(s, 1, 2);
              fs_:=[];
              if sa = info_B then fs_:=[fsBold];
              if sa = info_U then fs_:=[fsUnderline];
              if sa = info_I then fs_:=[fsItalic];
              if fs_ <> [] then begin
                s:=Copy(s, 3, MaxInt);
                fs:=fs + fs_;
              end
            until fs_ = [];

            s_ctrl:=s;
            b_main:=GetDrawInfoString(s);

            if b_main then b_ctrl:=false
            else begin
              b_ctrl:=MngProject.MngControl.FindControl(s);
              if b_ctrl then s_ctrl:=s
              else
                if (s[1] <> ' ') and (s[length(s)] <> ' ') then begin // убрать эти проверки на пробелы, если будут разделители строк
                  s_ctrl:=DelSpace(s);
                  b_ctrl:=MngProject.MngControl.FindControl(s_ctrl);
                end;

              if b_ctrl then begin
                sa:=MngProject.GetLngString(s_ctrl);
                if not CompareStrFlags(sa, s_ctrl) then s:=sa;
              end
            end;

            with GameForm, Canvas do begin
              s:=DelRSpace(s); //

              if b_main or b_ctrl then begin
                Font.Name:=show_FontName;
                Font.Size:=show_FontSize;
                Font.Style:=ByteToFontStyles(show_FontStyle);

                if not b_ctrl then Font.Color:=show_FontColor;
              end
              else begin
                Font.Name:=show_TextFontName;
                Font.Size:=show_TextFontSize;
                Font.Style:=ByteToFontStyles(show_TextFontStyle);
                Font.Color:=show_TextFontColor;

                s:=MngProject.GetLngString(s);
              end;

              Font.Style:=Font.Style + fs;

              h:=__TextHeight(Canvas, s);
              w:=__TextWidth(Canvas, s);
              hmax:=max(hmax, h);

              y_:=y^ - h div 5;
              if AShowType = shRight then dec(x, w);

              if b_ctrl then begin
                MngProject.MngControl.AddRectControl(x, y_, w, h, s_ctrl);

                if (show_ControlFontColorLight <> clNone) and
                   (FCursorPos.X >= x) and (FCursorPos.X < x + w) and
                   (FCursorPos.Y >= y_) and (FCursorPos.Y < y_ + h) then
                  Font.Color:=show_ControlFontColorLight
                else
                  Font.Color:=show_ControlFontColor;
              end;

              __Text(Canvas, x, y_, s);

              if AShowType = shLeft then inc(x, w + show_HSpace)
              else dec(x, show_HSpace)
            end
          end;
          inc(y^, hmax);
        end
      end
    end;

  var
    s   : string;
    i, j: integer;
  begin
    if (State <> gsStarted) or (AInfoStarted = show_AnotherStr) then s:=AInfo
    else s:=AInfoStarted;

    if length(s) > 0 then begin
      sl:=tStringList.Create;
      StringToList(s, sl, show_Sep);

      i:=0;
      while i < sl.Count do begin
        j:=i;
        while (i < sl.Count) and (length(sl[i]) > 0) do inc(i);
        _add(j, i - 1);
        inc(i)
      end;

      sl.Free
    end
  end;

begin
  with GameForm, Canvas do begin
    FShowY_Left:=ARect.Top + show_Y;
    FShowY_Right:=ARect.Top + show_Y;

    MngProject.MngControl.ClearRectControls;
    _dInfo(ARect, shLeft, show_Left, show_LeftStarted);
    _dInfo(ARect, shRight, show_Right, show_RightStarted);
  end
end;

procedure tMngGameA.__DrawNextGameObjects;
var
  i, w, h, y: integer;
  j         : ^integer;
  r         : tRect;
begin
  if show_NextGameObjects = shLeft then j:=@FShowY_Left
  else j:=@FShowY_Right;

  ARect.Top:=j^ + byte(j^ > show_Y)*show_VSpace;
  inc(ARect.Left, show_X + show_NextGameObjectsHSpace);
  dec(ARect.Right, show_X + show_NextGameObjectsHSpace);

  r:=ARect;
  y:=0;

  if show_NextGameObjects <> shNone then
    for i:=0 to FNextGameObjects.Count - 1 do begin
      r:=ARect;
      inc(r.Top, y);

      FNextGameObjects[i].__DrawNext(GameForm.Canvas, ARect, true, w, h);
      inc(y, h);

      if show_NextGameObjects = shRight then ARect.Left:=ARect.Right - w + 1;
      FNextGameObjects[i].__DrawNext(GameForm.Canvas, ARect, false, w, h);

      inc(j^, h);
      inc(ARect.Top, h);
    end;

  inc(j^, y);
end;

procedure tMngGameA.__DrawAfterMngDraw; begin
end;

procedure tMngGameA.SetGameFormCaption;
var s: string;
begin
  if GameForm <> nil then begin
    if not mf_CaptionLive or (FState = gsStarted) then SetLength(s, 0) else
    if FState = gsPaused then s:=caption_Paused else
    if FTime > 0 then s:=caption_GameOver
    else s:=caption_NewGame;

    if length(s) = 0 then s:=ProjectTitle
    else s:=Format(caption_Format, [ProjectTitle, s]);

    // GameForm.Caption что-то приглючивает при GameObject -> GameStop
    SendMessage(GameForm.Handle, WM_SETTEXT, 0, integer(pChar(s)))
  end
end;

function tMngGameA.GetSaveTitle; begin
  Result:=Format(save_Title, [ProjectTitle])
end;

function tMngGameA.SaveGameToConfig;
var
  gs : tGameSave;
  crc: longword;
  s  : string;
begin
  FMutex.WaitForObjectFull;

  PauseOnly;
  gs:=tGameSave.Create;
  try
    s:=GetSaveTitle;
    gs.Write(s[1], length(s));
    gs.Save(save_Version);

    SaveConfig(gs, AEx);
    SaveGame(gs);
    crc:=HashCRC32(gs);
    XorSteam(gs, length(s));
    gs.Save(crc);

    try
      gs.SaveToFile(AFileName);
      Result:=true;
    except
      Result:=false
    end;

    if Result then log(Format(ms_var_Save, [AFileName]))
    else log_err(Format(ms_var_ErrorSave, [AFileName]));

  finally
    gs.Free
  end;

  FMutex.ReleaseObjectFull;
end;

function tMngGameA.LoadGameFromConfig;
var
  gs      : tGameSave;
  crc     : longword;
  s, sver : string;
  lenTitle: integer;
begin
  FMutex.WaitForObjectFull;

  Result:=FileExists(AFileName);
  if Result then begin

    gs:=tGameSave.Create;
    try
      try
        lenTitle:=length(GetSaveTitle);

        gs.LoadFromFile(AFileName);
        gs.Seek(gs.Size - 4, soFromBeginning);
        gs.Load(crc);
        gs.Size:=gs.Size - 4;
        XorSteam(gs, lenTitle);

        Result:=(gs.Size >= lenTitle) and (crc = HashCRC32(gs));

        gs.Seek(0, soFromBeginning);
        SetLength(s, lenTitle);
        gs.Read(s[1], lenTitle);
        Result:=s = GetSaveTitle;

        if Result then begin
          gs.Load(sver);
          Result:=sver = save_Version;
        end;

      except
        Result:=false;
      end;

      if Result then begin
        Stop;
        log(Format(ms_var_Load, [AFileName]));
        LoadConfig(gs);
        LoadGame(gs);
        SetGameFormCaption;
        Draw
      end

    finally
      gs.Free
    end
  end;

  if not Result then log_err(Format(ms_var_ErrorLoad, [AFileName]));

  FMutex.ReleaseObjectFull;
end;

procedure tMngGameA.SaveGame; begin
  with ASave do begin
    Save(byte(FState));
    Save(FScores);
    Save(FTime);

    MngDraw.Save(ASave);

    Save(FActiveGameObject);
    FGameObjects.Save(ASave, self);
    FNextGameObjects.Save(ASave, self);
  end
end;

procedure tMngGameA.LoadGame; begin
  with ASave do begin
    Load(byte(FState));
    Load(FScores);
    Load(FTime);

    MngDraw.Load(ASave, g_RowCount, g_ColCount);

    Load(FActiveGameObject);
    FGameObjects.Load(ASave, self);
    FNextGameObjects.Load(ASave, self);
  end
end;

procedure tMngGameA.SaveConfig;
var
  sl: tStringList;
  i : integer;
begin
  with ASave do begin
    Save(ANeed);

    if ANeed then begin
      sl:=tStringList.Create;
      try
        Variables.GetConfigsStrings(sl);

        i:=0;
        while i < sl.Count do
          if (Pos(cfg_ctrl_begin, sl[i]) = 1) or
             (Pos(cfg_ctrl_bindSign, sl[i]) = 1) or
             (Pos(Format(cfg_ctrl_SignA, [vn_con_History]), sl[i]) = 1) then sl.Delete(i)
          else inc(i);

        Save(sl)
      finally
        sl.Free
      end
    end
  end
end;

procedure tMngGameA.LoadConfig;
var
  b : boolean;
  sl: tStringList;
begin
  with ASave do begin
    Load(b);

    if b then begin
      sl:=tStringList.Create;
      try
        Load(sl);
        MngProject.Exec(sl);
      finally
        sl.Free
      end
    end
  end
end;

class function tMngGameA.ParseLanguage; begin
  try
    with AIni do begin
      log_game_Start         := ReadString(ini_main, 'log_game_Start', log_game_Start);
      log_game_Pause         := ReadString(ini_main, 'log_game_Pause', log_game_Pause);
      log_game_Stop          := ReadString(ini_main, 'log_game_Stop', log_game_Stop);

      log_game_GameInfoTime  := ReadString(ini_main, 'log_game_GameInfoTime', log_game_GameInfoTime);
      log_game_GameInfoScore := ReadString(ini_main, 'log_game_GameInfoScore', log_game_GameInfoScore);

      caption_Paused         := ReadString(ini_main, 'caption_Paused', caption_Paused);
      caption_GameOver       := ReadString(ini_main, 'caption_GameOver', caption_GameOver);
      caption_NewGame        := ReadString(ini_main, 'caption_NewGame', caption_NewGame);
    end;

    Result:=true;
  except
    Result:=false;
  end;
end;

initialization
  screen_Width:=Screen.WorkAreaWidth; // Screen.Width;
  screen_Height:=Screen.WorkAreaHeight; // Screen.Height;
  screen_Left:=Screen.WorkAreaLeft;
  screen_Top:=Screen.WorkAreaTop;
  screen_PPI:=Screen.PixelsPerInch;

  auto_CellSize:=min_max(round(auto_CellSize*Screen.Height/auto_StartHeight), g_CellSizeMin, g_CellSizeMax);

//  auto_FontSize:=round(auto_FontSize*screen_PPI/auto_StartPPI);
  auto_FontSize:=Screen.MenuFont.Size + 1;

  auto_SmallFontSize:=min_max(round(0.9*auto_FontSize), show_FontSizeMin, show_FontSizeMax);
  auto_FontSize:=min_max(auto_FontSize, show_FontSizeMin, show_FontSizeMax); // да, отдельно! сначала посчитать small, потом уже это!
end.

