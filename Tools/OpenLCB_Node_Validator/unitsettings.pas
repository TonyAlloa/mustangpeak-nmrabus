unit Unitsettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  synaser;

type

  { TFormSettings }

  TFormSettings = class(TForm)
    ComboBoxPorts: TComboBox;
    EditBaudRate: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormActivate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  FormSettings: TFormSettings;

implementation

{$R *.lfm}

{ TFormSettings }

procedure TFormSettings.FormActivate(Sender: TObject);
begin
  ComboBoxPorts.Items.Delimiter:=';';
  ComboBoxPorts.Items.DelimitedText:=StringReplace(GetSerialPortNames, ',', ';', [rfReplaceAll, rfIgnoreCase]);
  if ComboBoxPorts.Items.Count > 0 then
    ComboBoxPorts.ItemIndex:= 0;
end;

end.

