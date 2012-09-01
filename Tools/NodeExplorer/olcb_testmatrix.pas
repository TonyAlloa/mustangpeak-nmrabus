unit olcb_testmatrix;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, olcb_utilities, unitolcb_defines, nodeexplorer_settings,
  DOM, XMLRead, XMLWrite, ComCtrls, unitDebugLogger;

const
  MAX_MTI_VALUE             = $09FFF000;
  MIN_MTI_VALUE             = $09000000;
  MTI_INC_STEP              = $00001000;
  MTI_ADDRESSED_BIT         = $00008000;

  PIP_UNASSIGNED_MASK       = $0007FFFFFFF0;
  PIP_RESERVED_MASK         = $00000000000F;
  PIP_EXTENSION_BIT_START   = $1000;                 // Active 0 so "xx01" were the 0 is the set bit and MSB it on the left... a network thing I guess
  PIP_EXTENSION_BIT_END     = $2000;                 // Active 0 so "xx10" were the 0 is the set bit and MSB is on the left... a network thing I guess

  STR_PROTOCOL_IDENTIFICATION_PROTOCOL_CLASS = 'TTestProtocolSupport';
  STR_TEST_GET_NODES_UNDER_TEST_CLASS        = 'TTestGetNodesUnderTest';

  XML_ERROR_INVALID_COUNT = 'The expected number of messages received for the objective was not met';
  XML_ERROR_INVALID_NODE_ID = 'The full node ID received did not match the Full Node Alias that Node Explorer was expecting for the test node';
  XML_ERROR_STANDARD_FRAME = 'The node should not respond to CAN standard frame (11 bit) messages';

  XML_ERROR_FORMAT_UNUSED_BITS_SET = 'The top 2 bits in the extended CAN header are not set to "0"';
  XML_ERROR_FORMAT_FORWARDING_BIT_NOT_SET = 'Bit 28 in the CAN header should be set if the node is not used to forward across network segments';
  XML_ERROR_FORMAT_INVALID_MTI = 'Bits 12-23 (MTI) in the CAN header were not correct in the reply';
  XML_ERROR_FORMAT_INVALID_SOURCE_ALIAS = 'Bits 0-11 defining the Node Alias did not match the stored Node Alias that Node Explorer was expecting for the test node';
  XML_ERROR_FORMAT_INVALID_DEST_ALIAS = 'Destination Alias (either in the CAN header or first 2 data bytes) did not match Proxy Alias of Node Explorer';

  XML_ERROR_PIP_UNASSIGNED_BITS = 'The node is using the bits in the Protocol Identification Protocol that are current unassigned';
  XML_ERROR_PIP_RESERVED_BITS = 'The node is using the bits in the Protocol Identification Protocol defined as reserved';
  XML_ERROR_PIP_START_END_BIT_SUPPORT = 'The node does not support the Protocol Identification Protocol start-end bit for future expansion, it is suggested this be implemented';
  XML_ERROR_PIP_UNEXPECTED_RESPONSE_TO_START_BIT = 'The node should not have responded to the PIP expansion start bit, it should have waited until the stop bit is sent';

  XML_ERROR_UNKOWN_MTI_EXPECTED_OIR = 'No Optional Interaction Recevied message recevied from the node';
  XML_ERROR_UNKOWN_MTI_INVALID_DEST_ALIAS =  'The destination Alias sent by the node was incorrect';
  XML_ERROR_UNKOWN_MTI_OPTIONAL_CODE = 'The optional code sent by the node should have been Permenemt Error ($2000) in the result';
  XML_ERROR_UNKOWN_MTI_NO_MATCH = 'The unknown MTI value should have been sent as extra data in the result';

  XML_ERROR_NO_STARTUP_NO_AMR = 'No Alias Mapping Reset (AMR) was detected';
  XML_ERROR_NO_STARTUP_NO_CID0 = 'The first Check ID (CID0) message was not detected';
  XML_ERROR_NO_STARTUP_NO_CID1 = 'The second Check ID (CID1) message was not detected';
  XML_ERROR_NO_STARTUP_NO_CID2 = 'The third Check ID (CID2) message was not detected';
  XML_ERROR_NO_STARTUP_NO_CID3 = 'The fourth Check ID (CID3) message was not detected';
  XML_ERROR_NO_STARTUP_NO_RID = 'The Reserve ID message was not detected';
  XML_ERROR_NO_STARTUP_NO_AMD = 'The Alias Mapping Definition (AMD) was not detected';
  XML_ERROR_NO_STARTUP_NO_INITIALZIED = 'The Node Initialized message was not detected';


type
  TTestErrorCode = (
    teIncorrectCount,          // The wrong number of messages were returned from the Node (not always possible to determine depends on message)
    teFullNodeIDInvalid,       // Full NodeID in the Data Bytes does not match what is stored in Settings for the node under test
    teStandardFrameResponse,   // Node replied to a Standard Frame Message, it should igore them all
    teCancelled                // The test was cancled
  );
  TTestErrorCodes = set of TTestErrorCode;

  TTestErrorFormatCode = (
    tefUnusedBitsSet,           // The node set one of the 3 unused upper bits (not accessible in CAN?)
    tefForwardingBitNotSet,     // Reserved bit was not a 1
    tefInvalidMTI,              // MTI was incorrect (includes the Frame Type set for OpenLCB messages)
    tefInvalidSourceAlias,      // Source Alias of the message sent back to Node Explorer was incorrect (assumes a single node under test)
    tefInvalidDestAlias        // Dest Alias of the message sent back to Node Explorer was incorrect (assumes a single node under test)
  );
  TTestErrorFormatCodes = set of TTestErrorFormatCode;

  TTestErrorPipCode = (
    tepPipUsingReservedBits,    // Using Reserved Bits in the PIP
    tepPipUsingUnassignedBits,  // Using Unassigned Bits in the PIP
    tepPipRespondedToStartBit,  // Unexpected response to start bit of extended PIP support
    tepPipStartEndBitSupport    // PIP implementation does not support the start and stop bit convention
  );
  TTestErrorPipCodes = set of TTestErrorPipCode;

  TTestUnknownMTICode = (
    tuExpectedOIR,              // Node did not send an Optional Interaction Rejected message
    tuInvalidDestAlias,         // Invalid destination alias sent by node
    tuOptionalCode,             // OIR Code was incorrect
    tuMTIMismatch               // The MTI did not match
  );
  TTestUnknownMTICodes = set of TTestUnknownMTICode;

  TTestNodeStartupCode = (
    tsNoAMR,                     // No AMR detected
    tsNoCID0,                    // No Check ID 0
    tsNoCID1,                    // No Check ID 1
    tsNoCID2,                    // No Check ID 2
    tsNoCID3,                    // No Check ID 3
    tsNoRID,                      // No Reserve ID
    tsNoAMD,                     // No Alias Map Definition
    tsNoInitialized              // No Node Initalized
  );
  TTestNodeStartupCodes = set of TTestNodeStartupCode;

type
  TTestState = (ts_Idle, ts_Initialize, ts_ObjectiveStart, ts_Sending, ts_Receiving, ts_ObjectiveEnd, ts_Complete);

  TMTIArray = array of DWord;

  { TKnownMTI }

  TKnownMTI = class
  private
    FMTI: DWord;
    FMTIArray: TMTIArray;
    FMTIList: TStringList;
  protected
    function DuplicateMTI(TestMTI: DWord): Boolean;
  public
    constructor Create;
    destructor Destroy;
    function FirstUnknownMTI: DWord;
    function NextUnknownMTI: DWord;
    procedure ResetMTI;
    property MTIList: TStringList read FMTIList write FMTIList;
    property MTI: DWord read FMTI write FMTI;
    property MTIArray: TMTIArray read FMTIArray write FMTIArray;
  end;

  TTestBase = class;
  TTestCompleteCallback = procedure(Test: TTestBase) of object;

  { TTestBase }

  TTestBase = class(TPersistent)
  private
    FErrorCodes: TTestErrorCodes;
    FErrorCodesFormat: TTestErrorFormatCodes;
    FErrorCodesPip: TTestErrorPipCodes;
    FErrorCodesStartup: TTestNodeStartupCodes;
    FErrorCodesUnknownMTI: TTestUnknownMTICodes;
    FErrorCodesUnknownMTIStrings: TStringList;
    FFreeOnLog: Boolean;
    FListItem: TListItem;
    FMessageHelper: TOpenLCBMessageHelper;
    FStateMachineIndex: Integer;
    FTestCompleteCallback: TTestCompleteCallback;
    FTestState: TTestState;
    FXMLResults: TXMLDocument;
    FXMLTests: TDOMNode;
    function GetPassed: Boolean;
  protected
    property MessageHelper: TOpenLCBMessageHelper read FMessageHelper write FMessageHelper;
    function TestForStartupReturn(Messages: TStringList; ExpectedMessageIndex: Integer; ExpectedMTI: DWord; ErrorCode: TTestNodeStartupCode): Boolean;
  public
    property ErrorCodes: TTestErrorCodes read FErrorCodes write FErrorCodes;
    property ErrorCodesFormat: TTestErrorFormatCodes read FErrorCodesFormat write FErrorCodesFormat;
    property ErrorCodesPip: TTestErrorPipCodes read FErrorCodesPip write FErrorCodesPip;
    property ErrorCodesUnknownMTIStrings: TStringList read FErrorCodesUnknownMTIStrings write FErrorCodesUnknownMTIStrings;
    property ErrorCodesUnknownMTI: TTestUnknownMTICodes read FErrorCodesUnknownMTI write FErrorCodesUnknownMTI;
    property ErrorCodesStartup: TTestNodeStartupCodes read FErrorCodesStartup write FErrorCodesStartup;
    property FreeOnLog: Boolean read FFreeOnLog write FFreeOnLog;
    property ListItem: TListItem read FListItem write FListItem;
    property Passed: Boolean read GetPassed;
    property StateMachineIndex: Integer read FStateMachineIndex write FStateMachineIndex;
    property TestCompleteCallback: TTestCompleteCallback read FTestCompleteCallback write FTestCompleteCallback;
    property TestState: TTestState read FTestState write FTestState;
    property XMLTests: TDOMNode  read FXMLTests write FXMLTests;                // Node that describes the test from the Test Matrix XML file ( <test>...</test> )
    property XMLResults: TXMLDocument read FXMLResults write FXMLResults;

    constructor Create; virtual;
    destructor Destroy; override;
    class function CreateInstanceFromString(AClassname: String): TTestBase;
    function ProcessObjectives(ProcessStrings: TStringList): Integer; virtual;
    procedure InitTest; virtual;
    procedure StripReceivesNotForNodeUnderTest(ReceiveStrings: TStringList);
    procedure ValidateBasicReturnMessage(ExpectedMTI: DWord; Helper: TOpenLCBMessageHelper); virtual;
    procedure ClearErrorCodes;
    procedure CallbackTestComplete;

  end;
  TTestBaseClass = class of TTestBase;

  { TTestGetNodesUnderTest }

  TTestGetNodesUnderTest = class(TTestBase)
  public
    function ProcessObjectives(ProcessStrings: TStringList): Integer; override;
  end;
  TTestVerifyNodesIDClass = class of TTestGetNodesUnderTest;

  { TTestAliasMapEnquiry }

  TTestAliasMapEnquiry = class(TTestBase)
  public
    function ProcessObjectives(ProcessStrings: TStringList): Integer; override;
  end;
  TTestAliasMapEnquiryClass = class of TTestAliasMapEnquiry;

  { TTestVerifyNodeID }

  TTestVerifyNodeID = class(TTestBase)
  public
    function ProcessObjectives(ProcessStrings: TStringList): Integer; override;
  end;
  TTestVerifyNodeIDClass = class of TTestVerifyNodeID;

  { TTestProtocolSupport }

  TTestProtocolSupport = class(TTestBase)
  public
    function ProcessObjectives(ProcessStrings: TStringList): Integer; override;
  end;
  TTestProtocolSupportClass = class of TTestProtocolSupport;

  { TTestStandardFrame }

  TTestStandardFrame = class(TTestBase)
  private
    FiFrame: Integer;
  public
    procedure InitTest; override;
    function ProcessObjectives(ProcessStrings: TStringList): Integer; override;
    property iFrame: Integer read FiFrame write FiFrame;
  end;
  TTestStandardFrameClass = class of TTestStandardFrame;

  { TTestUnknownMTIAddressed }

  TTestUnknownMTIAddressed = class(TTestBase)
  private
    FMTIManager: TKnownMTI;
  public
    constructor Create; override;
    destructor Destroy; override;
    function ProcessObjectives(ProcessStrings: TStringList): Integer; override;
    procedure InitTest; override;
    property MTIManager: TKnownMTI read FMTIManager write FMTIManager;
  end;
  TTestUnknownMTIAddressedClass = class of TTestUnknownMTIAddressed;

  { TTestAliasConflict }

  TTestAliasConflict = class(TTestBase)
  public
    function ProcessObjectives(ProcessStrings: TStringList): Integer; override;
  end;
  TTestAliasConflictClass = class of TTestAliasConflict;

  { TTestZeroOrRepeatedAllocation }

  TTestZeroOrRepeatedAllocation = class(TTestBase)
  private
    FReAllocationCount: Integer;
  public
    procedure InitTest; override;
    function ProcessObjectives(ProcessStrings: TStringList): Integer; override;
    property ReAllocationCount: Integer read FReAllocationCount write FReAllocationCount;
  end;
  TTestZeroOrRepeatedAllocationClass = class of TTestZeroOrRepeatedAllocation;

  { TTestStartup }

  TTestStartup = class(TTestBase)
  public
    function ProcessObjectives(ProcessStrings: TStringList): Integer; override;
  end;
  TTestStartupClass = class of TTestStartup;


  function FindTestFromXML(XMLDocTests: TXMLDocument; TestClassName: String): TTestBase;
  procedure ExtractResultsFromXML(XMLDoc: TXMLDocument; ReceiveResults: TStringList);

implementation

function FindTestFromXML(XMLDocTests: TXMLDocument; TestClassName: String): TTestBase;
var
  ClassNode: TDOMNode;
  TestClass: TTestBaseClass;
  i: Integer;
begin
  Result := nil;
  TestClass := nil;
  if Assigned(XMLDocTests) then
  begin
    for i := 0 to XMLDocTests.DocumentElement.ChildNodes.Count - 1 do
    begin
      if XMLDocTests.DocumentElement.ChildNodes[i].NodeName = XML_ELEMENT_TEST then
      begin
        ClassNode := XMLDocTests.DocumentElement.ChildNodes[i].FindNode(XML_ELEMENT_CLASSNAME);
        if Assigned(ClassNode) then
        begin
          if TestClassName = ClassNode.FirstChild.NodeValue then
          begin
            Result := TestClass.CreateInstanceFromString(TestClassName);
            Result.XMLTests := XMLDocTests.DocumentElement.ChildNodes[i];
          end;
        end;
      end;
    end;
  end;
end;

procedure ExtractResultsFromXML(XMLDoc: TXMLDocument; ReceiveResults: TStringList);
var
  TestResult, Test, TestObjective, Results: TDOMNode;
  i: Integer;
begin
  ReceiveResults.Clear;
  if Assigned(XMLDoc) then
  begin
    TestResult := XMLDoc.FindNode(XML_ELEMENT_TEST_RESULT_ROOT);
    if Assigned(TestResult) then
    begin
      Test := TestResult.FindNode(XML_ELEMENT_TEST);
      if Assigned(Test) then
      begin
        TestObjective := Test.FindNode(XML_ELEMENT_TESTOBJECTIVE);
        if Assigned(TestObjective) then
        begin
          Results := TestObjective.FindNode(XML_ELEMENT_OBJECTIVERESULTS);
          if Assigned(Results) then
          begin
            for i := 0 to Results.ChildNodes.Count - 1 do
            begin
              if Results.ChildNodes[i].NodeName = XML_ELEMENT_RECEIVE then
                ReceiveResults.Add(Results.ChildNodes[i].FirstChild.NodeValue);
            end;
          end;
        end;
      end;
    end;
  end;
end;


{ TKnownMTI }

function TKnownMTI.DuplicateMTI(TestMTI: DWord): Boolean;
var
  i: Integer;
begin
  Result := False;
  i := 0;
  while (i < Length(FMTIArray)) and not Result do
  begin
    Result := TestMTI = MTIArray[i];
    Inc(i);
  end;
end;

constructor TKnownMTI.Create;
begin
  inherited Create;
  FMTIList := TStringList.Create;
  ResetMTI;
end;

destructor TKnownMTI.Destroy;
begin
  FreeAndNil(FMTIList);
end;

function TKnownMTI.FirstUnknownMTI: DWord;
begin
  FMTI := MIN_MTI_VALUE;
  // Stop when the max value is but keep going if it is a Known MTI or it does not have the Addressed Bit set
  while (MTI <= MAX_MTI_VALUE) and (DuplicateMTI( MTI) or (MTI and MTI_ADDRESSED_BIT = 0)) do
    FMTI := FMTI + MTI_INC_STEP;
  Result := FMTI;
end;

function TKnownMTI.NextUnknownMTI: DWord;
begin
  FMTI := FMTI + MTI_INC_STEP;
  // Stop when the max value is but keep going if it is a Known MTI or it does not have the Addressed Bit set
  while (MTI <= MAX_MTI_VALUE) and (DuplicateMTI( MTI) or (MTI and MTI_ADDRESSED_BIT = 0)) do
    FMTI := FMTI + MTI_INC_STEP;
  Result := FMTI;
end;

procedure TKnownMTI.ResetMTI;
var
  i: Integer;
begin
  FMTI := MIN_MTI_VALUE;
  {$IFDEF Windows}
  MTIList.LoadFromFile(Settings.ApplicationPath + FILENAME_KNOWN_MTI_WIN);
  {$ENDIF}
  {$IFDEF darwin}
  MTIList.LoadFromFile(Settings.ApplicationPath + FILENAME_KNOWN_MTI_UNIX);
  {$ENDIF}
  SetLength(FMTIArray, MTIList.Count);
  for i := 0 to MTIList.Count - 1 do
    MTIArray[i] := StrToInt( MTIList[i]);
end;


{ TTestUnknownMTIAddressed }

constructor TTestUnknownMTIAddressed.Create;
begin
  inherited Create;
  FMTIManager := TKnownMTI.Create;
end;

destructor TTestUnknownMTIAddressed.Destroy;
begin
  FreeAndNil(FMTIManager);
  inherited Destroy;
end;

function TTestUnknownMTIAddressed.ProcessObjectives(ProcessStrings: TStringList): Integer;
var
  UnknownMTI: DWord;
  i: Integer;
begin
  Result := inherited ProcessObjectives(ProcessStrings);
  case StateMachineIndex of
    0 : begin
          // Send Unknown MTI Messages:
          UnknownMTI := MTIManager.FirstUnknownMTI;
          MessageHelper.Load(ol_OpenLCB, UnknownMTI, Settings.ProxyNodeAlias, Settings.TargetNodeAlias, 2, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);
          StateMachineIndex := 2;
          Result := 0;
        end;
    1 : begin
          // Send Unknown MTI Messages:
          UnknownMTI := MTIManager.NextUnknownMTI;
          MessageHelper.Load(ol_OpenLCB, UnknownMTI, Settings.ProxyNodeAlias, Settings.TargetNodeAlias, 2, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 0;                                                          // Objective 0
        end;
    2 : begin
          //
          if MTIManager.MTI < MAX_MTI_VALUE then
          begin
            FStateMachineIndex := 1;
            Result := 0;
          end else
          begin
            StripReceivesNotForNodeUnderTest(ProcessStrings);
            ErrorCodesUnknownMTIStrings.Clear;
            MTIManager.ResetMTI;
            for i := 0 to ProcessStrings.Count - 1 do
            begin
              MessageHelper.Decompose(ProcessStrings[i]);

      ///        ValidateBasicReturnMessage(MTI_PROTOCOL_SUPPORT_REPLY, MessageHelper);

      // TODO >>>>>>>

              if MessageHelper.MTI and MTI_OPTIONAL_INTERACTION_REJECTED = MTI_OPTIONAL_INTERACTION_REJECTED then
              begin
                if MessageHelper.ExtractDataBytesAsInt(0, 1) = Settings.TargetNodeAlias then
                begin
                   if MessageHelper.ExtractDataBytesAsInt(2, 3) = OIR_PERMANENT_ERROR then
                   begin
                      if MessageHelper.ExtractDataBytesAsInt(4, 5) = MTIManager.MTI then
                      begin
                      end else
                      begin

                      end;
                   end;
                end;
              end;
            end;

            Inc(FStateMachineIndex);
            Result := 1;                                                          // Objective 1
          end;
        end;
  end;
end;

procedure TTestUnknownMTIAddressed.InitTest;
begin
  inherited InitTest;
  MTIManager.ResetMTI;
end;

{ TTestStandardFrame }

procedure TTestStandardFrame.InitTest;
begin
  inherited InitTest;
  FiFrame := 0;
end;

function TTestStandardFrame.ProcessObjectives(ProcessStrings: TStringList): Integer;
var
  i: Integer;
begin
  Result := inherited ProcessObjectives(ProcessStrings);
  case StateMachineIndex of
    0 : begin
          // Send all Standard Messages in one shot and see what comes back
          if Settings.PingPongStandardFrameTest then
          begin
            ProcessStrings.Add(':S' + IntToHex(iFrame, 3) + 'N;');
          end else
          begin
            for i := 0 to 2047 do
              ProcessStrings.Add(':S' + IntToHex(i, 3) + 'N;');
          end;

          Inc(FStateMachineIndex);
          Result := 0;                                                          // Objective 0
        end;
    1 : begin
          // Send Standard Messages:
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count > 0 then                                      // Only one node should respond as this is addressed
            Include(FErrorCodes, teStandardFrameResponse);

          if Settings.PingPongStandardFrameTest then
          begin
            if iFrame >= 2047 then
            begin
              Inc(FStateMachineIndex);
              Result := 1;                                                          // Objective 1
            end else
            begin
              Inc(FiFrame);
              FStateMachineIndex := 0;
              Result := 0;                                                          // Objective 1
            end;
          end else
          begin
            Inc(FStateMachineIndex);
            Result := 1;
          end;
        end;
  end;
end;


{ TTestProtocolSupport }

function TTestProtocolSupport.ProcessObjectives(ProcessStrings: TStringList): Integer;
var
  PipMask: QWord;
begin
  Result := inherited ProcessObjectives(ProcessStrings);
  case StateMachineIndex of
    0 : begin
          // Send the Protocol Identification message
          MessageHelper.Load(ol_OpenLCB, MTI_PROTOCOL_SUPPORT_INQUIRY, Settings.ProxyNodeAlias, Settings.TargetNodeAlias, 2, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 0;                                                          // Objective 0
        end;
    1 : begin
          // Receive Node that responded with Protocol Identification message
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count = 1 then                                      // Only one node should respond as this is addressed
          begin
            MessageHelper.Decompose(ProcessStrings[0]);
            PipMask := MessageHelper.ExtractDataBytesAsInt(2, 7);
            ValidateBasicReturnMessage(MTI_PROTOCOL_SUPPORT_REPLY, MessageHelper);
            if PipMask and PIP_RESERVED_MASK <> 0 then
              Include(FErrorCodesPip, tepPipUsingReservedBits);
            if PipMask and PIP_UNASSIGNED_MASK <> 0 then
              Include(FErrorCodesPip, tepPipUsingUnassignedBits);
          end else
            Include(FErrorCodes, teIncorrectCount);

          Inc(FStateMachineIndex);
          Result := 1;
        end;
     2: begin
           MessageHelper.Load(ol_OpenLCB, MTI_PROTOCOL_SUPPORT_INQUIRY, Settings.ProxyNodeAlias, $001, 2, 0, 0, 0, 0, 0 ,0 ,0 ,0);  // TODO: NEED UNIQUE ALIAS NODE ID HERE
           ProcessStrings.Add(MessageHelper.Encode);

           Inc(FStateMachineIndex);
          Result := 1;                                                          // Objective 1
        end;
     3 : begin
          // Should be no response from any node
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count <> 0 then
            Include(FErrorCodes, teIncorrectCount);

          Inc(FStateMachineIndex);
          Result := 2;                                                          // Objective 2
        end;
      4 : begin
          // Send the Protocol Identification message start bit for expansion
          MessageHelper.Load(ol_OpenLCB, MTI_PROTOCOL_SUPPORT_INQUIRY, Settings.ProxyNodeAlias, (Settings.TargetNodeAlias) or PIP_EXTENSION_BIT_START, 2, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 2;                                                          // Objective 2
        end;
      5 : begin
          // Receive Nodes that responded with Protocol Identification message
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count > 0 then                                      // Node should not respond to the Start bit
            Include(FErrorCodesPip, tepPipRespondedToStartBit);

          Inc(FStateMachineIndex);
          Result := 2;                                                          // Objective 2
        end;
      6 : begin
          // Send the Protocol Identification message end bit for expansion
          MessageHelper.Load(ol_OpenLCB, MTI_PROTOCOL_SUPPORT_INQUIRY, Settings.ProxyNodeAlias, (Settings.TargetNodeAlias) or PIP_EXTENSION_BIT_END, 2, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 2;                                                          // Objective 2
        end;
      7 : begin
          // Receive Nodes that responded with Protocol Identification message
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count = 0 then
          begin
            Include(FErrorCodesPip, tepPipStartEndBitSupport);
          end else
          if ProcessStrings.Count = 1 then                                      // Only one node should respond as this is addressed
          begin
            MessageHelper.Decompose(ProcessStrings[0]);
            PipMask := MessageHelper.ExtractDataBytesAsInt(2, 7);
            ValidateBasicReturnMessage(MTI_PROTOCOL_SUPPORT_REPLY, MessageHelper);
            if PipMask and PIP_RESERVED_MASK <> 0 then
              Include(FErrorCodesPip, tepPipUsingReservedBits);
            if PipMask and PIP_UNASSIGNED_MASK <> 0 then
              Include(FErrorCodesPip, tepPipUsingUnassignedBits);
          end else
            Include(FErrorCodes, teIncorrectCount);
          Inc(FStateMachineIndex);
          Result := 3;
        end;
  end;
end;

{ TTestVerifyNodeID }

function TTestVerifyNodeID.ProcessObjectives(ProcessStrings: TStringList): Integer;
begin
  Result := inherited ProcessObjectives(ProcessStrings);
  case StateMachineIndex of
    0 : begin
          // Send a Global Verify Node ID with no target Full Node ID in the Data
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 0;                                                          // Objective 0
        end;
    1: begin
          // Receive Nodes that responded with Global Verifed Node ID
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count = 1 then
          begin
            MessageHelper.Decompose(ProcessStrings[0]);
            ValidateBasicReturnMessage(MTI_VERIFIED_NODE_ID_NUMBER, MessageHelper);
            if MessageHelper.ExtractDataBytesAsInt(0, 5) <> Settings.TargetNodeID then
              Include(FErrorCodes, teFullNodeIDInvalid);
          end else
            Include(FErrorCodes, teIncorrectCount);

          Inc(FStateMachineIndex);
          Result := 1;
       end;
    2 : begin
          // Send a Global Verify Node ID with our target Full Node ID in the Data
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          MessageHelper.StoreNodeIDToData(Settings.TargetNodeID, False);
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 1;                                                          // Objective 1
        end;
    3: begin
          // Receive Nodes only our test node should respond with Global Verifed Node ID
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count = 1 then
          begin
            MessageHelper.Decompose(ProcessStrings[0]);
            ValidateBasicReturnMessage(MTI_VERIFIED_NODE_ID_NUMBER, MessageHelper);
            if MessageHelper.ExtractDataBytesAsInt(0, 5) <> Settings.TargetNodeID then
              Include(FErrorCodes, teFullNodeIDInvalid);
          end else
            Include(FErrorCodes, teIncorrectCount);

          Inc(FStateMachineIndex);
          Result := 2;
       end;
    4 : begin
          // Send a Global Verify Node ID with a non-existent target Full Node ID in the Data
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER, Settings.ProxyNodeAlias, 0, 6, 0, 0, 0, 0, 0 ,1 ,0 ,0);  // TODO: NEED UNIQUE NODE ID HERE
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 2;                                                          // Objective 2
        end;
    5: begin
          // Should be no response from any node
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count <> 0 then
            Include(FErrorCodes, teIncorrectCount);

          Inc(FStateMachineIndex);
          Result := 3;
       end;
    6 : begin
          // Send a Addressed Verify Node ID with no data
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER_DEST, Settings.ProxyNodeAlias, Settings.TargetNodeAlias, 2, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 3;                                                          // Objective 3
        end;
    7: begin
          // Should be one and only one response from any node
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count = 1 then
          begin
            MessageHelper.Decompose(ProcessStrings[0]);
            ValidateBasicReturnMessage(MTI_VERIFIED_NODE_ID_NUMBER, MessageHelper);
            if MessageHelper.ExtractDataBytesAsInt(0, 5) <> Settings.TargetNodeID then
              Include(FErrorCodes, teFullNodeIDInvalid);
          end else
            Include(FErrorCodes, teIncorrectCount);

          Inc(FStateMachineIndex);
          Result := 4;
       end;
    8 : begin
          // Send a Addressed Verify Node ID with target Full Node ID in the Data
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER_DEST, Settings.ProxyNodeAlias, Settings.TargetNodeAlias, 2, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          MessageHelper.StoreNodeIDToData(Settings.TargetNodeID, True);
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 4;
        end;
    9: begin
          // Should be one and only one response from any node
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count = 1 then
          begin
            MessageHelper.Decompose(ProcessStrings[0]);
            ValidateBasicReturnMessage(MTI_VERIFIED_NODE_ID_NUMBER, MessageHelper);
            if MessageHelper.ExtractDataBytesAsInt(0, 5) <> Settings.TargetNodeID then
              Include(FErrorCodes, teFullNodeIDInvalid);
          end else
            Include(FErrorCodes, teIncorrectCount);

          Inc(FStateMachineIndex);
          Result := 5;
        end;
   10 : begin
          // Send a Addressed Verify Node ID with non-existent Full Node ID in the Data
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER_DEST, Settings.ProxyNodeAlias, Settings.TargetNodeAlias, 8, 0, 0, 0, 0, 0 ,0 ,0 ,1);  // TODO: NEED UNIQUE NODE ID HERE
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 5;
        end;
    11: begin
          // Should be one and only one response from any node
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count = 1 then
          begin
            MessageHelper.Decompose(ProcessStrings[0]);
            ValidateBasicReturnMessage(MTI_VERIFIED_NODE_ID_NUMBER, MessageHelper);
            if MessageHelper.ExtractDataBytesAsInt(0, 5) <> Settings.TargetNodeID then
              Include(FErrorCodes, teFullNodeIDInvalid);
          end else
            Include(FErrorCodes, teIncorrectCount);

          Inc(FStateMachineIndex);
          Result := 6;                                                          //
       end;
    12 : begin
          // Send an incorrectly Addressed Verify Node ID with no data
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER_DEST, Settings.ProxyNodeAlias, $001, 2, 0, 0, 0, 0, 0 ,0 ,0 ,0);   // TODO: NEED UNIQUE ALIAS NODE ID HERE
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 6;
        end;
    13: begin
          // Should be no response from any node
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count <> 0 then
            Include(FErrorCodes, teIncorrectCount);

          Inc(FStateMachineIndex);
          Result := 7;
       end;
    14 : begin
          // Send an incorrectly Addressed Verify Node ID with target Full Node ID in the Data
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER_DEST, Settings.ProxyNodeAlias, $001, 2, 0, 0, 0, 0, 0 ,0 ,0 ,0);   // TODO: NEED UNIQUE ALIAS NODE ID HERE
          MessageHelper.StoreNodeIDToData(Settings.TargetNodeID, True);
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 7;
        end;
    15: begin
          // Should be no response from any node
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count <> 0 then
            Include(FErrorCodes, teIncorrectCount);

          Inc(FStateMachineIndex);
          Result := 8;
        end;
   16 : begin
          // Send an incorrectly Addressed Verify Node ID with non-existent Full Node ID in the Data
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER_DEST, Settings.ProxyNodeAlias, $001, 8, 0, 0, 0, 0, 0 ,0 ,0 ,1);  // TODO: NEED UNIQUE ALIAS NODE ID HERE
          ProcessStrings.Add(MessageHelper.Encode);                                                                                  // TODO: NEED ALIAS NODE ID HERE

          Inc(FStateMachineIndex);
          Result := 8;
        end;
    17: begin
          // Should be no response from any node
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count <> 0 then
            Include(FErrorCodes, teIncorrectCount);

          Inc(FStateMachineIndex);
          Result := 9;                                                          //
       end;

  end;
end;

{ TTestAliasMapEnquiry }

function TTestAliasMapEnquiry.ProcessObjectives(ProcessStrings: TStringList): Integer;
//
//  WARNING:  This is called from the context of the Serial Thread
//
begin
  Result := inherited ProcessObjectives(ProcessStrings);
  case StateMachineIndex of
    0 : begin
          // Send Alias Mapping Enquiry with nothing in the CAN data bytes, all nodes should respond
          MessageHelper.Load(ol_CAN, MTI_AME, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 0;                                                          // Objective 0
        end;
    1: begin
          // All nodes should respond need to find the node under test
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count = 1 then
          begin
            MessageHelper.Decompose(ProcessStrings[0]);
            ValidateBasicReturnMessage(MTI_AMD, MessageHelper);
            if MessageHelper.ExtractDataBytesAsInt(0, 5) <> Settings.TargetNodeID then
              Include(FErrorCodes, teFullNodeIDInvalid);
          end else
            Include(FErrorCodes, teIncorrectCount);

          Inc(FStateMachineIndex);
          Result := 1;
       end;
    2 : begin
         // Send Alias Mapping Enquiry with a full Node ID in the CAN data bytes
          MessageHelper.Load(ol_CAN, MTI_AME, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          MessageHelper.StoreNodeIDToData(Settings.TargetNodeID, False);
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 1;                                                          // Objective 1
        end;
    3: begin
          // Should be one and only one response from node node under test
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count = 1 then
          begin
            MessageHelper.Decompose(ProcessStrings[0]);
            ValidateBasicReturnMessage(MTI_AMD, MessageHelper);
            if MessageHelper.ExtractDataBytesAsInt(0, 5) <> Settings.TargetNodeID then
              Include(FErrorCodes, teFullNodeIDInvalid);
          end else
            Include(FErrorCodes, teIncorrectCount);

          Inc(FStateMachineIndex);
          Result := 2;
       end;
    4 : begin
          // Send ProcessObjectives
          MessageHelper.Load(ol_CAN, MTI_AME, Settings.ProxyNodeAlias, 0, 6, 0, 0, 0, 0, 0 ,1 ,0 ,0);   // NEED TO FIND A UNIQUE NODE ID HERE.....
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 2;                                                          // Objective 2
        end;
    5: begin
          // Should be no response from any node
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count <> 0 then
            Include(FErrorCodes, teIncorrectCount);

          Result := 3;
       end;

  end;
end;

{ TTestGetNodesUnderTest }

function TTestGetNodesUnderTest.ProcessObjectives(ProcessStrings: TStringList): Integer;
begin
  Result := inherited ProcessObjectives(ProcessStrings);
  case StateMachineIndex of
    0 : begin
          // Send Global Verify Nodes to collect all nodes on the bus
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 0;
        end;
    1: begin
          // There is no pass fail here we are just collecting the nodes
          Result := 1;
       end;
  end;
end;

{ TTestStartup }

function TTestStartup.ProcessObjectives(ProcessStrings: TStringList): Integer;
var
  i: Integer;
begin
  Result := inherited ProcessObjectives(ProcessStrings);
  case StateMachineIndex of
    0 : begin
          // Send Global Verify Nodes but use the NUT Alias as the source from NodeExplorer to force the NUT to reallocate its Alias

      ///  NEED THE USER TO REBOOT HERE>>>>>>>>>>>

          Inc(FStateMachineIndex);
          Result := 0;
        end;
    1: begin
         StripReceivesNotForNodeUnderTest(ProcessStrings);
         if TestForStartupReturn(ProcessStrings, 0, MTI_AMR, tsNoAMR) then
           if TestForStartupReturn(ProcessStrings, 1, MTI_CID0, tsNoCID0) then
             if TestForStartupReturn(ProcessStrings, 2, MTI_CID1, tsNoCID1) then
               if TestForStartupReturn(ProcessStrings, 3, MTI_CID2, tsNoCID2) then
                 if TestForStartupReturn(ProcessStrings, 4, MTI_CID3, tsNoCID3) then
                   if TestForStartupReturn(ProcessStrings, 5, MTI_AMD, tsNoAMD) then
                     if TestForStartupReturn(ProcessStrings, 5, MTI_INITIALIZATION_COMPLETE, tsNoInitialized) then
                     begin

                     end;
         Result := 1;  // Done

       end;
  end;
end;

{ TTestZeroOrRepeatedAllocation }

procedure TTestZeroOrRepeatedAllocation.InitTest;
begin
  inherited InitTest;
  FReAllocationCount := 0;
end;

function TTestZeroOrRepeatedAllocation.ProcessObjectives(ProcessStrings: TStringList): Integer;
var
  i: Integer;
begin
  Result := inherited ProcessObjectives(ProcessStrings);
  case StateMachineIndex of
    0 : begin
          // Send Global Verify Nodes but use the NUT Alias as the source from NodeExplorer to force the NUT to reallocate its Alias
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER, Settings.TargetNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 0;
        end;
    1: begin
         StripReceivesNotForNodeUnderTest(ProcessStrings);

         Result := 1;  // Assume we are done

         if TestForStartupReturn(ProcessStrings, 0, MTI_AMR, tsNoAMR) then
           if TestForStartupReturn(ProcessStrings, 1, MTI_CID0, tsNoCID0) then
             if TestForStartupReturn(ProcessStrings, 2, MTI_CID1, tsNoCID1) then
               if TestForStartupReturn(ProcessStrings, 3, MTI_CID2, tsNoCID2) then
                 if TestForStartupReturn(ProcessStrings, 4, MTI_CID3, tsNoCID3) then
                   if TestForStartupReturn(ProcessStrings, 5, MTI_AMD, tsNoAMD) then
                   begin
                     Inc(FReAllocationCount);
                     if ReAllocationCount <= 4095 then
                     begin
                        Result := 0;
                       FStateMachineIndex := 0;
                     end
                   end;
       end;
  end;
end;

{ TTestAliasConflict }

function TTestAliasConflict.ProcessObjectives(ProcessStrings: TStringList): Integer;
begin
  Result := inherited ProcessObjectives(ProcessStrings);
  case StateMachineIndex of
    0 : begin
      // Send Global Verify Nodes but use the NUT Alias as the source from NodeExplorer to force the NUT to reallocate its Alias
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER, Settings.TargetNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);

          Inc(FStateMachineIndex);
          Result := 0;
        end;
    1: begin
          // There is no pass fail here we are just collecting the nodes
          Result := 1;
       end;
    2 : begin
          Inc(FStateMachineIndex);
          Result := 1;
        end;
    3: begin
          Result := 2;
       end;
    4 : begin
          Inc(FStateMachineIndex);
          Result := 2;
        end;
    5: begin
          Result := 31;
       end;
  end;
end;

{ TTestBase }

procedure TTestBase.StripReceivesNotForNodeUnderTest(ReceiveStrings: TStringList);
var
  i: Integer;
  TargetNodeAlias: String;
begin
  if Settings.MultiNodeTest then
  begin
    TargetNodeAlias := IntToHex(Settings.TargetNodeAlias, 3);
    for i := ReceiveStrings.Count - 1 downto 0 do
    begin
      // example - :X19170aaaN
      // Make sure the sender of the message is the node under test, if not then remove it from the list
      if (ReceiveStrings[i][8] <> TargetNodeAlias[1]) or (ReceiveStrings[i][9] <> TargetNodeAlias[2]) or (ReceiveStrings[i][10] <> TargetNodeAlias[3]) then
        ReceiveStrings.Delete(i);
    end;
  end;
end;

function TTestBase.GetPassed: Boolean;
var
  TestResult, Test, TestObjective, Results, PassFail: TDOMNode;
begin
  if  teCancelled in ErrorCodes then
    Result := False
  else begin
    Result := True;
    TestResult := XMLResults.FindNode(XML_ELEMENT_TEST_RESULT_ROOT);
    if Assigned(TestResult) then
    begin
      Test := TestResult.FindNode(XML_ELEMENT_TEST);
      if Assigned(Test) then
      begin
        TestObjective := Test.FirstChild;
        while Assigned(TestObjective) and Result do
        begin
          if TestObjective.NodeName = XML_ELEMENT_TESTOBJECTIVE then
          begin
            Results := TestObjective.FindNode(XML_ELEMENT_OBJECTIVERESULTS);
            if Assigned(Results) then
            begin
              PassFail := Results.FindNode(XML_ELEMENT_PASS_FAIL);
              if Assigned(PassFail) then
                Result := PassFail.FirstChild.NodeValue = XML_NAME_PASS;
            end;
          end;
          TestObjective := TestObjective.NextSibling;
        end;
      end;
    end;
  end;
end;

function TTestBase.TestForStartupReturn(Messages: TStringList; ExpectedMessageIndex: Integer; ExpectedMTI: DWord; ErrorCode: TTestNodeStartupCode): Boolean;
begin
  Result := False;
  ValidateBasicReturnMessage(ExpectedMTI, MessageHelper);
  if Messages.Count > ExpectedMessageIndex then
  begin
    MessageHelper.Decompose(Messages[ExpectedMessageIndex]);
    if MessageHelper.MTI = ExpectedMTI then
      Result := True
    else
      Include(FErrorCodesStartup, ErrorCode);
  end else
    Include(FErrorCodesStartup, ErrorCode);
end;

constructor TTestBase.Create;
begin
  inherited Create;
  FFreeOnLog := False;
  FMessageHelper := TOpenLCBMessageHelper.Create;
  FXMLResults := TXMLDocument.Create;
  ErrorCodesUnknownMTIStrings := TStringList.Create;
  FTestState := ts_Idle;
  FStateMachineIndex := 0;
  FListItem := nil;
  FErrorCodes := [];
  FTestCompleteCallback := nil;
end;

destructor TTestBase.Destroy;
begin
  FreeAndNil(FMessageHelper);
  FreeAndNil(FXMLResults);
  FreeAndNil(FErrorCodesUnknownMTIStrings);
  FStateMachineIndex := 0;
  inherited Destroy;
end;

function TTestBase.ProcessObjectives(ProcessStrings: TStringList): Integer;
begin
  Result := -1;
end;

procedure TTestBase.InitTest;
begin
  ClearErrorCodes;
  FStateMachineIndex := 0;
end;

class function TTestBase.CreateInstanceFromString(AClassname: String): TTestBase;
var
  TestBaseClass: TTestBaseClass;
begin
  Result := nil;
  TestBaseClass := TTestBaseClass( FindClass(AClassname));
  if Assigned(TestBaseClass) then
    Result := TestBaseClass.Create;
end;

procedure TTestBase.ValidateBasicReturnMessage(ExpectedMTI: DWord; Helper: TOpenLCBMessageHelper);
begin
  if Helper.UnimplementedBitsSet then
    Include(FErrorCodesFormat, tefUnusedBitsSet);

  if Helper.ForwardingBitNotSet then
    Include(FErrorCodesFormat, tefForwardingBitNotSet);

  if Helper.MTI <> ExpectedMTI then
    Include(FErrorCodesFormat, tefInvalidMTI);

  if Helper.SourceAliasID <> Settings.TargetNodeAlias then
    Include(FErrorCodesFormat, tefInvalidSourceAlias);

  if Helper.HasDestinationAddress then
    if Helper.DestinationAliasID <> Settings.ProxyNodeAlias then
      Include(FErrorCodesFormat, tefInvalidDestAlias);
end;

procedure TTestBase.ClearErrorCodes;
begin
  ErrorCodes := [];
  ErrorCodesFormat := [];
  ErrorCodesPip := [];
  ErrorCodesUnknownMTI := [];
  ErrorCodesUnknownMTIStrings.Clear;
end;

procedure TTestBase.CallbackTestComplete;
begin
  if Assigned(TestCompleteCallback) then
    TestCompleteCallback(Self);
end;


initialization
  RegisterClass(TTestGetNodesUnderTest);
  RegisterClass(TTestAliasMapEnquiry);
  RegisterClass(TTestVerifyNodeID);
  RegisterClass(TTestProtocolSupport);
  RegisterClass(TTestStandardFrame);
  RegisterClass(TTestUnknownMTIAddressed);
  RegisterClass(TTestAliasConflict);
  RegisterClass(TTestZeroOrRepeatedAllocation);
  RegisterClass(TTestStartup);

finalization

end.
