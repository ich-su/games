unit m_Draw;

interface

uses
  Windows, Classes, Graphics,
  i_classes,
  iwclasses, m_Color, save;

type
  tRowColRec = record
    Row, Col: integer;
  end;

  tRowCol = class
    public
      Row, Col: integer;

      constructor Create(ARow, ACol: integer);
  end;

  tRowColList = class(tSortedList)
    protected
      function Compare(AClass1, AClass2: pointer): integer; override;
      function GetItem(AIndex: integer): tRowCol;

    public
      property Items[Index: integer]: tRowCol read GetItem; default;
  end;

  tCellObject = class
    public
      procedure Draw(ACanvas: tCanvas; ARect: tRect; AParam: integer = 0); virtual;
  end;

  tCellEmpty = tCellObject;

  tCellWithMngColor = class(tCellObject)
    protected
      FMngColor: tMngColor;

    public
      constructor Create(AMngColor: tMngColor);
  end;

  tCellBar = class(tCellWithMngColor)
    protected
      FBorderColor: pColor;
      FNothingSize: pInteger;

    public
      constructor Create(AMngColor: tMngColor; var ABorderColor: tColor; var ANothingSize: integer);
      procedure Draw(ACanvas: tCanvas; ARect: tRect; AParam: integer); override;
  end;

  tCellObjectList = class(tExList)
    protected
      function GetItem(AIndex: integer): tCellObject;
      procedure SetItem(AIndex: integer; ACellObject: tCellObject);

    public
      property Items[Index: integer]: tCellObject read GetItem write SetItem; default;
  end;

  cellint = word;
  cellintdbl = longint;

  tCellIndex = record
    case integer of
      0: (Index, Param: cellint);
      1: (IndexL: cellintdbl);
  end;

  tCell2D = array of array of tCellIndex;

  tMngDraw = class(tMngA)
    protected
      FCellObjects: tCellObjectList;
      FCells      : tCell2D;
      FLocked     : boolean;

      function GetRowCount: integer;
      function GetColCount: integer;
      function GetCell(ARow, ACol: integer): tCellIndex;
      function GetCellEmpty(ARow, ACol: integer): boolean;

    public
      constructor Create;
      destructor Destroy; override;

      procedure Save(ASave: tGameSave);
      procedure Load(ASave: tGameSave; ARowCount, AColCount: integer);

      procedure AddCellObject(ACellObject: tCellObject);
      procedure DeleteCellObjects;

      function InDraw(ARow, ACol: integer): boolean;
      procedure VrfGameGrid(ARowCount, AColCount: integer);
      procedure Clear;

      procedure ClearCell(ARow, ACol: integer);
      procedure SetCell(ARow, ACol: integer; AIndex: cellint; AParam: cellint = 0); overload;
      procedure SetCell(ARow, ACol: integer; AIndexL: cellintdbl); overload;

      procedure Draw(ACanvas: tCanvas; ARect: tRect; ACellSize: integer);
      procedure DrawCell(ARow, ACol: integer; ACanvas: tCanvas; ARect: tRect);
      procedure DrawIndex(ACanvas: tCanvas; ARect: tRect; AIndex, AParam: cellint);

      procedure Lock(AObject: tObject);
      procedure UnLock(AObject: tObject);

      procedure CopyCells(var ADest: tCell2D);

      property RowCount: integer read GetRowCount;
      property ColCount: integer read GetColCount;
      property Cell[ARow, ACol: integer]: tCellIndex read GetCell; default;
      property CellEmpty[ARow, ACol: integer]: boolean read GetCellEmpty;

      property Locked: boolean read FLocked;
  end;

implementation

uses
  Types, SysUtils,
  i_sys,
  vars, pc, c_strings, iwgraphics;



constructor tRowCol.Create; begin
  inherited Create;
  Row:=ARow;
  Col:=ACol;
end;

function tRowColList.Compare; begin
  Result:=CompareInteger(tRowCol(AClass1).Row, tRowCol(AClass2).Row);
  if Result = 0 then
    Result:=CompareInteger(tRowCol(AClass1).Col, tRowCol(AClass2).Col);
end;

function tRowColList.GetItem; begin
  Result:=Get(AIndex)
end;



procedure tCellObject.Draw; begin
end;



constructor tCellWithMngColor.Create; begin
  inherited Create;
  FMngColor:=AMngColor;
end;



constructor tCellBar.Create; begin
  inherited Create(AMngColor);

  FBorderColor:=@ABorderColor;
  FNothingSize:=@ANothingSize;
end;

procedure tCellBar.Draw; begin
  dec(ARect.Bottom, FNothingSize^);
  if ARect.Bottom - ARect.Top < 2 then ARect.Bottom:=ARect.Top + 2;
  dec(ARect.Right, FNothingSize^);
  if ARect.Right - ARect.Left < 2 then ARect.Right:=ARect.Left + 2;

  __Bar(ACanvas, ARect, FMngColor[AParam], FBorderColor^)
end;



function tCellObjectList.GetItem; begin
  Result:=Get(AIndex)
end;

procedure tCellObjectList.SetItem; begin
  Put(AIndex, ACellObject);
end;



constructor tMngDraw.Create; begin
  inherited;
  FCellObjects:=tCellObjectList.Create;
end;

destructor tMngDraw.Destroy; begin
  FCellObjects.Free;
  inherited
end;

function tMngDraw.GetRowCount; begin
  Result:=length(FCells)
end;

function tMngDraw.GetColCount; begin
  if length(FCells) = 0 then Result:=0
  else Result:=length(FCells[0])
end;

function tMngDraw.GetCell; begin
  Result:=FCells[ARow, ACol]
end;

procedure tMngDraw.SetCell(ARow, ACol: integer; AIndex: cellint; AParam: cellint = 0); begin
  with FCells[ARow, ACol] do begin
    Index:=AIndex;
    Param:=AParam;
  end
end;

procedure tMngDraw.SetCell(ARow, ACol: integer; AIndexL: cellintdbl); begin
  FCells[ARow, ACol].IndexL:=AIndexL
end;

function tMngDraw.GetCellEmpty; begin
  Result:=FCells[ARow, ACol].Index = 0
end;

procedure tMngDraw.ClearCell; begin
  FCells[ARow, ACol].IndexL:=0;
end;

procedure tMngDraw.Clear;
var i, j: integer;
begin
  for i:=0 to RowCount - 1 do
    for j:=0 to ColCount - 1 do ClearCell(i, j)
end;

procedure tMngDraw.DeleteCellObjects; begin
  FCellObjects.Clear;
end;

procedure tMngDraw.AddCellObject; begin
  FCellObjects.Add(ACellObject);
end;

function tMngDraw.InDraw; begin
  Result:=(ARow >= 0) and (ACol >= 0) and (ARow < RowCount) and (ACol < ColCount)
end;

procedure tMngDraw.VrfGameGrid;
var i, j, k: integer;
begin
  SetLength(FCells, ARowCount);

  for i:=0 to length(FCells) - 1 do begin
    k:=length(FCells[i]);
    SetLength(FCells[i], AColCount);
    for j:=k to length(FCells[i]) - 1 do ClearCell(i, j);
  end
end;

procedure tMngDraw.DrawCell; begin
  with FCells[ARow, ACol] do
    DrawIndex(ACanvas, ARect, Index, Param);
end;

procedure tMngDraw.DrawIndex; begin
  if AIndex < FCellObjects.Count then
    FCellObjects[AIndex].Draw(ACanvas, ARect, AParam)
end;

procedure tMngDraw.Draw;
var i, j, x, y: integer;
begin
  for i:=0 to RowCount - 1 do
    for j:=0 to ColCount - 1 do
      if not CellEmpty[i, j] then begin
        x:=ARect.Left + j*ACellSize;
        y:=ARect.Top + i*ACellSize;

        if (x < ARect.Right - 1) and (y < ARect.Bottom - 1) then
          DrawCell(i, j, ACanvas, rect(x, y, x + ACellSize, y + ACellSize))
      end
end;

procedure tMngDraw.Lock; begin  // пока так
  FLocked:=true
end;

procedure tMngDraw.UnLock; begin
  FLocked:=false
end;

procedure tMngDraw.CopyCells;
var i, j: integer;
begin
  SetLength(ADest, RowCount);
  for i:=0 to length(ADest) - 1 do begin
    SetLength(ADest[i], ColCount);
    for j:=0 to length(ADest[i]) - 1 do ADest[i, j].IndexL:=FCells[i, j].IndexL
  end
end;

procedure tMngDraw.Save;
var i, j: integer;
begin
  ASave.Save(FLocked);
  ASave.Save(RowCount);
  ASave.Save(ColCount);

  for i:=0 to RowCount - 1 do
    for j:=0 to ColCount - 1 do ASave.Save(Cell[i, j].IndexL);
end;

procedure tMngDraw.Load;
var
  rc, cc, i, j: integer;
  k       : cellintdbl;
begin
  ASave.Load(FLocked);
  ASave.Load(rc);
  ASave.Load(cc);

  VrfGameGrid(ARowCount, AColCount);
  Clear;

  for i:=0 to rc - 1 do
    for j:=0 to cc - 1 do begin
      ASave.Load(k);
      if (i >= 0) and (i < RowCount) and (j >= 0) and (j < ColCount) then
        SetCell(i, j, k)
    end
end;

end.

