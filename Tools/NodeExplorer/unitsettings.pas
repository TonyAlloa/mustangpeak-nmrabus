unit unitsettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Spin,
  StdCtrls, nodeexplorer_settings;

type

  { TFormSettings }

  TFormSettings = class(TForm)
    CheckBoxPingPongStandardFrame: TCheckBox;
    Label1: TLabel;
    SpinEditDelayTimeout: TSpinEdit;
    procedure CheckBoxPingPongStandardFrameChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SpinEditDelayTimeoutChange(Sender: TObject);
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

procedure TFormSettings.SpinEditDelayTimeoutChange(Sender: TObject);
begin
  Settings.TimeoutComRead := SpinEditDelayTimeout.Value;
end;

procedure TFormSettings.FormShow(Sender: TObject);
begin
  SpinEditDelayTimeout.Value := Settings.TimeoutComRead
end;

procedure TFormSettings.CheckBoxPingPongStandardFrameChange(Sender: TObject);
begin
  Settings.PingPongStandardFrameTest := CheckBoxPingPongStandardFrame.Checked;
end;

end.

