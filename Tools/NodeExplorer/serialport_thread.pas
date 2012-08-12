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
    FThreadTestList: TThreadList;
    protected
      procedure Execute; override;
    public
      property Connected: Boolean read FConnected write FConnected;
      property Serial: TBlockSerial read FSerial write FSerial;
      property BaudRate: DWord read FBaudRate write FBaudRate;
      property Port: String read FPort write FPort;
      property ThreadTestList: TThreadList read FThreadTestList write FThreadTestList;
      constructor Create(CreateSuspended: Boolean);
      destructor Destroy; override;
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
  TempStr: AnsiString;
begin
  Serial := TBlockSerial.Create;                           // Create the Serial object in the context of the thread
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
            while Serial.SendingData > 0 do
              ThreadSwitch;                                             // Wait till "done" transmitting
            ActiveTest.TestState := ts_Receiving;
          end else
          if ActiveTest.TestState = ts_Receiving then
          begin
            TempStr := Serial.Recvstring(ActiveTest.WaitTime);
            if TempStr <> '' then
              ActiveTest.TestStrings.Add('Receiving: '+Trim(TempStr))
            else
              ActiveTest.TestState := ts_Complete;
            end;
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
end;

destructor TComPortThread.Destroy;
begin
  FreeAndNil(FThreadTestList);   // Thread does not own the items so just empty the list
  inherited Destroy;
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
      List.Add(Test);     // Add it to the Thread List
    end;
  finally
     TestList.Clear;
     ComPortThread.ThreadTestList.UnLockList;
  end;
end;

initialization
  RegisterClass(TTestVerifyNodeID);
  RegisterClass(TTestAliasMapEnquiry);

finalization


end.

