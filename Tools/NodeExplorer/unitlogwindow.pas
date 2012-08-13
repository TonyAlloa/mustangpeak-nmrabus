unit unitlogwindow;

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
  Classes, SysUtils, FileUtil, SynMemo, SynHighlighterXML, Forms, Controls,
  Graphics, Dialogs, StdCtrls;

type

  { TFormLog }

  TFormLog = class(TForm)
    ButtonClear: TButton;
    SynMemo: TSynMemo;
    SynXMLSyn: TSynXMLSyn;
    procedure FormActivate(Sender: TObject);
    procedure FormHide(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    CheckBoxLogWindow: TCheckBox;
  end;

var
  FormLog: TFormLog;

implementation

{$R *.lfm}

{ TFormLog }

procedure TFormLog.FormActivate(Sender: TObject);
begin

end;

procedure TFormLog.FormHide(Sender: TObject);
begin
  if Assigned(CheckBoxLogWindow) then
    CheckBoxLogWindow.Checked := False
end;

end.
