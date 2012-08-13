unit olcb_testmatrix;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, olcb_utilities, unitolcb_defines, nodeexplorer_settings,
  DOM, XMLRead, XMLWrite;

{ TTestBase }

type
  TTestState = (ts_Idle, ts_Initialize, ts_ObjectiveStart, ts_Sending, ts_Receiving, ts_ObjectiveEnd, ts_Complete);

  TTestBase = class(TPersistent)
  private
    FCompareMasks: TStringList;
    FMessageHelper: TOpenLCBMessageHelper;
    FTestStrings: TStringList;
    FStateMachineIndex: Integer;
    FTestState: TTestState;
    FWaitTime: Integer;
    FWideString: WideString;
    FXMLNode: TDOMNode;
  protected
    property MessageHelper: TOpenLCBMessageHelper read FMessageHelper write FMessageHelper;
  public
    property TestStrings: TStringList read FTestStrings write FTestStrings;     // List of TOpenLCBMessageHelpers to send for test
    property CompareMasks: TStringList read FCompareMasks write FCompareMasks;  // List of expected messages Masks that the NUT should have sent (format TBD)
    property WaitTime: Integer read FWaitTime write FWaitTime;                  // Time to wait for the messages to sent (varies depending on what is being sent)
    property StateMachineIndex: Integer read FStateMachineIndex write FStateMachineIndex;
    property TestState: TTestState read FTestState write FTestState;
    property XMLNode: TDOMNode  read FXMLNode write FXMLNode;
    constructor Create; virtual;
    destructor Destroy; override;
    function Process(ProcessStrings: TStringList): Integer; virtual;
    class function CreateInstanceFromString(AClassname: String): TTestBase;
  end;
  TTestBaseClass = class of TTestBase;

  { TTestVerifyNodesID }

  TTestVerifyNodesID = class(TTestBase)
    function Process(ProcessStrings: TStringList): Integer; override;
  end;
  TTestVerifyNodesIDClass = class of TTestVerifyNodesID;

  { TTestAliasMapEnquiry }

  TTestAliasMapEnquiry = class(TTestBase)
    function Process(ProcessStrings: TStringList): Integer; override;
  end;
  TTestAliasMapEnquiryClass = class of TTestAliasMapEnquiry;

  { TTestVerifyNodeID }

  TTestVerifyNodeID = class(TTestBase)
    function Process(ProcessStrings: TStringList): Integer; override;
  end;
  TTestVerifyNodeIDClass = class of TTestVerifyNodeID;

implementation

{ TTestVerifyNodeID }

function TTestVerifyNodeID.Process(ProcessStrings: TStringList): Integer;
begin
  Result := inherited Process(ProcessStrings);
  case StateMachineIndex of
    0 : begin
          // Send Process
          MessageHelper.Load(ol_CAN, MTI_VERIFY_NODE_ID_NUMBER, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 0;                                                          // Objective 0
        end;
    1: begin
          // Receive Process
          Inc(FStateMachineIndex);
          Result := 1;                                                          // Move to Objective 1
       end;
    2 : begin
          // Send Process
          MessageHelper.Load(ol_CAN, MTI_VERIFY_NODE_ID_NUMBER, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          MessageHelper.StoreNodeIDToData(Settings.TargetNodeID, False);
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 1;                                                          // Objective 1
        end;
    3: begin
          // Receive Process
          Inc(FStateMachineIndex);
          Result := 2;                                                          //
       end;
    4 : begin
          // Send Process
          MessageHelper.Load(ol_CAN, MTI_VERIFY_NODE_ID_NUMBER, Settings.ProxyNodeAlias, 0, 6, 0, 0, 0, 0, 0 ,1 ,0 ,0);  // NEED UNIQUE NODE ID HERE
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 2;                                                          // Objective 1
        end;
    5: begin
          // Receive Process
          Inc(FStateMachineIndex);
          Result := 3;                                                          //
       end;
    6 : begin
          // Send Process
          MessageHelper.Load(ol_CAN, MTI_VERIFY_NODE_ID_NUMBER_DEST, Settings.ProxyNodeAlias, Settings.TargetNodeAlias, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          MessageHelper.StoreNodeIDToData(Settings.TargetNodeID, True);
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 3;                                                          // Objective 2
        end;
    7: begin
          // Receive Process
          Inc(FStateMachineIndex);
          Result := 4;                                                          //
       end;
    8 : begin
          // Send Process
          MessageHelper.Load(ol_CAN, MTI_VERIFY_NODE_ID_NUMBER_DEST, Settings.ProxyNodeAlias, Settings.TargetNodeAlias, 8, 0, 0, 0, 0, 0 ,0 ,0 ,1);
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 4;                                                          // Objective 3
        end;
    9: begin
          // Receive Process
          Inc(FStateMachineIndex);
          Result := 5;                                                          //
       end;

  end;
end;

{ TTestAliasMapEnquiry }

function TTestAliasMapEnquiry.Process(ProcessStrings: TStringList): Integer;
begin
  Result := inherited Process(ProcessStrings);
  case StateMachineIndex of
    0 : begin
          // Send Process
          MessageHelper.Load(ol_CAN, MTI_AME, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          MessageHelper.StoreNodeIDToData(Settings.TargetNodeID, False);
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 0;                                                          // Objective 0
        end;
    1: begin
          // Receive Process
          Inc(FStateMachineIndex);
          Result := 1;                                                          // Move to Objective 1
       end;
    2 : begin
          // Send Process
          MessageHelper.Load(ol_CAN, MTI_AME, Settings.ProxyNodeAlias, 0, 6, 0, 0, 0, 0, 0 ,1 ,0 ,0);   // NEED TO FIND A UNIQUE NODE ID HERE.....
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 1;                                                          // Objective 1
        end;
    3: begin
          // Receive Process
          Result := 2;                                                          // Move to non-existant Objective 2
       end;

  end;
end;

{ TTestVerifyNodeID }

function TTestVerifyNodesID.Process(ProcessStrings: TStringList): Integer;
begin
  Result := inherited Process(ProcessStrings);
  case StateMachineIndex of
    0 : begin
          // Send Process
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          ProcessStrings.Add(MessageHelper.Encode);
          Inc(FStateMachineIndex);
          Result := 0;                                                          // Process 0
        end;
    1: begin
          // Receive Process
          Result := 1;                                                          // Done with Process 0 move to Process 1 (which is not valid in this case so thread will finish with this test)
       end;
  end;
end;

{ TTestBase }

constructor TTestBase.Create;
begin
  inherited Create;
  FTestStrings := TStringList.Create;
  FCompareMasks := TStringList.Create;
  FMessageHelper := TOpenLCBMessageHelper.Create;
  FTestState := ts_Idle;
  FWaitTime := DEFAULT_TIMEOUT;
  FStateMachineIndex := 0;
end;

destructor TTestBase.Destroy;
begin
  FreeAndNil(FTestStrings);
  FreeAndNil(FCompareMasks);
  FreeAndNil(FMessageHelper);
  FStateMachineIndex := 0;
  inherited Destroy;
end;

function TTestBase.Process(ProcessStrings: TStringList): Integer;
begin
  Result := -1;
  ProcessStrings.Clear;
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

initialization
  RegisterClass(TTestVerifyNodesID);
  RegisterClass(TTestAliasMapEnquiry);
  RegisterClass(TTestVerifyNodeID);

finalization

end.

