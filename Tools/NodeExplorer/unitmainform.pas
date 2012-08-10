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

interface

uses
  Classes, SysUtils, FileUtil, SynHighlighterXML, SynEdit, SynMemo, RTTICtrls,
  Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls, ActnList, Menus,
  ExtCtrls, synaser, lcltype, unitlogwindow, olcb_utilities,
  unitolcb_defines, unitsettings;


const
  BUNDLENAME = 'OpenLCB Node Validator';
  SOURCE_ALIAS = $0AAA;

type

  { TFormMain }

  TFormMain = class(TForm)
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
    ActionRunCANTests: TAction;
    ActionSendPacket: TAction;
    ActionRunOpenLCBTests: TAction;
    ActionClear: TAction;
    ActionListMain: TActionList;
    ApplicationProperties1: TApplicationProperties;
    ButtonConnect: TButton;
    ButtonConnect1: TButton;
    ButtonConnect2: TButton;
    ButtonConnect3: TButton;
    ButtonSendPacket: TButton;
    ButtonReadXML: TButton;
    ButtonReadEvents: TButton;
    ButtonRunOpenLCBTests: TButton;
    ButtonSendDatagramReply: TButton;
    ButtonRunOpenLCBTests1: TButton;
    CheckGroupCANPhysicalLayer: TCheckGroup;
    CheckGroupEvents: TCheckGroup;
    CheckGroupMemoryProtocol: TCheckGroup;
    CheckGroupDatagrams: TCheckGroup;
    CheckGroupCANMessages: TCheckGroup;
    CheckGroupMisc: TCheckGroup;
    ComboBoxBaud: TComboBox;
    ComboBoxPorts: TComboBox;
    EditBaudRate: TEdit;
    EditDiscoverNodeAlias: TEdit;
    EditDiscoverNodeID: TEdit;
    EditPacket: TEdit;
    EditSourceNodeAlias: TEdit;
    EditTargetNodeAlias: TEdit;
    GroupBox1: TGroupBox;
    GroupBoxEventReaderConsumers: TGroupBox;
    GroupBoxEventReaderProducers: TGroupBox;
    GroupBoxNodeDiscovery: TGroupBox;
    ImageOpenLCB: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    LabelBaud: TLabel;
    LabelCustomBaud: TLabel;
    LabelDiscoverNodeAlias: TLabel;
    LabelDiscoverNodeID: TLabel;
    LabelPort: TLabel;
    ListViewConsumers: TListView;
    ListViewConsumers1: TListView;
    ListViewDiscovery: TListView;
    ListViewProducers: TListView;
    MainMenu: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItemFile: TMenuItem;
    PageControl: TPageControl;
    Panel1: TPanel;
    SynEdit1: TSynEdit;
    SynXMLSyn: TSynXMLSyn;
    TabSheetDiscover: TTabSheet;
    TabSheetEventReader: TTabSheet;
    TabSheetHome: TTabSheet;
    TabSheetCustom: TTabSheet;
    TabSheetCANLayer: TTabSheet;
    TabSheetOpenLCBLayer: TTabSheet;
    TabSheetCDIReader: TTabSheet;
    TimerCAN: TTimer;
    procedure ActionClearExecute(Sender: TObject);
    procedure ActionConnectExecute(Sender: TObject);
    procedure ActionDiscoverNodeExecute(Sender: TObject);
    procedure ActionEventReaderExecute(Sender: TObject);
    procedure ActionHideLogExecute(Sender: TObject);
    procedure ActionReadXMLExecute(Sender: TObject);
    procedure ActionRescanPortsExecute(Sender: TObject);
    procedure ActionRunCANTestsExecute(Sender: TObject);
    procedure ActionRunOpenLCBTestsExecute(Sender: TObject);
    procedure ActionSendDatagramReplyExecute(Sender: TObject);
    procedure ActionSendPacketExecute(Sender: TObject);
    procedure ActionShowLogExecute(Sender: TObject);
    procedure ActionShowOptionsWinExecute(Sender: TObject);
    procedure ActionShowPreferencesMacExecute(Sender: TObject);
    procedure ApplicationProperties1Activate(Sender: TObject);
    procedure ApplicationProperties1Idle(Sender: TObject; var Done: Boolean);
    procedure ApplicationProperties1IdleEnd(Sender: TObject);
    procedure ComboBoxBaudChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TimerCANTimer(Sender: TObject);
  private
    FNodeManager: TOpenLCBNodeManager;
    { private declarations }
    FShownOnce: Boolean;
    FTestMatrix: TOpenLCBTestMatrix;
    FTestStrings: TStringList;
  protected
    { protected declarations }
    {$IFDEF DARWIN}
      AppMenu     : TMenuItem;
      AppAboutCmd : TMenuItem;
      AppSep1Cmd  : TMenuItem;
      AppPrefCmd  : TMenuItem;
    {$ENDIF}
  public
    { public declarations }
    procedure Log(Line: String);
    property ShownOnce: Boolean read FShownOnce write FShownOnce;
    property TestStrings: TStringList read FTestStrings write FTestStrings;
    property NodeManager: TOpenLCBNodeManager read FNodeManager write FNodeManager;
    property TestMatrix: TOpenLCBTestMatrix read FTestMatrix write FTestMatrix;
  end; 

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

{ TFormMain }

procedure TFormMain.ActionClearExecute(Sender: TObject);
begin
  FormLog.MemoLog.Lines.BeginUpdate;
  try
    FormLog.MemoLog.Clear;
  finally
    FormLog.MemoLog.Lines.EndUpdate
  end;
end;

procedure TFormMain.ActionConnectExecute(Sender: TObject);
begin
  if Assigned(TestMatrix.ComPortThread) then
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
      Sleep(1000);
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
  end
end;

procedure TFormMain.ActionDiscoverNodeExecute(Sender: TObject);
var
  Test: TOpenLCBTest_VerifyNodeID;
begin
 // TestMatrix.ClearTestList;
  Test := TOpenLCBTest_VerifyNodeID.Create(NodeManager.ProxyNodeAlias);
  TestMatrix.Add(Test);
  TestMatrix.Run;
  TimerCAN.Enabled := True;
end;

procedure TFormMain.ActionEventReaderExecute(Sender: TObject);
begin

end;

procedure TFormMain.ActionHideLogExecute(Sender: TObject);
begin
  FormLog.Hide;
end;

procedure TFormMain.ActionReadXMLExecute(Sender: TObject);
begin

end;

procedure TFormMain.ActionRescanPortsExecute(Sender: TObject);
begin
  ComboBoxPorts.Items.Delimiter:=';';
  ComboBoxPorts.Items.DelimitedText:=StringReplace(GetSerialPortNames, ',', ';', [rfReplaceAll, rfIgnoreCase]);
  if ComboBoxPorts.Items.Count > 0 then
    ComboBoxPorts.ItemIndex:= 0;
end;

procedure TFormMain.ActionRunCANTestsExecute(Sender: TObject);
begin

end;

procedure TFormMain.ActionRunOpenLCBTestsExecute(Sender: TObject);
var
  i: integer;
  Str: AnsiString;
  ByteArray: TByteArray;
begin
  TimerCAN.Enabled := False;
  try
    if CheckGroupMisc.Checked[0] then
    begin
      Log('Testing Simple Node Identification Protocol (SNII)');
      WordToByteArray(ByteArray, StrToInt( '$' + EditDiscoverNodeAlias.Text), 0);
      Str := BuildNMRALayerMessage(MTI_SIMPLE_NODE_INFO_REQUEST, SOURCE_ALIAS, 2, ByteArray, False);
      Log('Sending: ' + Str);

  //    ReadResult(TestStrings, False);
      for i := 0 to 2 do
      begin
        Log('Sending: ' + Str);
   //     ser.SendString(Str + LF);
      end;
  //    ReadResult(TestStrings, False);
    end;

    if CheckGroupMisc.Checked[1] then
    begin
      Log('Testing Protocol Identification Protocol (PIP)');
      WordToByteArray(ByteArray, StrToInt( '$' + EditDiscoverNodeAlias.Text), 0);
      Str := BuildNMRALayerMessage(MTI_PROTOCOL_SUPPORT_INQUIRY, SOURCE_ALIAS, 2, ByteArray, False);
      Log('Sending: ' + Str);
   //   ser.SendString(Str + LF);
   //   ReadResult(TestStrings, False);
    end;

    if CheckGroupEvents.Checked[0] then
    begin
      Log('Testing Global Identify Events');
      Str := BuildNMRALayerMessage(MTI_EVENTS_IDENTIFY, SOURCE_ALIAS, 0, ByteArray, False);
      Log('Sending: ' + Str);
  //    ser.SendString(Str + LF);
   //   ReadResult(TestStrings, False);
    end;

    if CheckGroupEvents.Checked[1] then
    begin
      Log('Testing Addressed Identify Events');
      WordToByteArray(ByteArray, StrToInt( '$' + EditDiscoverNodeAlias.Text), 0);
      Str := BuildNMRALayerMessage(MTI_EVENTS_IDENTIFY_DEST, SOURCE_ALIAS, 2, ByteArray, False);
      Log('Sending: ' + Str);
  //    ser.SendString(Str + LF);
  //    ReadResult(TestStrings, False);
    end;
  finally
    TimerCAN.Enabled := True;
  end;

end;

procedure TFormMain.ActionSendDatagramReplyExecute(Sender: TObject);
begin
  Log('Sending: :X19A28AAAN0641;');
 // ser.SendString(':X19A28AAAN0641;');
end;

procedure TFormMain.ActionSendPacketExecute(Sender: TObject);
begin
  if FormLog.Visible then
    FormLog.MemoLog.Lines.Add('Sending: '+EditPacket.Text);
 // ser.SendString(EditPacket.Text);
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

procedure TFormMain.ApplicationProperties1Activate(Sender: TObject);
begin

end;

procedure TFormMain.ApplicationProperties1Idle(Sender: TObject;
  var Done: Boolean);
begin

end;

procedure TFormMain.ApplicationProperties1IdleEnd(Sender: TObject);
begin

end;

procedure TFormMain.ComboBoxBaudChange(Sender: TObject);
begin
  EditBaudRate.Enabled := ComboBoxBaud.ItemIndex = 0;
  LabelCustomBaud.Enabled := ComboBoxBaud.ItemIndex = 0;
end;

procedure TFormMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin

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
  FTestStrings := TStringList.Create;
  FNodeManager := TOpenLCBNodeManager.Create;
  FTestMatrix := TOpenLCBTestMatrix.Create;
  ActionRescanPorts.Execute;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FTestStrings);
  FreeAndNil(FNodeManager);
  FreeAndNil(FTestMatrix);
end;

procedure TFormMain.FormShow(Sender: TObject);
begin
  if not ShownOnce then
  begin
    TimerCAN.Enabled := True;
  end;
  ShownOnce := True;
end;


procedure TFormMain.TimerCANTimer(Sender: TObject);
var
  i: Integer;
  Test: TOpenLCBTest;
begin
  if TestMatrix.TestList.Count > 0 then
  begin
    Test := TOpenLCBTest( TestMatrix.TestList[0]);
    if Test.TestState = ts_Complete then
    begin
      for i := 0 to Test.TestStrings.Count - 1 do
        Log(Test.TestStrings[i]);
      TestMatrix.TestList.Remove(Test);
      Test.Free;
    end;
  end;
end;

procedure TFormMain.Log(Line: String);
begin
  if FormLog.Visible then
  begin
    FormLog.MemoLog.Lines.Add(Line);
  end;
end;

end.

