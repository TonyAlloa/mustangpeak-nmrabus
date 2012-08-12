unit serialport_thread;

{$mode objfpc}{$H+}

interface
uses
  Classes, SysUtils, synaser, olcb_testmatrix, ExtCtrls;

type

{ TComPortThread }

  TComPortThread = class(TThread)
  private
    FBaudRate: DWord;
    FConnected: Boolean;
    FPort: String;
    FSerial: TBlockSerial;
    FNoReplyWaitTimer: TTimer;
    FThreadTestList: TThreadList;
    protected
      procedure Execute; override;
    public
      property Connected: Boolean read FConnected write FConnected;
      property Serial: TBlockSerial read FSerial write FSerial;
      property BaudRate: DWord read FBaudRate write FBaudRate;
      property Port: String read FPort write FPort;
      property ThreadTestList: TThreadList read FThreadTestList write FThreadTestList;
      property NoReplyWaitTimer: TTimer read FNoReplyWaitTimer write FNoReplyWaitTimer;
      constructor Create(CreateSuspended: Boolean);
      destructor Destroy; override;
      procedure ClearThreadList(AList: TThreadList);
      procedure TimerCallback(Sender: TObject);
  end;

  { TOpenLCBTestMatrix }

  TOpenLCBTestMatrix = class
  private
    FComPortThread: TComPortThread;
    FTestList: TList;
  public
    property ComPortThread: TComPortThread read FComPortThread write FComPortThread;
    property TestList: TList read FTestList write FTestList;
    constructor Create;
    destructor Destroy; override;
    procedure ClearTestList;
    procedure Add(Test: TTestBase);
    procedure Run;
  end;

implementation

{ TComPortThread }

procedure TComPortThread.Execute;
var
  List: TList;
  i: Integer;
  ActiveTest: TTestBase;
begin
  Serial := TBlockSerial.Create;
  Serial.LinuxLock:=False;
  Serial.RaiseExcept:=False;
  Serial.Connect(Port);
  try
    Connected:=True;
    Serial.Config(BaudRate, 8, 'N', 0, False, False);      // FTDI Driver uses no stop bits for non-standard baud rates.
    while not Terminated do
    begin
      ThreadSwitch;
      List := ThreadTestList.LockList;
      try
        if List.Count > 0 then
        begin
          ActiveTest := TTestBase( List[0]);
          if ActiveTest.TestState = ts_Idle then
          begin
            ActiveTest.TestState := ts_Sending;
            for i := 0 to ActiveTest.TestStrings.Count - 1 do
            begin
              if Length(ActiveTest.TestStrings[i]) > 0 then
              begin
                if ActiveTest.TestStrings[i][1] = ':' then              // Only send valid OpenLCB strings ":XnnnnnnnnNnn...."
                  Serial.SendString(ActiveTest.TestStrings[i] + LF);
              end;
            end;
            while Serial.SendingData > 0 do ThreadSwitch;          // Wait till "done" transmitting
            NoReplyWaitTimer.Interval := ActiveTest.WaitTime;      // Timer to detect no response
            NoReplyWaitTimer.Enabled := True;
            ActiveTest.TestState := ts_Receiving;
          end else
          if ActiveTest.TestState = ts_Receiving then
          begin
            if Serial.WaitingDataEx > 0 then
            begin
              try
                NoReplyWaitTimer.Enabled := False;            // Reset the No Reply Timer
                ActiveTest.TestStrings.Add('Receiving:');
                ActiveTest.TestStrings.Add(Trim( Serial.Recvstring(0)));
              finally
                NoReplyWaitTimer.Enabled := True;            // Restart the No Reply Timer
              end;
            end;
          end;
        end else
        begin

        end;
      finally
        ThreadTestList.UnlockList;
      end;
    end;
  finally
    if Connected then
      Serial.CloseSocket;
    Connected := False;
  end;
end;

constructor TComPortThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FThreadTestList := TThreadList.Create;
  FBaudRate := 9600;
  FPort := '';
  FNoReplyWaitTimer := TTimer.Create(nil);
  FNoReplyWaitTimer.Enabled := False;
  FNoReplyWaitTimer.OnTimer := @TimerCallback;
end;

destructor TComPortThread.Destroy;
begin
  ClearThreadList(FThreadTestList);
  FreeAndNil(FThreadTestList);
  FreeAndNil(FNoReplyWaitTimer);
  inherited Destroy;
end;

procedure TComPortThread.ClearThreadList(AList: TThreadList);
var
  List: TList;
  i: Integer;
begin
  if Assigned(AList) then
  begin
    List := AList.LockList;
    try
      if Assigned(List) then
      begin
        try
          for i := 0 to List.Count - 1 do
            TObject( List[i]).Free;
        finally
          List.Clear;
        end;
      end;
    finally
      AList.UnlockList;
    end;
  end;
end;

procedure TComPortThread.TimerCallback(Sender: TObject);
var
  List: TList;
  ActiveTest: TTestBase;
begin
  List := ThreadTestList.LockList;     // This is called in the context of the Thread so this is safe
  try
    if List.Count > 0 then
    begin
      ActiveTest := TTestBase( List[0]);      // The assumption here is the main thread loop started this and it did not fire randomly
      if ActiveTest.TestState = ts_Receiving then
      begin;
        if ActiveTest.Process then                 // Move to next state of the Test
          ActiveTest.TestState := ts_Idle          // There is another state, run it
        else begin
          List.Remove( List.First);                // Test is complete
          ActiveTest.TestState := ts_Complete;     // Remove it from the Thread List to Run
        end;
        NoReplyWaitTimer.Enabled := False;
      end;
    end;
  finally
    ThreadTestList.UnlockList;
  end;
end;

{ TOpenLCBTestMatrix }

constructor TOpenLCBTestMatrix.Create;
begin
  inherited Create;
  FTestList := TList.Create;
  FComPortThread := nil;
end;

destructor TOpenLCBTestMatrix.Destroy;
begin
  if Assigned(ComPortThread) then
  begin
    ComPortThread.Terminate;
    ComPortThread := nil;
  end;
  ClearTestList;
  FreeAndNil(FTestList);
  inherited Destroy;
end;

procedure TOpenLCBTestMatrix.ClearTestList;
var
  i: Integer;
begin
  try
    for i := 0 to TestList.Count - 1 do
      TObject( TestList[i]).Free;
  finally
    TestList.Clear;
  end;
end;

procedure TOpenLCBTestMatrix.Add(Test: TTestBase);
begin
  TestList.Add(Test);
end;

procedure TOpenLCBTestMatrix.Run;
var
  i: Integer;
  List: TList;
  Test: TTestBase;
begin
  List := ComPortThread.ThreadTestList.LockList;
  try
    for i := 0 to TestList.Count - 1 do
    begin
      Test := TTestBase( TestList[i]);
      Test.Process;       // Run first State
      List.Add(Test);
    end;
  finally
     ComPortThread.ThreadTestList.UnLockList;
  end;
end;

initialization
  RegisterClass(TTestVerifyNodeID);
  RegisterClass(TTestAliasMapEnquiry);

finalization


end.

