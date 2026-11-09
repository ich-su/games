unit spTrayIcon;

interface

uses
  ShellApi, Windows, Classes, Messages, Menus, Graphics, Forms, SysUtils,
  Controls;

type
  TOnTrayClick = procedure(Sender: TObject; Button: TMouseButton) of object;

  TspTrayIcon = class
  protected
    FFormHandle : THandle;
    FHandle     : THandle;
    FIcon       : TIcon;
    FPopupMenu  : TPopupMenu;
    FTip        : string;
    FMinimized  : Boolean;

    FNim        : TNotifyIconData;
    FSelfForm   : TForm;

    FActive     : Boolean;
    FHideButton : Boolean;
    FShowForm   : Boolean;

    FOnClick    : TOnTrayClick;
    FOnDblClick : TNotifyEvent;
    FBeforePopup: TNotifyEvent;

    procedure SetPopup(P: TPopupMenu);
    procedure SetIcon(I: TIcon);
    procedure SetTip(const Tip: string);
    procedure SetActive(const Value: Boolean);

    procedure WndProc(var Msg: TMessage);
  public
    constructor Create(AForm: TForm; Tip: string = ''; Active: Boolean = True);
    destructor Destroy; override;

    procedure Minimize;
    procedure Restore;

    property Active: Boolean read FActive write SetActive;
    property Minimized: Boolean read FMinimized;
    property PopupMenu: TPopupMenu read FPopupMenu write SetPopup;
    property Icon: TIcon read FIcon write SetIcon;
    property Tip: string read FTip write SetTip;
    property HideButton: Boolean read FHideButton write FHideButton;
    property ShowOnPopup: Boolean read FShowForm write FShowForm;
    property OnClick: TOnTrayClick read FOnClick write FOnClick;
    property OnDblClick: TNotifyEvent read FOnDblClick write FOnDblClick;
    property BeforePopup: TNotifyEvent read FBeforePopup write FBeforePopup;
  end;

implementation

{ TspTrayIcon }

constructor TspTrayIcon.Create(AForm: TForm; Tip: string = ''; Active: Boolean = True);
begin
  FHandle := AllocateHWnd(WndProc);
  FFormHandle := AForm.Handle;
  FSelfForm := TForm.Create(AForm);
  FIcon := Application.Icon;
  FTip := Tip;
  FActive := False;
  FHideButton := True;
  FShowForm := True;

  with FNim do begin
    cbSize := SizeOf(FNim);
    Wnd := FHandle;
    uID := 0;
    uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
    hIcon := FIcon.Handle;
    uCallbackMessage := WM_USER + 100;
    StrPLCopy(szTip, FTip, SizeOf(szTip) - 1);
  end;

  SetActive(Active);
end;

destructor TspTrayIcon.Destroy;
begin
  if FActive or FMinimized then Shell_NotifyIcon(NIM_DELETE, @FNim);
  DeallocateHWnd(FHandle);
  FSelfForm.Free;
  inherited;
end;

procedure TspTrayIcon.SetIcon(I: TIcon);
begin
  if (FIcon = nil) or (FIcon.Handle <> I.Handle) then begin
    FIcon := I;
    FNim.hIcon := FIcon.Handle;
    if FActive or FMinimized then Shell_NotifyIcon(NIM_MODIFY, @FNim);
  end;
end;

procedure TspTrayIcon.SetPopup(P: TPopupMenu);
begin
  if (FPopupMenu = nil) or (FPopupMenu.Handle <> P.Handle) then
    FPopupMenu := P;
end;

procedure TspTrayIcon.SetTip(const Tip: string);
begin
  if FTip <> Tip then begin
    FTip := Tip;
    StrPLCopy(FNim.szTip, FTip, SizeOf(FNim.szTip) - 1);
    if FActive or FMinimized then Shell_NotifyIcon(NIM_MODIFY, @FNim);
  end;
end;

procedure TspTrayIcon.SetActive(const Value: Boolean);
begin
  if FActive <> Value then begin
    FActive := Value;
    if FActive then
      Shell_NotifyIcon(NIM_ADD, @FNim)
    else
      Shell_NotifyIcon(NIM_DELETE, @FNim);
  end;
end;

procedure TspTrayIcon.WndProc(var Msg: TMessage);
var
  p: TPoint;
begin
  try
    with Msg do
      if (FActive or FMinimized) and (Msg = WM_USER + 100) then begin
        GetCursorPos(p);
        case lParam of
          WM_LBUTTONDBLCLK:
            if Assigned(FOnDblClick) then OnDblClick(Self);
          WM_LBUTTONDOWN:
            if Assigned(FOnClick) then OnClick(Self, mbLeft);
          WM_RBUTTONDOWN:
            begin
              if FPopupMenu <> nil then begin
                if Assigned(FBeforePopup) then BeforePopup(Self);
                if FShowForm then SetForegroundWindow(FSelfForm.Handle);
                FPopupMenu.Popup(p.x, p.y);
                PostMessage(FFormHandle, WM_NULL, 0, 0);
              end;
              if Assigned(FOnClick) then OnClick(Self, mbRight);
            end;
          WM_MBUTTONDOWN:
            if Assigned(FOnClick) then OnClick(Self, mbMiddle);
          else DefWindowProc(FHandle, Msg, wParam, lParam);
        end;
      end;
  except
    Application.HandleException(Self);
  end;
end;

procedure TspTrayIcon.Minimize;
begin
  if not FMinimized then begin
    if FHideButton then begin
      Application.ShowMainForm := False;
      ShowWindow(Application.Handle, SW_HIDE);
    end;
    ShowWindow(FFormHandle, SW_HIDE);
    if not FActive then Shell_NotifyIcon(NIM_ADD, @FNim);
    FMinimized := True;
  end;
end;

procedure TspTrayIcon.Restore;
begin
  if FMinimized then begin
    if FHideButton then begin
      Application.ShowMainForm := True;
      Application.Restore;
      ShowWindow(Application.Handle, SW_SHOW);
    end;
    ShowWindow(FFormHandle, SW_SHOW);
    SetForegroundWindow(FFormHandle);
    if not FActive then Shell_NotifyIcon(NIM_DELETE, @FNim);
    FMinimized := False;
  end;
end;

end.
