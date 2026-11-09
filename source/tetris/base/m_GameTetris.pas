unit m_GameTetris;

interface

uses
  Windows, Classes, Graphics, IniFiles,
  i_classes,
  iwclasses, m_GameA, m_Draw, m_Color, save;

const
  g_BrickSpeed            : integer = 350;
  g_BrickDropSpeed        : integer = 10;
  g_BrickDropQuick        : boolean = true;

  g_QuadColor             : tColor = clWhite;
  g_QuadBorderColor       : tColor = clNone;
  g_QuadNothingSize       : integer = 1;
  g_QuadCountMin          : integer = 3;
  g_QuadCountMax          : integer = 5;

  g_WallColorEnabled      : boolean = true;
  g_WallColor             : tColor  = $AAAAAA;
  g_WallColorR            : tColor  = $AAAAAA;
  g_WallBorderColor       : tColor  = clNone;
  g_WallBorderColorR      : tColor  = clNone;

  g_QuadDieColorEnabled   : boolean = false;
  g_QuadDieColor          : tColor  = clYellow;
  g_QuadDieColorR         : tColor  = clWhite;
  g_QuadDieColorNone      : tColor  = clNone; // не регится в переменных - для прозрачных эффектов

    go_qds_Quick          = 0; // удаляет quad`ы на первый же tick таймера
    go_qds_Light          = 1; // подсвечивает на первый tick quad`ы, потом ждет g_QuadDieStyle1WaitParam tick`ов, после чего удаляет
    go_qds_Blink          = 2; // мигает g_QuadDieStyle2ParamCount раз по g_QuadDieStyle2ParamWait tick`ов
    go_qds_RunLine        = 3; // бежит слева-направо и подсвечивает quad`ы, потом опять бежит и очищает, потом удаляет
    go_qds_Crumble        = 4; // бежит слева-направо, подсвечивает quad`ы, осыпает col`ы постепенно
    go_qds_Max            = go_qds_Crumble;

  g_QuadDieStyle          : integer = go_qds_Blink;
  g_QuadDieStyle1ParamWait: integer = 10;
  g_QuadDieStyle2ParamCount: integer = 2;
  g_QuadDieStyle2ParamWait: integer = 5;
  g_QuadDieSpeed          : integer = 10;

    go_WallIndex          = 1; // тут все перепутано, но так уж исторически сложилось
    go_BrickIndex         = 2;
    go_ShowNextIndex      = 3;
    go_BrickParam         = 0; // только для тетриса, не для колрисов
    go_WallParam          = 1; // --"--
    go_ShowNextParam      = 4; // --"--
    go_QuadDieParam       : integer = 2;
    go_QuadDieClearParam  : integer = 3; // эмуляция невидимости

    go_QuadNothingSizeMax = 64;

    go_BrickSpeedMin      = 5;
    go_BrickSpeedMax      = 5000;
    go_QuadDieSpeedMax    = 200;

    go_QuadDieStyle1ParamWaitMax  = 200;
    go_QuadDieStyle2ParamWaitMax  = 100;
    go_QuadDieStyle2ParamCountMax = 10;

    go_QuadCountMaxGlobalMax = 16; // максимальное количество Quad`ов в Brick`е во всех видах тетриса
    go_ChanceMax             = 512;

  go_QuadCountMinMin       : integer = 3;
  go_QuadCountMaxMax       : integer = go_QuadCountMaxGlobalMax;

  go_QuadCountChance: array[0..go_QuadCountMaxGlobalMax] of integer =
    (0, 0, 0, 5, 60, 35, 10, 10, 5, 5, 4, 4, 3, 3, 2, 2, 1);

  g_QuadColorCount         : integer = 6;
  g_QuadDieMinCount        : integer = 4;

    go_QuadColorCountMin   : integer = 3;
    go_QuadColorCountMax   : integer = 16;
    go_QuadDieMinCountMin  : integer = 2;
    go_QuadDieMinCountMax  : integer = 16;

  g_QuadAloneDropEnabled   : boolean = true;
  g_KillLine               : boolean = true; // color tetris
  g_KillColors             : boolean = true; // --"--
  g_BrickRotateSkirting    : boolean = true;

    gpi_KillQuad = gpi_idxMin + 1; // game param indexs
    gpi_KillLine = gpi_idxMin + 2;


    go_tgqa_Ex             = -100; // такое константо для особенности rotate

var
  show_NextBrickNothingSize: integer = 1;
  show_NextBrickBorderColor: tColor = clNone;
  show_NextBrickColor      : tColor = $AAAAAA; // только для тетриса!

type
  tGameObjectQuadA = class(tGameObject)
    protected
      FDroped: boolean;

      function GetCanActive: boolean; override;
      function GetTimerInterval: cardinal; override;
      procedure OnTimer; override;
      procedure GenerateQuads; virtual; abstract;
      procedure GenerateQuadsAdd; virtual; abstract;
      function CanToDrawCell(ARow, ACol: integer): tCanDrawResult; override;
      function CanMove(ARow, ACol, NRow, NCol: integer): tCanDrawResult; override;
      function InitScores: tScores; override;
      function RandomCount: integer;
      function StepOneScores: tScores; virtual;

    public
      constructor Create(AMngGame: tMngGameA; ACellIndex: cellint; ATimerUse: boolean);
      procedure Save(ASave: tGameSave); override;
      procedure Load(ASave: tGameSave); override;
      procedure Run(AData: tObject = nil); override;
      procedure Stop; override;
      function OnControl(ASender: tObject; AControl: tIWControl): boolean; override;
      procedure __DrawNext(ACanvas: tCanvas; ARect: tRect; ACalc: boolean; var AWidth, AHeight: integer); override;
      procedure Drop;
  end;

  tGameObjectQuadTetrisA = class(tGameObjectQuadA)
    protected
      FPowerRow,
      FPowerCol: integer;

      procedure GenerateQuads; override;
      procedure GenerateQuadsAdd; override;
      function GetQuadParam: cellint; virtual; abstract;
      function Rotate(ASide: shortint): boolean;

    public
      procedure Save(ASave: tGameSave); override;
      procedure Load(ASave: tGameSave); override;
      function Move(ADRow, ADCol: integer): tCanDrawResult; override;
      function OnControl(ASender: tObject; AControl: tIWControl): boolean; override;
  end;

  tGameObjectQuadTetris = class(tGameObjectQuadTetrisA)
    protected
      function GetQuadParam: cellint; override;

    public
      procedure Stop; override;
      procedure __DrawNext(ACanvas: tCanvas; ARect: tRect; ACalc: boolean; var AWidth, AHeight: integer); override;
  end;

  tGameObjectQuadTetrisColor = class(tGameObjectQuadTetrisA)
    protected
      function GetQuadParam: cellint; override;
      function InitScores: tScores; override;
  end;

  tGameObjectQuadColris = class(tGameObjectQuadA)
    protected
      procedure GenerateQuads; override;
      procedure GenerateQuadsAdd; override;
      function InitScores: tScores; override;
      function Shift(ASide: shortint): boolean;

    public
      function OnControl(ASender: tObject; AControl: tIWControl): boolean; override;
  end;



  tGameObjectQuadDieA = class(tGameObject)
    protected
      FStyle,
      FIdxNext,
      FIdxPrev: integer;

      function GetTimerInterval: cardinal; override;
      procedure OnTimer; override;
      function FindSpareQuads: boolean; virtual; abstract;

    public
      constructor Create(AMngGame: tMngGameA; AStyle: integer; ATimerUse: boolean);
      procedure Save(ASave: tGameSave); override;
      procedure Load(ASave: tGameSave); override;
      procedure Run(AData: tObject = nil); override;
      procedure Stop; override;
  end;

  tGameObjectQuadDieTetris = class(tGameObjectQuadDieA)
    protected
      FKillLine: integer;

      function FindSpareQuads: boolean; override;

    public
      constructor Create(AMngGame: tMngGameA; AStyle: integer; ATimerUse: boolean);
      procedure Save(ASave: tGameSave); override;
      procedure Load(ASave: tGameSave); override;
      procedure Stop; override;
  end;

  tGameObjectQuadDieColor = class(tGameObjectQuadDieA)
    protected
      function FindSpareQuads: boolean; override;
  end;

  tGameObjectQuadDieComplex = class(tGameObjectQuadDieTetris)
    protected
      function FindSpareQuads: boolean; override;
  end;



  tMngGameTetrisVarsRegisterA = class
    protected
      FMngGame: tMngGameA;

    public
      constructor Create(AMngGame: tMngGameA);

      procedure RegistryGameVars; virtual; abstract;
      function VrfGameVars(PtrValue: pointer): boolean; virtual;
  end;

  tMngGameTetrisVarsRegisterNoColor = class(tMngGameTetrisVarsRegisterA)
    public
      procedure RegistryGameVars; override;
      function VrfGameVars(PtrValue: pointer): boolean; override;
  end;

  tMngGameTetrisVarsRegisterColor = class(tMngGameTetrisVarsRegisterA)
    public
      procedure RegistryGameVars; override;
      function VrfGameVars(PtrValue: pointer): boolean; override;
  end;



  tMngGameTetrisA = class(tMngGameA)
    protected
      FMngGameTetrisVarsRegister: tMngGameTetrisVarsRegisterA;
      FKillQuad                 : integer;

      procedure GetGameFormSizes(var AWidth, AHeight: integer); override;
      function GetGameDrawRect: tRect; override;

      function tolog_GameInfo: string; override;
      procedure ClearTimeScoreEtc; override;
      function GameLoop: boolean; override;
      procedure AddToVariablesConfig(AList: tStringList); override;
      procedure InitGameVars; override;

      procedure RegistryGameVars; override;
      function VrfGameVars(PtrValue: pointer): boolean; override;

      function CreateMngGameTetrisVarsRegister: tMngGameTetrisVarsRegisterA; virtual; abstract;

      procedure g_QuadCountChance(AQuadCount, AChance: integer);
      procedure g_QuadCountChanceList;

      function CreateGameObjectQuadDie: tGameObjectQuadDieA; virtual; abstract;
      function GameObjectToIndex(AGameObject: tGameObject): integer; override;

      function GetDrawInfoString(var AString: string): boolean; override;
      procedure SaveGame(ASave: tGameSave); override;
      procedure LoadGame(ASave: tGameSave); override;

    public
      constructor Create;
      destructor Destroy; override;

      class function ParseLanguage(AIni: tIniFile): boolean; override;
      class procedure tolog_MainInfoGame; override;
      procedure AddParams(AIndex: integer; AParams: array of const); override;
  end;



  tMngGameTetrisA_ = class(tMngGameTetrisA)
    protected
      FKillLine: integer;

      function tolog_GameInfo: string; override;
      procedure ClearTimeScoreEtc; override;
      procedure RegistryGameVars; override;
      procedure InitGameVars; override;
      procedure InitGameVars2; override;

      function GetDrawInfoString(var AString: string): boolean; override;
      procedure SaveGame(ASave: tGameSave); override;
      procedure LoadGame(ASave: tGameSave); override;

    public
      procedure AddParams(AIndex: integer; AParams: array of const); override;
  end;



  tMngGameTetris = class(tMngGameTetrisA_)
    protected
      procedure InitGameVars; override;
      function IndexToGameObject(AIndex: integer): tGameObject; override;
      function CreateDefaultGameObject: tGameObject; override;
      function CreateGameObjectQuadDie: tGameObjectQuadDieA; override;
      function CreateMngGameTetrisVarsRegister: tMngGameTetrisVarsRegisterA; override;

    public
      constructor Create;
  end;



  tMngGameCrazyTetris = class(tMngGameTetris)
  end;



  tMngGameColorTetris = class(tMngGameTetrisA_)
    protected
      procedure RegistryGameVars; override;
      procedure InitGameVars; override;
      function IndexToGameObject(AIndex: integer): tGameObject; override;
      function CreateMngGameTetrisVarsRegister: tMngGameTetrisVarsRegisterA; override;
      function CreateDefaultGameObject: tGameObject; override;
      function CreateGameObjectQuadDie: tGameObjectQuadDieA; override;

    public
      constructor Create;
      class procedure tolog_MainInfoGame; override;
  end;



  tMngGameColris = class(tMngGameTetrisA)
    protected
      procedure RegistryGameVars; override;
      procedure InitGameVars; override;
      procedure InitGameVars2; override;
      function IndexToGameObject(AIndex: integer): tGameObject; override;
      function CreateDefaultGameObject: tGameObject; override;
      function CreateGameObjectQuadDie: tGameObjectQuadDieA; override;
      function CreateMngGameTetrisVarsRegister: tMngGameTetrisVarsRegisterA; override;

    public
      constructor Create;
      class procedure tolog_MainInfoGame; override;
  end;

implementation

uses
  SysUtils, math,
  pc,
  vars, misc, c_strings, main;


  
constructor tGameObjectQuadA.Create; begin
  inherited Create(AMngGame, ACellIndex, ATimerUse);
  if ATimerUse then GenerateQuads; // это проверка для Load
end;

procedure tGameObjectQuadA.Save; begin
  ASave.Save(FDroped);
  inherited Save(ASave);
end;

procedure tGameObjectQuadA.Load; begin
  ASave.Load(FDroped);
  inherited Load(ASave);
end;

procedure tGameObjectQuadA.Run; begin
  FDroped:=false;

  if (AData <> nil) and (AData is tElementList) then FElements.Assign(tElementList(AData));
  if FElements.Count = 0 then GenerateQuads;

  GenerateQuadsAdd;

  if CellEmptyAll then begin
    ToDraw;
    inherited;
  end
  else begin
    FElements.Clear;
    FLive:=false;
    FMngGame.OnControl(self, ctrl_game_Stop);
  end;
end;

function tGameObjectQuadA.StepOneScores; begin
  Result:=0.5
end;

function tGameObjectQuadA.InitScores; begin
  Result:=FElements.Count + (FMngGame.MngDraw.RowCount - 1)*StepOneScores
  // вместо FElements.Count можно inherited сделать
end;

function tGameObjectQuadA.GetCanActive; begin
  Result:=true
end;

function tGameObjectQuadA.GetTimerInterval; begin
  Result:=g_BrickSpeed
end;

function tGameObjectQuadA.CanToDrawCell; begin
  Result:=inherited CanToDrawCell(ARow, ACol);

  if Result <> cdrYes then
    with FMngGame.MngDraw.Cell[ARow, ACol] do

      if (Index = go_BrickIndex) or (Param = go_QuadDieParam) or (Param = go_QuadDieClearParam) then
        Result:=cdrWait
      else
        Result:=cdrNo
end;

function tGameObjectQuadA.CanMove; begin
  with FMngGame.MngDraw do
    if not (NCol in [0..ColCount - 1]) or (NRow >= RowCount) then Result:=cdrNo
    else
      Result:=inherited CanMove(ARow, ACol, NRow, NCol);
end;

procedure tGameObjectQuadA.Stop; begin
  FLive:=false; // на всякслучай
  ToDraw(go_WallIndex);
  inherited;
end;

procedure tGameObjectQuadA.OnTimer; begin
  case Move(1, 0) of
    cdrYes: begin
      if not FDroped then FScores:=FScores - StepOneScores;
      inherited OnTimer;
    end;
    cdrNo: Stop;
    // cdrWait - то ничего не делать
  end
end;

procedure tGameObjectQuadA.__DrawNext;
var i: cellint;
begin
  i:=FCellIndex;
  FCellIndex:=go_ShowNextIndex;
  inherited __DrawNext(ACanvas, ARect, ACalc, AWidth, AHeight);
  FCellIndex:=i
end;

procedure tGameObjectQuadA.Drop;
var cdr: tCanDrawResult;
begin
  FDroped:=not FDroped;

  if not FDroped then FTimer.Interval:=GetTimerInterval
  else begin

    if g_BrickDropQuick then begin
      repeat
        cdr:=Move(1, 0)
      until cdr <> cdrYes;

      if cdr = cdrNo then Stop
      else FMngGame.OnControl(self, ctrl_game_obj_Draw)
    end;

    if FLive then FTimer.Interval:=g_BrickDropSpeed
  end
end;

function tGameObjectQuadA.RandomCount: integer;
var i, b, e, c: integer;
begin
  b:=min(g_QuadCountMin, g_QuadCountMax);
  e:=max(g_QuadCountMin, g_QuadCountMax);
  c:=0;
  for i:=b to e do inc(c, go_QuadCountChance[i]);

  if c <= 0 then Result:=-1
  else begin
    i:=random(c);
    c:=0;
    Result:=b;
    repeat
      inc(c, go_QuadCountChance[Result]);
      if c < i then inc(Result)
    until (c >= i) or (Result = e);
  end;

  if (Result < b) or (Result > e) then Result:=g_QuadCountMin + random(e - b + 1);
end;

function tGameObjectQuadA.OnControl; begin
  Result:=inherited OnControl(ASender, AControl);

  if FLive then
    if AControl = ctrl_game_MoveRight then Result:=(Move(0, 1) = cdrYes) or Result else
    if AControl = ctrl_game_MoveLeft then Result:=(Move(0, -1) = cdrYes) or Result else
    if AControl = ctrl_game_Drop then Drop else
end;



procedure tGameObjectQuadTetrisA.Save; begin
  ASave.Save(FPowerRow);
  ASave.Save(FPowerCol);
  inherited Save(ASave)
end;

procedure tGameObjectQuadTetrisA.Load; begin
  ASave.Load(FPowerRow);
  ASave.Load(FPowerCol);
  inherited Load(ASave)
end;

procedure tGameObjectQuadTetrisA.GenerateQuads;
var
  il_res, il_next               : tRowColList;
  RowMax, RowMin, ColMax, ColMin: integer;

  procedure _add(rc: tRowCol);
  var
    i, j: integer;
    rcn : tRowCol;
  begin
    RowMax:=max(RowMax, rc.Row);
    RowMin:=min(RowMin, rc.Row);
    ColMax:=max(ColMax, rc.Col);
    ColMin:=min(ColMin, rc.Col);

    il_res.AddSorted(rc);
    for i:=0 to 3 do begin
      rcn:=tRowCol.Create(rc.Row + NeighbourCell[i].Row, rc.Col + NeighbourCell[i].Col);
      if not il_res.FindSorted(rcn, j) and
         not il_next.FindSorted(rcn, j) and
         (rcn.Col >= 0) and
         (rcn.Col < FMngGame.MngDraw.ColCount) then il_next.AddSorted(rcn)
      else rcn.Free
    end
  end;

var
  cnt_need, i, j: integer;
  rc            : tRowCol;
begin
  il_res:=tRowColList.Create;
  il_next:=tRowColList.Create;

  cnt_need:=RandomCount;
  RowMax:=0; RowMin:=MaxInt; ColMax:=0; ColMin:=MaxInt;
  _add(tRowCol.Create(0, FMngGame.MngDraw.ColCount div 2 - 1));

  while il_res.Count < cnt_need do begin
    i:=random(il_next.Count);
    rc:=tRowCol.Create(il_next[i].Row, il_next[i].Col);
    il_next.Delete(i);
    _add(rc);
  end;

  j:=(FMngGame.MngDraw.ColCount - (ColMax - ColMin + 1) + 1) div 2;

  FElements.Clear;
  for i:=0 to il_res.Count - 1 do
    FElements.Add(tElement.Create(il_res[i].Row - RowMax, il_res[i].Col  - (ColMin - j), GetQuadParam));

  il_next.Free;
  il_res.Free;
end;

procedure tGameObjectQuadTetrisA.GenerateQuadsAdd;
var
  power         : array of array of integer;
  i, j, k, r, c : integer;
  RowMax, RowMin,
  ColMax, ColMin: integer;
begin
  GetMinMaxs(RowMin, RowMax, ColMin, ColMax);

  if (FElements.Count in [3, 4]) and (ColMax - ColMin = 1) and (RowMax - RowMin = 1) then FPowerCol:=go_tgqa_Ex
  else begin
    RowMin:=RowMin - RowMax;
    RowMax:=0;

    SetLength(power, ColMax - ColMin + 1);
    for i:=ColMin to ColMax do SetLength(power[i - ColMin], RowMax - RowMin + 1);

    for i:=ColMin to ColMax do
      for j:=RowMin to RowMax do begin
        r:=0;
        c:=0;
        for k:=0 to FElements.Count - 1 do begin
          c:=c + i - FElements[k].Col;
          r:=r + j - FElements[k].Row;
        end;
        power[i - ColMin, j - RowMin]:=abs(c) + abs(r)
      end;

    k:=MaxInt;
    for i:=ColMin to ColMax do
      for j:=RowMin to RowMax do
        if power[i - ColMin, j - RowMin] < k then begin // еще можно добавить приоритет клетке с quad перед пустой
          k:=power[i - ColMin, j - RowMin];
          FPowerCol:=i;
          FPowerRow:=j;
        end
  end
end;

function tGameObjectQuadTetrisA.Move; begin
  Result:=inherited Move(ADRow, ADCol);

  if (Result = cdrYes) and (FPowerCol <> go_tgqa_Ex) then begin
    inc(FPowerRow, ADRow);
    inc(FPowerCol, ADCol);
  end
end;

function tGameObjectQuadTetrisA.Rotate;
const
  rotateex: array[-1..1] of array[0..3] of tRowColRec =
              (((row: 0; col: 1), (row: -1; col: 0), (row: 1; col: 0), (row: 0; col: -1)),
               ((row: 0; col: 0), (row: 0; col: 0), (row: 0; col: 0), (row: 0; col: 0)),
               ((row: 1; col: 0), (row: 0; col: 1), (row: 0; col: -1), (row: -1; col: 0)));

var
  i, j, rn, cn, rmin,
  rmax, cmin, cmax,
  cnmin, cnmax      : integer;
  il                : tIntegerList;
begin
  il:=tIntegerList.Create;
  GetMinMaxs(rmin, rmax, cmin, cmax);

  cnmin:=MaxInt;
  cnmax:=-MaxInt;
  i:=0;
  while i < FElements.Count do begin

    with FElements[i] do
      if FPowerCol = go_tgqa_Ex then begin // некрасива зато ибо!
        if Col = cmin then
          if Row = rmin then j:=0 else j:=1
        else
          if Row = rmin then j:=2 else j:=3;

        rn:=Row + rotateex[ASide, j].row;
        cn:=Col + rotateex[ASide, j].col;
      end
      else begin
        rn:=ASide*FPowerCol - ASide*Col + FPowerRow;
        cn:=ASide*Row - ASide*FPowerRow + FPowerCol;
      end;

    cnmin:=min(cnmin, cn);
    cnmax:=max(cnmax, cn);
    il.Add(rn);
    il.Add(cn);

    inc(i);
  end;

  j:=0;

  with FMngGame.MngDraw do
    if (cnmin < 0) and (cnmax >= ColCount) then Result:=false
    else begin

      if g_BrickRotateSkirting then
        if cnmin < 0 then j:=-cnmin
        else
          if cnmax >= ColCount then j:=ColCount - cnmax - 1;

      Result:=true;
      i:=0;
      while Result and (i < FElements.Count) do begin
        rn:=il[i shl 1];
        cn:=il[i shl 1 + 1] + j;
        Result:=(InDraw(rn, cn) and (CanToDrawCell(rn, cn) = cdrYes)) or
                ((cn >= 0) and (cn < ColCount) and (rn < 0));
        inc(i)
      end
    end;

  if Result then begin
    FromDraw;

    for i:=0 to FElements.Count - 1 do
      with FElements[i] do begin
        Row:=il[i shl 1];
        Col:=il[i shl 1 + 1] + j;
      end;

    if FPowerCol <> go_tgqa_Ex then inc(FPowerCol, j);

    ToDraw
  end;

  il.Free;




{
  il:=tIntegerList.Create;
  GetMinMaxs(rmin, rmax, cmin, cmax);

  Result:=true;
  i:=0;
  while Result and (i < FElements.Count) do
    with FElements[i] do begin

      if FPowerCol = go_tgqa_Ex then begin // некрасива зато ибо!
        if Col = cmin then
          if Row = rmin then j:=0 else j:=1
        else
          if Row = rmin then j:=2 else j:=3;

        rn:=Row + rotateex[ASide, j].row;
        cn:=Col + rotateex[ASide, j].col;
      end
      else begin
        rn:=ASide*FPowerCol - ASide*Col + FPowerRow;
        cn:=ASide*Row - ASide*FPowerRow + FPowerCol;
      end;

      with FMngGame.MngDraw do
        Result:=(InDraw(rn, cn) and (CanToDrawCell(rn, cn) = cdrYes)) or
                ((cn >= 0) and (cn < ColCount) and (rn < 0));

      if Result then begin
        il.Add(rn);
        il.Add(cn);

        inc(i);
      end
    end;

  if Result then begin
    FromDraw;

    for i:=0 to FElements.Count - 1 do
      with FElements[i] do begin
        Row:=il[i shl 1];
        Col:=il[i shl 1 + 1];
      end;

    ToDraw
  end;

  il.Free;
}
end;

function tGameObjectQuadTetrisA.OnControl; begin
  Result:=inherited OnControl(ASender, AControl);

  if FLive then
    if AControl = ctrl_game_RotateRight then Result:=Rotate(-1) or Result else
    if AControl = ctrl_game_RotateLeft then Result:=Rotate(1) or Result else
end;



function tGameObjectQuadTetris.GetQuadParam; begin
  Result:=go_BrickParam
end;

procedure tGameObjectQuadTetris.Stop; begin
  FElements.ChangeParams(go_WallParam);
  inherited
end;

procedure tGameObjectQuadTetris.__DrawNext;
var p: cellint;
begin
  if FElements.Count = 0 then begin
    AWidth:=0;
    AHeight:=0;
  end
  else
    if ACalc then inherited __DrawNext(ACanvas, ARect, ACalc, AWidth, AHeight)
    else begin
      p:=FElements[0].Param;
      FElements.ChangeParams(go_ShowNextParam);
      inherited __DrawNext(ACanvas, ARect, ACalc, AWidth, AHeight);
      FElements.ChangeParams(p);
    end
end;



function tGameObjectQuadTetrisColor.GetQuadParam; begin
  Result:=random(g_QuadColorCount)
end;

function tGameObjectQuadTetrisColor.InitScores; begin
  Result:=inherited InitScores + g_QuadColorCount - go_QuadColorCountMin
end;



procedure tGameObjectQuadColris.GenerateQuads;
var i, c: integer;
begin
  c:=RandomCount;
  FElements.Clear;
  for i:=0 downto -c + 1 do
    FElements.Add(tElement.Create(i, FMngGame.MngDraw.ColCount div 2, random(g_QuadColorCount)));

{ // тест цветов
  for i:=0 to 3 do
    for c:=0 to 3 do
      FElements.Add(tElement.Create(i + 1, c + 1, i*4 + c)); }
end;

procedure tGameObjectQuadColris.GenerateQuadsAdd; begin
end;

function tGameObjectQuadColris.InitScores; begin
  Result:=inherited InitScores + g_QuadColorCount - go_QuadColorCountMin
end;

function tGameObjectQuadColris.Shift;
var
  i: integer;
  p: cellint;
begin
  Result:=true;
  
  if ASide = -1 then begin
    p:=FElements[FElements.Count - 1].Param;
    for i:=FElements.Count - 1 downto 1 do FElements[i].Param:=FElements[i - 1].Param;
    FElements[0].Param:=p;
  end
  else begin
    p:=FElements[0].Param;
    for i:=0 to FElements.Count - 2 do FElements[i].Param:=FElements[i + 1].Param;
    FElements[FElements.Count - 1].Param:=p;
  end;

  ToDraw
end;

function tGameObjectQuadColris.OnControl; begin
  Result:=inherited OnControl(ASender, AControl);

  if FLive then
    if AControl = ctrl_game_ShiftUp then Result:=Shift(-1) or Result else
    if AControl = ctrl_game_ShiftDown then Result:=Shift(1) or Result else
end;



constructor tGameObjectQuadDieA.Create; begin
  FStyle:=AStyle;
  inherited Create(AMngGame, 0, ATimerUse);
end;

procedure tGameObjectQuadDieA.Save; begin
  ASave.Save(FStyle);
  ASave.Save(FIdxNext);
  ASave.Save(FIdxPrev);

  inherited Save(ASave)
end;

procedure tGameObjectQuadDieA.Load; begin
  ASave.Load(FStyle);
  ASave.Load(FIdxNext);
  ASave.Load(FIdxPrev);

  inherited Load(ASave)
end;

function tGameObjectQuadDieA.GetTimerInterval; begin
  Result:=g_QuadDieSpeed;
  if FStyle = go_qds_RunLine then Result:=round(Result*1.5); // Result:=Result shl 1  
end;

procedure tGameObjectQuadDieA.OnTimer;

  procedure CrumbleCol(ACol, ABeginIndex, AEndIndex: integer);
  var
    j, l, jaj  : integer;
    a          : array of integer;
    from_Wall,
    from_Empty,
    to_Wall,
    to_Empty   : boolean;
  begin
    with FMngGame.MngDraw do
      if ACol < ColCount then begin
        SetLength(a, RowCount);

        for j:=0 to RowCount - 1 do a[j]:=0;
        for j:=ABeginIndex to AEndIndex do
          with FElements[j] do begin
            if InDraw(Row, ACol) then ClearCell(Row, ACol);
            for l:=0 to Row - 1 do inc(a[l]);
          end;

        for j:=RowCount - 2 downto 0 do begin
          // двигать, если пусто или стена
          // если куда двигать пусто или стена, то двигать
          // если там не пусто или не стена, а двигается не пусто, то искать, что это там и делать ему Stop
          // если не двигать, но куда двигать - стена, то ClearCell

          jaj:=j + a[j];

          from_Wall:=Cell[j, ACol].Index = go_WallIndex;
          from_Empty:=CellEmpty[j, ACol];
          to_Wall:=Cell[jaj, ACol].Index = go_WallIndex;
          to_Empty:=CellEmpty[jaj, ACol];

          if from_Empty or from_Wall then begin
            if to_Empty or to_Wall then SetCell(jaj, ACol, Cell[j, ACol].Index, Cell[j, ACol].Param)
            else
              if from_Wall then begin
                if FMngGame.FindGameObject(ACol, jaj, Cell[jaj, ACol].Index, Cell[jaj, ACol].Param, l) then
                  with FMngGame.GameObjects[l] do
                    if Live then Stop;
                SetCell(jaj, ACol, Cell[j, ACol].Index, Cell[j, ACol].Param)
              end
          end
          else
            if to_Wall then ClearCell(jaj, ACol)

        end;

        for j:=0 to a[0] - 1 do
          if Cell[j, ACol].Index = go_WallIndex then ClearCell(j, ACol);
      end
  end;

  procedure CrumbleAll;
  var i, j: integer;
  begin
    i:=0;
    while i < FElements.Count do begin
      j:=i + 1;
      while (j < FElements.Count) and (FElements[i].Col = FElements[j].Col) do inc(j);
      CrumbleCol(FElements[i].Col, i, j - 1);
      i:=j;
    end;
  end;

  procedure SetCellAll(AParam: cellint);
  var i: integer;
  begin
    with FMngGame.MngDraw do
      for i:=0 to FElements.Count - 1 do
        with FElements[i] do
          if InDraw(Row, Col) then SetCell(Row, Col, go_WallIndex, AParam);
  end;

var
  n, i    : integer;
  StopNeed,
  DrawNeed: boolean;

begin
  StopNeed:=true;
  DrawNeed:=true;

  with FMngGame.MngDraw do

    case FStyle of
      go_qds_Quick: CrumbleAll;

      go_qds_Light: begin
        if (FIdxNext = 0) or (FIdxNext = g_QuadDieStyle1ParamWait) then begin
          if FIdxNext = 0 then n:=go_QuadDieParam
          else n:=go_QuadDieClearParam;
          SetCellAll(n)
        end
        else
          if FIdxNext >= g_QuadDieStyle1ParamWait + 1 then CrumbleAll
          else DrawNeed:=false;

        StopNeed:=FIdxNext >= g_QuadDieStyle1ParamWait + 1;
        inc(FIdxNext)
      end;

      go_qds_Blink: begin
        n:=-1;

        if FIdxNext mod (2*g_QuadDieStyle2ParamWait) = 0 then n:=go_QuadDieParam
        else
          if FIdxNext mod (2*g_QuadDieStyle2ParamWait) - g_QuadDieStyle2ParamWait = 0 then n:=go_QuadDieClearParam;

        if n <> -1 then SetCellAll(n)
        else DrawNeed:=false;

        i:=2*g_QuadDieStyle2ParamWait*g_QuadDieStyle2ParamCount; // (g_QuadDieStyle2ParamWait + 1)*(g_QuadDieStyle2ParamCount + 1);
        if FIdxNext >= i then begin
          CrumbleAll;
          DrawNeed:=true;
        end;

        StopNeed:=FIdxNext >= i;
        inc(FIdxNext);
      end;

      go_qds_RunLine: begin
        StopNeed:=false;

        n:=FIdxNext;
        while (FIdxNext < FElements.Count) and
          ((FElements[FIdxNext].Col = FElements[n].Col) or (FElements[FIdxNext].Col = FElements[n].Col + 1)) do

        begin
          if FIdxPrev = -1 then i:=go_QuadDieParam
          else i:=go_QuadDieClearParam;

          with FElements[FIdxNext] do
            if InDraw(Row, Col) then SetCell(Row, Col, go_WallIndex, i);

          inc(FIdxNext)
        end;

        if FIdxNext >= FElements.Count then begin
          inc(FIdxPrev);

          if FIdxPrev = 0 then FIdxNext:=0
          else
            if FIdxPrev > 1 then begin
              CrumbleAll;
              StopNeed:=true
            end
        end
      end;

      go_qds_Crumble: begin
        n:=FIdxNext;
        while (FIdxNext < FElements.Count) and (FElements[FIdxNext].Col = FElements[n].Col) do begin
          with FElements[FIdxNext] do
            if InDraw(Row, Col) then SetCell(Row, Col, go_WallIndex, go_QuadDieParam);

          inc(FIdxNext)
        end;

        if FIdxPrev <> -1 then
          CrumbleCol(FElements[FIdxPrev].Col, FIdxPrev, n - 1);

        FIdxPrev:=n;
        StopNeed:=FIdxPrev >= FElements.Count;
      end
    end;

  if DrawNeed then inherited OnTimer;
  if StopNeed then Stop
end;

procedure tGameObjectQuadDieA.Run; begin
  FLive:=(FElements.Count > 0) or FindSpareQuads;

  if FLive then begin
    FMngGame.MngDraw.Lock(self);

    FIdxNext:=0;
    FIdxPrev:=-1;

    inherited
  end
end;

procedure tGameObjectQuadDieA.Stop; begin
  FMngGame.MngDraw.UnLock(self);
  FMngGame.AddParams(gpi_KillQuad, [FElements.Count]);
  inherited
end;



constructor tGameObjectQuadDieTetris.Create; begin
  inherited Create(AMngGame, AStyle, ATimerUse);
  FKillLine:=0;
end;

function tGameObjectQuadDieTetris.FindSpareQuads;
var
  i, j: integer;
  b   : boolean;
begin
  with FMngGame.MngDraw do
    for i:=RowCount - 1 downto 0 do begin
      b:=true;
      j:=0;
      while b and (j < ColCount) do begin
        b:=Cell[i, j].Index = go_WallIndex;
        inc(j)
      end;
      if b then begin
        inc(FKillLine);
        for j:=0 to ColCount - 1 do
          FElements.Add(tElement.Create(i, j, 0))
      end
    end;

  Result:=FElements.Count > 0;
  if Result then FElements.Sort
end;

procedure tGameObjectQuadDieTetris.Stop; begin
  FMngGame.AddParams(gpi_KillLine, [FKillLine]);
  inherited
end;

procedure tGameObjectQuadDieTetris.Save; begin
  ASave.Save(FKillLine);
  inherited Save(ASave)
end;

procedure tGameObjectQuadDieTetris.Load; begin
  ASave.Load(FKillLine);
  inherited Load(ASave)
end;



function tGameObjectQuadDieColor.FindSpareQuads;
var
  el: tElementList;

  procedure _Spare(e: tElement);
  var rn, cn, i: integer;
  begin
    if not FElements.FindSorted(e, i) and not el.FindSorted(e, i) then begin
      el.AddSorted(e);

      with FMngGame.MngDraw do
        for i:=0 to 3 do begin
          rn:=e.Row + NeighbourCell[i].Row;
          cn:=e.Col + NeighbourCell[i].Col;

          if (rn >= 0) and (rn < RowCount) and
             (cn >= 0) and (cn < ColCount) and
             (Cell[rn, cn].Index = go_WallIndex) and
             (Cell[rn, cn].Param = e.Param) then _Spare(tElement.Create(rn, cn, e.Param))
        end
    end
    else e.Free
  end;

var i, j, k: integer;
begin
  el:=tElementList.Create;

  with FMngGame.MngDraw do
    for i:=RowCount - 1 downto 0 do
      for j:=0 to ColCount - 1 do
        if Cell[i, j].Index = go_WallIndex then begin
          el.Clear;
          _Spare(tElement.Create(i, j, Cell[i, j].Param));

          if el.Count >= g_QuadDieMinCount then
            for k:=0 to el.Count - 1 do
              FElements.AddSorted(tElement.Create(el[k].Row, el[k].Col, el[k].Param))
        end;

  el.Free;

  Result:=FElements.Count > 0;
end;



function tGameObjectQuadDieComplex.FindSpareQuads;
var
  go  : tGameObjectQuadDieA;
  i, j: integer;
begin
  if g_KillLine then inherited FindSpareQuads;

  if g_KillColors then begin
    go:=tGameObjectQuadDieColor.Create(FMngGame, 0, false);
    go.FindSpareQuads;

    for i:=0 to go.FElements.Count - 1 do
      if not FElements.FindSorted(go.FElements[i], j) then
        with go.FElements[i] do
          FElements.AddSorted(tElement.Create(Row, Col, Param));

    go.Free;
  end;

  Result:=FElements.Count > 0;
end;



constructor tMngGameTetrisVarsRegisterA.Create; begin
  inherited Create;
  FMngGame:=AMngGame;
end;

function tMngGameTetrisVarsRegisterA.VrfGameVars; begin
  Result:=true;

  if (PtrValue = @g_QuadDieColorEnabled) or (PtrValue = @g_QuadDieColor) then
    if g_QuadDieColorEnabled then g_QuadDieColorR:=g_QuadDieColor
    else g_QuadDieColorR:=g_QuadColor
end;

procedure tMngGameTetrisVarsRegisterNoColor.RegistryGameVars; begin
  with Variables do begin
    RegistryColor(vn_g_QuadColor, g_QuadColor, self, VrfGameVars);
    RegistryBoolean(vn_g_QuadDieColorEnabled, g_QuadDieColorEnabled, self, VrfGameVars);

    RegistryBoolean(vn_g_WallColorEnabled, g_WallColorEnabled, self, VrfGameVars);
    RegistryColor(vn_g_WallColor, g_WallColor, self, VrfGameVars);
    RegistryColor(vn_g_WallBorderColor, g_WallBorderColor, self, VrfGameVars);

    RegistryColor(vn_info_NextBrickColor, show_NextBrickColor, self, VrfGameVars);
  end;
end;

function tMngGameTetrisVarsRegisterNoColor.VrfGameVars; begin
  // замаялся я с проверками на переменные тут
  
  if g_WallColorEnabled then begin
    g_WallColorR:=g_WallColor;
    g_WallBorderColorR:=g_WallBorderColor;
  end
  else begin
    g_WallColorR:=g_QuadColor;
    g_WallBorderColorR:=g_QuadBorderColor;
  end;

  Result:=inherited VrfGameVars(PtrValue);

  FMngGame.ChangeGameForm
end;

procedure tMngGameTetrisVarsRegisterColor.RegistryGameVars; begin
  with Variables do begin
    RegistryColor(vn_g_WallBorderColor, g_WallBorderColorR, self, VrfGameVars);
    RegistryNatural(vn_g_QuadColorCount, g_QuadColorCount, self, VrfGameVars);
    RegistryNatural(vn_g_QuadDieMinCount, g_QuadDieMinCount, self, VrfGameVars);
  end
end;

function tMngGameTetrisVarsRegisterColor.VrfGameVars; begin
  if (PtrValue = @g_QuadColorCount) then
    Result:=(g_QuadColorCount >= go_QuadColorCountMin) and (g_QuadColorCount <= go_QuadColorCountMax)
  else
  if (PtrValue = @g_QuadDieMinCount) then
    Result:=(g_QuadDieMinCount >= go_QuadDieMinCountMin) and (g_QuadDieMinCount <= go_QuadDieMinCountMax)
  else begin
    Result:=inherited VrfGameVars(PtrValue);
    FMngGame.ChangeGameForm
  end
end;





constructor tMngGameTetrisA.Create; begin
  FMngGameTetrisVarsRegister:=CreateMngGameTetrisVarsRegister;

  inherited;

  MngDraw.AddCellObject(tCellBar.Create(FMngColor, g_WallBorderColorR, g_QuadNothingSize)); // валяющие кубы, index = 1
  MngDraw.AddCellObject(tCellBar.Create(FMngColor, g_QuadBorderColor, g_QuadNothingSize)); // падающие кубы, index = 2
  MngDraw.AddCellObject(tCellBar.Create(FMngColor, show_NextBrickBorderColor, show_NextBrickNothingSize)); // показ следующего куба
end;

destructor tMngGameTetrisA.Destroy; begin
  FMngGameTetrisVarsRegister.Free;
  inherited;
end;

function tMngGameTetrisA.tolog_GameInfo; begin
  Result:=Format(log_game_StateChange, [inherited tolog_GameInfo,
                 Format(log_game_tetris_KillQuad, [IntToStr(FKillQuad)])]);
end;

procedure tMngGameTetrisA.ClearTimeScoreEtc; begin
  inherited;
  FKillQuad:=0;
end;

class procedure tMngGameTetrisA.tolog_MainInfoGame; begin
  log(Format(iwg_by, [iwg_BetaTesting, iwg_People_Spectre + ' and ' + iwg_iwerg]));
end;

class function tMngGameTetrisA.ParseLanguage; begin
  try
    with AIni do begin
      log_game_tetris_KillQuad:=ReadString(ini_main, 'log_game_tetris_KillQuad', log_game_tetris_KillQuad);
      log_game_tetris_KillLine:=ReadString(ini_main, 'log_game_tetris_KillLine', log_game_tetris_KillLine);
    end;

    Result:=inherited ParseLanguage(AIni);
  except
    Result:=false;
  end;
end;

procedure tMngGameTetrisA.GetGameFormSizes; begin
  inherited GetGameFormSizes(AWidth, AHeight);

  dec(AWidth, g_QuadNothingSize);
  dec(AHeight, g_QuadNothingSize);
end;

function tMngGameTetrisA.GetGameDrawRect; begin
  Result:=inherited GetGameDrawRect;

  dec(Result.Right, g_QuadNothingSize);
  dec(Result.Bottom, g_QuadNothingSize);
end;

procedure tMngGameTetrisA.InitGameVars; begin
  inherited;

  g_NextGameObjectCount:=4;

  show_Left:=cfgr_info_Left + cfgr_info_TetrisNext;
  show_Right:=cfgr_info_Right;
end;

procedure tMngGameTetrisA.RegistryGameVars; begin
  inherited;

  with Variables do begin
    RegistryColor(vn_g_QuadBorderColor, g_QuadBorderColor, self, VrfGameVars);
    RegistryNatural(vn_g_QuadNothingSize, g_QuadNothingSize, self, VrfGameVars);
    RegistryNatural(vn_g_QuadCountMin, g_QuadCountMin, self, VrfGameVars);
    RegistryNatural(vn_g_QuadCountMax, g_QuadCountMax, self, VrfGameVars);

    RegistryColor(vn_g_QuadDieColor, g_QuadDieColor, self, VrfGameVars);
    RegistryNatural(vn_g_QuadDieSpeed, g_QuadDieSpeed, self, VrfGameVars);
    RegistryNatural(vn_g_QuadDieStyle, g_QuadDieStyle, self, VrfGameVars);
    RegistryNatural(vn_g_QuadDieStyle1ParamWait, g_QuadDieStyle1ParamWait, self, VrfGameVars);
    RegistryNatural(vn_g_QuadDieStyle2ParamWait, g_QuadDieStyle2ParamWait, self, VrfGameVars);
    RegistryNatural(vn_g_QuadDieStyle2ParamCount, g_QuadDieStyle2ParamCount, self, VrfGameVars);

    RegistryBoolean(vn_g_QuadAloneDropEnabled, g_QuadAloneDropEnabled);

    RegistryNatural(vn_g_BrickSpeed, g_BrickSpeed, self, VrfGameVars);
    RegistryNatural(vn_g_BrickDropSpeed, g_BrickDropSpeed, self, VrfGameVars);
    RegistryBoolean(vn_g_BrickDropQuick, g_BrickDropQuick);

    RegistryFunction(vn_g_QuadCountChance, @tMngGameTetrisA.g_QuadCountChance, self, vtVoid, [vtInteger, vtInteger]);
    RegistryFunction(vn_g_QuadCountChanceList, @tMngGameTetrisA.g_QuadCountChanceList, self, vtVoid, []);

    RegistryNatural(vn_info_NextBrickNothingSize, show_NextBrickNothingSize, self, VrfGameVars);
    RegistryColor(vn_info_NextBrickBorderColor, show_NextBrickBorderColor, self, VrfGameVars);
  end;

  RegistryNextGameVars(vn_info_NextBrick, vn_info_NextBrickCellSize, vn_info_NextBrickCount, vn_info_NextBrickHSpace);
  FMngGameTetrisVarsRegister.RegistryGameVars;

  with MngProject.MngControl do begin
    RegistryControl(self, ctrl_game_MoveLeft,  key_c_Left);
    RegistryControl(self, ctrl_game_MoveRight, key_c_Right);
    RegistryControl(self, ctrl_game_Drop,      key_c_Space);

    Bind(keyname_mouseleft, ctrl_game_MoveLeft);
    Bind(keyname_mouseright, ctrl_game_MoveRight);
    Bind(keyname_mousemiddle, ctrl_game_Drop);
  end;
end;

function tMngGameTetrisA.VrfGameVars; begin
  if (PtrValue = @g_QuadBorderColor) then Result:=FMngGameTetrisVarsRegister.VrfGameVars(@g_QuadBorderColor) else
  if (PtrValue = @g_QuadCountMin) or (PtrValue = @g_QuadCountMax) then Result:=integer(PtrValue^) in [go_QuadCountMinMin..go_QuadCountMaxMax] else
  if PtrValue = @g_QuadDieStyle then Result:=g_QuadDieStyle in [go_qds_Quick..go_qds_Max] else
  if PtrValue = @g_QuadDieStyle1ParamWait then Result:=g_QuadDieStyle1ParamWait in [1..go_QuadDieStyle1ParamWaitMax] else
  if PtrValue = @g_QuadDieStyle2ParamWait then Result:=g_QuadDieStyle2ParamWait in [1..go_QuadDieStyle2ParamWaitMax] else
  if PtrValue = @g_QuadDieStyle2ParamCount then Result:=g_QuadDieStyle2ParamCount in [1..go_QuadDieStyle2ParamCountMax] else
  if PtrValue = @g_QuadDieSpeed then Result:=g_QuadDieSpeed <= go_QuadDieSpeedMax else
  if (PtrValue = @g_BrickSpeed) or (PtrValue = @g_BrickDropSpeed) then
    Result:=(integer(PtrValue^) >= go_BrickSpeedMin) and (integer(PtrValue^) <= go_BrickSpeedMax)
  else
    if (PtrValue = @g_QuadNothingSize) or (PtrValue = @show_NextBrickNothingSize) then begin
      Result:=integer(PtrValue^) in [0..go_QuadNothingSizeMax];
      if Result then ChangeGameForm;
    end
    else
      if (PtrValue = @g_QuadDieColorEnabled) or (PtrValue = @g_QuadDieColor) then
        Result:=FMngGameTetrisVarsRegister.VrfGameVars(PtrValue)
      else
        Result:=inherited VrfGameVars(PtrValue)
end;

function tMngGameTetrisA.GameLoop;

  procedure _VrfAloneQuad;
  var
    Cells: tCell2D;

    procedure _AddCell(ARow, ACol: integer; AElements: tElementList);
    var i, rn, cn: integer;
    begin
      if Cells[ARow, ACol].Index = go_WallIndex then begin
        if AElements <> nil then AElements.Add(tElement.Create(ARow, ACol, Cells[ARow, ACol].Param));
        Cells[ARow, ACol].IndexL:=0;

        with MngDraw do
          for i:=0 to 3 do begin
            rn:=ARow + NeighbourCell[i].Row;
            cn:=ACol + NeighbourCell[i].Col;

            if (rn >= 0) and (rn < RowCount) and
               (cn >= 0) and (cn < ColCount) then _AddCell(rn, cn, AElements)
          end
      end
    end;

  var
    i, j, k: integer;
    got    : tGameObjectQuadTetrisA;
    el     : tElementList;
  begin
    if g_QuadAloneDropEnabled then
      with MngDraw do begin

        MngDraw.CopyCells(Cells);
        for i:=0 to ColCount - 1 do _AddCell(RowCount - 1, i, nil);

        el:=tElementList.Create;

        for i:=RowCount - 1 downto 0 do
          for j:=0 to ColCount - 1 do begin
            el.Clear;
            _AddCell(i, j, el);

            if el.Count > 0 then begin
              for k:=0 to el.Count - 1 do ClearCell(el[k].Row, el[k].Col);

              got:=tGameObjectQuadTetrisA(CreateDefaultGameObject);
              FGameObjects.Add(got);
              got.Run(el);
              got.Drop;
            end
          end;

        el.Free
      end;
  end;

begin
  Result:=inherited GameLoop;

  _VrfAloneQuad;
  if not MngDraw.Locked then RunGameObject(CreateGameObjectQuadDie)
end;

procedure tMngGameTetrisA.g_QuadCountChance; begin
  if (AQuadCount >= go_QuadCountMinMin) and
     (AQuadCount <= go_QuadCountMaxMax) and
     (AChance >= 0) and (AChance <= go_ChanceMax) then go_QuadCountChance[AQuadCount]:=AChance
  else log_err(Format(log_err_invalidarg, [vn_g_QuadCountChance]))
end;

procedure tMngGameTetrisA.g_QuadCountChanceList;
var i: integer;
begin
  for i:=go_QuadCountMinMin to go_QuadCountMaxMax do
    log(Format(log_game_QuadCountChanceList, [i, go_QuadCountChance[i]]))
end;

procedure tMngGameTetrisA.AddToVariablesConfig;
var i: integer;
begin
  inherited AddToVariablesConfig(AList);

  for i:=go_QuadCountMinMin to go_QuadCountMaxMax do
    AList.Add(Format(cfg_game_obj_QuadCountChance, [i, go_QuadCountChance[i]]))
end;

function tMngGameTetrisA.GameObjectToIndex; begin
  if AGameObject is tGameObjectQuadA then Result:=1 + go_idxMin
  else
    if AGameObject is tGameObjectQuadDieA then Result:=2 + go_idxMin
    else Result:=inherited GameObjectToIndex(AGameObject);
end;

procedure tMngGameTetrisA.SaveGame; begin
  ASave.Save(FKillQuad);
  inherited SaveGame(ASave);
end;

procedure tMngGameTetrisA.LoadGame; begin
  ASave.Load(FKillQuad);
  inherited LoadGame(ASave);
end;

procedure tMngGameTetrisA.AddParams; begin
  if AIndex = gpi_KillQuad then inc(FKillQuad, AParams[0].VInteger)
  else inherited AddParams(AIndex, AParams)
end;

function tMngGameTetrisA.GetDrawInfoString; begin
  Result:=inherited GetDrawInfoString(AString);

  if not Result then
    if AString = info_KillQuad then begin
      Result:=true;
      AString:=IntToStr(FKillQuad)
    end;
end;





procedure tMngGameTetrisA_.InitGameVars2; begin
  mf_NothingSizeRight:=3*show_X + Max(
    canvas_TextWidth(show_FontName, show_FontSize, show_FontStyle, 'gameplay'),
    canvas_TextWidth(show_FontName, show_FontSize, show_FontStyle, 'appearance')
  );

  mf_NothingSizeLeft:=3*show_X + Max(
    canvas_TextWidth(show_FontName, show_FontSize, show_FontStyle, '9999') +
    show_VSpace +
    canvas_TextWidth(show_TextFontName, show_TextFontSize, show_TextFontStyle, 'quads killed'),

    g_QuadCountMax*show_NextGameObjectsCellSize
  );
end;

procedure tMngGameTetrisA_.InitGameVars; begin
  inherited;

  g_RowCount:=22;
  g_ColCount:=12;

//  mf_NothingSizeLeft:=Max(mf_NothingSizeLeft, show_X + g_QuadCountMax*show_NextGameObjectsCellSize);
end;


function tMngGameTetrisA_.tolog_GameInfo; begin
  Result:=Format(log_game_StateChange, [inherited tolog_GameInfo,
                 Format(log_game_tetris_KillLine, [IntToStr(FKillLine)])]);
end;

procedure tMngGameTetrisA_.ClearTimeScoreEtc; begin
  inherited;
  FKillLine:=0;
end;

procedure tMngGameTetrisA_.RegistryGameVars; begin
  inherited;

  Variables.RegistryBoolean(vn_g_BrickRotateSkirting, g_BrickRotateSkirting);

  with MngProject.MngControl do begin
    RegistryControl(self, ctrl_game_RotateRight, key_c_Down);
    RegistryControl(self, ctrl_game_RotateLeft,  key_c_Up);

    Bind(keyname_mousewheeldown, ctrl_game_RotateRight);
    Bind(keyname_mousewheelup, ctrl_game_RotateLeft);
  end;
end;

procedure tMngGameTetrisA_.SaveGame; begin
  ASave.Save(FKillLine);
  inherited SaveGame(ASave);
end;

procedure tMngGameTetrisA_.LoadGame; begin
  ASave.Load(FKillLine);
  inherited LoadGame(ASave);
end;

procedure tMngGameTetrisA_.AddParams; begin
  if AIndex = gpi_KillLine then inc(FKillLine, AParams[0].VInteger)
  else inherited AddParams(AIndex, AParams)
end;

function tMngGameTetrisA_.GetDrawInfoString; begin
  Result:=inherited GetDrawInfoString(AString);

  if not Result then
    if AString = info_KillLine then begin
      Result:=true;
      AString:=IntToStr(FKillLine)
    end;
end;





constructor tMngGameTetris.Create; begin
  inherited;

  FMngColor.AddColor(g_QuadColor);
  FMngColor.AddColor(g_WallColorR);
  FMngColor.AddColor(g_QuadDieColorR);
  FMngColor.AddColor(g_QuadDieColorNone);
  FMngColor.AddColor(show_NextBrickColor);
end;

procedure tMngGameTetris.InitGameVars;
var s: string;
begin
  inherited;

  s:=show_Left;
  show_Left:=Format(s, [ctrl_Play, cfgr_info_Tetris2]);
  show_LeftStarted:=Format(s, [ctrl_Pause, cfgr_info_Tetris2]);
end;

function tMngGameTetris.CreateMngGameTetrisVarsRegister; begin
  Result:=tMngGameTetrisVarsRegisterNoColor.Create(self)
end;

function tMngGameTetris.CreateDefaultGameObject; begin
  Result:=tGameObjectQuadTetris.Create(self, go_BrickIndex, true);
end;

function tMngGameTetris.CreateGameObjectQuadDie; begin
  Result:=tGameObjectQuadDieTetris.Create(self, g_QuadDieStyle, true)
end;

function tMngGameTetris.IndexToGameObject; begin
  case AIndex of
    go_idxMin + 1: Result:=tGameObjectQuadTetris.Create(self, 0, false);
    go_idxMin + 2: Result:=tGameObjectQuadDieTetris.Create(self, 0, false);
    else Result:=inherited IndexToGameObject(AIndex)
  end
end;





{
function tMngGameCrazyTetris.CreateDefaultGameObject; begin
  // тут можно сечь, сколько уже наделано объектов и думать - надо ли
  // если не надо - nil
end;
}





constructor tMngGameColorTetris.Create; begin
  inherited;

  FMngColor.InitDefaultMainColors(vn_g_SetQuadColor, vn_g_QuadColorList, FMngGameTetrisVarsRegister.VrfGameVars);
  go_QuadDieParam:=FMngColor.AddColor(g_QuadDieColorR);
  go_QuadDieClearParam:=FMngColor.AddColor(g_QuadDieColorNone);
end;

class procedure tMngGameColorTetris.tolog_MainInfoGame; begin
  log(Format(iwg_by, [iwg_16QuadColors, iwg_people_Spectre]));
  inherited;
end;

procedure tMngGameColorTetris.RegistryGameVars; begin
  inherited;
  Variables.RegistryBoolean(vn_g_KillLine, g_KillLine);
  Variables.RegistryBoolean(vn_g_KillColors, g_KillColors)
end;

procedure tMngGameColorTetris.InitGameVars;
var s: string;
begin
  inherited;

  s:=show_Left;
  show_Left:=Format(s, [ctrl_Play, cfgr_info_Tetris1 + cfgr_info_Tetris2]);
  show_LeftStarted:=Format(s, [ctrl_Pause, cfgr_info_Tetris1 + cfgr_info_Tetris2]);

  g_BackImage:=4;
  g_QuadDieColor:=g_QuadColor; // cl_White;
  g_QuadDieColorEnabled:=true;
  g_QuadDieStyle:=go_qds_Light;
end;

function tMngGameColorTetris.CreateMngGameTetrisVarsRegister; begin
  Result:=tMngGameTetrisVarsRegisterColor.Create(self)
end;

function tMngGameColorTetris.CreateDefaultGameObject; begin
  Result:=tGameObjectQuadTetrisColor.Create(self, go_BrickIndex, true);
end;

function tMngGameColorTetris.CreateGameObjectQuadDie; begin
  Result:=tGameObjectQuadDieComplex.Create(self, g_QuadDieStyle, true);
end;

function tMngGameColorTetris.IndexToGameObject; begin
  case AIndex of
    go_idxMin + 1: Result:=tGameObjectQuadTetrisColor.Create(self, 0, false);
    go_idxMin + 2: Result:=tGameObjectQuadDieComplex.Create(self, 0, false);
    else Result:=inherited IndexToGameObject(AIndex)
  end
end;





constructor tMngGameColris.Create; begin
  inherited;

  FMngColor.InitDefaultMainColors(vn_g_SetQuadColor, vn_g_QuadColorList, FMngGameTetrisVarsRegister.VrfGameVars);
  go_QuadDieParam:=FMngColor.AddColor(g_QuadDieColorR);
  go_QuadDieClearParam:=FMngColor.AddColor(g_QuadDieColorNone);
end;

class procedure tMngGameColris.tolog_MainInfoGame; begin
  log(Format(iwg_by, [iwg_16QuadColors, iwg_people_Spectre]));
  inherited;
end;

function tMngGameColris.CreateMngGameTetrisVarsRegister; begin
  Result:=tMngGameTetrisVarsRegisterColor.Create(self)
end;

procedure tMngGameColris.InitGameVars2; begin
  mf_NothingSizeRight:=3*show_X + Max(
    canvas_TextWidth(show_FontName, show_FontSize, show_FontStyle, 'gameplay'),
    canvas_TextWidth(show_FontName, show_FontSize, show_FontStyle, 'appearance')
  );

  mf_NothingSizeLeft:=
    3*show_X +
    canvas_TextWidth(show_FontName, show_FontSize, show_FontStyle, '9999') +
    show_VSpace +
    canvas_TextWidth(show_TextFontName, show_TextFontSize, show_TextFontStyle, 'quads killed');
end;

procedure tMngGameColris.InitGameVars;
var s: string;
begin
  inherited;

  s:=show_Left;
  show_Left:=Format(s, [ctrl_Play, cfgr_info_Tetris1]);
  show_LeftStarted:=Format(s, [ctrl_Pause, cfgr_info_Tetris1]);

  g_ColCount:=9;
  g_RowCount:=18;

  g_BackImage:=4;

//  g_QuadBorderColor:=clWhite;
//  g_WallBorderColorR:=clWhite;
  g_QuadDieColor:=g_QuadColor; // cl_White;
  g_QuadDieColorEnabled:=true;
  g_QuadDieStyle:=go_qds_Blink;

  g_QuadCountMin:=3;
  g_QuadCountMax:=3;
  go_QuadCountMaxMax:=6;

  go_QuadCountChance[3]:=60;
  go_QuadCountChance[4]:=40;
  go_QuadCountChance[5]:=10;
  go_QuadCountChance[6]:=5;
end;

procedure tMngGameColris.RegistryGameVars; begin
  inherited;

  with MngProject.MngControl do begin
    RegistryControl(self, ctrl_game_ShiftUp, key_c_Up);
    RegistryControl(self, ctrl_game_ShiftDown, key_c_Down);

    Bind(keyname_mousewheelup, ctrl_game_ShiftUp);
    Bind(keyname_mousewheeldown, ctrl_game_ShiftDown);
  end
end;

function tMngGameColris.CreateDefaultGameObject; begin
  Result:=tGameObjectQuadColris.Create(self, go_BrickIndex, true);
end;

function tMngGameColris.CreateGameObjectQuadDie; begin
  Result:=tGameObjectQuadDieColor.Create(self, g_QuadDieStyle, true);
end;

function tMngGameColris.IndexToGameObject; begin
  case AIndex of
    go_idxMin + 1: Result:=tGameObjectQuadColris.Create(self, 0, false);
    go_idxMin + 2: Result:=tGameObjectQuadDieColor.Create(self, 0, false);
    else Result:=inherited IndexToGameObject(AIndex)
  end
end;

end.

