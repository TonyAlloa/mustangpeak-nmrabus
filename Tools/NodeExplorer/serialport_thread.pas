unit serialport_thread;

{$mode objfpc}{$H+}

interface
uses
  Classes, SysUtils, synaser, olcb_testmatrix, ExtCtrls, olcb_utilities, DOM, XMLRead, XMLWrite;

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
    constructor Create;
    destructor Destroy; override;
    procedure Add(Test: TTestBase);
  end;

implementation

{ TComPortThread }

procedure TComPortThread.Execute;
var
  List: TList;
  i: Integer;
  ActiveTest: TTestBase;
  TempStr: AnsiString;
  ProcessStrings: TStringList;
  Objectives: TList;
  iNextObjective, iCurrentObjective, ObjectiveCount: Integer;
begin
  Serial := TBlockSerial.Create;                           // Create the Serial object in the context of the thread
  Serial.LinuxLock:=False;
  Serial.RaiseExcept:=False;
  Serial.Connect(Port);
  ProcessStrings := TStringList.Create;
  Objectives := TList.Create;
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

          case ActiveTest.TestState of
            ts_Initialize     : begin
                                  ActiveTest.TestStrings.Clear;
                                  ActiveTest.StateMachineIndex := 0;
                                  iCurrentObjective := 0;
                                  ExtractTestObjectivesFromTestNode(ActiveTest.XMLNode, Objectives);
                                  ObjectiveCount := Objectives.Count;
                                  if ObjectiveCount < 1 then
                                  begin
                                    ActiveTest.TestStrings.Add('<objective>');
                                    ActiveTest.TestStrings.Add('None Found');
                                    ActiveTest.TestStrings.Add('</objective>');
                                    ActiveTest.TestState := ts_Complete;
                                  end;
                                  ActiveTest.TestState := ts_ObjectiveStart;
                                end;
            ts_ObjectiveStart : begin
                                  ActiveTest.TestStrings.Add('<objective>');
                                  if iCurrentObjective < ObjectiveCount then
                                    ActiveTest.TestStrings.Add(ObjectiveFromObjectiveNode(TDOMNode( Objectives[iCurrentObjective])));
                                  ActiveTest.TestState := ts_Sending;
                                end;
            ts_Sending :        begin
                                  ActiveTest.TestStrings.Add('<send>');
                                  Activetest.TestStrings.Add('Test: ' + TestNameFromTestNode(ActiveTest.XMLNode));
                                  Activetest.TestStrings.Add(TestDescriptionFromTestNode(ActiveTest.XMLNode));
                                  iCurrentObjective := ActiveTest.Process(ProcessStrings);  // Run Next State and get State specific strings
                                  for i := 0 to ProcessStrings.Count - 1 do          // Start with the next objective information
                                  begin
                                    if Length(ProcessStrings[i]) > 0 then
                                    begin
                                      if ProcessStrings[i][1] = ':' then              // Only send valid OpenLCB strings ":XnnnnnnnnNnn...."
                                        Serial.SendString(ProcessStrings[i] + LF);
                                    end;
                                  end;
                                  Activetest.TestStrings.Text := ActiveTest.TestStrings.Text + ProcessStrings.Text;
                                  while Serial.SendingData > 0 do
                                    ThreadSwitch;                                    // Wait till "done" transmitting
                                  ActiveTest.TestStrings.Add('</send>');
                                  ActiveTest.TestState := ts_Receiving;
                                  ActiveTest.TestStrings.Add('<receive>');
                                end;
            ts_Receiving      : begin
                                  TempStr := Serial.Recvstring(ActiveTest.WaitTime);  // Try to get something from the CAN
                                  if TempStr <> '' then
                                    ActiveTest.TestStrings.Add(Trim(TempStr))         // Received something, store and keep looking
                                  else begin
                                     iNextObjective := ActiveTest.Process(ProcessStrings); // Timed out, move on
                                     if iNextObjective = iCurrentObjective then          // Same objective to continue
                                       ActiveTest.TestState := ts_Sending
                                     else begin
                                       iCurrentObjective := iNextObjective;
                                       ActiveTest.TestState := ts_ObjectiveEnd;          // Start next objective
                                     end;
                                     ActiveTest.TestStrings.Add('</receive>');
                                  end;
                                end;
            ts_ObjectiveEnd :   begin
                                  ActiveTest.TestStrings.Add('</objective>');
                                  if iCurrentObjective < ObjectiveCount then
                                    ActiveTest.TestState := ts_ObjectiveStart
                                  else
                                    ActiveTest.TestState := ts_Complete;
                                end;
            ts_Complete       : begin
                                end;
          end;
        end else
        begin
          // Unsolicited Information
          TempStr := Serial.Recvstring(0);
          if TempStr <> '' then
          begin
            ///  Do something?///
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
    FreeAndNil(ProcessStrings);
    FreeandNil(Objectives);
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
  inherited Destroy;
end;

procedure TOpenLCBTestMatrix.Add(Test: TTestBase);
var
  i: Integer;
  List: TList;
begin
  Test.TestState := ts_Initialize;
  List := ComPortThread.ThreadTestList.LockList;
  try
    List.Add(Test);     // Add it to the Thread List
  finally
    ComPortThread.ThreadTestList.UnLockList;
  end;
end;

initialization
  RegisterClass(TTestVerifyNodeID);
  RegisterClass(TTestAliasMapEnquiry);

finalization


end.

