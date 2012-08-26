unit unitAbout;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, LCLIntf;

type

  { TFormAbout }

  TFormAbout = class(TForm)
    ImageOpenLCB: TImage;
    LabelTargetCPU: TLabel;
    LabelTargetOS: TLabel;
    LabelTargetOperatingSystem: TLabel;
    LabelCPU: TLabel;
    LabelBuildDate: TLabel;
    LabelBuild: TLabel;
    LabelIcon: TLabel;
    LabelNodeExplorer: TLabel;
    LabelMyName: TLabel;
    LabelWrittenIn: TLabel;
    StaticTextURLFreePascal: TStaticText;
    StaticTextURLIcons: TStaticText;
    StaticTextURLLazarus: TStaticText;
    procedure FormShow(Sender: TObject);
    procedure ImageOpenLCBClick(Sender: TObject);
    procedure ImageAboutMouseEnter(Sender: TObject);
    procedure LabelIconClick(Sender: TObject);
    procedure StaticTextURLFreePascalClick(Sender: TObject);
    procedure StaticTextURLFreePascalMouseEnter(Sender: TObject);
    procedure StaticTextURLFreePascalMouseLeave(Sender: TObject);
    procedure StaticTextURLIconsClick(Sender: TObject);
    procedure StaticTextURLIconsMouseEnter(Sender: TObject);
    procedure StaticTextURLIconsMouseLeave(Sender: TObject);
    procedure StaticTextURLLazarusClick(Sender: TObject);
    procedure StaticTextURLLazarusMouseEnter(Sender: TObject);
    procedure StaticTextURLLazarusMouseLeave(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  FormAbout: TFormAbout;

implementation

{$R *.lfm}

{ TFormAbout }

procedure TFormAbout.LabelIconClick(Sender: TObject);
begin

end;

procedure TFormAbout.ImageAboutMouseEnter(Sender: TObject);
begin

end;

procedure TFormAbout.ImageOpenLCBClick(Sender: TObject);
begin
  OpenURL('http://www.openlcb.org');
end;

procedure TFormAbout.FormShow(Sender: TObject);
begin
  LabelBuildDate.Caption := {$I %DATE%} + ': ' + {$I %TIME%};
  LabelTargetOS.Caption := {$I %FPCTARGETOS%};
  LabelTargetCPU.Caption := {$I %FPCTARGETCPU%};
end;

procedure TFormAbout.StaticTextURLFreePascalClick(Sender: TObject);
begin
  OpenURL('http://' + StaticTextURLFreePascal.Caption);
end;

procedure TFormAbout.StaticTextURLFreePascalMouseEnter(Sender: TObject);
begin
  StaticTextURLFreePascal.Font.Style := [fsUnderline];
end;

procedure TFormAbout.StaticTextURLFreePascalMouseLeave(Sender: TObject);
begin
  StaticTextURLFreePascal.Font.Style := [];
end;

procedure TFormAbout.StaticTextURLIconsClick(Sender: TObject);
begin
  OpenURL('http://' + StaticTextURLIcons.Caption);
end;

procedure TFormAbout.StaticTextURLIconsMouseEnter(Sender: TObject);
begin
  StaticTextURLIcons.Font.Style := [fsUnderline];
end;

procedure TFormAbout.StaticTextURLIconsMouseLeave(Sender: TObject);
begin
  StaticTextURLIcons.Font.Style := [];
end;


procedure TFormAbout.StaticTextURLLazarusClick(Sender: TObject);
begin
  OpenURL('http://' + StaticTextURLLazarus.Caption);
end;

procedure TFormAbout.StaticTextURLLazarusMouseEnter(Sender: TObject);
begin
  StaticTextURLLazarus.Font.Style := [fsUnderline];
end;

procedure TFormAbout.StaticTextURLLazarusMouseLeave(Sender: TObject);
begin
  StaticTextURLLazarus.Font.Style := [];
end;

end.

