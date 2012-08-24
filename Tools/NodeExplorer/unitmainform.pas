unit UnitMainForm;

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

{.$DEFINE DISABLE_UI_UPDATE}
{.$DEFINE USE_DEBUG_LOGGER}

interface

uses
  Classes, SysUtils, FileUtil, SynHighlighterXML, SynEdit,
  RTTICtrls, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls, ActnList,
  Menus, ExtCtrls, synaser, lcltype, unitlogwindow, unitsettings,
  DOM, XMLRead, XMLWrite, serialport_thread, olcb_testmatrix,
  {$IFDEF UNIX}
  unitLinuxFTDI,
  {$ENDIF}
  nodeexplorer_settings, olcb_utilities, unitolcb_defines, unitDebugLogger;


const
  BUNDLENAME = 'NodeExplorer';

type

  { TFormMain }

  TFormMain = class(TForm)
    ActionReadPip: TAction;
    ActionLogShowGutter: TAction;
    ActionExecuteTests: TAction;
    ActionSaveTestMatrix: TAction;
    ActionLoadTestMatrix: TAction;
    ActionRescanPorts: TAction;
    ActionShowOptionsWin: TAction;
    ActionShowPreferencesMac: TAction;
    ActionDiscoverNode: TAction;
    ActionHideLog: TAction;
    ActionShowLog: TAction;
    ActionEventReader: TAction;
    ActionReadXML: TAction;
    ActionSendDatagramReply: TAction;
    ActionConnect: TAction;
    ActionSendPacket: TAction;
    ActionClear: TAction;
    ActionListMain: TActionList;
    ApplicationProperties1: TApplicationProperties;
    ButtonConnect: TButton;
    ButtonDiscoverNodes: TButton;
    ButtonExecuteTests: TButton;
    ButtonReadPIP: TButton;
    ButtonSaveTests: TButton;
    ButtonShowLog: TButton;
    ButtonRescanPorts: TButton;
    ButtonLoadTests: TButton;
    ButtonSendPacket: TButton;
    ButtonReadXML: TButton;
    ButtonReadEvents: TButton;
    ButtonSendDatagramReply: TButton;
    CheckGroupPIP: TCheckGroup;
    ComboBoxBaud: TComboBox;
    ComboBoxPorts: TComboBox;
    EditPipRawMessage: TEdit;
    EditCustomBaudRate: TEdit;
    EditDiscoverNodeAlias: TEdit;
    EditDiscoverNodeID: TEdit;
    EditPacket: TEdit;
    EditSourceNodeAlias: TEdit;
    EditTargetNodeAlias: TEdit;
    GroupBoxComPort: TGroupBox;
    GroupBoxEventReaderConsumers: TGroupBox;
    GroupBoxEventReaderProducers: TGroupBox;
    ImageListLarge: TImageList;
    ImageListSmall: TImageList;
    ImageOpenLCB: TImage;
    LabelDiscoverMultiNode: TLabel;
    LabelPipPassFail: TLabel;
    LabelHomeMessage1: TLabel;
    LabelHomeMessage2: TLabel;
    LabelPipRawMessage: TLabel;
    LabelHomeMessage: TLabel;
    LabelHomeMessageNote: TLabel;
    LabelDiscoverNodeAlias: TLabel;
    LabelDiscoverNodeID: TLabel;
    LabelTargetAlias: TLabel;
    LabelSourceAlias: TLabel;
    LabelPacket: TLabel;
    LabelBaud: TLabel;
    LabelCustomBaud: TLabel;
    LabelPort: TLabel;
    ListViewNodeDiscovery: TListView;
    ListViewTestMatrix: TListView;
    ListViewConsumers: TListView;
    ListViewDiscovery: TListView;
    ListViewProducers: TListView;
    MainMenu: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItemFile: TMenuItem;
    OpenDialog: TOpenDialog;
    PageControl: TPageControl;
    PanelLogo: TPanel;
    SaveDialog: TSaveDialog;
    SynEditCDI: TSynEdit;
    SynXMLSyn: TSynXMLSyn;
    TabSheetProtocolID: TTabSheet;
    TabSheetVerification: TTabSheet;
    TabSheetDiscover: TTabSheet;
    TabSheetEventReader: TTabSheet;
    TabSheetHome: TTabSheet;
    TabSheetCustom: TTabSheet;
    TabSheetCDIReader: TTabSheet;
    TimerSafetyNet: TTimer;
    TimerCAN: TTimer;
    procedure ActionClearExecute(Sender: TObject);
    procedure ActionConnectExecute(Sender: TObject);
    procedure ActionDiscoverNodeExecute(Sender: TObject);
    procedure ActionEventReaderExecute(Sender: TObject);
    procedure ActionExecuteTestsExecute(Sender: TObject);
    procedure ActionHideLogExecute(Sender: TObject);
    procedure ActionLoadTestMatrixExecute(Sender: TObject);
    procedure ActionLogShowGutterExecute(Sender: TObject);
    procedure ActionReadPipExecute(Sender: TObject);
    procedure ActionReadXMLExecute(Sender: TObject);
    procedure ActionRescanPortsExecute(Sender: TObject);
    procedure ActionSaveTestMatrixExecute(Sender: TObject);
    procedure ActionSendDatagramReplyExecute(Sender: TObject);
    procedure ActionSendPacketExecute(Sender: TObject);
    procedure ActionShowLogExecute(Sender: TObject);
    procedure ActionShowOptionsWinExecute(Sender: TObject);
    procedure ActionShowPreferencesMacExecute(Sender: TObject);
    procedure ComboBoxBaudChange(Sender: TObject);
    procedure ComboBoxPortsChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListViewNodeDiscoverySelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure ListViewTestMatrixDeletion(Sender: TObject; Item: TListItem);
    procedure TimerCANTimer(Sender: TObject);
    procedure TimerSafetyNetTimer(Sender: TObject);
  private
    FSafetyRelease: Boolean;
    { private declarations }
    FShownOnce: Boolean;
    FTestThread: TComPortThread;
    FTestStrings: TStringList;
    FXMLDocTestMatrix: TXMLDocument;
    FXMLDocTestResults: TXMLDocument;
    function GetConnected: Boolean;
  protected
    { protected declarations }
    {$IFDEF DARWIN}
      AppMenu     : TMenuItem;
      AppAboutCmd : TMenuItem;
      AppSep1Cmd  : TMenuItem;
      AppPrefCmd  : TMenuItem;
    {$ENDIF}
    procedure UpdateUI;
    procedure ClearTestResultsXML;
    property Connected: Boolean read GetConnected;
    procedure LoadTestMatrixListview;
  public
    { public declarations }
    procedure Log(Line: String);
    property SafetyRelease: Boolean read FSafetyRelease write FSafetyRelease;
    property ShownOnce: Boolean read FShownOnce write FShownOnce;
    property TestStrings: TStringList read FTestStrings write FTestStrings;
    property TestThread: TComPortThread read FTestThread write FTestThread;
    property XMLDocTestMatrix: TXMLDocument read FXMLDocTestMatrix write FXMLDocTestMatrix;
    property XMLDocTestResults: TXMLDocument read FXMLDocTestResults write FXMLDocTestResults;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

{$ifdef Windows}
uses Windows;
{$endif}
{$IFDEF Darwin}
uses
  MacOSAll;
{$ENDIF}

{ TFormMain }

procedure TFormMain.ActionClearExecute(Sender: TObject);
begin
  FormLog.SynMemo.Lines.BeginUpdate;
  try
    FormLog.SynMemo.Lines.Clear
  finally
    FormLog.SynMemo.Lines.EndUpdate
  end;
end;

procedure TFormMain.ActionConnectExecute(Sender: TObject);
begin
  if Connected then
  begin
    TestThread.Terminate;
    FTestThread := nil;
    ActionConnect.Caption:='Connect';
  end else
  begin
    FTestThread := TComPortThread.Create(True);
    try
      TestThread.FreeOnTerminate := True;
      {$IFDEF MSWINDOWS}
      TestThread.Port := ComboBoxPorts.Text;
      {$ELSE}
      TestThread.Port := 'dev/' + ComboBoxPorts.Text;
      {$ENDIF}
      if ComboBoxBaud.ItemIndex = 0 then
        TestThread.BaudRate := StrToInt(EditCustomBaudRate.Text)
      else
        TestThread.BaudRate := StrToInt(ComboBoxBaud.Items[ComboBoxBaud.ItemIndex]);
      TestThread.Suspended := False;
      Sleep(500);
      if TestThread.Connected then
        ActionConnect.Caption:='Disconnect'
      else begin
        TestThread.Terminate;
        TestThread := nil;
      end;
    except
      if Assigned(TestThread) then
      begin
        TestThread.Terminate;
        TestThread := nil;
      end;
      ActionConnect.Caption:='Connect';
    end;
  end;
  UpdateUI;
end;

procedure TFormMain.ActionDiscoverNodeExecute(Sender: TObject);
var
  Helper: TOpenLCBMessageHelper;
  ResultStrings: TStringList;
  ListItem: TListItem;
  i: Integer;
  Test: TTestVerifyNodesID;
begin
  Test := FindTestFromXML(XMLDocTestMatrix, STR_TEST_VERIFY_NODES_ID_CLASS) as TTestVerifyNodesID;
  if Assigned(Test) then
  begin
    Test.FreeOnLog := True;
    TestThread.Add(Test);

    SafetyRelease := False;
    TimerSafetyNet.Enabled := True;
    while (Test.TestState <> ts_Complete) and not SafetyRelease do      // Wait for the test to end.....
      ThreadSwitch;

    Helper := TOpenLCBMessageHelper.Create;
    ListViewNodeDiscovery.Items.BeginUpdate;
    try
      ResultStrings := TStringList.Create;
      try
        ListViewNodeDiscovery.Items.Clear;

        ExtractResultsFromXML(Test.XMLResults, ResultStrings);

        for i := 0 to ResultStrings.Count - 1 do
        begin;
          Helper.Decompose(ResultStrings[i]);
          if Helper.MTI = MTI_VERIFIED_NODE_ID_NUMBER then
          begin
             ListItem := ListViewNodeDiscovery.Items.Add;
             ListItem.Caption := IntToHex(Helper.SourceAliasID, 3);
             ListItem.SubItems.Add(IntToHex(Helper.ExtractDataBytesAsInt(0, 5), 12));
          end;
        end;
      finally
        if ListViewNodeDiscovery.Items.Count > 0 then
        begin
          ListViewNodeDiscovery.Items[0].Focused := True;
          ListViewNodeDiscovery.Items[0].Selected  := True;
          if ListViewNodeDiscovery.Items.Count = 1 then
          begin
            Settings.MultiNodeTest := False;
            LabelDiscoverMultiNode.Caption := 'Mode: SingleNode test'
          end else
          begin
            Settings.MultiNodeTest := True;
            LabelDiscoverMultiNode.Caption := 'Mode: MultiNode test';
          end;
        end else
          LabelDiscoverMultiNode.Caption := 'Mode:';

        ResultStrings.Free
      end;
    finally
      ListViewNodeDiscovery.Items.EndUpdate;
      Helper.Free
    end;
  end;
end;

procedure TFormMain.ActionEventReaderExecute(Sender: TObject);
begin
   ShowMessage('Not implemented yet');
end;

procedure TFormMain.ActionExecuteTestsExecute(Sender: TObject);
var
  i: Integer;
begin
  ClearTestResultsXML;
  if ListViewNodeDiscovery.SelCount = 1 then
  begin
    for i := 0 to ListViewTestMatrix.Items.Count - 1 do
    begin
      if ListViewTestMatrix.Items[i].Checked then
        TestThread.Add( TTestBase( ListViewTestMatrix.Items[i].Data));
    end;
  end else
    ShowMessage('No node is selected to test. Run "Discover Nodes" in the "Discovery" tab and select the node to test');
end;

procedure TFormMain.ActionHideLogExecute(Sender: TObject);
begin
  FormLog.Hide;
end;

procedure TFormMain.ActionLoadTestMatrixExecute(Sender: TObject);
begin
  OpenDialog.DefaultExt := '*.xml';
  OpenDialog.Filter := 'XML Files|*.xml';
  OpenDialog.Options := [ofFileMustExist];
  if OpenDialog.Execute then
  begin
    if FileExistsUTF8(OpenDialog.FileName) then
    begin
      ReadXMLFile(FXMLDocTestMatrix, UTF8ToSys(OpenDialog.FileName));
      LoadTestMatrixListview;
    end;
  end;
end;

procedure TFormMain.ActionLogShowGutterExecute(Sender: TObject);
begin
  FormLog.SynMemo.Gutter.Visible := FormLog.CheckBoxShowGutter.Checked;
end;

procedure TFormMain.ActionReadPipExecute(Sender: TObject);
var
  XMLDoc: TXMLDocument;
  Test: TTestProtocolSupport;
  ReceiveResults: TStringList;
  Helper: TOpenLCBMessageHelper;
  Mask: QWord;
  i: Integer;
begin
  if FileExistsUTF8(Settings.TestMatrixFile) then
  begin
    XMLDoc := TXMLDocument.Create;
    try
      ReadXMLFile(XMLDoc, Settings.TestMatrixFile);
      Test := FindTestFromXML(XMLDoc, STR_PROTOCOL_IDENTIFICATION_PROTOCOL_CLASS) as TTestProtocolSupport;
      if Assigned(Test) then
      begin
        for i := 0 to CheckGroupPIP.Items.Count - 1 do
          CheckGroupPIP.Checked[i] := False;
        CheckGroupPIP.Invalidate;
        CheckGroupPIP.Update;

        Test.FreeOnLog := True;
        TestThread.Add(Test);

        SafetyRelease := False;
        TimerSafetyNet.Enabled := True;
        while (Test.TestState <> ts_Complete) and not SafetyRelease do      // Wait for the test to end.....
          ThreadSwitch;

        if Test.Passed then
        begin
          ReceiveResults := TStringList.Create;
          Helper := TOpenLCBMessageHelper.Create;
          try
            ExtractResultsFromXML(Test.XMLResults, ReceiveResults);
            Test.StripReceivesNotForNodeUnderTest(ReceiveResults);
            if ReceiveResults.Count = 1 then
            begin
              Helper.Decompose(ReceiveResults[0]);
              Mask := Helper.ExtractDataBytesAsInt(2, 7);
              CheckGroupPIP.Checked[0] := Mask and PIP_PIP = PIP_PIP;
              CheckGroupPIP.Checked[1] := Mask and PIP_DATAGRAM = PIP_DATAGRAM;
              CheckGroupPIP.Checked[2] := Mask and PIP_STREAM = PIP_STREAM;
              CheckGroupPIP.Checked[3] := Mask and PIP_MEMORY_CONFIG = PIP_MEMORY_CONFIG;
              CheckGroupPIP.Checked[4] := Mask and PIP_RESERVATION = PIP_RESERVATION;
              CheckGroupPIP.Checked[5] := Mask and PIP_EVENT_EXCHANGE = PIP_EVENT_EXCHANGE;
              CheckGroupPIP.Checked[6] := Mask and PIP_IDENTIFCIATION = PIP_IDENTIFCIATION;
              CheckGroupPIP.Checked[7] := Mask and PIP_TEACH_LEARN = PIP_TEACH_LEARN;
              CheckGroupPIP.Checked[8] := Mask and PIP_REMOTE_BUTTON = PIP_REMOTE_BUTTON;
              CheckGroupPIP.Checked[9] := Mask and PIP_ABBREVIATED_CDI = PIP_ABBREVIATED_CDI;
              CheckGroupPIP.Checked[10] := Mask and PIP_DISPLAY = PIP_DISPLAY;
              CheckGroupPIP.Checked[11] := Mask and PIP_SIMPLE_NODE_ID = PIP_SIMPLE_NODE_ID;
              CheckGroupPIP.Checked[12] := Mask and PIP_CDI = PIP_CDI;
              CheckGroupPIP.Checked[13] := Mask and PIP_UNASSIGNED <> 0;
              CheckGroupPIP.Checked[14] := Mask and PIP_RESERVED <> 0;
              EditPipRawMessage.Text := ReceiveResults[0]
            end;
            LabelPipPassFail.Caption := 'Test Passed'
          finally
            ReceiveResults.Free;
            Helper.Free
          end;
        end else
        begin
          LabelPipPassFail.Caption := 'Test Failed'
        end;
      end;
    finally
      XMLDoc.Free;
    end;
  end;
end;

procedure TFormMain.ActionReadXMLExecute(Sender: TObject);
begin
   ShowMessage('Not implemented yet');
end;

procedure TFormMain.ActionRescanPortsExecute(Sender: TObject);
begin
  ComboBoxPorts.Items.Delimiter:=';';
  ComboBoxPorts.Items.DelimitedText := StringReplace(GetSerialPortNames, ',', ';', [rfReplaceAll, rfIgnoreCase]);
  if ComboBoxPorts.Items.Count > 0 then
    ComboBoxPorts.ItemIndex:= 0;
  UpdateUI
end;

procedure TFormMain.ActionSaveTestMatrixExecute(Sender: TObject);
var
  EnabledNode: TDOMNode;
  Test: TTestBase;
  i: Integer;
begin
  SaveDialog.DefaultExt := '*.xml';
  SaveDialog.Filter := 'XML Files|*.xml';
  if SaveDialog.Execute then
  begin
    for i := 0 to ListViewTestMatrix.Items.Count - 1 do
    begin
      Test := TTestBase( ListViewTestMatrix.Items[i].Data);
      EnabledNode := Test.XMLTests.FindNode('Enabled');
      if ListViewTestMatrix.Items[i].Checked then
        EnabledNode.FirstChild.NodeValue := 'True'
      else
        EnabledNode.FirstChild.NodeValue := 'False'
     end;
    WriteXMLFile(FXMLDocTestMatrix, SaveDialog.FileName);
  end;
end;

procedure TFormMain.ActionSendDatagramReplyExecute(Sender: TObject);
begin
  ShowMessage('Not implemented yet');
end;

procedure TFormMain.ActionSendPacketExecute(Sender: TObject);
begin
  ShowMessage('Not implemented yet');

end;

procedure TFormMain.ActionShowLogExecute(Sender: TObject);
begin
  FormLog.Left := Left+Width+4;
  FormLog.Top := Top;
  FormLog.Height := Height;
  FormLog.Width := 320;
  FormLog.Show;
end;

procedure TFormMain.ActionShowOptionsWinExecute(Sender: TObject);
begin
  FormSettings.Show;
end;

procedure TFormMain.ActionShowPreferencesMacExecute(Sender: TObject);
begin
  FormSettings.Show;
end;

procedure TFormMain.ComboBoxBaudChange(Sender: TObject);
begin
  UpdateUI;
end;

procedure TFormMain.ComboBoxPortsChange(Sender: TObject);
begin
  UpdateUI;
end;

procedure TFormMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  TimerCAN.Enabled := False;
  if Assigned(FTestThread) then
  begin
    TestThread.Terminate;
    FTestThread := nil;
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  {$IFDEF DARWIN}
  AppMenu := TMenuItem.Create(Self);  {Application menu}
  AppMenu.Caption := #$EF#$A3#$BF;  {Unicode Apple logo char}
  MainMenu.Items.Insert(0, AppMenu);

  AppAboutCmd := TMenuItem.Create(Self);
  AppAboutCmd.Caption := 'About ' + BUNDLENAME;
 // AppAboutCmd.OnClick := AboutCmdClick;
  AppMenu.Add(AppAboutCmd);  {Add About as item in application menu}

  AppSep1Cmd := TMenuItem.Create(Self);
  AppSep1Cmd.Caption := '-';
  AppMenu.Add(AppSep1Cmd);

  ActionShowPreferencesMac.ShortCut := ShortCut(VK_OEM_COMMA, [ssMeta]);
  AppPrefCmd := TMenuItem.Create(Self);
  AppPrefCmd.Action := ActionShowPreferencesMac;
  AppMenu.Add(AppPrefCmd);
  ActionShowOptionsWin.Visible := False;
  {$ENDIF}

  ShownOnce := False;
  FTestStrings := TStringList.Create;
  FXMLDocTestResults := TXMLDocument.Create;
  FSafetyRelease := False;
  ActionRescanPorts.Execute;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FTestStrings);
  FreeAndNil(FXMLDocTestMatrix);
  FreeAndNil(FXMLDocTestResults);
end;

procedure TFormMain.FormShow(Sender: TObject);
begin
  if not ShownOnce then
  begin
    Settings.ReadSettings;
    EditDiscoverNodeAlias.Text := IntToHex(Settings.ProxyNodeAlias, 4);
    EditDiscoverNodeID.Text := IntToHex(Settings.ProxyNodeID, 6);
    ComboBoxPorts.ItemIndex := ComboBoxPorts.Items.IndexOf(Settings.ComPort);
    ComboBoxPorts.ItemIndex := ComboBoxPorts.Items.IndexOfName(Settings.ComPort);
    EditCustomBaudRate.Enabled := True;
    LabelCustomBaud.Enabled := True;
    ComboBoxBaud.ItemIndex := 0; // Custom
    ComboBoxBaud.ItemIndex := ComboBoxBaud.Items.IndexOf(IntToStr(Settings.BaudRate));
    ReadXMLFile(FXMLDocTestMatrix, Settings.TestMatrixFile);
    LoadTestMatrixListview;
    UpdateUI;
    {$IFDEF USE_DEBUG_LOGGER}
    FormDebugLogger.Show;
    {$ENDIF}
  end;
  ShownOnce := True;
end;

procedure TFormMain.ListViewNodeDiscoverySelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  i: Integer;
begin
  if Selected then
  begin
    Settings.TargetNodeAlias := StrToInt('$' + Item.Caption);
    Settings.TargetNodeID := StrToInt64('$' + Item.SubItems[0]);
  end;
  for i := 0 to ListViewTestMatrix.Items.Count - 1 do
    ListViewTestMatrix.Items[i].ImageIndex := 2;
  ListViewTestMatrix.Invalidate;
  UpdateUI;
end;

procedure TFormMain.ListViewTestMatrixDeletion(Sender: TObject; Item: TListItem);
var
  Test: TTestBase;
begin
  Test := TTestBase( Item.Data);
  Test.XMLTests := nil;                    // The XML Document owns this
  FreeAndNil( Test);
end;

procedure TFormMain.TimerCANTimer(Sender: TObject);
var
  Test: TTestBase;
  List: TList;
  XMLTestResults: TXMLDocument;
  MemStream: TMemoryStream;
  Str: String;
  ListItem: TListItem;
begin
  Test := nil;
  ListItem := nil;
  XMLTestResults := nil;
  if Assigned(TestThread) then
  begin
    List := TestThread.ThreadTestList.LockList;
    try
      if List.Count > 0 then
      begin
        Test := TTestBase( List[0]);
        if Test.TestState = ts_Complete then
        begin
          if FormLog.Visible then
            XMLTestResults := Test.XMLResults;
          ListItem := Test.ListItem;
          List.Remove(Test);
        end else
          Test := nil;
      end;
    finally
      TestThread.ThreadTestList.UnLockList;
    end;

    // Do this outside of the thread lock so the thread can keep churning
    if Assigned(ListItem) and Assigned(Test) then
    begin
      if Test.Passed then
        ListItem.ImageIndex := 0
      else
        ListItem.ImageIndex := 1;
    end;
    if Assigned(XMLTestResults) then
    begin
      FormLog.SynMemo.Lines.BeginUpdate;
      try
        MemStream := TMemoryStream.Create;
        XMLWrite.WriteXMLFile(XMLTestResults, MemStream);
        SetLength(Str, MemStream.Size);
        MemStream.Seek(0, soBeginning);
        MemStream.ReadBuffer(PChar( Str)^, MemStream.Size);
        FormLog.SynMemo.Text := FormLog.SynMemo.Text + Str;
        MemStream.Free;
      finally
        FormLog.SynMemo.Lines.EndUpdate;
      end;
    end;

    if Assigned(Test) then
    begin
      if Test.FreeOnLog then
        Test.Free;
    end;
  end;
end;

procedure TFormMain.TimerSafetyNetTimer(Sender: TObject);
begin
  SafetyRelease := True;
  TimerSafetyNet.Enabled := False;
end;

function TFormMain.GetConnected: Boolean;
begin
  Result := Assigned(TestThread)
end;

procedure TFormMain.UpdateUI;
begin
  {$IFNDEF DISABLE_UI_UPDATE}
  ActionDiscoverNode.Enabled := Connected;
  ActionReadPip.Enabled := (ListViewNodeDiscovery.SelCount = 1) and Connected;
  ActionExecuteTests.Enabled := (ListViewNodeDiscovery.SelCount = 1) and Connected;
  ActionSaveTestMatrix.Enabled := Connected;
  ActionReadXML.Enabled := (ListViewNodeDiscovery.SelCount = 1) and Connected;
  ActionEventReader.Enabled := (ListViewNodeDiscovery.SelCount = 1) and Connected;
  ActionSendPacket.Enabled := (ListViewNodeDiscovery.SelCount = 1) and Connected;
  ActionSendDatagramReply.Enabled := (ListViewNodeDiscovery.SelCount = 1) and Connected;
  ActionConnect.Enabled :=  ComboBoxPorts.ItemIndex > -1;
  EditCustomBaudRate.Enabled := ComboBoxBaud.ItemIndex = 0;
  LabelCustomBaud.Enabled := ComboBoxBaud.ItemIndex = 0;
  if ComboBoxBaud.ItemIndex > 0 then EditCustomBaudRate.Text := '';
  {$ENDIF}
end;

procedure TFormMain.ClearTestResultsXML;
var
  Node: TDOMNode;
begin
  Node := XMLDocTestResults.FindNode('TestResults');
  if Assigned(Node) then
    XMLDocTestResults.RemoveChild(Node);
  Node := XMLDocTestResults.CreateElement('TestResult')
end;

procedure TFormMain.LoadTestMatrixListview;
var
  TestList: TList;
  Test: TTestBase;
  ListItem: TListItem;
  TestNode: TDOMNode;
  i: Integer;
begin
  if Assigned(XMLDocTestMatrix) then
  begin
    ListviewTestMatrix.Items.BeginUpdate;
    try
      ListviewTestMatrix.Items.Clear;
      TestList := TList.Create;
      try
        ExtractTestsFromXML(XMLDocTestMatrix, TestList);
        for i := 0 to TestList.Count - 1 do
        begin
          TestNode := TDOMNode( TestList[i]);
          Test := TTestBase.CreateInstanceFromString( TestClassnameFromTestNode(TestNode));  // Create a Test Object from the Classname in the XML

          if not Assigned(Test) then
              ShowMessage('Invalid Classname for Test ' + TestNameFromTestNode(TestNode))
          else begin
            if not (Test is TTestVerifyNodesID) then
            begin
              ListItem := ListviewTestMatrix.Items.Add;
              ListItem.Caption := TestNameFromTestNode(TestNode);
              ListItem.SubItems.Add(TestDescriptionFromTestNode(TestNode));
              ListItem.SubItems.Add(TestSpecDocFromTestNode(TestNode));
              ListItem.SubItems.Add(TestClassnameFromTestNode(TestNode));
              ListItem.Checked :=  TestEnabledStateFromTestNode(TestNode) = 'True';
              ListItem.ImageIndex := 2;
              ListItem.Data := Test;
              Test.XMLTests := TestNode;
              Test.ListItem := ListItem;   // Back Link to the Item
            end;
          end;
        end;
      finally
        TestList.Free;  // Does not own the nodes
        UpdateUI;
      end;
    finally
      ListviewTestMatrix.Items.EndUpdate
    end;
  end;
end;

procedure TFormMain.Log(Line: String);
begin
  if FormLog.Visible then
  begin
    FormLog.SynMemo.Lines.Add(Line);
  end;
end;


end.
