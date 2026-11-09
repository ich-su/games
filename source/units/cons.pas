{$I defines.inc}

unit cons;

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Jpeg, Messages,
  HPanel, HEdit, pc, vars;



const
{$IFDEF LANGENG}
  con_VersionValue = 'Console, v1.40';
{$ELSE}
  con_VersionValue = 'Консоль, версия 1.40';
{$ENDIF}

var
  con_FullScreen       : boolean;
  con_Height           : double;
  con_Width            : double;
  con_StepCount        : integer;
  con_StepPause        : integer;
  con_BackColor        : tColor;
  con_FontColor        : tColor;
  con_InactiveFontColor: tColor;
  con_ErrorColor       : tColor;
  con_Caption          : boolean;
  con_HistorySize      : integer;
  con_History          : string;
  con_FontSize         : integer;
  con_FontName         : string;
  con_FontStyle        : integer;
  con_Version          : string;
  con_Image            : integer;
  con_ImageName        : string;
  con_ShowTime         : boolean;
  con_ScrPage          : integer;
  con_Extended         : boolean;
  con_ExtStep          : double;
  con_ExtPos           : integer;
  con_Transparent      : double;  // руками не менять, вызывать tConsole.Transparent

  con_2_ErrorColor     : tColor;

const
  vn_con_FullScreen        = 'con_FullScreen';
  vn_con_Width             = 'con_Width';
  vn_con_Height            = 'con_Height';
  vn_con_StepCount         = 'con_StepCount';
  vn_con_StepPause         = 'con_StepPause';
  vn_con_BackColor         = 'con_BackColor';
  vn_con_FontColor         = 'con_FontColor';
  vn_con_Caption           = 'con_Caption';
  vn_con_HistorySize       = 'con_HistorySize';
  vn_con_History           = 'con_History';
  vn_con_FontName          = 'con_FontName';
  vn_con_FontSize          = 'con_FontSize';
  vn_con_FontStyle         = 'con_FontStyle';
  vn_con_Exit              = 'con_Exit';
  vn_con_Version           = 'con_Version';
  vn_con_ErrorColor        = 'con_ErrorColor';
  vn_con_Image             = 'con_Image';
  vn_con_ImageName         = 'con_ImageName';
  vn_con_ShowTime          = 'con_ShowTime';
  vn_con_ScrPage           = 'con_ScrPage';
  vn_con_Extended          = 'con_Extended';
  vn_con_ExtStep           = 'con_ExtStep';
  vn_con_ExtPos            = 'con_ExtPos';
  vn_con_InactiveFontColor = 'con_InactiveFontColor';
  vn_con_Transparent       = 'con_Transparent';

  c_chCons       = ']';
{$IFDEF LANGENG}
  con_Name          : string = 'Console';
  con_ExtHintInc    : string = 'enlarge console';
  con_ExtHintDec    : string = 'reduce console';
  con_ExtHintOpenCfg: string = 'load config';
{$ELSE}
  con_Name          : string = 'Консоль';
  con_ExtHintInc    : string = 'расширить консоль';
  con_ExtHintDec    : string = 'сузить консоль';
  con_ExtHintOpenCfg: string = 'загрузить конфиг';
{$ENDIF}
  con_Next       = #218;
  con_ExtInc     = #215;
  con_ExtDec     = #216;
  con_OpenCfg    = #$31;
  con_SepChar    = #$a7;
  con_NextFont   = 'Wingdings';
  con_HistorySep = '`';

  con_MinFontSize = 6;
  con_MaxFontSize = 32;

  ciNone    = 0;
  ciCenter  = 1;
  ciHeight  = 2;
  ciStretch = 3;

  log_TimeSep  = '  ';

  vk_Tilda     = 192;
  vk_WheelUp   = 64000;
  vk_WheelDown = 64001;



type
  TConsole = class(TForm)
    PDown: tHPanel;
    PLine: tHPanel;
    Edit: tHEdit;
    LEdit: TLabel;
    PDraw: TPaintBox;
    PCaption: tHPanel;
    PLineExt: tHPanel;
    procedure PLineExtMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PLineExtPaint(Sender: TObject);
    procedure PLineExtMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure PDrawPaint(Sender: TObject);
    procedure PLineResize(Sender: TObject);
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure EditKeyPress(Sender: TObject; var Key: Char);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure EditCNKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);

  protected
    CancelPressed,
    ChangedHeight,
    Closing        : boolean;
    DownIndex,
    HistoryIndex   : integer;
    History        : tStringList;
    FFuncOpenCfg   : tNotifyEvent;

    FList          : tList;
    FMainImage     : tJpegImage;
    FBMap          : tBitMap;
    FBuffer        : tBitMap;
    hBMap2         : HBitMap;
    hDC2           : hDC;
    sv2_Width,
    sv2_Height     : integer;
    FImageChanged  : boolean;

    FLock,
    FActivated     : boolean;
    FLookImage,
    FChImage       : integer;

    FPref          : string;
    FAllFullScreen : boolean;

    LastIDLogState : cardinal;

    procedure InitVars;
    procedure SetColors(AControl: tControl);
    procedure SetFont(AControl: tControl);
    procedure SetControls;
    procedure ToInput;
    procedure ToHistory(s: string);
    procedure TruncateHistory;
    procedure WriteLog(APaintBox: tPaintBox);
    procedure WriteAdded;
    procedure WriteAllLogs;
    procedure ChangeHeight(h: integer; Open: boolean);

    function GetHeight: integer;
    procedure SetSelfRect;
    procedure VisibleCaption;
    procedure CommandEnd;
    procedure EscDown;

    procedure SetTransparent(AValue: double);
    function GetTransparent: double;

    function Vrf_FullScreen(PtrValue: pointer): boolean;
    function Vrf_Height(PtrValue: pointer): boolean;
    function Vrf_Width(PtrValue: pointer): boolean;
    function Vrf_Caption(PtrValue: pointer): boolean;
    function Vrf_History(PtrValue: pointer): boolean;
    function Vrf_Color(PtrValue: pointer): boolean;
    function Vrf_Image(PtrValue: pointer): boolean;
    function Vrf_Font(PtrValue: pointer): boolean;
    function Vrf_ShowTime(PtrValue: pointer): boolean;
    function Vrf_Extended(PtrValue: pointer): boolean;
    function Vrf_Transparent(PtrValue: pointer): boolean;

    procedure OnPaint(Sender: tObject);
    procedure GetButtonXs(var x1, x2, x3: integer);

    procedure DeleteBMap2;
    procedure AssignSymbolText(AFont: tFont);

    procedure ListToStrings;
    procedure StringsToList;

    procedure MOnChange(var M: tMessage); message wm_LogChange;

  public
    procedure Exec;
    procedure Exit;
    procedure NormalizeSize;
    procedure Add(APaintBox: tPaintBox);
    procedure Delete(APaintBox: tPaintBox);
    procedure LockImage;
    procedure AssignMainImage(AJpegImage: tJpegImage);

    property Pref: string read FPref write FPref;
    property AllFullScreen: boolean read FAllFullScreen write FAllFullScreen;
    property Transparent: double read GetTransparent write SetTransparent;

    property FuncOpenCfg: tNotifyEvent read FFuncOpenCfg write FFuncOpenCfg;
  end;

var
  Console: tConsole;

implementation

uses
  rxStrUtils,
  i_str, i_sys;

{$R *.DFM}

procedure tConsole.WriteLog;
const dlt = 0;
var
  h, i, t, lH,
  DnIndex    : integer;
  cl         : tColor;
  style      : byte;
  s          : string;
  lt         : tLogType;

  W_, X_, _W,
  Y_, H_, rH : integer;

  function BackImage: boolean; begin
    Result:=(FBMap <> nil) and (APaintBox.Tag < 0) and (con_Image <> ciNone)
  end;

  procedure CalcBackImageParam;
  var
    bHead2: BITMAPINFO;
    p     : pointer;
    k     : double;
  begin
    if APaintBox = PDraw then
      rH:=GetHeight - PLine.Height - PCaption.Height*byte(PCaption.Visible) -
          BorderWidth shl 1 - 2
    else
      rH:=APaintBox.Height;

    if BackImage then begin
      k:=rH/FBMap.Height;

      Y_:=0;
      H_:=rH;

      if con_Image = ciStretch then begin
        W_:=APaintBox.Width;
        _W:=FBMap.Width;
        X_:=0;
      end
      else begin
        _W:=round(APaintBox.Width/k);
        if _W < FBMap.Width then begin
          X_:=0;
          W_:=APaintBox.Width;

          if con_Image = ciCenter then begin
            k:=APaintBox.Width/FBMap.Width;
            _W:=FBMap.Width;

            W_:=APaintBox.Width;
            H_:=round(FBMap.Height*k);
            Y_:=round((rH - H_)/2);
          end

        end
        else begin
          _W:=FBMap.Width;
          W_:=round(_W*k);
          X_:=round((APaintBox.Width - W_)/2)
        end
      end;

      if (sv2_Width <> W_) or (sv2_Height <> H_) or FImageChanged then begin
        DeleteBMap2;
        sv2_Width:=W_;
        sv2_Height:=H_;
        FImageChanged:=false;

        hDC2:=CreateCompatibleDC(APaintBox.Canvas.Handle);

        with bHead2.bmiHeader do begin
          biSize:=sizeof(BITMAPINFOHEADER);
          biWidth:=W_;
          biHeight:=-H_;
          biSizeImage:=W_*H_*3;
          biPlanes:=1;
          biBitCount:=24;
          biCompression:=BI_RGB;
          biXPelsPerMeter:=100;
          biYPelsPerMeter:=100;
          biClrUsed:=0;
          biClrImportant:=0;
        end;

        hBMap2:=CreateDIBSection(APaintBox.Canvas.Handle,
                                 bHead2, DIB_RGB_COLORS, p, 0, 0);
        SelectObject(hDC2, hBMap2);
        StretchBlt(hDC2, 0, 0, W_, H_,
                   FBMap.Canvas.Handle, 0, 0, _W, FBMap.Height, SRCCOPY);

      end
    end;

    FBuffer.Width:=APaintBox.Width;
    FBuffer.Height:=rH; // APaintBox.Height;
  end;

  procedure FillBackground; begin
    with FBuffer, Canvas do
      if not BackImage then FillRect(Bounds(0, 0, Width, Height))
      else begin
        SelectObject(hDC2, hBMap2);
        if X_ > 0 then begin
          FillRect(Bounds(0, 0, X_, Height));
          FillRect(Bounds(X_ + W_, 0, Width - X_ - W_, Height));
        end;
        if Y_ > 0 then begin
          FillRect(Bounds(X_, 0, X_ + W_, Y_));
          FillRect(Bounds(X_, Y_ + H_, X_ + W_, rH - Y_ - H_));
        end;
        BitBlt(Handle, X_, Y_, W_, H_, hDC2, 0, 0, SRCCOPY);
      end
  end;

var
  last : boolean;
  r    : tRect;
  sTime: string;
begin
  with FBuffer, Canvas do begin
    h:=LEdit.Height - dlt;

    Brush.Color:=APaintBox.Color;
    Brush.Style:=bsSolid;
    Font.Assign(APaintBox.Font);

    if APaintBox = PDraw then begin
      lH:=0;
      DnIndex:=DownIndex
    end
    else begin
      lH:=LEdit.Height - LEdit.Height shr 1;
      DnIndex:=Variables.LogSize - 1
    end;

    CalcBackImageParam;
    FillBackground;

    i:=DnIndex; last:=false;
    repeat
      t:=rH - h*(DnIndex - i + 1) - LEdit.Height + lH;

      if (i >= 0) and not last then
        with Variables do begin
          LogLineEx(i, s, sTime, lt, cl, style);

          if (con_ShowTime) and (length(s) > 0) then s:=sTime + log_TimeSep + s;

          last:=(APaintBox.Tag = -2) and (LogMark[i] = var_MarkInit);

          if lt = ltError then
            if APaintBox.Tag <> -2 then Font.Color:=con_ErrorColor
            else Font.Color:=con_2_ErrorColor
          else
            if cl <> -1 then Font.Color:=cl
            else Font.Color:=APaintBox.Font.Color; // con_FontColor;

          if style < 16 then Font.Style:=ByteToFontStyles(style)
          else Font.Style:=ByteToFontStyles(con_FontStyle);

          Brush.Style:=bsClear;
//          TextOut(LEdit.Left, t, s);

          r:=Bounds(LEdit.Left, t, APaintBox.Width - LEdit.Left, h);
          DrawText(Canvas.Handle, pChar(s), -1, r, DT_LEFT or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX);

          Brush.Style:=bsSolid;
        end;

      dec(i)
    until t + h < 0;

    t:=rH - LEdit.Height;

    if DnIndex < Variables.LogSize - 1 then begin
      AssignSymbolText(Font);
      Brush.Style:=bsClear;
      TextOut(LEdit.Left, t, MakeStr(con_Next, 3)); //(APaintBox.Width - LEdit.Left) div TextWidth(con_Next)))
      Brush.Style:=bsSolid;
    end;

    BitBlt(APaintBox.Canvas.Handle, 0, 0, APaintBox.Width, APaintBox.Height,
           FBuffer.Canvas.Handle, 0, rH - APaintBox.Height, SRCCOPY)
  end;
end;

procedure TConsole.AssignSymbolText; begin
  with AFont do begin
    Name:=con_NextFont;
    CharSet:=SYMBOL_CHARSET;
    Size:=con_FontSize;
    Color:=con_FontColor;
    Style:=ByteToFontStyles(con_FontStyle);
  end;
end;

procedure tConsole.LockImage; begin
  FLock:=not FLock;

  if FLock then begin
    FLookImage:=con_Image;
    FChImage:=con_Image
  end
  else begin
    con_Image:=FChImage;
    Vrf_Image(@con_ImageName)
  end
end;

procedure TConsole.DeleteBMap2; begin
  DeleteDC(hDC2);
  DeleteObject(hBMap2);
  sv2_Width:=0;
  sv2_Height:=0;

  FBuffer.Width:=0;
  FBuffer.Height:=0;
end;

procedure TConsole.WriteAdded;
var i: integer;
begin
  for i:=0 to FList.Count - 1 do WriteLog(FList[i])
end;

procedure TConsole.Exec; begin
  ShowModal;
end;

procedure TConsole.NormalizeSize; begin
  if Visible then begin
    Height:=GetHeight;
    if con_FullScreen then Align:=alTop
    else SetSelfRect;
  end;
end;

procedure TConsole.SetColors; begin
  if AControl = self then begin
    Color:=con_BackColor;
    Font.Color:=con_FontColor;
    PCaption.Color:=con_FontColor; // clActiveCaption; -
    PCaption.Font.Color:=con_BackColor; // clCaptionText;
  end
  else
    if AControl.Tag <> -2 then begin
      tPanel(AControl.Parent).Color:=con_BackColor;
      tPanel(AControl.Parent).Font.Color:=con_FontColor;
    end;
end;

procedure TConsole.SetFont; begin
  if AControl = self then begin
    Font.Name:=con_FontName;
    Font.CharSet:=RUSSIAN_CHARSET;
    Font.Size:=con_FontSize;
    Font.Style:=ByteToFontStyles(con_FontStyle);

    PCaption.Font.Assign(Font);
    PCaption.Font.Color:=con_BackColor;

    Edit.Height:=LEdit.Height + 2;
    PLine.Height:=Edit.Height + 2;
    Edit.Left:=LEdit.Left + LEdit.Width;
    PCaption.Height:=LEdit.Height + 3;

    SetControls
  end
  else
    if AControl.Tag <> -2 then
      with tPanel(AControl.Parent) do begin
        Font.Name:=con_FontName;
        Font.CharSet:=RUSSIAN_CHARSET;
        Font.Size:=con_FontSize;
        Font.Style:=ByteToFontStyles(con_FontStyle);
      end
end;

procedure TConsole.SetControls; begin
  AssignSymbolText(PLineExt.Canvas.Font);
//  PLineExt.Width:=round(1.5*PLineExt.Canvas.TextWidth(con_ExtInc + con_ExtDec));
  PLineExt.Width:=PLineExt.Canvas.TextWidth(con_SepChar + con_ExtInc + con_SepChar + con_ExtDec + con_SepChar + con_OpenCfg + con_SepChar);
  PLineExt.Visible:=con_Extended; // and not con_FullScreen;

  if PLineExt.Visible then Edit.Width:=PLine.ClientWidth - Edit.Left - 2 - PLineExt.Width
  else Edit.Width:=PLine.ClientWidth - Edit.Left - LEdit.Left shr 1
end;

procedure tConsole.InitVars; begin
  con_FullScreen  :=false;
  con_Height      :=0.7;
  con_Width       :=0.8;
  con_StepCount   :=5;
  con_StepPause   :=2;
  con_BackColor   :=Color;
  con_FontColor   :=Font.Color;
  con_Caption     :=false;
  con_HistorySize :=50;
  con_FontSize    :=Font.Size;
  con_FontName    :=Font.Name;
  con_FontStyle   :=FontStylesToByte(Font.Style);
  con_Version     :=con_VersionValue;
  con_ErrorColor  :=clRed;
  con_2_ErrorColor:=con_ErrorColor;
  con_Image       :=ciCenter;
  con_ShowTime    :=false;
  con_ScrPage     :=4;
  con_Extended    :=false;
  con_ExtStep     :=0.2;
  con_ExtPos      :=0;
  con_InactiveFontColor:=clGrayText;

  SetLength(con_ImageName, 0);

  SetTransparent(1);
end;

procedure TConsole.FormCreate(Sender: TObject); begin
  FFuncOpenCfg:=nil;

  LastIDLogState:=0;
  FAllFullScreen:=false;
  SetLength(FPref, 0);
  FBuffer:=tBitMap.Create;

  FList:=tList.Create;
  InitVars;
  History:=tStringList.Create;
  DownIndex:=Variables.LogSize - 1;
  PDown.DoubleBuffered:=true;
  LEdit.Caption:=c_chCons;
  Edit.BorderStyle:=bsNone;
  PCaption.Caption:=con_Name;
  FLock:=false;
  FImageChanged:=false;
  HistoryIndex:=-1;

  with Variables do begin
    RegistryBoolean (vn_con_FullScreen,  con_FullScreen,  self, Vrf_FullScreen);
    RegistryPercent (vn_con_Width,       con_Width,       self, Vrf_Width);
    RegistryPercent (vn_con_Height,      con_Height,      self, Vrf_Height);
    RegistryNatural (vn_con_StepCount,   con_StepCount);
    RegistryNatural (vn_con_StepPause,   con_StepPause);
    RegistryColor   (vn_con_BackColor,   con_BackColor,   self, Vrf_Color);
    RegistryColor   (vn_con_FontColor,   con_FontColor,   self, Vrf_Color);
    RegistryColor   (vn_con_InactiveFontColor, con_InactiveFontColor, self, Vrf_Color);
    RegistryBoolean (vn_con_Caption,     con_Caption,     self, Vrf_Caption);
    RegistryNatural (vn_con_HistorySize, con_HistorySize, self, Vrf_History);
    RegistryString  (vn_con_History,     con_History,     self, Vrf_History);
    RegistryString  (vn_con_FontName,    con_FontName,    self, Vrf_Font);
    RegistryNatural (vn_con_FontSize,    con_FontSize,    self, Vrf_Font);
    RegistryNatural (vn_con_FontStyle,   con_FontStyle,   self, Vrf_Font);
    RegistryString  (vn_con_Version,     con_Version,     self, nil, true);
    RegistryColor   (vn_con_ErrorColor,  con_ErrorColor,  self, Vrf_Color);
    RegistryNatural (vn_con_Image,       con_Image,       self, Vrf_Image);
    RegistryString  (vn_con_ImageName,   con_ImageName,   self, Vrf_Image);
    RegistryBoolean (vn_con_ShowTime,    con_ShowTime,    self, Vrf_ShowTime);
    RegistryNatural (vn_con_ScrPage,     con_ScrPage);
    RegistryBoolean (vn_con_Extended,    con_Extended,    self, Vrf_Extended);
    RegistryNatural (vn_con_ExtPos,      con_ExtPos,      self, Vrf_Extended);
    RegistryPercent (vn_con_ExtStep,     con_ExtStep,     self, Vrf_Extended);
    RegistryPercent (vn_con_Transparent, con_Transparent, self, Vrf_Transparent);

    RegistryFunction(vn_con_Exit,       @tConsole.Exit,   self, vtVoid, []);

    SetOnLogChange(self.Handle);
  end;
end;

procedure TConsole.FormShow(Sender: TObject); begin
  Closing:=false;
  CancelPressed:=false;
  ChangedHeight:=false;
  Height:=0;
  FActivated:=false;
end;

procedure TConsole.FormDestroy(Sender: TObject); begin
  FList.Free;
  History.Free;

  DeleteBMap2;
  FBuffer.Free;
  FreeAndNil(FBMap);
  FreeAndNil(FMainImage);
end;

function TConsole.GetHeight;
var
  r: tRect;
  i: integer;
begin
  if con_FullScreen then // а если > 1 моника ?!
    if SystemParametersInfo(SPI_GETWORKAREA, 0, @r, 0) then Result:=r.Bottom - r.Top
    else Result:=Screen.Height
  else begin
    if Application.MainForm.BorderStyle = bsNone then i:=1
    else i:=GetSystemMetrics(SM_CYFRAME);
    Result:=Application.MainForm.Height - i;
  end;

  Result:=round(Result*con_Height);
end;

procedure TConsole.SetSelfRect;
var i, l, t, w: integer;
begin
{
  with Application.MainForm do begin
    self.Align:=alNone;
    self.Width:=round(Width*con_Width) - 2; // - 1 - byte(BorderStyle = bsNone);
    self.Left:=Left + Width - self.Width - 1;

    if BorderStyle = bsNone then i:=1
    else i:=GetSystemMetrics(SM_CYFRAME);
    self.Top:=Top + i;
  end;
}
  with Application.MainForm do begin
    self.Align:=alNone;

    i:=round(Width*con_Width*(1 + byte(con_Extended)*con_ExtStep*con_ExtPos)) - 2;
    if Left + Width - i - 1 < 0 then i:=Left + Width - 1;

    l:=Left + Width - i - 1;
    w:=i;

//    if BorderStyle = bsNone then i:=1
//    else i:=GetSystemMetrics(SM_CYFRAME);
//    t:=Top + i;

    t:=Top;

    if Transparent = 1 then self.SetBounds(l, t, w, self.Height)
    else begin
      self.Left:=l;
      self.Top:=t;
      self.Width:=w;
    end
  end
end;

procedure TConsole.VisibleCaption; begin
  PCaption.Visible:=con_Caption;
  PCaption.Caption:=con_Name;
end;

procedure TConsole.FormActivate(Sender: TObject);
var h: integer;
begin
  if not FActivated then begin
    SetColors(self);
    SetFont(self);

    VisibleCaption;

    if con_FullScreen or AllFullScreen then Align:=alTop
    else SetSelfRect;
    h:=GetHeight;

    ChangeHeight(h, true);

    CancelPressed:=false;
    Closing:=true;

    FActivated:=true;
  end;
end;

procedure tConsole.ChangeHeight;
var
  i   : integer;
  tick: cardinal;
begin
  ChangedHeight:=true;
  i:=1;
  while (i < con_StepCount) and not CancelPressed do begin
    tick:=GetTickCount;
    if Open then Height:=round((h * i) / con_StepCount)
    else Height:=round((h * (con_StepCount - i + 1)) / con_StepCount);
    inc(i);
    while (tick + cardinal(con_StepPause) > GetTickCount) and
          not CancelPressed do Application.ProcessMessages;
  end;
  if Open then Height:=h
  else Height:=0;
  ChangedHeight:=false;
end;

procedure TConsole.ToHistory;
var i: integer;
begin
  if (length(s) > 0) and (con_HistorySize > 0) then begin
    i:=0;
    while i < History.Count do
      if CompareStrFlags(s, History[i]) then History.Delete(i)
      else inc(i);

    History.Insert(0, s);

    while (History.Count > 0) and
          (History.Count > con_HistorySize) do History.Delete(History.Count - 1);
  end;

  HistoryIndex:=-1;
  ListToStrings
end;

procedure TConsole.TruncateHistory; begin
  while History.Count > con_HistorySize do History.Delete(History.Count - 1);
  ListToStrings
end;

procedure TConsole.ToInput;
var s: string;
begin
  with Variables do begin
    s:=Edit.Text;
    Edit.Text:='';
    AddToLog(c_chCons + s);
    ToHistory(s);
    Input(s);
  end;
end;

procedure TConsole.PDrawPaint(Sender: TObject); begin
  WriteLog(PDraw)
end;

procedure tConsole.MOnChange; begin
  Variables.Mutex.WaitForObjectFull;

  if LastIDLogState <> Variables.IDLogState then begin
    LastIDLogState:=Variables.IDLogState;
    DownIndex:=Variables.LogSize - 1;
    WriteAllLogs;
  end;

  Variables.Mutex.ReleaseObjectFull
end;

procedure TConsole.PLineResize(Sender: TObject); begin
  SetControls
end;

procedure TConsole.EscDown; begin
  if Closing then
    if not ChangedHeight then begin
      Edit.Text:='';
      ChangeHeight(Height, false);
      Close
    end
    else CancelPressed:=true
  else CancelPressed:=true
end;

procedure TConsole.EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

  procedure HistoryToEdit; begin
    if (HistoryIndex >= 0) and (HistoryIndex < History.Count) then Edit.Text:=History[HistoryIndex]
    else Edit.Text:='';

    if length(Edit.Text) > 0 then begin
      Edit.SelLength:=0;
      Edit.SelStart:=length(Edit.Text) + 2;
    end;

    Abort
  end;

var i: integer;
begin
  case Key of
    vk_Return: ToInput;

    vk_Next, vk_WheelDown:
      if DownIndex < Variables.LogSize - 1 then begin
        if Key = vk_Next then i:=DownIndex + con_ScrPage
        else i:=DownIndex + 1;

        if i >= Variables.LogSize then DownIndex:=Variables.LogSize - 1
        else DownIndex:=i;

        WriteLog(PDraw);
      end;

    vk_Prior, vk_WheelUp:
      if DownIndex > 0 then begin
        if Key = vk_Prior then i:=DownIndex - con_ScrPage
        else i:=DownIndex - 1;
        
        if i < 0 then DownIndex:=0
        else DownIndex:=i;

        WriteLog(PDraw);
      end;

    vk_Up:
      if HistoryIndex < History.Count then begin
        inc(HistoryIndex);
        HistoryToEdit;
      end;

    vk_Down:
      if HistoryIndex > -1 then begin
        dec(HistoryIndex);
        HistoryToEdit
      end;
  end;
end;

procedure TConsole.EditKeyPress(Sender: TObject; var Key: Char); begin
  if Key in [{'`',} #13, #27] then Key:=#0
end;

procedure TConsole.FormMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
var k: word;
begin
  k:=vk_WheelDown;
  EditKeyDown(Edit, k, [])
end;

procedure TConsole.FormMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
var k: word;
begin
  k:=vk_WheelUp;
  EditKeyDown(Edit, k, [])
end;



procedure tConsole.ListToStrings;
var i: integer;
begin
  if History.Count > 0 then con_History:=History[0];
  for i:=1 to History.Count - 1 do
    con_History:=con_History + con_HistorySep + History[i]
end;

procedure tConsole.StringsToList;
var
  i: integer;
  s: string;
begin
  History.Clear;
  s:=con_History;
  repeat
    i:=Pos(con_HistorySep, s);
    if i = 0 then i:=length(s) + 1;
    History.Add(Copy(s, 1, i - 1));
    System.Delete(s, 1, i)
  until (History.Count > con_HistorySize) or (length(s) = 0)
end;




function tConsole.Vrf_FullScreen; begin
  Result:=true;
  SetControls;
  NormalizeSize
end;

function tConsole.Vrf_Height; begin
  Result:=con_Height + MinFloat >= 0.15;
  if Result and Visible then Height:=GetHeight
end;

function tConsole.Vrf_Width; begin
  Result:=con_Width + MinFloat >= 0.15;
  if Result and Visible and not con_FullScreen then SetSelfRect
end;

function tConsole.Vrf_Caption; begin
  Result:=true;
  if Visible then VisibleCaption
end;

function tConsole.Vrf_History; begin
  Result:=true;
  if PtrValue = @con_HistorySize then TruncateHistory
  else
    if PtrValue = @con_History then StringsToList
end;

function tConsole.Vrf_Color;
var i: integer;
begin
  Result:=true;
  if Visible then begin
    SetColors(self);
    if PtrValue = @con_ErrorColor then WriteLog(PDraw)
  end;

  for i:=0 to FList.Count - 1 do begin
    SetColors(tControl(FList[i]));
    if PtrValue = @con_ErrorColor then WriteLog(FList[i])
  end
end;

function tConsole.Vrf_Font;
var i: integer;
begin
  Result:=(con_FontSize in [con_MinFontSize..con_MaxFontSize]) and
          (con_FontStyle in [0..15]);
  if Result and Visible then SetFont(self);

  for i:=0 to FList.Count - 1 do SetFont(tControl(FList[i]));
end;

function tConsole.Vrf_ShowTime; begin
  Result:=true;
  WriteAllLogs
end;

function tConsole.Vrf_Extended; begin
  if PtrValue = @con_ExtStep then Result:=con_ExtStep + MinFloat >= 0.1
  else Result:=true;
  if Result then begin
    SetControls;
    NormalizeSize
  end
end;

function tConsole.Vrf_Transparent; begin
  Result:=(con_Transparent + MinFloat >= 0.1);
  if Result then begin
    AlphaBlend:=con_Transparent <> 1;
    AlphaBlendValue:=round(con_Transparent*255);
  end
end;

function tConsole.Vrf_Image; begin
  Result:=con_Image in [ciNone, ciHeight, ciCenter, ciStretch];

  if FLock then
    if PtrValue = @con_Image then begin
      FChImage:=con_Image;
      con_Image:=FLookImage;
    end
    else
  else
    if Result then begin
      if con_Image = ciNone then begin
        FreeAndNil(FBMap);
        DeleteBMap2;
      end
      else
        if not ((PtrValue = @con_Image) and (FBMap <> nil)) then begin
          if FBMap = nil then FBMap:=tBitMap.Create;

          if length(con_ImageName) > 0 then
            if LoadImageFromFile(con_ImageName, FBMap) then
              Variables.AddToLog(Format(FPref + ms_var_Load, [con_ImageName]))
            else begin
              if FMainImage <> nil then FBMap.Assign(FMainImage)
              else FreeAndNil(FBMap);
              Variables.Error(Format(FPref + ms_var_ErrorLoad, [con_ImageName]));
            end
          else
            if FMainImage <> nil then FBMap.Assign(FMainImage)
            else FreeAndNil(FBMap)
        end;

      FImageChanged:=true;  
      WriteAllLogs
    end
end;

procedure tConsole.AssignMainImage; begin
  if AJpegImage <> nil then begin
    if FMainImage = nil then FMainImage:=tJpegImage.Create;
    FMainImage.Assign(AJpegImage);
    Vrf_Image(@con_ImageName)
  end
end;

procedure tConsole.WriteAllLogs; begin
  if Visible then WriteLog(PDraw);
  WriteAdded
end;

procedure tConsole.Exit; begin
  if Visible then EscDown;
end;

procedure tConsole.OnPaint; begin
  WriteLog(tPaintBox(Sender))
end;

procedure TConsole.PLineExtMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

  procedure _shift(d: integer); begin
    con_ExtPos:=con_ExtPos + d;
    NormalizeSize
  end;

var x1, x2, x3, w: integer;
begin
(*
  if X <= tControl(Sender).ClientWidth div 2 then
    if Left > 0 then _shift(1)
    else
  else
    if con_ExtPos > 0 then _shift(-1)
*)

  GetButtonXs(x1, x2, x3);
  w:=PLineExt.Canvas.TextWidth(con_SepChar) div 2;

  if X in [0..x2 - w - 1] then
    if Left > 0 then _shift(1)
    else
  else
    if X in [x2 - w .. x3 - w] then
      if con_ExtPos > 0 then _shift(-1)
      else
    else
      if Assigned(FFuncOpenCfg) then FFuncOpenCfg(self);
end;

procedure TConsole.PLineExtMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  x1, x2, x3, w: integer;
  s            : string;
begin
  GetButtonXs(x1, x2, x3);
  w:=PLineExt.Canvas.TextWidth(con_SepChar) div 2;
  if X in [0..x2 - w - 1] then s:=con_ExtHintInc
  else
    if X in [x2 - w .. x3 - w] then s:=con_ExtHintDec
    else s:=con_ExtHintOpenCfg;

  if PLineExt.Hint <> s then begin
    Application.HideHint;
    PLineExt.Hint:=s;
  end
end;

procedure TConsole.GetButtonXs; begin
  with PLineExt.Canvas do begin
    AssignSymbolText(Font);
    x1:=TextWidth(con_SepChar);
    x2:=x1 + TextWidth(con_ExtInc + con_SepChar);
    x3:=x2 + TextWidth(con_ExtDec + con_SepChar);
  end;
end;

procedure TConsole.PLineExtPaint(Sender: TObject);

  procedure _d(ADisabled: boolean; AX: integer; AStr: string); begin
    with PLineExt.Canvas do begin
      if ADisabled then Font.Color:=con_InactiveFontColor
      else Font.Color:=con_FontColor;
      TextOut(AX, 0, AStr);
    end;
  end;

var x1, x2, x3: integer;
begin
  GetButtonXs(x1, x2, x3);
  _d(con_FullScreen or (self.Left <= 0), x1, con_ExtInc);
  _d(con_FullScreen or (con_ExtPos = 0), x2, con_ExtDec);
  _d(not Assigned(FFuncOpenCfg), x3, con_OpenCfg);
end;

procedure tConsole.Add; begin
  if APaintBox <> nil then begin
    FList.Add(APaintBox);

    APaintBox.OnPaint:=OnPaint;
    SetColors(APaintBox);
    SetFont(APaintBox);

    WriteLog(APaintBox);
  end
end;

procedure tConsole.Delete;
var i: integer;
begin
  with FList do begin
    i:=IndexOf(APaintBox);
    if i <> -1 then begin
      Delete(i);
      DeleteBMap2
    end
  end
end;

procedure TConsole.FormClose(Sender: TObject; var Action: TCloseAction); begin
  DeleteBMap2;
end;

procedure TConsole.EditCNKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); begin
  case Key of
    vk_Tab: begin
      CommandEnd;
      Key:=0;
    end;
    vk_Escape: EscDown;
    vk_Tilda: if ssCtrl in Shift then EscDown;
  end
end;

procedure TConsole.CommandEnd;
const
  SetName = ['a'..'z', 'A'..'Z', '0'..'9', '_', '@'];
var
  i, j, idx   : integer;
  s, sText, s2: string;
  sl, sl2     : tStringList;

  procedure InsertChars(AChars: string); begin
    Edit.Text:=Copy(sText, 1, i) + AChars + Copy(sText, i + 1, MaxInt);
//    Edit.SelStart:=j + length(Name[idx]) - 1;
    Edit.SelStart:=i + length(AChars);
    Edit.SelLength:=0
  end;

begin
  with Edit do
    if (length(Text) > 0) and (SelLength = 0) then begin
      i:=SelStart;
      sText:=Text;
      if (i > 0) and ((i = length(sText)) or (not (sText[i + 1] in SetName))) then begin
        j:=i;
        while (j > 1) and (sText[j - 1] in SetName) do dec(j);
        s:=Copy(sText, j, i - j + 1);
        if length(s) > 0 then

          with Variables do begin
            sl:=tStringList.Create;
            sl2:=tStringList.Create;
            try
              SearchVar(s, idx);

              while (idx < Count) and CompareStrBegin(Name[idx], s) do begin

                if VType[idx] <> vtFunction then s2:=' = ' + ConstToStr(Value[idx], VType[idx])
                else SetLength(s2, 0);

                sl.Add(Name[idx]);
                sl2.Add(s2);

                inc(idx)
              end;

              if sl2.Count > 1 then
                for idx:=0 to sl2.Count - 1 do AddToLog(sl[idx] + sl2[idx]);

              InsertChars(Copy(EquBeginStrs(sl), length(s) + 1, MaxInt));

            finally
              sl2.Free;
              sl.Free
            end
          end
{
            if not SearchVar(s, idx) and (idx < Count) then
              if CompareStrBegin(Name[idx], s) then

                if (idx = Count - 1) or not CompareStrBegin(Name[idx + 1], s) then
                  InsertChars(Copy(Name[idx], length(s) + 1, MaxInt))

                else begin
                  InsertChars(Copy(EquBeginStrs(Name[idx], Name[idx + 1]), length(s) + 1, MaxInt));

                  while (idx < Count) and CompareStrBegin(Name[idx], s) do begin
                    if VType[idx] <> vtFunction then s2:=' = ' + ConstToStr(Value[idx], VType[idx])
                    else SetLength(s2, 0);

                    AddToLog(Name[idx] + s2);
                    inc(idx)
                  end
                end
}
      end
    end
end;

procedure TConsole.SetTransparent;
var t: double;
begin
  t:=con_Transparent;
  con_Transparent:=AValue;
  if not Vrf_Transparent(@con_Transparent) then con_Transparent:=t;
end;

function TConsole.GetTransparent; begin
  Result:=con_Transparent
end;

end.

