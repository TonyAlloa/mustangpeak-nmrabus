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
  Graphics, Dialogs, StdCtrls, RackCtls, SynEditMarkupSpecialLine;

type

  { TFormLog }

  TFormLog = class(TForm)
    ButtonClear: TButton;
    CheckBoxShowGutter: TCheckBox;
    LabelReceiving: TLabel;
    LabelSending: TLabel;
    LEDButtonSending: TLEDButton;
    LEDButtonReceiving: TLEDButton;
    SynMemo: TSynMemo;
    SynXMLSyn: TSynXMLSyn;
    procedure FormActivate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure SynMemoSpecialLineColors(Sender: TObject; Line: integer;
      var Special: boolean; var FG, BG: TColor);
  private
    { private declarations }
  public
    { public declarations }
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

end;

procedure TFormLog.SynMemoSpecialLineColors(Sender: TObject; Line: integer;
  var Special: boolean; var FG, BG: TColor);
begin
  if Pos(':X', SynMemo.Lines[Line-1]) > 0 then
  begin
    Special := True;
    FG := clGreen;
  //  BG := clLtGray;
  end;
end;

end.

