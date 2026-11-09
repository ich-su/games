Unit Mutex;

Interface

Uses
  Windows;

Const
  IncTaskSleepTime  = 10;
  FullTaskSleepTime = 10;

Type
  TMutexObject = Class
  Protected
    uFullCounter  : Integer;
    uFullThreadId : Cardinal;
    uFullRepeat   : Integer;
    uIncCounter   : Integer;
  Public
    Constructor     Create;

    Procedure       WaitForObject;
    Procedure       WaitForObjectFull;
    Function        TryWaitForObject: Bool;
    Function        TryWaitForObjectFull: Bool;
    Function        TryWaitForObjectThread: Bool;
    Function        TryWaitForObjectFullThread: Bool;
    Procedure       ReleaseObject;
    Procedure       ReleaseObjectFull;
  End;

Implementation

Constructor     TMutexObject.Create;
Begin
  uFullCounter  := 0;
  uFullThreadId := 0;
  uFullRepeat   := 0;
  uIncCounter   := 0;
End;

Procedure       TMutexObject.WaitForObject;
Begin
  While (Not TryWaitForObject()) Do Sleep(IncTaskSleepTime);
End;

Procedure       TMutexObject.WaitForObjectFull;
Begin
  while (Not TryWaitForObjectFull()) Do Sleep(FullTaskSleepTime);
End;

Function        TMutexObject.TryWaitForObject: Bool;
Begin
  InterlockedIncrement(uIncCounter);
  Result := ((uFullCounter = 0) Or (uFullThreadId = GetCurrentThreadId()));
  If (Not Result) Then InterlockedDecrement(uIncCounter);
End;

Function        TMutexObject.TryWaitForObjectFull: Bool;
Begin
  Result := False;
  If (InterlockedIncrement(uFullCounter) = 1) Then
    Begin
      If (uIncCounter = 0) Then
        Begin
          uFullThreadId := GetCurrentThreadId();
          Inc(uFullRepeat);
          Result := True;
        End;
    End
  Else
    Begin
      If (uFullThreadId = GetCurrentThreadId()) Then
        Begin
          If (uIncCounter = 0) Then
            Begin
              Inc(uFullRepeat);
              Result := True;
            End;
        End;
    End;
  If (Not Result) Then InterlockedDecrement(uFullCounter);
End;

Function        TMutexObject.TryWaitForObjectThread: Bool;
Begin
  InterlockedIncrement(uIncCounter);
  Result := (uFullCounter = 0);
  If (Not Result) Then InterlockedDecrement(uIncCounter);
End;

Function        TMutexObject.TryWaitForObjectFullThread: Bool;
Begin
  Result := False;
  If (InterlockedIncrement(uFullCounter) = 1) Then
    Begin
      If (uIncCounter = 0) Then
        Begin
          uFullThreadId := GetCurrentThreadId();
          Inc(uFullRepeat);
          Result := True;
        End;
    End;
  If (Not Result) Then InterlockedDecrement(uFullCounter);
End;

Procedure       TMutexObject.ReleaseObject;
Begin
  InterlockedDecrement(uIncCounter);
End;

Procedure       TMutexObject.ReleaseObjectFull; Assembler;
Begin
  Dec(uFullRepeat);
  If (uFullRepeat = 0) Then uFullThreadId := 0;
  InterlockedDecrement(uFullCounter);
End;

End.

