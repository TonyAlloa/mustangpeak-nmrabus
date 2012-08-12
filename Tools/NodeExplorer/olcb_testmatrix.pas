unit olcb_testmatrix;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, olcb_utilities, unitolcb_defines, nodeexplorer_settings,
  DOM, XMLRead, XMLWrite;

{ TTestBase }

type
  TTestState = (ts_Idle, ts_Sending, ts_Receiving, ts_Complete);

  TTestBase = class(TPersistent)
  private
    FCompareMasks: TStringList;
    FFreeOnComplete: Boolean;
    FMessageHelper: TOpenLCBMessageHelper;
    FTestStrings: TStringList;
    FStateMachineIndex: Integer;
    FTestState: TTestState;
    FWaitTime: Integer;
    FWideString: WideString;
    FXMLNode: TDOMNode;
  protected
    property MessageHelper: TOpenLCBMessageHelper read FMessageHelper write FMessageHelper;
    property StateMachineIndex: Integer read FStateMachineIndex write FStateMachineIndex;
  public
    property Description: WideString read FWideString write FWideString;
    property FreeOnComplete: Boolean read FFreeOnComplete write FFreeOnComplete;
    property TestStrings: TStringList read FTestStrings write FTestStrings;        // List of TOpenLCBMessageHelpers to send for test
    property CompareMasks: TStringList read FCompareMasks write FCompareMasks;        // List of expected messages Masks that the NUT should have sent (format TBD)
    property WaitTime: Integer read FWaitTime write FWaitTime;                  // Time to wait for the messages to sent (varies depending on what is being sent)
    property TestState: TTestState read FTestState write FTestState;
    property XMLNode: TDOMNode  read FXMLNode write FXMLNode;
    constructor Create; virtual;
    destructor Destroy; override;
    function Process: Boolean; virtual; abstract;
    class function CreateInstanceFromString(AClassname: String): TTestBase;
  end;
  TTestBaseClass = class of TTestBase;

  { TTestVerifyNodeID }

  TTestVerifyNodeID = class(TTestBase)
    function Process: Boolean; override;
  end;
  TTestVerifyNodeIDClass = class of TTestVerifyNodeID;

  { TTestAliasMapEnquiry }

  TTestAliasMapEnquiry = class(TTestBase)
    function Process: Boolean; override;
  end;
  TTestAliasMapEnquiryClass = class of TTestAliasMapEnquiry;

implementation

{ TTestAliasMapEnquiry }

function TTestAliasMapEnquiry.Process: Boolean;
begin
  Result := False
end;

{ TTestVerifyNodeID }

function TTestVerifyNodeID.Process: Boolean;
begin
  Result := True;
  case StateMachineIndex of
    0 : begin
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);

          // Need to read the XML Strings here......

          TestStrings.Add(MessageHelper.Encode);  // Must be by itself... how to add "Sending: "....???/
          Inc(FStateMachineIndex);
        end;
    1: begin
          Result := False      // Done
       end;
  end;
end;

{ TTestBase }

constructor TTestBase.Create;
begin
  inherited Create;
  Description := '';
  FTestStrings := TStringList.Create;
  FCompareMasks := TStringList.Create;
  FMessageHelper := TOpenLCBMessageHelper.Create;
  FTestState := ts_Idle;
  FWaitTime := DEFAULT_TIMEOUT;
  FStateMachineIndex := 0;
  FFreeOnComplete := False
end;

destructor TTestBase.Destroy;
begin
  FreeAndNil(FTestStrings);
  FreeAndNil(FCompareMasks);
  FreeAndNil(FMessageHelper);
  FStateMachineIndex := 0;
  inherited Destroy;
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

end.

