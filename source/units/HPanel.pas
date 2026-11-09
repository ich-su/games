unit HPanel;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls;

type
  tSide = (sdLeft, sdTop, sdRight, sdBottom);
  tSides = set of tSide;
  tVerticalAgliment = (vaTop, vaCenter, vaBottom);
  tWMNCHitTestEvent = procedure(var AMessage: tWMNCHitTest) of object;

  tHPanel = class(tCustomPanel)
  private
    FBevelInnerSides,
    FBevelOuterSides,
    FBorderSides         : tSides;
    FVerticalAgliment    : tVerticalAgliment;
    FBorderColor         : tColor;
    FHMerge, FVMerge     : integer;
    FWordWrap            : boolean;
    FOnPaint             : tNotifyEvent;
    FOnWMNCHitTest       : tWMNCHitTestEvent;

    procedure SetBevelInnerSides(Value: tSides);
    procedure SetBevelOuterSides(Value: tSides);
    procedure SetBorderSides(Value: tSides);
    procedure SetVerticalAgliment(Value: tVerticalAgliment);
    procedure SetBorderColor(Value: tColor);
    procedure SetHMerge(Value: integer);
    procedure SetVMerge(Value: integer);
    procedure SetWordWrap(Value: boolean);

  protected
    procedure DrawSides(Rect: tRect; ULColor, LRColor: tColor; Sides: tSides);
    procedure DrawBevel(var Rect: tRect; ULColor, LRColor: tColor; Width: integer; Sides: tSides);
//    function GetClientRect: tRect; override;
    procedure Paint; override;

    procedure WMNCHitTest(var AMessage: tWMNCHitTest); message WM_NCHITTEST;

  public
    constructor Create(AOwner: tComponent); override;

    property Canvas;

  published
    property BevelInnerSides: tSides read FBevelInnerSides write SetBevelInnerSides default [sdLeft, sdTop, sdRight, sdBottom];
    property BevelOuterSides: tSides read FBevelOuterSides write SetBevelOuterSides default [sdLeft, sdTop, sdRight, sdBottom];
    property BorderSides: tSides read FBorderSides write SetBorderSides;
    property VerticalAgliment: tVerticalAgliment read FVerticalAgliment write SetVerticalAgliment default vaCenter;
    property BorderColor: tColor read FBorderColor write SetBorderColor default clBtnFace;
    property HMerge: integer read FHMerge write SetHMerge default 4;
    property VMerge: integer read FVMerge write SetVMerge;
    property WordWrap: boolean read FWordWrap write SetWordWrap default true;

    property OnPaint: tNotifyEvent read FOnPaint write FOnPaint;
    property OnWMNCHitTest: tWMNCHitTestEvent read FOnWMNCHitTest write FOnWMNCHitTest;

    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BevelInner;
    property BevelOuter;
    property BevelWidth;
    property BiDiMode;
    property BorderWidth;
//    property BorderStyle;
    property Caption;
    property Color;
    property Constraints;
    property Ctl3D;
    property UseDockManager default True;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property FullRepaint;
    property Font;
    property Locked;
    property ParentBiDiMode;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnCanResize;
    property OnClick;
    property OnConstrainedResize;
    property OnContextPopup;
    property OnDockDrop;
    property OnDockOver;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
  end;

procedure Register;

implementation

constructor tHPanel.Create; begin
  inherited Create(AOwner);
  ControlStyle:=ControlStyle - [csSetCaption, csOpaque];
  FBevelInnerSides:=[sdLeft, sdTop, sdRight, sdBottom];
  FBevelOuterSides:=[sdLeft, sdTop, sdRight, sdBottom];
  FVerticalAgliment:=vaCenter;
  FBorderColor:=clBtnFace;
  FWordWrap:=true;
  HMerge:=4;
end;

procedure tHPanel.SetBevelInnerSides; begin
  if FBevelInnerSides <> Value then begin
    FBevelInnerSides:=Value;
    Invalidate
  end
end;

procedure tHPanel.SetBevelOuterSides; begin
  if FBevelOuterSides <> Value then begin
    FBevelOuterSides:=Value;
    Invalidate
  end
end;

procedure tHPanel.SetBorderSides; begin
  if FBorderSides <> Value then begin
    FBorderSides:=Value;
    Invalidate
  end
end;

procedure tHPanel.SetVerticalAgliment; begin
  if FVerticalAgliment <> Value then begin
    FVerticalAgliment:=Value;
    Invalidate
  end
end;

procedure tHPanel.SetBorderColor; begin
  if FBorderColor <> Value then begin
    FBorderColor:=Value;
    Invalidate
  end
end;

procedure tHPanel.SetHMerge; begin
  if (FHMerge <> Value) and (Value >= 0) then begin
    FHMerge:=Value;
    Invalidate
  end
end;

procedure tHPanel.SetVMerge; begin
  if (FVMerge <> Value) and (Value >= 0) then begin
    FVMerge:=Value;
    Invalidate
  end
end;

procedure tHPanel.SetWordWrap; begin
  if FWordWrap <> Value then begin
    FWordWrap:=Value;
    Invalidate
  end
end;

procedure tHPanel.DrawSides; begin
  with Canvas, Rect do begin
    Pen.Color:=ULColor;
    if sdLeft in Sides then begin
      MoveTo(Left, Top);
      LineTo(Left, Bottom)
    end;
    if sdTop in Sides then begin
      MoveTo(Left, Top);
      LineTo(Right, Top)
    end;
    Pen.Color:=LRColor;
    if sdRight in Sides then begin
      MoveTo(Right - 1, Top);
      LineTo(Right - 1, Bottom)
    end;
    if sdBottom in Sides then begin
      MoveTo(Left, Bottom - 1);
      LineTo(Right, Bottom - 1)
    end;
  end
end;

procedure tHPanel.DrawBevel;
var i: integer;
begin
  Canvas.Pen.Width:=1;
  for i:=1 to Width do begin
    DrawSides(Rect, ULColor, LRColor, Sides);
    InflateRect(Rect, -1, -1)
  end
end;
{
function tHPanel.GetClientRect; begin
  Result:=inherited GetClientRect;
  if sdLeft in FBorderSides then inc(Result.Left);
  if sdTop in FBorderSides then inc(Result.Top);
  if sdRight in FBorderSides then dec(Result.Right);
  if sdBottom in FBorderSides then dec(Result.Bottom);
end;
}
procedure tHPanel.Paint;
const
  Alignments: array[TAlignment] of Longint = (DT_LEFT, DT_RIGHT, DT_CENTER);
var
  DrawRct, TextRct     : tRect;
  h                    : integer;
  TopColor, BottomColor: tColor;
  Flags                : longint;


  procedure AdjustColors(Bevel: TPanelBevel); begin
    if Bevel = bvLowered then TopColor:=clBtnShadow
    else TopColor:=clBtnHighlight;
    if Bevel = bvLowered then BottomColor:=clBtnHighlight
    else BottomColor:=clBtnShadow;
  end;

begin
  DrawRct:=Rect(0, 0, Width, Height);

  with Canvas do begin
    if BevelOuter <> bvNone then begin
      AdjustColors(BevelOuter);
      DrawBevel(DrawRct, TopColor, BottomColor, BevelWidth, FBevelOuterSides);
    end;
    if BorderWidth > 0 then
      DrawBevel(DrawRct, FBorderColor, FBorderColor, BorderWidth, FBorderSides);
    if BevelInner <> bvNone then begin
      AdjustColors(BevelInner);
      DrawBevel(DrawRct, TopColor, BottomColor, BevelWidth, FBevelInnerSides);
    end;

    Brush.Color:=Color;
    FillRect(DrawRct);
    Brush.Style:=bsClear;
    Font:=self.Font;
    InflateRect(DrawRct, -HMerge, -VMerge);
    TextRct:=DrawRct;

    Flags:=dt_CalcRect or dt_ExpandTabs or dt_VCenter or dt_NoPrefix or Alignments[Alignment];
    if FWordWrap then Flags:=Flags or dt_WordBreak;
    Flags:=DrawTextBiDiModeFlags(Flags);
    h:=DrawText(Handle, pChar(Caption), -1, TextRct, Flags);

    with DrawRct do
      case FVerticalAgliment of
        vaCenter: if h < Bottom - Top then begin
          Top:=(Bottom + Top - h) shr 1;
          Bottom:=Top + h
        end;
        vaBottom: Top:=Bottom - h - 1;
      end;

    Flags:=dt_ExpandTabs or dt_VCenter or dt_NoPrefix or Alignments[Alignment];
    if FWordWrap then Flags:=Flags or dt_WordBreak;
    Flags:=DrawTextBiDiModeFlags(Flags);
    DrawText(Handle, pChar(Caption), -1, DrawRct, Flags)
  end;

  if Assigned(FOnPaint) then FOnPaint(self)
end;

procedure tHPanel.WMNCHitTest; begin
  inherited;
  if Assigned(FOnWMNCHitTest) then FOnWMNCHitTest(AMessage);
end;

procedure Register;
begin
  RegisterComponents('ich', [THPanel]);
end;

end.

