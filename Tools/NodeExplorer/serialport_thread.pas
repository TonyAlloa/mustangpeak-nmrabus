unit serialport_thread;

{$mode objfpc}{$H+}

interface
uses
  Classes, SysUtils, synaser, olcb_testmatrix, ExtCtrls, olcb_utilities, DOM, XMLRead, XMLWrite, unitDebugLogger,
  nodeexplorer_settings;

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
      procedure ErrorCodesToXML(ActiveTest: TtestBase; RootXMLElement: TDOMNode);
      procedure ErrorCodesFormatToXML(ActiveTest: TtestBase; RootXMLElement: TDOMNode);
      procedure ErrorCodesPipToXML(ActiveTest: TtestBase; RootXMLElement: TDOMNode);
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
  XMLRoot, XMLTestNode, XMLNode, XMLTestObjectiveNode, XMLObjectiveNode, XMLObjectiveResultsNode, XMLFailureCodes: TDOMNode;
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
                                  ActiveTest.InitTest;
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

                                    XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_SPECDOC);
                                    XMLObjectiveNode.AppendChild(XMLNode);
                                    XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(SpecDocFromObjectiveNode(TDOMNode( Objectives[iCurrentObjective]))));

                                    XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_SEND);
                                    XMLObjectiveNode.AppendChild(XMLNode);
                                    XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(ObjectiveFromObjectiveNode(TDOMNode( Objectives[iCurrentObjective]))));

                                    XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_RECEIVE);
                                    XMLObjectiveNode.AppendChild(XMLNode);
                                    XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(ObjectiveResultFromObjectiveNode(TDOMNode( Objectives[iCurrentObjective]))));

                                    XMLObjectiveResultsNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_OBJECTIVERESULTS);
                                    XMLTestObjectiveNode.AppendChild(XMLObjectiveResultsNode);
                                  end;

                                  ActiveTest.ErrorCodes := [];                  // Clear out the errors at the start of an objective so they can accumulate throught the objective

                                  ActiveTest.TestState := ts_Sending;
                                end;
            ts_Sending :        begin
                                  ProcessStrings.Clear;
                                  iCurrentObjective := ActiveTest.ProcessObjectives(ProcessStrings);  // Run Next State and get State specific strings
                                  for i := 0 to ProcessStrings.Count - 1 do          // Start with the next objective information
                                  begin
                                    Serial.SendString(ProcessStrings[i] + LF);
                                    XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_SEND);
                                    XMLObjectiveResultsNode.AppendChild(XMLNode);
                                    XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(ProcessStrings[i]));
                                  end;
                                  ProcessStrings.Clear;
                                  while Serial.SendingData > 0 do
                                    ThreadSwitch;                                    // Wait till "done" transmitting

                                  ActiveTest.TestState := ts_Receiving;
                                end;
            ts_Receiving      : begin
                                  TempStr := Serial.Recvstring(Settings.TimeoutComRead);  // Try to get something from the CAN
                                  if TempStr <> '' then
                                  begin
                                    ProcessStrings.Add( Trim( UpperCase(TempStr)));
                                    XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_RECEIVE);    // Received something, store and keep looking
                                    XMLObjectiveResultsNode.AppendChild(XMLNode);
                                    XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(ProcessStrings[ProcessStrings.Count - 1]));
                                  end else
                                  begin                                                 // Timed out, send in what was received
                                     iNextObjective := ActiveTest.ProcessObjectives(ProcessStrings);
                                     if iNextObjective = iCurrentObjective then          // Same objective to continue
                                       ActiveTest.TestState := ts_Sending
                                     else begin
                                       XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_PASS_FAIL);
                                       XMLObjectiveResultsNode.AppendChild(XMLNode);
                                       if ActiveTest.ErrorCodes = [] then
                                         XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_NAME_PASS))
                                       else begin
                                         XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_NAME_FAIL));

                                         XMLFailureCodes := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODES);
                                         XMLObjectiveResultsNode.AppendChild(XMLFailureCodes);

                                         ErrorCodesToXML(ActiveTest, XMLFailureCodes);
                                         ErrorCodesFormatToXML(ActiveTest, XMLFailureCodes);
                                         ErrorCodesPipToXML(ActiveTest, XMLFailureCodes);
                                       end;
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

procedure TComPortThread.ErrorCodesToXML(ActiveTest: TtestBase; RootXMLElement: TDOMNode);
var
  XMLNode: TDOMNode;
begin
  if ActiveTest.ErrorCodes <> [] then
  begin
    if teIncorrectCount in ActiveTest.ErrorCodes then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_FAILURE_INVALID_COUNT));
    end;
    if teFullNodeIDInvalid in ActiveTest.ErrorCodes then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_INVALID_NODE_ID));
    end;
    if teStandardFrameResponse in ActiveTest.ErrorCodes then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_STANDARD_FRAME));
    end;


  end;
end;

procedure TComPortThread.ErrorCodesFormatToXML(ActiveTest: TtestBase; RootXMLElement: TDOMNode);
var
  XMLNode: TDOMNode;
begin
  if ActiveTest.ErrorCodesFormat <> [] then
  begin
    if tefUnusedBitsSet in ActiveTest.ErrorCodesFormat then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_FORMAT_UNUSED_BITS_SET));
     end;
    if tefForwardingBitNotSet in ActiveTest.ErrorCodesFormat then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
       RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_FORMAT_FORWARDING_BIT_NOT_SET));
    end;
    if tefInvalidMTI in ActiveTest.ErrorCodesFormat then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
       XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_FORMAT_INVALID_MTI));
    end;
    if tefInvalidSourceAlias in ActiveTest.ErrorCodesFormat then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_FORMAT_INVALID_SOURCE_ALIAS));
    end;
    if tefInvalidDestAlias in ActiveTest.ErrorCodesFormat then
     begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_FORMAT_INVALID_DEST_ALIAS));
    end;
  end;
end;

procedure TComPortThread.ErrorCodesPipToXML(ActiveTest: TtestBase; RootXMLElement: TDOMNode);
var
  XMLNode: TDOMNode;
begin
  if ActiveTest.ErrorCodesPip <> [] then
  begin
    if tepPipUsingUnassignedBits in ActiveTest.ErrorCodesPip then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_PIP_UNASSIGNED_BITS));
    end;
    if tepPipUsingReservedBits in ActiveTest.ErrorCodesPip then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
       RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_PIP_RESERVED_BITS));
    end;
    if tepPipStartEndBitSupport in ActiveTest.ErrorCodesPip then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_PIP_START_END_BIT_SUPPORT));
     end;
    if tepPipRespondedToStartBit in ActiveTest.ErrorCodesPip then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_PIP_UNEXPECTED_RESPONSE_TO_START_BIT));
    end;
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

