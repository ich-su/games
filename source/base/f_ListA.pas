unit f_ListA;

interface

uses
  Windows, Classes, Graphics, Controls, Grids, StdCtrls, Buttons, 
  f_A, i_classes;

type
  tTextsList = class(tExList)
    protected
      function GetText(AIndex: integer): tStringList;

    public
      property Text[AIndex: integer]: tStringList read GetText; default;

      function New: tStringList;
  end;

  TFListA = class;
  tOnShiftPosition = procedure(AForm: TFListA) of object;

  TFListA = class(TFA)
    Grid: TDrawGrid;
    LabelTitle: TLabel;
    ButtonOk: TBitBtn;
    ButtonCancel: TBitBtn;
    procedure ButtonOkClick(Sender: TObject);
    procedure GridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure GridDblClick(Sender: TObject);
    procedure GridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    protected
      FTexts: tTextsList;
      FSpace,
      FSpace2,
      FScrollW,
      FMaxWidth,
      FMaxHeight: integer;
      FOnShiftPosition: tOnShiftPosition;

      procedure MakeSelf; virtual;
      function AddButtons: integer; virtual;

      function DrawTextIndex(AIndex: integer; ACanvas: tCanvas; ARect: tRect; ACalc: boolean = false): integer;

      function GetTitle: string;
      procedure SetTitle(ATitle: string);
      function GetCaption: string;
      procedure SetCaption(ACaption: string);

      function GetMaxWidth: integer;
      function GetMaxHeight: integer;

      function ButtonWidth(ACaptions: array of string): integer;

      function GetRes: integer;

    public
      property Texts: tTextsList read FTexts;
      property Title: string read GetTitle write SetTitle;
      property Caption: string read GetCaption write SetCaption;
      property MaxWidth: integer read GetMaxWidth write FMaxWidth;
      property MaxHeight: integer read GetMaxHeight write FMaxHeight;

      property OnShiftPosition: tOnShiftPosition read FOnShiftPosition write FOnShiftPosition;

      property Res: integer read GetRes;
  end;

implementation

{$R *.dfm}

uses
  Math, SysUtils, Forms,
  misc, c_strings;



function tTextsList.GetText; begin
  Result:=Items[AIndex]
end;

function tTextsList.New; begin
  Result:=tStringList.Create;
  Add(Result)
end;



function TFListA.GetTitle; begin
  Result:=LabelTitle.Caption;
end;

procedure TFListA.SetTitle; begin
  LabelTitle.Caption:=ATitle;
end;

function TFListA.GetCaption; begin
  Result:=inherited Caption;
end;

procedure TFListA.SetCaption; begin
  inherited Caption:=Format(list_caption, [Application.Title, ACaption]);
end;

function TFListA.GetRes; begin
  if Texts.Count > 0 then Result:=Grid.Row
  else Result:=-1;
end;

function TFListA.DrawTextIndex;
var
  o, i, s, p: integer;
  r, r2     : tRect;
  s_        : string;
  c         : tColor;
begin
  s:=ARect.Top;

  o:=DT_LEFT or DT_WORDBREAK or DT_NOPREFIX;
  if ACalc then o:=o or DT_CALCRECT;

  c:=ACanvas.Font.Color;

  for i:=0 to Texts[AIndex].Count - 1 do begin

    s_:=Texts[AIndex][i];
    p:=Pos(list_Metka, s_);
    if p > 0 then begin
      Delete(s_, p, length(list_Metka));
      if ACanvas.Font.Color = clHighlightText then ACanvas.Font.Color:=clSilver
      else ACanvas.Font.Color:=clGrayText
    end;

    r:=ARect;
    r2:=ARect;
    inc(ARect.Top, DrawText(ACanvas.Handle, pChar(s_), -1, r, o));

    ACanvas.Font.Color:=c;
    if p > 0 then DrawText(ACanvas.Handle, pChar(Copy(s_, 1, p - 1)), -1, r2, o);
  end;

  Result:=ARect.Top - s;
end;

procedure TFListA.GridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var r: tRect;
begin
  inherited;

  with tDrawGrid(Sender), Canvas do begin
    Font.Assign(self.Font);

    if ARow = Row then begin
      Brush.Color:=clHighLight;
      Font.Color:=clHighlightText
    end
    else begin
      Brush.Color:=clWindow;
      Font.Color:=clWindowText
    end;
    Pen.Style:=psSolid;
    Pen.Color:=clBtnFace;

    r:=Rect;
    inc(r.Top);

    Rectangle(r);

    if ARow < Texts.Count then begin
      inc(r.Left, FSpace - Grid.Left);
      dec(r.Right, FSpace - Grid.Left);
      inc(r.Top, FSpace2 - 1);
      DrawTextIndex(ARow, Canvas, r);
    end
  end;
end;

procedure TFListA.GridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); begin
  case Key of
//    vk_Return: ModalResult:=mrOk;
    vk_Escape: ModalResult:=mrCancel;
    vk_Home: Grid.Row:=Grid.FixedRows;
    vk_End: Grid.Row:=Grid.RowCount - 1;
  end;
end;

procedure TFListA.GridDblClick(Sender: TObject); begin
  ButtonOk.OnClick(ButtonOk);
end;


procedure TFListA.FormCreate(Sender: TObject); begin
  inherited;

  FMaxWidth:=-1;
  FMaxHeight:=-1;
  FTexts:=tTextsList.Create;
  FOnShiftPosition:=nil;
end;

procedure TFListA.FormDestroy(Sender: TObject); begin
  FTexts.Free;
  inherited;
end;

procedure TFListA.FormShow(Sender: TObject); begin
  MakeSelf;
  if Assigned(FOnShiftPosition) then FOnShiftPosition(self);

  inherited;
end;

function TFListA.GetMaxWidth; begin
  if FMaxWidth <= 0 then Result:=Screen.Width div 2
  else Result:=FMaxWidth
end;

function TFListA.GetMaxHeight; begin
  if FMaxHeight <= 0 then Result:=5*Screen.Height div 6
  else Result:=FMaxHeight
end;

procedure TFListA.ButtonOkClick(Sender: TObject); begin
  inherited;
  ModalResult:=mrOk
end;

function TFListA.ButtonWidth;
var i: integer;
begin
  Result:=0;
  for i:=low(ACaptions) to high(ACaptions) do
    Result:=Max(Result, Canvas.TextWidth(ACaptions[i]));

  inc(Result, 3*FSpace);
end;

function TFListA.AddButtons; begin
  Result:=0;
end;

procedure TFListA.MakeSelf;
var
  i, j, n, w: integer;
  r         : tRect;
begin
  FScrollW:=GetSystemMetrics(SM_CXVSCROLL);

//  Font.Assign(Screen.MenuFont);

  Font.Size:=auto_FontSize;
  Font.Name:=about_FontName;
  Font.Style:=[];

  Canvas.Font.Assign(Font);

  Grid.Font.Assign(Font);
  Grid.Canvas.Font.Assign(Font);
  Grid.Left:=4;

  r:=rect(0, 0, MaxInt, MaxInt);
  FSpace:=DrawText(Grid.Canvas.Handle, 'q', -1, r, DT_LEFT);
  FSpace2:=FSpace div 2;

  LabelTitle.Left:=FSpace;
  LabelTitle.Top:=FSpace;

  ButtonOk.Font.Assign(Screen.MenuFont);
  ButtonCancel.Font.Assign(Screen.MenuFont);

  ButtonOk.Caption:=list_button_Ok;
  ButtonCancel.Caption:=list_button_Cancel;

  ButtonOk.Left:=FSpace;
  ButtonOk.Width:=ButtonWidth([list_button_Ok, list_button_Cancel]);
  ButtonOk.Height:=round(1.6*FSpace);

  ButtonCancel.Left:=ButtonOk.Left + ButtonOk.Width + 4;
  ButtonCancel.Width:=ButtonOk.Width;
  ButtonCancel.Height:=ButtonOk.Height;

  n:=1;
  w:=0;

  for i:=0 to Texts.Count - 1 do begin
    n:=Max(n, Texts[i].Count);

    for j:=0 to Texts[i].Count - 1 do
      w:=Max(w, Canvas.TextWidth(Texts[i][j]));
  end;

  ClientWidth:=
    Min(MaxWidth - (Width - ClientWidth),
        Max(w + 2*FSpace - Grid.Left*2 + FScrollW, ButtonCancel.Left + ButtonCancel.Width + FSpace + AddButtons));

  LabelTitle.Width:=ClientWidth - 2*FSpace;
  LabelTitle.WordWrap:=true;

  Grid.Top:=FSpace + FSpace2 + LabelTitle.Height;
  Grid.RowCount:=Max(1, Texts.Count);
  Grid.Width:=ClientWidth - 2*Grid.Left;

  r:=rect(FSpace - Grid.Left, 0, Grid.Width - FSpace + Grid.Left (* - FScrollW *), MaxInt);
  n:=0;
  for i:=0 to Texts.Count - 1 do begin
    w:=2*FSpace2 + DrawTextIndex(i, Grid.Canvas, r, true);
    Grid.RowHeights[i]:=w;
    inc(n, w);
  end;

  Grid.ClientHeight:=
    Min(MaxHeight - (Height - ClientHeight) - Grid.Top - 2*FSpace - ButtonOk.Height,
        n);

  if Grid.ClientHeight < n then begin
    Width:=Width + FScrollW;
    Grid.Width:=Grid.Width + FScrollW;
  end;

  Grid.ColWidths[0]:=Grid.ClientWidth;

  ButtonOk.Top:=Grid.Top + Grid.Height + FSpace;
  ButtonCancel.Top:=ButtonOk.Top;

  ClientHeight:=ButtonOk.Top + ButtonOk.Height + FSpace;
end;

end.

