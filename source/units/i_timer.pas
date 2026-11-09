unit i_timer;

interface

uses
  Classes,
  Mutex;

const
  HTimersThreadPriority: tThreadPriority = tpNormal;

type
  tHTimer = class;

  tHTimerThread = class(tThread)
    protected
      FTimer   : tHTimer;
      FInterval: Cardinal;

      procedure Execute; override;

    public
      constructor Create(ATimer: tHTimer; AInterval: integer);
  end;

  tHTimer = class
    protected
      FEnabled : boolean;
      FInterval: cardinal;
      FOnTimer : tNotifyEvent;
      FThread  : tHTimerThread;
      FMutex   : tMutexObject;

      procedure SetEnabled(AEnabled: boolean);
      procedure SetInterval(AInterval: cardinal);

    protected
      procedure Timer; virtual;

    public
      constructor Create;
      destructor Destroy; override;

      property Enabled: boolean read FEnabled write SetEnabled;
      property Interval: cardinal read FInterval write SetInterval;
      property OnTimer: tNotifyEvent read FOnTimer write FOnTimer;
  end;

implementation

uses
  Windows;



constructor tHTimerThread.Create; begin
  FTimer:=ATimer;
  FInterval:=AInterval;
  FreeOnTerminate:=true;

  inherited Create(false);
  Priority:=HTimersThreadPriority;
end;

procedure tHTimerThread.Execute; begin
  while not Terminated do begin
    Sleep(FInterval);
    if not Terminated then FTimer.Timer;
  end;
end;



constructor tHTimer.Create; begin
  inherited;

  FMutex:=tMutexObject.Create;
  FEnabled:=false;
  FInterval:=1000;
  FThread:=nil
end;

destructor tHTimer.Destroy; begin
  FOnTimer:=nil;
  if FThread <> nil then FThread.Terminate;
  FMutex.Free;

  inherited;
end;

procedure tHTimer.SetEnabled; begin
  FMutex.WaitForObjectFull;

  if FEnabled and not AEnabled then begin
    FEnabled:=false;
    FThread.Terminate;
    FThread:=nil
  end
  else
    if not FEnabled and AEnabled then begin
      FEnabled:=true;
      FThread:=tHTimerThread.Create(self, FInterval);
    end;

  FMutex.ReleaseObjectFull;
end;

procedure tHTimer.SetInterval; begin
  FMutex.WaitForObjectFull;

  if FInterval <> AInterval then begin
    FInterval:=AInterval;

    if FEnabled then begin
      FThread.Terminate;
      FThread:=tHTimerThread.Create(self, FInterval)
    end
  end;

  FMutex.ReleaseObjectFull;
end;

procedure tHTimer.Timer; begin
  if Assigned(FOnTimer) then FOnTimer(self)
end;

end.

