unit m_GameClick;

interface

uses
  Windows, Graphics, IniFiles,
  iwclasses, save, m_GameA, m_GameTetris;

const
    go_qbs_None  = 0;
    go_qbs_Def   = 1;
    go_qbs_Click = 2; go_qbs_Max = go_qbs_Click;

var
  g_QuadBorderColorR  : tColor;
  g_QuadNothingSizeR  : integer;
  g_QuadBorderStyle   : integer;
  g_QuadDieMouseDown  : boolean = false;
  g_QuadMouseDownColor: tColor = clWhite;

    go_QuadDieMouseDownParam: integer;

type
  tGameObjectQuadDieClick = class(tGameObjectQuadDieA)
    protected
      FRow, FCol: integer;
      FLight    : boolean;

      function FindSpareQuads: boolean; override;
      procedure SetLight(ALight: boolean);

    public
      constructor Create(AMngGame: tMngGameA; AStyle: integer; ATimerUse: boolean; ARow, ACol: integer);
      procedure Save(ASave: tGameSave); override;
      procedure Load(ASave: tGameSave); override;

      property Light: boolean read FLight write SetLight;
  end;

  tMngGameClick = class(tMngGameA)
    protected
      FQuads: integer;
      
      procedure RegistryGameVars; override;
      function VrfGameVars(PtrValue: pointer): boolean; override;
      procedure InitGameVars; override;
      procedure InitGameVars2; override;

      procedure GetGameFormSizes(var AWidth, AHeight: integer); override;
      function GetGameDrawRect: tRect; override;

      function tolog_GameInfo: string; override;
      function ScoreEnabled: boolean; override;
      procedure BeforeStarted; override;
      procedure ClearTimeScoreEtc; override;
      function CreateDefaultGameObject: tGameObject; override;
      function GameObjectToIndex(AGameObject: tGameObject): integer; override;
      function IndexToGameObject(AIndex: integer): tGameObject; override;
      function GameLoop: boolean; override;
      function MouseReaction(AData: tControlDataMouse): boolean; override;
      procedure __DrawAfterMngDraw(ACanvas: tCanvas; ARect: tRect); override;
      procedure FreeGameObjectMouse; override;

      procedure SaveGame(ASave: tGameSave); override;
      procedure LoadGame(ASave: tGameSave); override;
      function GetDrawInfoString(var AString: string): boolean; override;

      function GetGameObjectMouse: tGameObjectQuadDieClick;
      procedure FillGameCells;

      property GameObjectMouse: tGameObjectQuadDieClick read GetGameObjectMouse;

    public
      constructor Create;

      class procedure tolog_MainInfoGame; override;
      class function ParseLanguage(AIni: tIniFile): boolean; override;
      procedure AddParams(AIndex: integer; AParams: array of const); override;
  end;

implementation

uses
  SysUtils,
  vars,
  c_strings, misc, main, iwgraphics, m_Color, m_Control, m_Draw, f_A;



constructor tGameObjectQuadDieClick.Create; begin
  inherited Create(AMngGame, AStyle, ATimerUse);

  FRow:=ARow;
  FCol:=ACol;
  FLight:=false
end;

procedure tGameObjectQuadDieClick.Save; begin
  ASave.Save(FRow);
  ASave.Save(FCol);
  ASave.Save(FLight);

  inherited Save(ASave)
end;

procedure tGameObjectQuadDieClick.Load; begin
  ASave.Load(FRow);
  ASave.Load(FCol);
  ASave.Load(FLight);

  inherited Load(ASave)
end;

function tGameObjectQuadDieClick.FindSpareQuads;

  procedure _add(e: tElement);
  var rn, cn, i: integer;
  begin
    if not FElements.FindSorted(e, i) then begin
      FElements.AddSorted(e);

      with FMngGame.MngDraw do
        for i:=0 to 3 do begin
          rn:=e.Row + NeighbourCell[i].Row;
          cn:=e.Col + NeighbourCell[i].Col;

          if (rn >= 0) and (rn < RowCount) and
             (cn >= 0) and (cn < ColCount) and
             (Cell[rn, cn].Index <> 0 {= go_WallIndex}) and
             (Cell[rn, cn].Param = e.Param) then _add(tElement.Create(rn, cn, e.Param))
        end
    end
    else e.Free
  end;

begin
  with FMngGame.MngDraw.Cell[FRow, FCol] do begin
    Result:=Index <> 0 {= go_WallIndex};
    if Result then begin
      _add(tElement.Create(FRow, FCol, Param));
      Result:=FElements.Count >= g_QuadDieMinCount;
    end;
  end;
end;

procedure tGameObjectQuadDieClick.SetLight;
var
  i: integer;
  p: cellint;
begin
  if FLight <> ALight then begin
    FLight:=ALight;

    for i:=0 to FElements.Count - 1 do
      with FMngGame.MngDraw, FElements[i] do begin
        if ALight then p:=go_QuadDieMouseDownParam // go_QuadDieParam
        else p:=Param;
        if InDraw(Row, Col) then SetCell(Row, Col, FMngGame.MngDraw.Cell[Row, Col].Index, p)
      end
  end;
end;



constructor tMngGameClick.Create; begin
  inherited;

  MngDraw.AddCellObject(tCellBar.Create(FMngColor, g_QuadBorderColorR, g_QuadNothingSizeR));

  DefaultMainColors:=DefaultMainColors2;
  FMngColor.InitDefaultMainColors(vn_g_SetQuadColor, vn_g_QuadColorList, VrfGameVars);
  go_QuadDieParam:=FMngColor.AddColor(g_QuadDieColorR);
  go_QuadDieClearParam:=FMngColor.AddColor(g_QuadDieColorNone);
  go_QuadDieMouseDownParam:=FMngColor.AddColor(g_QuadMouseDownColor);
end;

class procedure tMngGameClick.tolog_MainInfoGame; begin
  log(Format(iwg_by, [iwg_16QuadColors, iwg_people_Spectre]));
  inherited;
end;

class function tMngGameClick.ParseLanguage; begin
  try
    log_game_click_Quads:=AIni.ReadString(ini_main, 'log_game_click_Quads', log_game_click_Quads);
    Result:=inherited ParseLanguage(AIni);
  except
    Result:=false;
  end;
end;

procedure tMngGameClick.InitGameVars2; begin
  mf_NothingSizeLeft:=3*show_X + canvas_TextWidth(show_FontName, show_FontSize, show_FontStyle, 'gameplay');
end;

procedure tMngGameClick.InitGameVars; begin
  inherited;

  g_ColCount:=10;
  g_RowCount:=20;

  g_BackImage:=1;

  g_QuadColorCount:=4;
  go_QuadColorCountMin:=2;
  
  g_QuadNothingSize:=1;
  g_QuadNothingSizeR:=1;
  g_QuadBorderColor:=clWhite;
  g_QuadBorderColorR:=clWhite;

  g_QuadDieStyle:=go_qds_Blink;
  g_QuadDieStyle2ParamCount:=2;
  g_QuadDieStyle2ParamWait:=4;
  g_QuadDieMinCount:=2;

  mf_NChitTest:=false;

  g_QuadBorderStyle:=go_qbs_Click;
  g_QuadBorderColorR:=clNone;
  g_QuadNothingSizeR:=0;

  g_BackImage:=0;
  g_BorderColor:=clNone;
  g_NothingSize:=0;
  mf_NothingSizeRight:=0;
  mf_NothingSizeLeft:=88;
  mf_BackImageScaled:=1;
  mf_NothingSize:=10;

  g_NextGameObjectCount:=0;
  g_NextGameObjectCountMax:=0;

  show_Left:=Format(cfgr_info_LeftClick, [ctrl_Play]) + cfgr_info_Right;
  show_LeftStarted:=Format(cfgr_info_LeftClick, [ctrl_Pause]) + cfgr_info_Right
end;

procedure tMngGameClick.RegistryGameVars; begin
  inherited;

  with Variables do begin
    RegistryColor(vn_g_QuadBorderColor, g_QuadBorderColor, self, VrfGameVars);
    RegistryNatural(vn_g_QuadBorderStyle, g_QuadBorderStyle, self, VrfGameVars);
    RegistryNatural(vn_g_QuadNothingSize, g_QuadNothingSize, self, VrfGameVars);
    RegistryBoolean(vn_g_QuadDieMouseDown, g_QuadDieMouseDown);

    RegistryColor(vn_g_QuadDieColor, g_QuadDieColorR, self, VrfGameVars);
    RegistryNatural(vn_g_QuadDieStyle, g_QuadDieStyle, self, VrfGameVars);
    RegistryNatural(vn_g_QuadDieSpeed, g_QuadDieSpeed, self, VrfGameVars);
    RegistryNatural(vn_g_QuadDieStyle1ParamWait, g_QuadDieStyle1ParamWait, self, VrfGameVars);
    RegistryNatural(vn_g_QuadDieStyle2ParamWait, g_QuadDieStyle2ParamWait, self, VrfGameVars);
    RegistryNatural(vn_g_QuadDieStyle2ParamCount, g_QuadDieStyle2ParamCount, self, VrfGameVars);

    RegistryColor(vn_g_QuadMouseDownColor, g_QuadMouseDownColor, self, VrfGameVars);

    RegistryNatural(vn_g_QuadColorCount, g_QuadColorCount, self, VrfGameVars);
    RegistryNatural(vn_g_QuadDieMinCount, g_QuadDieMinCount, self, VrfGameVars);
  end;

  with MngProject.MngControl do begin
    bind(keyname_mouseleft, ctrl_UnPauseOnly);
    bind(keyname_mouseright, ctrl_UnPauseOnly)
  end;
end;

function tMngGameClick.VrfGameVars; begin
  if PtrValue = @g_QuadDieStyle then Result:=g_QuadDieStyle in [go_qds_Quick..go_qds_Max] else
  if PtrValue = @g_QuadDieStyle1ParamWait then Result:=g_QuadDieStyle1ParamWait in [1..go_QuadDieStyle1ParamWaitMax] else
  if PtrValue = @g_QuadDieStyle2ParamWait then Result:=g_QuadDieStyle2ParamWait in [1..go_QuadDieStyle2ParamWaitMax] else
  if PtrValue = @g_QuadDieStyle2ParamCount then Result:=g_QuadDieStyle2ParamCount in [1..go_QuadDieStyle2ParamCountMax] else
  if PtrValue = @g_QuadDieSpeed then Result:=g_QuadDieSpeed <= go_QuadDieSpeedMax else
  if (PtrValue = @g_QuadDieMinCount) then Result:=g_QuadDieMinCount in [go_QuadDieMinCountMin..go_QuadDieMinCountMax] else
  if (PtrValue = @g_QuadColorCount) then Result:=g_QuadColorCount in [go_QuadColorCountMin..go_QuadColorCountMax]
  else begin

    if PtrValue = @g_QuadNothingSize then Result:=g_QuadNothingSize in [0..go_QuadNothingSizeMax] else
    if PtrValue = @g_QuadBorderStyle then Result:=g_QuadBorderStyle in [0..go_qbs_Max]
    else Result:=true;

    if Result then
      case g_QuadBorderStyle of
        go_qbs_Click: begin
          g_QuadBorderColorR:=clNone;
          g_QuadNothingSizeR:=0
        end;
        go_qbs_None: begin
          g_QuadBorderColorR:=clNone;
          g_QuadNothingSizeR:=g_QuadNothingSize
        end
        else begin
          g_QuadBorderColorR:=g_QuadBorderColor;
          g_QuadNothingSizeR:=g_QuadNothingSize;
        end
      end;

    Result:=Result and inherited VrfGameVars(PtrValue)
  end
end;

procedure tMngGameClick.GetGameFormSizes; begin
  inherited GetGameFormSizes(AWidth, AHeight);

  if g_QuadBorderStyle <> go_qbs_Click then begin
    dec(AWidth, g_QuadNothingSize);
    dec(AHeight, g_QuadNothingSize)
  end
  else begin
    inc(AWidth);
    inc(AHeight)
  end;
end;

function tMngGameClick.GetGameDrawRect; begin
  Result:=inherited GetGameDrawRect;

  if g_QuadBorderStyle <> go_qbs_Click then begin
    dec(Result.Right, g_QuadNothingSize);
    dec(Result.Bottom, g_QuadNothingSize)
  end
  else begin
    inc(Result.Right);
    inc(Result.Bottom)
  end
end;

function tMngGameClick.ScoreEnabled; begin
  Result:=false
end;

function tMngGameClick.tolog_GameInfo; begin
  Result:=Format(log_game_StateChange, [inherited tolog_GameInfo,
                 Format(log_game_click_Quads, [IntToStr(FQuads)])]);
end;

procedure tMngGameClick.BeforeStarted; begin
  inherited;
  FillGameCells
end;

procedure tMngGameClick.ClearTimeScoreEtc; begin
  inherited;
  FQuads:=0;
end;

procedure tMngGameClick.FillGameCells;
var i, j: integer;
begin
  MngDraw.VrfGameGrid(g_RowCount, g_ColCount);

  for i:=0 to g_RowCount - 1 do
    for j:=0 to g_ColCount - 1 do
      MngDraw.SetCell(i, j, go_WallIndex, random(g_QuadColorCount));

  FQuads:=g_RowCount*g_ColCount
end;

function tMngGameClick.MouseReaction;
var b: boolean;
begin
  Result:=not MngDraw.Locked;

  if Result then
    with AData do

      case Action of
        maDown: begin
          Result:=(GameObjectMouse = nil) and (Row <> -1) and (Col <> -1);
          if Result then
            if g_QuadDieMouseDown then
              RunGameObject(tGameObjectQuadDieClick.Create(self, g_QuadDieStyle, true, Row, Col))
            else begin
              FGameObjectMouse:=tGameObjectQuadDieClick.Create(self, g_QuadDieStyle, true, Row, Col);
              Result:=GameObjectMouse.FindSpareQuads;
              if not Result then FreeGameObjectMouse
              else GameObjectMouse.Light:=true
            end
        end;
        maUp: begin
          Result:=GameObjectMouse <> nil;
          if Result then
            if GameObjectMouse.ItIsYourCell(Row, Col, true) then begin
              GameObjectMouse.Run;
              GameObjects.Add(GameObjectMouse);
              FGameObjectMouse:=nil
            end
            else FreeGameObjectMouse
        end
        else begin // maMove
          Result:=GameObjectMouse <> nil;
          if Result then begin

            b:=GameObjectMouse.ItIsYourCell(Row, Col, true);
            Result:=GameObjectMouse.Light <> b;
            if Result then GameObjectMouse.Light:=b
          end
        end
      end
end;

function tMngGameClick.GetGameObjectMouse; begin
  Result:=tGameObjectQuadDieClick(FGameObjectMouse);
end;

function tMngGameClick.CreateDefaultGameObject; begin
  if FGameObjects.Count = 0 then Result:=tGameObject.Create(self, 0, true)
  else Result:=nil
end;

procedure tMngGameClick.FreeGameObjectMouse; begin
  if GameObjectMouse <> nil then GameObjectMouse.Light:=false;
  inherited
end;

function tMngGameClick.GameLoop;
var
  go     : tGameObjectQuadDieClick;
  i, j, k: integer;
  b      : boolean;
begin
  Result:=inherited GameLoop;

  with MngDraw do begin
    i:=ColCount - 2;

    while i >= 0 do begin
      b:=true;
      j:=0;
      while b and (j < RowCount) do begin
        b:=CellEmpty[j, i];
        inc(j)
      end;

      if b then begin
        for j:=i to ColCount - 2 do
          for k:=0 to RowCount - 1 do SetCell(k, j, Cell[k, j + 1].IndexL);
        for k:=0 to RowCount - 1 do ClearCell(k, ColCount - 1)
      end;

      dec(i)
    end;

    go:=tGameObjectQuadDieClick.Create(self, 0, false, 0, 0);

    b:=true;
    i:=RowCount - 1;
    while b and (i >= 0) do begin
      j:=0;
      while b and (j < ColCount) do begin
        go.FElements.Clear;
        go.FRow:=i;
        go.FCol:=j;
        b:=not go.FindSpareQuads;
        inc(j)
      end;
      dec(i)
    end;

    go.Free;

    if b then
      self.OnControl(self, ctrl_game_Stop);
  end
end;

function tMngGameClick.GameObjectToIndex; begin
  if AGameObject is tGameObjectQuadDieClick then Result:=1 + go_idxMin
  else
    Result:=inherited GameObjectToIndex(AGameObject);
end;

function tMngGameClick.IndexToGameObject; begin
  if AIndex = go_idxMin + 1 then Result:=tGameObjectQuadDieClick.Create(self, 0, false, 0, 0)
  else Result:=inherited IndexToGameObject(AIndex)
end;

procedure tMngGameClick.SaveGame; begin
  ASave.Save(FQuads);
  inherited SaveGame(ASave);
end;

procedure tMngGameClick.LoadGame; begin
  ASave.Load(FQuads);
  inherited LoadGame(ASave);
end;

procedure tMngGameClick.AddParams; begin
  if AIndex = gpi_KillQuad then dec(FQuads, AParams[0].VInteger)
  else inherited AddParams(AIndex, AParams)
end;

function tMngGameClick.GetDrawInfoString; begin
  Result:=inherited GetDrawInfoString(AString);

  if not Result then
    if AString = info_Quads then begin
      Result:=true;
      AString:=IntToStr(FQuads)
    end;
end;

procedure tMngGameClick.__DrawAfterMngDraw;

  function _cmp(ARow1, ACol1, ARow2, ACol2: integer): boolean;
  var v1, v2: cellintdbl;
  begin
    with MngDraw do begin
      if (ARow1 >= 0) and (ARow1 < g_RowCount) and (ARow1 < RowCount) and
         (ACol1 >= 0) and (ACol1 < g_ColCount) and (ACol1 < ColCount) then v1:=Cell[ARow1, ACol1].IndexL
      else v1:=0;
      if (ARow2 >= 0) and (ARow2 < g_RowCount) and (ARow2 < RowCount) and
         (ACol2 >= 0) and (ACol2 < g_ColCount) and (ACol2 < ColCount) then v2:=Cell[ARow2, ACol2].IndexL
      else v2:=0;

      Result:=v1 = v2;
    end
  end;

var i, j, x, y: integer;
begin
  inherited __DrawAfterMngDraw(ACanvas, ARect);

  if (g_QuadBorderStyle = go_qbs_Click) and (g_QuadBorderColor <> clNone) then
    for i:=0 to g_RowCount do
      for j:=0 to g_ColCount do begin
        x:=ARect.Left + j*g_CellSize;
        y:=ARect.Top + i*g_CellSize;

        if (x <= ARect.Right) and (y <= ARect.Bottom) then
          if not _cmp(i, j, i, j - 1) then __Line(ACanvas, x, y, x, y + g_CellSize, g_QuadBorderColor);
          if not _cmp(i, j, i - 1, j) then __Line(ACanvas, x, y, x + g_CellSize + 1, y, g_QuadBorderColor);
      end
end;

end.

