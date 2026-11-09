unit iwgraphics;

interface

uses
  Windows, Graphics;

procedure __Bar(ACanvas: tCanvas; ARect: tRect; AColor: tColor; ARectangleColor: tColor = clNone);
procedure __BarBitMap(ACanvas: tCanvas; ARect: tRect; ABitMap: tBitMap);
procedure __Line(ACanvas: tCanvas; x1, y1, x2, y2: integer; AColor: tColor);
procedure __Rectangle(ACanvas: tCanvas; ARect: tRect; AColor: tColor);

procedure __Text(ACanvas: tCanvas; x, y: integer; AText: string);
function __TextWidth(ACanvas: tCanvas; AText: string): integer;
function __TextHeight(ACanvas: tCanvas; AText: string): integer;

implementation

procedure __Bar; begin
  with ACanvas do
    if AColor <> clNone then begin
      Brush.Style:=bsSolid;
      Brush.Color:=AColor;
      FillRect(ARect);

      if ARectangleColor <> clNone then begin
        Pen.Color:=ARectangleColor;
        Pen.Style:=psSolid;
        Brush.Style:=bsClear;
        Rectangle(ARect);
      end
    end
end;

procedure __BarBitMap; begin
  with ACanvas do begin
    Brush.Style:=bsSolid;
    Brush.Bitmap:=ABitMap;
    FillRect(ARect);
  end; 
end;

procedure __Rectangle; begin
  if AColor <> clNone then
    with ACanvas do begin
      Brush.Style:=bsClear;
      Pen.Color:=AColor;
      Pen.Style:=psSolid;
      Rectangle(ARect);
    end
end;

procedure __Line; begin
  if AColor <> clNone then
    with ACanvas do begin
      Pen.Color:=AColor;
      Pen.Style:=psSolid;
      MoveTo(x1, y1);
      LineTo(x2, y2)
    end
end;

procedure __Text; begin
  with ACanvas do begin
    Brush.Style:=bsClear;
    TextOut(x, y, AText)
  end
end;

function __TextWidth; begin
  Result:=ACanvas.TextWidth(AText)
end;

function __TextHeight; begin
  Result:=ACanvas.TextHeight(AText)
end;

end.

