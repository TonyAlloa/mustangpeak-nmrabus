unit olcb_utilities;

// ******************************************************************************
//
// * Copyright:
//     (c) Mustangpeak Software 2012.
//
//     The contents of this file are subject to the GNU GPL v3 licence/ you maynot use
//     this file except in compliance with the License. You may obtain a copy of the
//     License at http://www.gnu.org/licenses/gpl.html
//
// * Revision History:
//     2012-08-05:   Created
//
// * Description:

//
// *****************************************************************************

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, strutils, synaser, ExtCtrls, unitolcb_defines;

const
  LF = #13+#10;
  CAN_BYTE_COUNT = 8;
  DEFAULT_TIMEOUT = 200;                  // 200ms of no activity on the UART signals the receoption is complete

type
  TByteArray = array[0..CAN_BYTE_COUNT-1] of Byte;
  PByteArray = ^TByteArray;

  TOpenLCBLayer = (ol_CAN, ol_OpenLCB);

  { TSettings }

  TSettings = class
  private
    FProxyNodeAlias: Word;
  public
    property ProxyNodeAlias: Word read FProxyNodeAlias write FProxyNodeAlias;
    constructor Create;
  end;

  { TOpenLCBMessage }

  TOpenLCBMessageHelper = class
  private
    FDestinationAliasID: Word;
    FSourceAliasID: Word;
    FData: TByteArray;
    FDataCount: Integer;
    FLayer: TOpenLCBLayer;
    FMTI: DWord;
    procedure SetData(AValue: TByteArray);
    procedure SetLayer(AValue: TOpenLCBLayer);
  public
    property Layer: TOpenLCBLayer read FLayer write SetLayer;
    property MTI: DWord read FMTI write FMTI;
    property Data: TByteArray read FData write SetData;
    property DataCount: Integer read FDataCount write FDataCount;
    property SourceAliasID: Word read FSourceAliasID write FSourceAliasID;
    property DestinationAliasID: Word read FDestinationAliasID write FDestinationAliasID;

    constructor Create;
    destructor Destroy; override;
    procedure Decompose(MessageStr: AnsiString);
    function Encode: AnsiString;
    procedure Load(ALayer: TOpenLCBLayer; AMTI: DWord; ASourceAlias: Word; ADestinationAlias: Word; ADataCount: Integer; AData0, AData1, AData2, AData3, AData4, AData5, AData6, AData7: Byte);
  end;

  { TTestBase }

  TTestState = (ts_Idle, ts_Sending, ts_Receiving, ts_Complete);

  TTestBase = class(TPersistent)
  private
    FCompareMasks: TStringList;
    FMessageHelper: TOpenLCBMessageHelper;
    FTestStrings: TStringList;
    FStateMachineIndex: Integer;
    FTestState: TTestState;
    FWaitTime: Integer;
    FWideString: WideString;
  protected
    property MessageHelper: TOpenLCBMessageHelper read FMessageHelper write FMessageHelper;
    property StateMachineIndex: Integer read FStateMachineIndex write FStateMachineIndex;
  public
    property Description: WideString read FWideString write FWideString;
    property TestStrings: TStringList read FTestStrings write FTestStrings;        // List of TOpenLCBMessageHelpers to send for test
    property CompareMasks: TStringList read FCompareMasks write FCompareMasks;        // List of expected messages Masks that the NUT should have sent (format TBD)
    property WaitTime: Integer read FWaitTime write FWaitTime;                  // Time to wait for the messages to sent (varies depending on what is being sent)
    property TestState: TTestState read FTestState write FTestState;
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


var
  Settings: TSettings;


implementation

{ TTestAliasMapEnquiry }

function TTestAliasMapEnquiry.Process: Boolean;
begin

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

{ TSettings }

constructor TSettings.Create;
begin
  inherited Create;
  FProxyNodeAlias := $0AAA
end;

{ TTestVerifyNodeID }

function TTestVerifyNodeID.Process: Boolean;
begin
  Result := True;
  case StateMachineIndex of
    0 : begin
          MessageHelper.Load(ol_OpenLCB, MTI_VERIFY_NODE_ID_NUMBER, Settings.ProxyNodeAlias, 0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0);
          TestStrings.Add(Description);
          TestStrings.Add(MessageHelper.Encode);
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
  TestState := ts_Idle;
  WaitTime := DEFAULT_TIMEOUT;
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


{ TOpenLCBMessageHelper }

procedure TOpenLCBMessageHelper.SetData(AValue: TByteArray);
begin
  FData:=AValue;
end;

procedure TOpenLCBMessageHelper.SetLayer(AValue: TOpenLCBLayer);
begin
  if FLayer=AValue then Exit;
  FLayer:=AValue;
end;

constructor TOpenLCBMessageHelper.Create;
var
  i: Integer;
begin
  inherited Create;
  FLayer := ol_CAN;
  FMTI := 0;
  for i := 0 to CAN_BYTE_COUNT - 1 do
    FData[i] := 0;
  FDataCount := 0;
  FSourceAliasID := 0;
  FDestinationAliasID := 0;
end;

destructor TOpenLCBMessageHelper.Destroy;
begin
  inherited Destroy
end;

procedure TOpenLCBMessageHelper.Decompose(MessageStr: AnsiString);
var
  x, n, SemiColon, i: Integer;
  Head: PAnsiChar;
  ByteStr: AnsiString;
begin
  MessageStr := UpperCase(MessageStr);
  x := Pos('X', MessageStr);
  if x > 0 then
  begin
    n := PosEx('N', MessageStr, x);
    if n > 0 then
    begin
      MessageStr[n] := #0;
      Inc(n);
      SemiColon := PosEx(';', MessageStr, n);
      if SemiColon > 0 then
      begin
        Head := @MessageStr[x+1];

        MTI := StrToInt('$' + Head);
        SourceAliasID := MTI and $00000FFF;
        if MTI and $10000000 = $10000000 then
          Layer := ol_OpenLCB
        else
          Layer := ol_CAN;

        FDataCount := 0;
        i := n;
        while i < SemiColon do
        begin
          ByteStr := MessageStr[i] + MessageStr[i+1];
          Data[FDataCount] := StrToInt('$'+ByteStr);
          Inc(i, 2);
          Inc(FDataCount);
        end;
      end
    end;
  end;
end;

function TOpenLCBMessageHelper.Encode: AnsiString;
var
  i: Integer;
  FullMTI: DWord;
begin
  FullMTI := MTI or SourceAliasID;
  if Layer = ol_OpenLCB then
    FullMTI := FullMTI or $10000000;
  Result := ':X' + IntToHex(FullMTI, 8) + 'N';
  for i := 0 to DataCount - 1 do
     Result := Result + IntToHex(Data[i], 2);
  Result := Result  + ';'
end;

procedure TOpenLCBMessageHelper.Load(ALayer: TOpenLCBLayer; AMTI: DWord;
  ASourceAlias: Word; ADestinationAlias: Word; ADataCount: Integer; AData0,
  AData1, AData2, AData3, AData4, AData5, AData6, AData7: Byte);
begin
  Layer := ALayer;
  MTI := AMTI;
  DataCount := ADataCount;
  SourceAliasID := ASourceAlias;
  DestinationAliasID := ADestinationAlias;
  Data[0] := AData0;
  Data[1] := AData1;
  Data[2] := AData2;
  Data[3] := AData3;
  Data[4] := AData4;
  Data[5] := AData5;
  Data[6] := AData6;
  Data[7] := AData7;

end;

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

initialization
  RegisterClass(TTestVerifyNodeID);
  RegisterClass(TTestAliasMapEnquiry);
  Settings := TSettings.Create;

finalization
  FreeAndNil(Settings);

end.

