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

interface

uses
  Classes, SysUtils, FileUtil, SynHighlighterXML, SynEdit,
  RTTICtrls, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls, ActnList,
  Menus, ExtCtrls, synaser, lcltype, unitlogwindow, unitsettings,
  DOM, XMLRead, XMLWrite, serialport_thread, olcb_testmatrix,
  nodeexplorer_settings, olcb_utilities, unitolcb_defines;


const
  BUNDLENAME = 'NodeExplorer';

type

  { TFormMain }

  TFormMain = class(TForm)
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
    ButtonSaveTests: TButton;
    ButtonShowLog: TButton;
    ButtonRescanPorts: TButton;
    ButtonLoadTests: TButton;
    ButtonSendPacket: TButton;
    ButtonReadXML: TButton;
    ButtonReadEvents: TButton;
    ButtonSendDatagramReply: TButton;
    ComboBoxBaud: TComboBox;
    ComboBoxPorts: TComboBox;
    EditBaudRate: TEdit;
    EditDiscoverNodeAlias: TEdit;
    EditDiscoverNodeID: TEdit;
    EditPacket: TEdit;
    EditSourceNodeAlias: TEdit;
    EditTargetNodeAlias: TEdit;
    GroupBoxComPort: TGroupBox;
    GroupBoxEventReaderConsumers: TGroupBox;
    GroupBoxEventReaderProducers: TGroupBox;
    ImageOpenLCB: TImage;
    Label1: TLabel;
    Label2: TLabel;
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
    TabSheetVerification: TTabSheet;
    TabSheetDiscover: TTabSheet;
    TabSheetEventReader: TTabSheet;
    TabSheetHome: TTabSheet;
    TabSheetCustom: TTabSheet;
    TabSheetCDIReader: TTabSheet;
    TimerCAN: TTimer;
    procedure ActionClearExecute(Sender: TObject);
    procedure ActionConnectExecute(Sender: TObject);
    procedure ActionDiscoverNodeExecute(Sender: TObject);
    procedure ActionEventReaderExecute(Sender: TObject);
    procedure ActionExecuteTestsExecute(Sender: TObject);
    procedure ActionHideLogExecute(Sender: TObject);
    procedure ActionLoadTestMatrixExecute(Sender: TObject);
    procedure ActionLogShowGutterExecute(Sender: TObject);
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
  private
    { private declarations }
    FShownOnce: Boolean;
    FTestMatrix: TOpenLCBTestMatrix;
    FTestStrings: TStringList;
    FVerifyNodesIDTest: TTestVerifyNodesID;
    FXMLDoc: TXMLDocument;
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
    property Connected: Boolean read GetConnected;
  public
    { public declarations }
    procedure Log(Line: String);
    procedure LoadTestMatrix;
    property ShownOnce: Boolean read FShownOnce write FShownOnce;
    property TestStrings: TStringList read FTestStrings write FTestStrings;
    property TestMatrix: TOpenLCBTestMatrix read FTestMatrix write FTestMatrix;
    property VerifyNodesIDTest: TTestVerifyNodesID read FVerifyNodesIDTest write FVerifyNodesIDTest;
    property XMLDoc: TXMLDocument read FXMLDoc write FXMLDoc;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

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
    TestMatrix.ComportThread.Terminate;
    TestMatrix.ComPortThread := nil;
    ActionConnect.Caption:='Connect';
  end else
  begin
    TestMatrix.ComPortThread := TComPortThread.Create(True);
    try
      TestMatrix.ComPortThread.FreeOnTerminate := True;
      {$IFDEF MSWINDOWS}
      TestMatrix.ComPortThread.Port := ComboBoxPorts.Text;
      {$ELSE}
      TestMatrix.ComPortThread.Port := 'dev/' + ComboBoxPorts.Text;
      {$ENDIF}
      if ComboBoxBaud.ItemIndex = 0 then
        TestMatrix.ComPortThread.BaudRate := StrToInt(EditBaudRate.Text)
      else
        TestMatrix.ComPortThread.BaudRate := StrToInt(ComboBoxBaud.Items[ComboBoxBaud.ItemIndex]);
      TestMatrix.ComPortThread.Suspended := False;
      Sleep(500);
      if TestMatrix.ComportThread.Connected then
        ActionConnect.Caption:='Disconnect'
      else begin
        TestMatrix.ComPortThread.Terminate;
        TestMatrix.ComPortThread := nil;
      end;
    except
      if Assigned(TestMatrix.ComPortThread) then
      begin
        TestMatrix.ComPortThread.Terminate;
        TestMatrix.ComPortThread := nil;
      end;
      ActionConnect.Caption:='Connect';
    end;
  end;
  UpdateUI;
end;

procedure TFormMain.ActionDiscoverNodeExecute(Sender: TObject);
var
  StartLine, EndLine, i: Integer;
  Helper: TOpenLCBMessageHelper;
  ListItem: TListItem;
begin
  StartLine := 0;
  EndLine := 0;
  TestMatrix.Add(VerifyNodesIDTest);
  TimerCAN.Enabled := True;
  while VerifyNodesIDTest.TestState <> ts_Complete do
    ThreadSwitch;
  Helper := TOpenLCBMessageHelper.Create;
  ListViewNodeDiscovery.Items.BeginUpdate;
  try
    ListViewNodeDiscovery.Items.Clear;

    StartLine := VerifyNodesIDTest.TestStrings.IndexOf('    <receive>');
    EndLine := VerifyNodesIDTest.TestStrings.IndexOf('    </receive>');
    for i := StartLine + 1 to EndLine - 1 do
    begin
      Helper.Decompose(VerifyNodesIDTest.TestStrings[i]);
      if Helper.MTI = MTI_VERIFIED_NODE_ID_NUMBER then
      begin
         ListItem := ListViewNodeDiscovery.Items.Add;
         ListItem.Caption := IntToHex(Helper.SourceAliasID, 3);
         ListItem.SubItems.Add(IntToHex(Helper.DataAsNodeID, 12));
      end;
    end;
  finally
    ListViewNodeDiscovery.Items.EndUpdate;
    Helper.Free
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
  if ListViewNodeDiscovery.SelCount = 1 then
  begin
    for i := 0 to ListViewTestMatrix.Items.Count - 1 do
    begin
      if ListViewTestMatrix.Items[i].Checked then
        TestMatrix.Add( TTestBase( ListViewTestMatrix.Items[i].Data));
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
      ReadXMLFile(FXMLDoc, UTF8ToSys(OpenDialog.FileName));
    LoadTestMatrix
  end;
end;

procedure TFormMain.ActionLogShowGutterExecute(Sender: TObject);
begin
  FormLog.SynMemo.Gutter.Visible := FormLog.CheckBoxShowGutter.Checked;
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
      EnabledNode := Test.XMLNode.FindNode('Enabled');
      if ListViewTestMatrix.Items[i].Checked then
        EnabledNode.FirstChild.NodeValue := 'True'
      else
        EnabledNode.FirstChild.NodeValue := 'False'
     end;
    WriteXMLFile(FXMLDoc, SaveDialog.FileName);
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
  FormLog.Left := Left+Width;
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
  EditBaudRate.Enabled := ComboBoxBaud.ItemIndex = 0;
  LabelCustomBaud.Enabled := ComboBoxBaud.ItemIndex = 0;
end;

procedure TFormMain.ComboBoxPortsChange(Sender: TObject);
begin
  UpdateUI;
end;

procedure TFormMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  TimerCAN.Enabled := False;
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
  FVerifyNodesIDTest := nil;
  FTestStrings := TStringList.Create;
  FTestMatrix := TOpenLCBTestMatrix.Create;
  ActionRescanPorts.Execute;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FTestStrings);
  FreeAndNil(FTestMatrix);
  FreeAndNil(FXMLDoc);
end;

procedure TFormMain.FormShow(Sender: TObject);
var
  i: Integer;
begin
  if not ShownOnce then
  begin
    TimerCAN.Enabled := True;
    Settings.ReadSettings;
    EditDiscoverNodeAlias.Text := IntToHex(Settings.ProxyNodeAlias, 4);
    EditDiscoverNodeID.Text := IntToHex(Settings.ProxyNodeID, 6);
    for i := 0 to ComboBoxPorts.Items.Count - 1 do
    begin
      if CompareText(ComboBoxPorts.Items[i], Settings.ComPort) = 0 then
      begin
        ComboBoxPorts.ItemIndex := i;
        Break;
      end
    end;
    ComboBoxPorts.ItemIndex := ComboBoxPorts.Items.IndexOfName(Settings.ComPort);
    EditBaudRate.Enabled := True;
    LabelCustomBaud.Enabled := True;
    ComboBoxBaud.ItemIndex := 0; // Custom
    EditBaudRate.Text := IntToStr(Settings.BaudRate);
    for i := 0 to ComboBoxBaud.Items.Count - 1 do
    begin
      if CompareText(ComboBoxBaud.Items[i], IntToStr(Settings.BaudRate)) = 0 then
      begin
        ComboBoxBaud.ItemIndex := i;
        EditBaudRate.Text := '';
        EditBaudRate.Enabled := False;
        LabelCustomBaud.Enabled := False;
        Break;
      end;
    end;
    UpdateUI;
  end;
  ShownOnce := True;
end;

procedure TFormMain.ListViewNodeDiscoverySelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
begin
  if Selected then
  begin
    Settings.TargetNodeAlias := StrToInt('$' + Item.Caption);
    Settings.TargetNodeID := StrToInt64('$' + Item.SubItems[0]);
  end;
end;

procedure TFormMain.ListViewTestMatrixDeletion(Sender: TObject; Item: TListItem);
var
  Test: TTestBase;
begin
  Test := TTestBase( Item.Data);
  Test.XMLNode := nil;                    // The XML Document owns this
  FreeAndNil( Test);
end;

procedure TFormMain.TimerCANTimer(Sender: TObject);
var
  i: Integer;
  Test: TTestBase;
  List: TList;
  LocalStrings: TStringList;
begin
  Test := nil;
  LocalStrings := nil;
  if Assigned(TestMatrix.ComPortThread) then
  begin
    List := TestMatrix.ComPortThread.ThreadTestList.LockList;
    try
      if List.Count > 0 then
      begin
        Test := TTestBase( List[0]);
        if Test.TestState = ts_Complete then
        begin
          if FormLog.Visible then
          begin
            LocalStrings := TStringList.Create;
            LocalStrings.Text := Test.TestStrings.Text;  // Make a copy for the log
          end;
          List.Remove(Test);
        end else
          Test := nil;
      end;
    finally
      TestMatrix.ComPortThread.ThreadTestList.UnLockList;
    end;

    // Do this outside of the thread lock so the thread can keep churning
    if Assigned(LocalStrings) then
    begin
      FormLog.SynMemo.Lines.BeginUpdate;
      try
        for i := 0 to LocalStrings.Count - 1 do
          Log(LocalStrings[i]);
      finally
        FormLog.SynMemo.Lines.EndUpdate;
        FreeAndNil(LocalStrings)
      end;
    end;
  end;
end;

function TFormMain.GetConnected: Boolean;
begin
  Result := Assigned(TestMatrix.ComPortThread)
end;

procedure TFormMain.UpdateUI;
begin
  {$IFNDEF DISABLE_UI_UPDATE}
  ActionDiscoverNode.Enabled := Assigned(VerifyNodesIDTest) and Connected;
  ActionExecuteTests.Enabled := Assigned(XMLDoc) and Connected;
  ActionSaveTestMatrix.Enabled := Assigned(XMLDoc);
  ActionReadXML.Enabled := Connected;
  ActionEventReader.Enabled := Connected;
  ActionSendPacket.Enabled := Connected;
  ActionSendDatagramReply.Enabled := Connected;
  ActionConnect.Enabled :=  ComboBoxPorts.ItemIndex > -1;
  {$ENDIF}
end;

procedure TFormMain.Log(Line: String);
begin
  if FormLog.Visible then
  begin
    FormLog.SynMemo.Lines.Add(Line);
  end;
end;

procedure TFormMain.LoadTestMatrix;
var
  i: Integer;
  TestNode: TDOMNode;
  ListItem: TListItem;
  Test: TTestBase;
  TestList: TList;
begin
  ListviewTestMatrix.Items.BeginUpdate;
  try
    VerifyNodesIDTest := nil;          // Need to find it again
    ListviewTestMatrix.Items.Clear;
    TestList := TList.Create;
    try
      ExtractTestsFromXML(XMLDoc, TestList);
      for i := 0 to TestList.Count - 1 do
      begin
        TestNode := TDOMNode( TestList[i]);
        Test := TTestBase.CreateInstanceFromString( TestClassnameFromTestNode(TestNode));  // Create a Test Object from the Classname in the XML

        if not Assigned(Test) then
            ShowMessage('Invalid Classname for Test ' + TestNameFromTestNode(TestNode))
        else begin
          if Test is TTestVerifyNodesID then
          begin
            VerifyNodesIDTest := Test as TTestVerifyNodesID;
            VerifyNodesIDTest.XMLNode := TestNode;
          end else
          begin
            ListItem := ListviewTestMatrix.Items.Add;
            ListItem.Caption := TestNameFromTestNode(TestNode);
            ListItem.SubItems.Add(TestDescriptionFromTestNode(TestNode));
            ListItem.SubItems.Add(TestSpecDocFromTestNode(TestNode));
            ListItem.SubItems.Add(TestClassnameFromTestNode(TestNode));
            ListItem.Checked := CompareText(TestEnabledStateFromTestNode(TestNode), 'True') = 0;
            ListItem.Data := Test;
            Test.XMLNode := TestNode;
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

end.

