unit UnitMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ActnList, Menus, ExtCtrls, synaser, unitsettings;

type

  { TFormMain }

  TFormMain = class(TForm)
    ActionSendPacket: TAction;
    ActionRunTests: TAction;
    ActionClear: TAction;
    ActionShowSettings: TAction;
    ActionList1: TActionList;
    ApplicationProperties1: TApplicationProperties;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    ButtonClear: TButton;
    ButtonConnect: TButton;
    CheckGroupCAN: TCheckGroup;
    CheckGroupOpenLCB: TCheckGroup;
    EditPacket: TEdit;
    EditTargetNodeAlias: TEdit;
    EditSourceNodeAlias: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenuItemOptions: TMenuItem;
    MenuItemSettings: TMenuItem;
    MenuItemFile: TMenuItem;
    Timer1: TTimer;
    procedure ActionClearExecute(Sender: TObject);
    procedure ActionRunTestsExecute(Sender: TObject);
    procedure ActionSendPacketExecute(Sender: TObject);
    procedure ActionShowSettingsExecute(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ButtonConnectClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItemFileClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    ser:TBlockSerial;
    Connected: Boolean;
    function ReadCAN: AnsiString;
  end; 

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

{ TFormMain }

procedure TFormMain.ActionShowSettingsExecute(Sender: TObject);
begin
  FormSettings.Show;
end;

procedure TFormMain.Button2Click(Sender: TObject);
begin

end;

procedure TFormMain.Button3Click(Sender: TObject);
begin
  Memo1.Lines.Add('Sending: :X1E641AAAN4C;');
  ser.SendString(':X1E641AAAN4C;');
end;

procedure TFormMain.ActionClearExecute(Sender: TObject);
begin
  Memo1.Lines.BeginUpdate;
  try
    Memo1.Clear;
  finally
    Memo1.Lines.EndUpdate
  end;
end;

procedure TFormMain.ActionRunTestsExecute(Sender: TObject);
var
  i: integer;
begin
  if CheckGroupOpenLCB.Checked[0] then
  begin
    Memo1.Lines.Add('Testing Simple Node Identification Info (SNII)');
    Memo1.Lines.Add('Sending: :X1E641AAAN52;');
    ser.SendString(':X1E641AAAN52;');
    Sleep(2000);
    while ReadCAN <> '' do;
    for i := 0 to 2 do
    begin
      Memo1.Lines.Add('Sending: :X1E641AAAN52;');
      ser.SendString(':X1E641AAAN52;');
      Sleep(1);
    end;
  end;
end;

procedure TFormMain.ActionSendPacketExecute(Sender: TObject);
begin
  Memo1.Lines.Add('Sending: '+EditPacket.Text);
  ser.SendString(EditPacket.Text);
//  Memo1.Lines.Add('Sending: :X1E741AAAN52;');
//  ser.SendString(':X1E741AAAN52;');
end;



procedure TFormMain.ButtonConnectClick(Sender: TObject);
begin
  if Connected then
  begin
    ser.CloseSocket;
    ButtonConnect.Caption:='Connect';
    Connected:=False
  end else
  begin
    ser.Connect( FormSettings.ComboBoxPorts.Text);
    ser.Config(StrToInt(FormSettings.EditBaudRate.Text), 8, 'N', 0, False, False);      // FTDI Driver uses no stop bits for non-standard baud rates.
    ButtonConnect.Caption:='Disconnect';
    Connected:=True
  end;
end;


procedure TFormMain.FormCreate(Sender: TObject);
begin
  ser:=TBlockSerial.Create;
  ser.RaiseExcept:=True;
  Connected:=False;
end;

procedure TFormMain.MenuItemFileClick(Sender: TObject);
begin

end;

procedure TFormMain.Timer1Timer(Sender: TObject);
begin
  ReadCAN;
end;

function TFormMain.ReadCAN: AnsiString;
begin
  if Connected then
  begin
    Memo1.Lines.BeginUpdate;
    try
      if ser.WaitingDataEx <> 0 then
      begin
        Result := Result + ser.RecvPacket(5000);
        Memo1.Text:=Memo1.Text+Result;
      end;
    finally
      Memo1.Lines.EndUpdate;
    end;
  end;
end;

end.

