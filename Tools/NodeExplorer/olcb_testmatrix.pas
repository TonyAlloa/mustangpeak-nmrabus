unit olcb_testmatrix;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, olcb_utilities, unitolcb_defines, nodeexplorer_settings,
  DOM, XMLRead, XMLWrite;

type
  TTestState = (ts_Idle, ts_Initialize, ts_ObjectiveStart, ts_Sending, ts_Receiving, ts_ObjectiveEnd, ts_Complete);

  { TResultMask }

  TResultMask = class
  private
    FMask: String;       // Mask to use on the received messages.
                         // aaa = Alias ID of the node under test
                         // AAAAAAAAAAAA = Full Node ID of the node under test
                         // ddd = proxy Alias of Node Explorer
                         // DDDDDDDDDDDD = Full Node ID of the Node Explorer Full Alias
                         // ii = auto increment the byte
                         // iiii = auto increment the word
                         //  ....
    FUseCount: Integer;  // Number of continious receive messages to use this mask on, a 0 mean the number is variable and the statemachine will figure it out
  published
    property Mask: String read FMask write FMask;
    property UseCount: Integer read FUseCount write FUseCount;
  end;

  { TResultMaskList }

  TResultMaskList = class(TList)
  private
    FCurrentMask: Integer;
    function GetMask(Index: Integer): TResultMask;
    procedure PutMask(Index: Integer; AValue: TResultMask);
  public
    property Masks[Index: Integer]: TResultMask read GetMask write PutMask; default;
    property CurrentMask: Integer read FCurrentMask write FCurrentMask;
    constructor Create;
    function AddMask: TResultMask;
  end;

  { TTestBase }

  TTestBase = class(TPersistent)
  private
    FMessageHelper: TOpenLCBMessageHelper;
    FResultMasks: TResultMaskList;
    FStateMachineIndex: Integer;
    FTestState: TTestState;
    FWaitTime: Integer;
    FXMLResults: TXMLDocument;
    FXMLTests: TDOMNode;
  protected
    property MessageHelper: TOpenLCBMessageHelper read FMessageHelper write FMessageHelper;
    procedure StripReceivesNotForNodeUnderTest(ReceiveStrings: TStringList);
  public
    property ResultMasks: TResultMaskList read FResultMasks write FResultMasks; // Masks to compare against the Results
    property WaitTime: Integer read FWaitTime write FWaitTime;                  // Time to wait for the messages to sent (varies depending on what is being sent)
    property StateMachineIndex: Integer read FStateMachineIndex write FStateMachineIndex;
    property TestState: TTestState read FTestState write FTestState;
    property XMLTests: TDOMNode  read FXMLTests write FXMLTests;                // Node that describes the test from the Test Matrix XML file ( <test>...</test> )
    property XMLResults: TXMLDocument read FXMLResults write FXMLResults;
    constructor Create; virtual;
    destructor Destroy; override;
    class function CreateInstanceFromString(AClassname: String): TTestBase;
    function ProcessObjectives(ProcessStrings: TStringList; var PassResult: Boolean): Integer; virtual;
    function VerifyTestObjective(Index: Integer): Boolean;
  end;
  TTestBaseClass = class of TTestBase;

  { TTestVerifyNodesID }

  TTestVerifyNodesID = class(TTestBase)
  public
    function ProcessObjectives(ProcessStrings: TStringList; var PassResult: Boolean): Integer; override;
  end;
  TTestVerifyNodesIDClass = class of TTestVerifyNodesID;

  { TTestAliasMapEnquiry }

  TTestAliasMapEnquiry = class(TTestBase)
  public
    function ProcessObjectives(ProcessStrings: TStringList; var PassResult: Boolean): Integer; override;
  end;
  TTestAliasMapEnquiryClass = class of TTestAliasMapEnquiry;

  { TTestVerifyNodeID }

  TTestVerifyNodeID = class(TTestBase)
  public
    function ProcessObjectives(ProcessStrings: TStringList; var PassResult: Boolean): Integer; override;
  end;
  TTestVerifyNodeIDClass = class of TTestVerifyNodeID;

implementation

{ TResultMaskList }

function TResultMaskList.GetMask(Index: Integer): TResultMask;
begin
  Result := TResultMask( Items[Index]);
end;

procedure TResultMaskList.PutMask(Index: Integer; AValue: TResultMask);
begin
  Items[Index] := AValue
end;

constructor TResultMaskList.Create;
begin
  FCurrentMask := 0;
end;

function TResultMaskList.AddMask: TResultMask;
begin
  Result := TResultMask.Create;
  Add( Result);
end;

{ TTestVerifyNodeID }

function TTestVerifyNodeID.ProcessObjectives(ProcessStrings: TStringList; var PassResult: Boolean): Integer;
begin
  Result := inherited ProcessObjectives(ProcessStrings, PassResult);
  case StateMachineIndex of
    0 : begin
          // Send ProcessObjectives
          MessageHelper.Load(ol_CAN, MTI_VERIFY_NODE_ID_NUMBER, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 0;                                                          // Objective 0
        end;
    1: begin
          // Receive ProcessObjectives
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          if ProcessStrings.Count = 1 then
          begin
            MessageHelper.Decompose(ProcessStrings[0]);
            PassResult := (MessageHelper.MTI = MTI_VERIFIED_NODE_ID_NUMBER) and (MessageHelper.DataAsNodeID = Settings.TargetNodeID) and (MessageHelper.SourceAliasID = Settings.TargetNodeAlias);
          end;
          Inc(FStateMachineIndex);
          Result := 1;                                                          // Move to Objective 1
       end;
    2 : begin
          // Send ProcessObjectives
          MessageHelper.Load(ol_CAN, MTI_VERIFY_NODE_ID_NUMBER, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          MessageHelper.StoreNodeIDToData(Settings.TargetNodeID, False);
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 1;                                                          // Objective 1
        end;
    3: begin
          // Receive ProcessObjectives
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          Inc(FStateMachineIndex);
          Result := 2;                                                          //
       end;
    4 : begin
          // Send ProcessObjectives
          MessageHelper.Load(ol_CAN, MTI_VERIFY_NODE_ID_NUMBER, Settings.ProxyNodeAlias, 0, 6, 0, 0, 0, 0, 0 ,1 ,0 ,0);  // NEED UNIQUE NODE ID HERE
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 2;                                                          // Objective 2
        end;
    5: begin
          // Receive ProcessObjectives
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          Inc(FStateMachineIndex);
          Result := 3;                                                          //
       end;
    6 : begin
          // Send ProcessObjectives
          MessageHelper.Load(ol_CAN, MTI_VERIFY_NODE_ID_NUMBER_DEST, Settings.ProxyNodeAlias, Settings.TargetNodeAlias, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          MessageHelper.StoreNodeIDToData(Settings.TargetNodeID, True);
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 3;                                                          // Objective 3
        end;
    7: begin
          // Receive ProcessObjectives
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          Inc(FStateMachineIndex);
          Result := 4;                                                          //
       end;
    8 : begin
          // Send ProcessObjectives
          MessageHelper.Load(ol_CAN, MTI_VERIFY_NODE_ID_NUMBER_DEST, Settings.ProxyNodeAlias, Settings.TargetNodeAlias, 8, 0, 0, 0, 0, 0 ,0 ,0 ,1);
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 4;                                                          // Objective 4
        end;
    9: begin
          // Receive ProcessObjectives
          StripReceivesNotForNodeUnderTest(ProcessStrings);
          Inc(FStateMachineIndex);
          Result := 5;                                                          //
       end;

  end;
end;

{ TTestAliasMapEnquiry }

function TTestAliasMapEnquiry.ProcessObjectives(ProcessStrings: TStringList; var PassResult: Boolean): Integer;
//
//  WARNING:  This is called from the context of the Serial Thread
//
begin
  Result := inherited ProcessObjectives(ProcessStrings, PassResult);
  case StateMachineIndex of
    0 : begin
          // Send ProcessObjectives
          MessageHelper.Load(ol_CAN, MTI_AME, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          MessageHelper.StoreNodeIDToData(Settings.TargetNodeID, False);
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 0;                                                          // Objective 0
        end;
    1: begin
          // Receive ProcessObjectives
          Inc(FStateMachineIndex);
          Result := 1;                                                          // Move to Objective 1
       end;
    2 : begin
          // Send ProcessObjectives
          MessageHelper.Load(ol_CAN, MTI_AME, Settings.ProxyNodeAlias, 0, 6, 0, 0, 0, 0, 0 ,1 ,0 ,0);   // NEED TO FIND A UNIQUE NODE ID HERE.....
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 1;                                                          // Objective 1
        end;
    3: begin
          // Receive ProcessObjectives
          Result := 2;                                                          // Move to non-existant Objective 2
       end;

  end;
end;

{ TTestVerifyNodeID }

function TTestVerifyNodesID.ProcessObjectives(ProcessStrings: TStringList; var PassResult: Boolean): Integer;
begin
  Result := inherited ProcessObjectives(ProcessStrings, PassResult);
  case StateMachineIndex of
    0 : begin
          // Send ProcessObjectives
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 0;                                                          // ProcessObjectives 0
        end;
    1: begin
          // Receive ProcessObjectives
          if ProcessStrings.Count = 1 then
          begin
            MessageHelper.Decompose(ProcessStrings[0]);
            PassResult := (MessageHelper.MTI = MTI_VERIFIED_NODE_ID_NUMBER) and (MessageHelper.DataAsNodeID = Settings.TargetNodeID) and (MessageHelper.SourceAliasID = Settings.TargetNodeAlias);
          end;
          Result := 1;                                                          // Done with ProcessObjectives 0 move to ProcessObjectives 1 (which is not valid in this case so thread will finish with this test)
       end;
  end;
end;

{ TTestBase }

procedure TTestBase.StripReceivesNotForNodeUnderTest(ReceiveStrings: TStringList);
var
  i: Integer;
  TargetNodeAlias: String;
begin
  TargetNodeAlias := IntToHex(Settings.TargetNodeAlias, 3);
  for i := ReceiveStrings.Count - 1 downto 0 do
  begin
    // example - :X19170aaaN
    ReceiveStrings[i] := Trim( ReceiveStrings[i]);
    if (ReceiveStrings[8] <> TargetNodeAlias[1]) or (ReceiveStrings[9] <> TargetNodeAlias[2]) or (ReceiveStrings[10] <> TargetNodeAlias[3]) then
      ReceiveStrings.Delete(i);
  end;
end;

constructor TTestBase.Create;
begin
  inherited Create;
  FMessageHelper := TOpenLCBMessageHelper.Create;
  FXMLResults := TXMLDocument.Create;
  FResultMasks := TResultMaskList.Create;
  FTestState := ts_Idle;
  FWaitTime := DEFAULT_TIMEOUT;
  FStateMachineIndex := 0;
end;

destructor TTestBase.Destroy;
begin
  FreeAndNil(FMessageHelper);
  FreeAndNil(FXMLResults);
  FreeAndNil(FResultMasks);
  FStateMachineIndex := 0;
  inherited Destroy;
end;

function TTestBase.ProcessObjectives(ProcessStrings: TStringList; var PassResult: Boolean): Integer;
begin
  Result := -1;
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

function TTestBase.VerifyTestObjective(Index: Integer): Boolean;
begin
  // Search the results for the test objective at Index

end;


initialization
  RegisterClass(TTestVerifyNodesID);
  RegisterClass(TTestAliasMapEnquiry);
  RegisterClass(TTestVerifyNodeID);

finalization

end.

