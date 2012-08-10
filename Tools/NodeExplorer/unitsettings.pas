unit unitsettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Spin,
  StdCtrls;

type

  { TFormSettings }

  TFormSettings = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    SpinEditDelayTimeout: TSpinEdit;
    SpinEditPortTimeout: TSpinEdit;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  FormSettings: TFormSettings;

implementation

{$R *.lfm}

end.

