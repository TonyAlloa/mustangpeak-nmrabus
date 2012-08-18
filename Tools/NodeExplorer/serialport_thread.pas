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
  iNextObjective, iCurrentObjective: Integer;
  XMLRoot, XMLTestNode, XMLNode, XMLTestObjectiveNode, XMLObjectiveNode, XMLObjectiveResultsNode: TDOMNode;
  PassResult: Boolean;
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
                                  Objectives.Clear;
                                  ActiveTest.StateMachineIndex := 0;
                                  iCurrentObjective := 0;
                                  ExtractTestObjectivesFromTestNode(ActiveTest.XMLTests, Objectives);

                                  if ActiveTest.XMLResults.DocumentElement <> nil then
                                    ActiveTest.XMLResults.RemoveChild(ActiveTest.XMLResults.DocumentElement);
                                  ActiveTest.XMLResults.AppendChild(ActiveTest.XMLResults.CreateElement(XML_ELEMENT_TEST_RESULT_ROOT));

                                  XMLRoot := ActiveTest.XMLResults.FindNode(XML_ELEMENT_TEST_RESULT_ROOT);

                                  XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_NAME);
                                  XMLRoot.AppendChild(XMLNode);
                                  XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(TestNameFromTestNode(ActiveTest.XMLTests)));

                                  XMLTestNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_TEST);
                                  XMLRoot.AppendChild(XMLTestNode);

                                  XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_DESCRIPTION);
                                  XMLTestNode.AppendChild(XMLNode);
                                  XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(TestDescriptionFromTestNode(ActiveTest.XMLTests)));

                                  XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_SPECDOC);
                                  XMLTestNode.AppendChild(XMLNode);
                                  XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(TestSpecDocFromTestNode(ActiveTest.XMLTests)));

                                  XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_CLASSNAME);
                                  XMLTestNode.AppendChild(XMLNode);
                                  XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(TestClassnameFromTestNode(ActiveTest.XMLTests)));

                                  ActiveTest.TestState := ts_ObjectiveStart;
                                end;
            ts_ObjectiveStart : begin
                                  XMLTestObjectiveNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_TESTOBJECTIVE);
                                  XMLTestNode.AppendChild(XMLTestObjectiveNode);

                                  if iCurrentObjective < Objectives.Count then
                                  begin
                                    XMLObjectiveNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_OBJECTIVE);
                                    XMLTestObjectiveNode.AppendChild(XMLObjectiveNode);

                                    XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_NAME);
                                    XMLObjectiveNode.AppendChild(XMLNode);
                                    XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(ObjectiveFromObjectiveNode(TDOMNode( Objectives[iCurrentObjective]))));
                                  end;

                                  ActiveTest.TestState := ts_Sending;
                                end;
            ts_Sending :        begin
                                  PassResult := False;
                                  ProcessStrings.Clear;
                                  iCurrentObjective := ActiveTest.ProcessObjectives(ProcessStrings, PassResult);  // Run Next State and get State specific strings
                                  for i := 0 to ProcessStrings.Count - 1 do          // Start with the next objective information
                                  begin
                                    Serial.SendString(ProcessStrings[i] + LF);
                                    XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_SEND);
                                    XMLObjectiveNode.AppendChild(XMLNode);
                                    XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(ProcessStrings[i]));
                                  end;
                                  ProcessStrings.Clear;
                                  while Serial.SendingData > 0 do
                                    ThreadSwitch;                                    // Wait till "done" transmitting

                                  ActiveTest.TestState := ts_Receiving;

                                  XMLObjectiveResultsNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_OBJECTIVERESULTS);
                                  XMLTestObjectiveNode.AppendChild(XMLObjectiveResultsNode);

                                  XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_NAME);
                                  XMLObjectiveResultsNode.AppendChild(XMLNode);
                                  XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(ObjectiveResultFromObjectiveNode(TDOMNode( Objectives[iCurrentObjective]))));
                                end;
            ts_Receiving      : begin
                                  TempStr := Serial.Recvstring(ActiveTest.WaitTime);  // Try to get something from the CAN
                                  if TempStr <> '' then
                                  begin
                                    ProcessStrings.Add(TempStr);
                                    XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_RECEIVE);    // Received something, store and keep looking
                                    XMLObjectiveResultsNode.AppendChild(XMLNode);
                                    XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(Trim(TempStr)));
                                  end else
                                  begin
                                     PassResult := False;
                                     iNextObjective := ActiveTest.ProcessObjectives(ProcessStrings, PassResult); // Timed out, send in what was received
                                     if iNextObjective = iCurrentObjective then          // Same objective to continue
                                       ActiveTest.TestState := ts_Sending
                                     else begin
                                       XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_PASS_FAIL);
                                       XMLTestObjectiveNode.AppendChild(XMLNode);
                                       if PassResult then
                                         XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_NAME_PASS))
                                       else
                                         XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_NAME_FAIL));
                                       iCurrentObjective := iNextObjective;
                                       ActiveTest.TestState := ts_ObjectiveEnd;          // Start next objective
                                     end;
                                  end;
                                end;
            ts_ObjectiveEnd :   begin
                                  if iCurrentObjective < Objectives.Count then
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

procedure TComPortThread.Add(Test: TTestBase);
var

  List: TList;
begin
  Test.TestState := ts_Initialize;
  List := ThreadTestList.LockList;
  try
    List.Add(Test);     // Add it to the Thread List
  finally
    ThreadTestList.UnLockList;
  end;
end;


end.

