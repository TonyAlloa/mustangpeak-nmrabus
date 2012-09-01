unit serialport_thread;

{$mode objfpc}{$H+}

interface
uses
  Classes, SysUtils, synaser, olcb_testmatrix, ExtCtrls, olcb_utilities, DOM, XMLRead, XMLWrite, unitDebugLogger,
  nodeexplorer_settings, dialogs;

const
  UI_UPDATE_RATE = 20;

type

{ TComPortThread }

  TSyncronizedMessageFunc = procedure(MessageStr: String);

  TComPortThread = class(TThread)
  private
    FActiveTest: TTestBase;
    FBaudRate: DWord;
    FConnected: Boolean;
    FPort: String;
    FSerial: TBlockSerial;
    FSyncronizedMessageStr: String;
    FTerminatedTest: Boolean;
    FTerminateTest: Boolean;
    FTestCount: Integer;
    FThreadTestList: TThreadList;
    FTimerUIUpdate: Word;
      procedure ShowStatus;
    protected
      property ActiveTest: TTestBase read FActiveTest write FActiveTest;
      property TimerUIUpdate: Word read FTimerUIUpdate write FTimerUIUpdate;
      property SyncronizedMessageStr: String read FSyncronizedMessageStr write FSyncronizedMessageStr;
      procedure Execute; override;
      procedure ErrorCodesToXML(RootXMLElement: TDOMNode);
      procedure ErrorCodesFormatToXML(RootXMLElement: TDOMNode);
      procedure ErrorCodesPipToXML(RootXMLElement: TDOMNode);
      procedure ErrorCodesUnknownMTI(RootXMLElement: TDOMNode);
      procedure ErrorCodesStartupToXML(RootXMLElement: TDOMNode);
      procedure SyncronizeUpdateUI;
      procedure SyncronizeMessageBox;
    public
      property Connected: Boolean read FConnected write FConnected;
      property Serial: TBlockSerial read FSerial write FSerial;
      property BaudRate: DWord read FBaudRate write FBaudRate;
      property Port: String read FPort write FPort;
      property ThreadTestList: TThreadList read FThreadTestList write FThreadTestList;
      property TerminateTest: Boolean read FTerminateTest write FTerminateTest;
      property TerminatedTest: Boolean read FTerminatedTest;
      property TestCount: Integer read FTestCount;
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
  TempStr: AnsiString;
  SendStrings, ReceiveStrings: TStringList;
  Objectives: TList;
  iNextObjective, iCurrentObjective: Integer;
  XMLRoot, XMLTestNode, XMLNode, XMLTestObjectiveNode, XMLObjectiveNode, XMLObjectiveResultsNode, XMLFailureCodes: TDOMNode;
  TimeSent, TimeReceived: DWORD;
begin
  Serial := TBlockSerial.Create;                           // Create the Serial object in the context of the thread
  Serial.LinuxLock:=False;
  Serial.RaiseExcept:=False;
  Serial.Connect(Port);
  SendStrings := TStringList.Create;
  ReceiveStrings := TStringList.Create;
  Objectives := TList.Create;
  try
    Connected:=True;
    Serial.Config(BaudRate, 8, 'N', 0, Settings.SoftwareFlowControl, False);      // FTDI Driver uses no stop bits for non-standard baud rates.
    while not Terminated do
    begin

      ThreadSwitch;

      // Pickup a new ActiveTest if needed
      if ActiveTest = nil then
      begin
        List := ThreadTestList.LockList;
        try
          if List.Count > 0 then
          begin
            ActiveTest := TTestBase( List[0]);
            List.Delete(0);
          end else
            ActiveTest := nil;
          FTestCount := List.Count;
        finally
          ThreadTestList.UnlockList;        // Deadlock if we don't do this here when the main thread blocks trying to add a new Test and we call Syncronize asking the main thread to run.....
        end;
      end;


      if Assigned(ActiveTest) then
      begin
        case ActiveTest.TestState of
          ts_Initialize     : begin
                                if Assigned(ActiveTest.ListItem) then
                                  Synchronize(@SyncronizeUpdateUI);
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

                                if TerminateTest then
                                  ActiveTest.TestState := ts_Complete
                                else
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

                                ActiveTest.ClearErrorCodes;                     // Clear out the errors at the start of an objective so they can accumulate throught the objective

                                if TerminateTest then
                                  ActiveTest.TestState := ts_Complete
                                else
                                  ActiveTest.TestState := ts_Sending;
                              end;
          ts_Sending :        begin
                                if Assigned(ActiveTest.ListItem) then
                                begin
                                  Inc(FTimerUIUpdate);
                                  if TimerUIUpdate = UI_UPDATE_RATE then
                                    Synchronize(@SyncronizeUpdateUI);
                                end;

                                SendStrings.Clear;
                                iCurrentObjective := ActiveTest.ProcessObjectives(SendStrings);  // Run Next State and get State specific strings
                                for i := 0 to SendStrings.Count - 1 do          // Start with the next objective information
                                begin
                                  if TerminateTest then
                                    Break;
                                  Serial.SendString(SendStrings[i] + LF);
                                  XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_SEND);
                                  XMLObjectiveResultsNode.AppendChild(XMLNode);
                                  XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(SendStrings[i]));
                                end;
                                SendStrings.Clear;
                                while Serial.SendingData > 0 do
                                  ThreadSwitch;                                    // Wait till "done" transmitting
                                TimeSent := GetTickCount;

                                ActiveTest.TestState := ts_Receiving;            // Receive what we asked for before terminating
                              end;
          ts_Receiving      : begin
                                if Assigned(ActiveTest.ListItem) then
                                begin
                                  Inc(FTimerUIUpdate);
                                  if TimerUIUpdate = UI_UPDATE_RATE then
                                    Synchronize(@SyncronizeUpdateUI);
                                end;

                                TempStr := Serial.Recvstring(Settings.TimeoutComRead);  // Try to get something from the CAN
                                if TempStr <> '' then
                                begin
                                  TimeReceived := GetTickCount;
                                  ReceiveStrings.Add( Trim( UpperCase(TempStr)));      THIS SORT OF ASSUMES ONE PACKET AT AT TIME RECEIVED>>>>>>>> RETHINK.......
                                  XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_RECEIVE);    // Received something, store and keep looking
                                  XMLObjectiveResultsNode.AppendChild(XMLNode);
                                  XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(ReceiveStrings[ReceiveStrings.Count - 1]));
                                end else
                                begin                                                 // Timed out, send in what was received
                                   iNextObjective := ActiveTest.ProcessObjectives(ReceiveStrings);
                                   if iNextObjective = iCurrentObjective then          // Same objective to continue
                                   begin
                                     if TerminateTest then
                                       ActiveTest.TestState := ts_Complete
                                     else
                                       ActiveTest.TestState := ts_Sending
                                   end else
                                   begin
                                     XMLNode := ActiveTest.XMLResults.CreateElement(XML_ELEMENT_PASS_FAIL);
                                     XMLObjectiveResultsNode.AppendChild(XMLNode);
                                     if ActiveTest.ErrorCodes = [] then
                                       XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_NAME_PASS))
                                     else begin
                                       XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_NAME_FAIL));

                                       XMLFailureCodes := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODES);
                                       XMLObjectiveResultsNode.AppendChild(XMLFailureCodes);

                                       ErrorCodesToXML(XMLFailureCodes);
                                       ErrorCodesFormatToXML(XMLFailureCodes);
                                       ErrorCodesPipToXML(XMLFailureCodes);
                                       ErrorCodesStartupToXML(XMLFailureCodes);
                                       ErrorCodesUnknownMTI(XMLFailureCodes);
                                     end;
                                     iCurrentObjective := iNextObjective;

                                     if TerminateTest then
                                       ActiveTest.TestState := ts_Complete
                                     else
                                       ActiveTest.TestState := ts_ObjectiveEnd;          // Start next objective
                                   end;
                                end;
                              end;
          ts_ObjectiveEnd :   begin
                                if iCurrentObjective < Objectives.Count then
                                begin
                                  if TerminateTest then
                                    ActiveTest.TestState := ts_Complete
                                  else
                                    ActiveTest.TestState := ts_ObjectiveStart
                                end else
                                  ActiveTest.TestState := ts_Complete;
                              end;
          ts_Complete       : begin
                                if TerminateTest then
                                begin
                                  List := ThreadTestList.LockList;
                                  try
                                    for i := List.Count - 1 downto 0 do
                                    begin
                                      if TTestBase( List[i]).FreeOnLog then
                                        TTestBase( List[i]).Free;
                                    end
                                  finally
                                    List.Clear;
                                    FTestCount := List.Count;
                                    ThreadTestList.UnlockList;
                                  end;
                                  FTerminatedTest := True;
                                  ActiveTest.ErrorCodes := ActiveTest.ErrorCodes + [teCancelled];
                                  Synchronize(@ActiveTest.CallbackTestComplete);
                                  ActiveTest := nil;
                                  FTerminatedTest := False;
                                  FTerminateTest := False;
                                end else
                                begin
                                  Synchronize(@ActiveTest.CallbackTestComplete);
                                  ActiveTest := nil;
                                end
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


    end;
  finally
    if Connected then
      Serial.CloseSocket;
    Connected := False;
    FreeAndNil(SendStrings);
    FreeAndNil(ReceiveStrings);
    FreeandNil(Objectives);
  end;
end;

procedure TComPortThread.ErrorCodesToXML(RootXMLElement: TDOMNode);
var
  XMLNode: TDOMNode;
begin
  if ActiveTest.ErrorCodes <> [] then
  begin
    if teIncorrectCount in ActiveTest.ErrorCodes then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_INVALID_COUNT));
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

procedure TComPortThread.ErrorCodesFormatToXML(RootXMLElement: TDOMNode);
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

procedure TComPortThread.ErrorCodesPipToXML(RootXMLElement: TDOMNode);
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

procedure TComPortThread.ErrorCodesUnknownMTI(RootXMLElement: TDOMNode);
var
  XMLNode: TDOMNode;
begin
  if ActiveTest.ErrorCodesUnknownMTI <> [] then
  begin
    if tuExpectedOIR in ActiveTest.ErrorCodesUnknownMTI then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_UNKOWN_MTI_EXPECTED_OIR));
    end;
    if tuInvalidDestAlias in ActiveTest.ErrorCodesUnknownMTI then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_UNKOWN_MTI_INVALID_DEST_ALIAS));
    end;
    if tuOptionalCode in ActiveTest.ErrorCodesUnknownMTI then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_UNKOWN_MTI_OPTIONAL_CODE));
    end;
    if tuMTIMismatch in ActiveTest.ErrorCodesUnknownMTI then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_UNKOWN_MTI_NO_MATCH));
    end;
  end;

end;

procedure TComPortThread.ErrorCodesStartupToXML(RootXMLElement: TDOMNode);
var
  XMLNode: TDOMNode;
begin
  if ActiveTest.ErrorCodesStartup <> [] then
  begin
    if tsNoAMR in ActiveTest.ErrorCodesStartup then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_NO_STARTUP_NO_AMR));
    end;
    if tsNoCID0 in ActiveTest.ErrorCodesStartup then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_NO_STARTUP_NO_CID0));
    end;
    if tsNoCID1 in ActiveTest.ErrorCodesStartup then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_NO_STARTUP_NO_CID1));
    end;
    if tsNoCID2 in ActiveTest.ErrorCodesStartup then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_NO_STARTUP_NO_CID2));
    end;
    if tsNoCID3 in ActiveTest.ErrorCodesStartup then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_NO_STARTUP_NO_CID3));
    end;
    if tsNoRID in ActiveTest.ErrorCodesStartup then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_NO_STARTUP_NO_RID));
    end;
    if tsNoAMD in ActiveTest.ErrorCodesStartup then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_NO_STARTUP_NO_AMD));
    end;
    if tsNoInitialized in ActiveTest.ErrorCodesStartup then
    begin
      XMLNode := ActiveTest.XMLResults.CreateElement(XML_NAME_FAILURE_CODE);
      RootXMLElement.AppendChild(XMLNode);
      XMLNode.AppendChild(ActiveTest.XMLResults.CreateTextNode(XML_ERROR_NO_STARTUP_NO_INITIALZIED));
    end;
  end
end;

procedure TComPortThread.SyncronizeUpdateUI;
begin
  if Assigned(ActiveTest) then
  begin
    if Assigned(ActiveTest.ListItem) then
    begin
      if ActiveTest.ListItem.ImageIndex = 20 then
        ActiveTest.ListItem.ImageIndex := 21
      else
        ActiveTest.ListItem.ImageIndex := 20;
    end;
  end;
  TimerUIUpdate := 0;
end;

procedure TComPortThread.SyncronizeMessageBox;
begin
  ShowMessage(SyncronizedMessageStr);
end;

procedure TComPortThread.ShowStatus;
begin
  if Assigned(ActiveTest) then
  begin
    if ActiveTest.TestState = ts_Initialize then
      ActiveTest.ListItem.ImageIndex := 19;
    if ActiveTest.TestState = ts_ObjectiveEnd then
      ActiveTest.ListItem.ImageIndex := 2;
  end;
end;

constructor TComPortThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FActiveTest := nil;
  FThreadTestList := TThreadList.Create;
  FBaudRate := 9600;
  FPort := '';
  FTimerUIUpdate := 0;
  FTestCount := 0;
  FTerminateTest := False;
  FTerminatedTest := False;
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
    FTestCount := List.Count;
  finally
    ThreadTestList.UnLockList;
  end;
end;


end.
