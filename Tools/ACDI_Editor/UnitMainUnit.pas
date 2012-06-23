unit UnitMainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls;

const
  MAX_MFG_CHARS = 64;
  MAX_USER_NAME_CHARS = 20;
  MAX_USER_DESC_CHARS = 40;

type
  TForm1 = class(TForm)
    EditMfg: TEdit;
    EditName: TEdit;
    EditHWVersion: TEdit;
    EditSWVersion: TEdit;
    EditUserDefinedName: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    EditUserDefinedDesc: TEdit;
    RichEdit1: TRichEdit;
    ButtonGenerateCode: TButton;
    ButtonDecompile: TButton;
    LabelMfgInfoVer: TLabel;
    EditMfgInfoVer: TEdit;
    LabelUserInfoVersion: TLabel;
    EditUserInfoVer: TEdit;
    GroupBox1: TGroupBox;
    LabelMfgLen: TLabel;
    LabelNodeNameLen: TLabel;
    LabelHardwareLen: TLabel;
    LabelSoftwareLen: TLabel;
    LabelUserName: TLabel;
    LabelUserDesc: TLabel;
    Label13: TLabel;
    LabelTotalCount: TLabel;
    Label15: TLabel;
    LabelMaxDesc: TLabel;
    LabelUserMaxChar: TLabel;
    LabelMaxMfg: TLabel;
    Label19: TLabel;
    LabelMfgSubTotal: TLabel;
    Label21: TLabel;
    Bevel1: TBevel;
    Bevel2: TBevel;
    CheckBoxACDI: TCheckBox;
    procedure EditMfgChange(Sender: TObject);
    procedure EditNameChange(Sender: TObject);
    procedure EditHWVersionChange(Sender: TObject);
    procedure EditSWVersionChange(Sender: TObject);
    procedure EditUserDefinedNameChange(Sender: TObject);
    procedure EditUserDefinedDescChange(Sender: TObject);
    procedure ButtonGenerateCodeClick(Sender: TObject);
    procedure ButtonDecompileClick(Sender: TObject);
    procedure EditMfgInfoVerKeyPress(Sender: TObject; var Key: Char);
    procedure EditMfgInfoVerExit(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function ACDILen: Integer;
    function PackString(Str: string; EndComma, IsVersion: Boolean): string;
    function DecompileString(Str: string): string;
    function DecompileVersionString(Str: string): string;
    procedure UpdateUI;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.EditMfgChange(Sender: TObject);
begin
  LabelMfgLen.Caption := IntToStr(Length(EditMfg.Text)+1);
  LabelTotalCount.Caption := IntToStr(ACDILen);
  UpdateUI
end;

procedure TForm1.EditNameChange(Sender: TObject);
begin
  LabelNodeNameLen.Caption := IntToStr(Length(EditName.Text)+1);
  LabelTotalCount.Caption := IntToStr(ACDILen);
  UpdateUI
end;

procedure TForm1.EditHWVersionChange(Sender: TObject);
begin
  LabelHardwareLen.Caption := IntToStr(Length(EditHWVersion.Text)+1);
  LabelTotalCount.Caption := IntToStr(ACDILen);
  UpdateUI
end;

procedure TForm1.EditSWVersionChange(Sender: TObject);
begin
  LabelSoftwareLen.Caption := IntToStr(Length(EditSWVersion.Text)+1);
  LabelTotalCount.Caption := IntToStr(ACDILen);
  UpdateUI
end;

procedure TForm1.EditUserDefinedNameChange(Sender: TObject);
begin
  LabelUserName.Caption := IntToStr(Length(EditUserDefinedName.Text)+1);
  LabelTotalCount.Caption := IntToStr(ACDILen);
  UpdateUI
end;

procedure TForm1.EditUserDefinedDescChange(Sender: TObject);
begin
  LabelUserDesc.Caption := IntToStr(Length(EditUserDefinedDesc.Text));
  LabelTotalCount.Caption := IntToStr(ACDILen);
  UpdateUI
end;

procedure TForm1.ButtonGenerateCodeClick(Sender: TObject);
var
  s1: string;
begin
  RichEdit1.Lines.BeginUpdate;
  try
    s1 := '';
    RichEdit1.Lines.Clear;
    s1 := '';
    s1 := 'const';
    RichEdit1.Lines.Add(s1);
    if CheckBoxACDI.Checked then
    begin
      RichEdit1.Lines.Add('  MAX_VNODE_ACDI_ARRAY = ' + IntToStr(ACDILen)+';');
      s1 := '  TACDI_VNODE_STRINGS: array[0..MAX_VNODE_ACDI_ARRAY - 1] of byte = (';
    end else
    begin
       RichEdit1.Lines.Add('  MAX_ACDI_ARRAY = ' + IntToStr(ACDILen)+';');
      s1 := '  TACDI_NODE_STRINGS: array[0..MAX_ACDI_ARRAY - 1] of byte = (';
    end;
    RichEdit1.Lines.Add(s1);
    RichEdit1.Lines.Add(PackString(EditMfgInfoVer.Text, True, True));
    RichEdit1.Lines.Add(PackString(EditMfg.Text, True, False));
    RichEdit1.Lines.Add(PackString(EditName.Text, True, False));
    RichEdit1.Lines.Add(PackString(EditHWVersion.Text, True, False));
    RichEdit1.Lines.Add(PackString(EditSWVersion.Text, True, False));
    RichEdit1.Lines.Add(PackString(EditUserInfoVer.Text, True, True));
    RichEdit1.Lines.Add(PackString(EditUserDefinedName.Text, True, False));
    RichEdit1.Lines.Add(PackString(EditUserDefinedDesc.Text, False, False));
    s1 := '    );';
    RichEdit1.Lines.Add(s1)
  finally
    RichEdit1.Lines.EndUpdate
  end;
end;

function TForm1.ACDILen: Integer;
  begin
  Result := Length(EditMfg.Text) + Length(EditName.Text) + Length(EditHWVersion.Text) +
              Length(EditSWVersion.Text) + Length(EditUserDefinedName.Text) + Length(EditUserDefinedDesc.Text) + 8 // For the #0 and Version IDs

end;

function TForm1.PackString(Str: string; EndComma, IsVersion: Boolean): string;
var
  i: Integer;
begin
  Result := '';
  Str := Trim(Str);
  for i := 1 to Length(Str) do
    Result := Result + IntToStr( Ord(Str[i])) + ',';
  if IsVersion then
  begin
    Result := '      '+Result + '  // Version = ' + Str
  end else
  begin
    if EndComma then
      Result := '      '+Result + IntToStr( Ord(#0)) + ',  // ' + Str
    else
      Result := '      '+Result + IntToStr( Ord(#0))+'  // ' + Str
  end
end;

procedure TForm1.ButtonDecompileClick(Sender: TObject);
var
  Index: Integer;
begin
  if Pos('const', LowerCase(RichEdit1.Lines[0])) = 0 then
    Index := 2
  else
    Index := 3;
  EditMfgInfoVer.Text := DecompileVersionString(RichEdit1.Lines[Index]);
  Inc(Index);
  EditMfg.Text := DecompileString(RichEdit1.Lines[Index]);
  Inc(Index);
  EditName.Text := DecompileString(RichEdit1.Lines[Index]);
  Inc(Index);
  EditHWVersion.Text := DecompileString(RichEdit1.Lines[Index]);
  Inc(Index);
  EditSWVersion.Text := DecompileString(RichEdit1.Lines[Index]);
  Inc(Index);
  EditUserInfoVer.Text := DecompileVersionString(RichEdit1.Lines[Index]);
  Inc(Index);
  EditUserDefinedName.Text := DecompileString(RichEdit1.Lines[Index]);
  Inc(Index);
  EditUserDefinedDesc.Text := DecompileString(RichEdit1.Lines[Index]);
end;

function TForm1.DecompileVersionString(Str: string): string;
var
  i: Integer;
  Temp: string;
begin
  Str := Trim(Str);
  Result := '';
  Temp := '';
  i := 1;
  if Str <> '' then
  begin
    while i < Length(Str) do
    begin
      if Str[i] = ',' then
      begin
        Result := Result + Char( StrToInt(Temp));
        Temp := '';
      end else
      begin
        if (Str[i] >= '0') and (Str[i] <= '9') then
          Temp := Temp + Str[i];
      end;
      Inc(i)
    end;
  end
end;

function TForm1.DecompileString(Str: string): string;
var
  i: Integer;
  Temp: string;
begin
  Str := Trim(Str);
  Result := '';
  Temp := '';
  i := 1;
  if Str <> '' then
  begin
    while (Str[i] <> #0) and (i < Length(Str)) do
    begin
      if Str[i] = ',' then
      begin
        Result := Result + Char( StrToInt(Temp));
        Temp := '';
      end else
      begin
        if (Str[i] >= '0') and (Str[i] <= '9') then
          Temp := Temp + Str[i];
      end;
      Inc(i)
    end;
  end
end;

procedure TForm1.EditMfgInfoVerKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key < '0') and (Key > '9') then
  begin
    Beep;
    Key := #0;
  end;
end;

procedure TForm1.EditMfgInfoVerExit(Sender: TObject);
begin
  try
    if StrToInt(EditMfgInfoVer.Text) > 255 then
      EditMfgInfoVer.SelectAll;
  except
  end;
end;

procedure TForm1.UpdateUI;
begin
  LabelMfgSubTotal.Caption := IntToStr(Length(EditMfg.Text)+1+Length(EditName.Text)+1+Length(EditHWVersion.Text)+1+Length(EditSWVersion.Text)+1);
  if (StrToInt(LabelMfgSubTotal.Caption) > MAX_MFG_CHARS) then
  begin
    LabelMaxMfg.Font.Color := clRed;
    LabelMaxMfg.Font.Style := [fsBold];
  end else
  begin
    LabelMaxMfg.Font.Color := clWindowText;
    LabelMaxMfg.Font.Style := []
  end;

  if (StrToInt(LabelUserName.Caption) > MAX_USER_NAME_CHARS) then
  begin
    LabelUserMaxChar.Font.Color := clRed;
    LabelUserMaxChar.Font.Style := [fsBold];
  end else
  begin
    LabelUserMaxChar.Font.Color := clWindowText;
    LabelUserMaxChar.Font.Style := []
  end;

  if (StrToInt(LabelUserDesc.Caption) > MAX_USER_DESC_CHARS) then
  begin
    LabelMaxDesc.Font.Color := clRed;
    LabelMaxDesc.Font.Style := [fsBold];
  end else
  begin
    LabelMaxDesc.Font.Color := clWindowText;
    LabelMaxDesc.Font.Style := []
  end;
end;

end.
