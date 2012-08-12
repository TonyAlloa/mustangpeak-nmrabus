unit olcb_utilities;

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
  Classes, SysUtils, strutils, ExtCtrls;

const
  LF = #13+#10;
  CAN_BYTE_COUNT = 8;
  DEFAULT_TIMEOUT = 200;                  // 200ms of no activity on the UART signals the receoption is complete

type
  TByteArray = array[0..CAN_BYTE_COUNT-1] of Byte;
  PByteArray = ^TByteArray;

  TOpenLCBLayer = (ol_CAN, ol_OpenLCB);

  { TOpenLCBMessage }

  TOpenLCBMessageHelper = class
  private
    FDestinationAliasID: Word;
    FSourceAliasID: Word;
    FData: TByteArray;
    FDataCount: Integer;
    FLayer: TOpenLCBLayer;
    FMTI: DWord;
    procedure SetData(AValue: TByteArray);
    procedure SetLayer(AValue: TOpenLCBLayer);
  public
    property Layer: TOpenLCBLayer read FLayer write SetLayer;
    property MTI: DWord read FMTI write FMTI;
    property Data: TByteArray read FData write SetData;
    property DataCount: Integer read FDataCount write FDataCount;
    property SourceAliasID: Word read FSourceAliasID write FSourceAliasID;
    property DestinationAliasID: Word read FDestinationAliasID write FDestinationAliasID;

    constructor Create;
    destructor Destroy; override;
    procedure Decompose(MessageStr: AnsiString);
    function Encode: AnsiString;
    procedure Load(ALayer: TOpenLCBLayer; AMTI: DWord; ASourceAlias: Word; ADestinationAlias: Word; ADataCount: Integer; AData0, AData1, AData2, AData3, AData4, AData5, AData6, AData7: Byte);
  end;


implementation

{ TOpenLCBMessageHelper }

procedure TOpenLCBMessageHelper.SetData(AValue: TByteArray);
begin
  FData:=AValue;
end;

procedure TOpenLCBMessageHelper.SetLayer(AValue: TOpenLCBLayer);
begin
  if FLayer=AValue then Exit;
  FLayer:=AValue;
end;

constructor TOpenLCBMessageHelper.Create;
var
  i: Integer;
begin
  inherited Create;
  FLayer := ol_CAN;
  FMTI := 0;
  for i := 0 to CAN_BYTE_COUNT - 1 do
    FData[i] := 0;
  FDataCount := 0;
  FSourceAliasID := 0;
  FDestinationAliasID := 0;
end;

destructor TOpenLCBMessageHelper.Destroy;
begin
  inherited Destroy
end;

procedure TOpenLCBMessageHelper.Decompose(MessageStr: AnsiString);
var
  x, n, SemiColon, i: Integer;
  Head: PAnsiChar;
  ByteStr: AnsiString;
begin
  MessageStr := UpperCase(MessageStr);
  x := Pos('X', MessageStr);
  if x > 0 then
  begin
    n := PosEx('N', MessageStr, x);
    if n > 0 then
    begin
      MessageStr[n] := #0;
      Inc(n);
      SemiColon := PosEx(';', MessageStr, n);
      if SemiColon > 0 then
      begin
        Head := @MessageStr[x+1];

        MTI := StrToInt('$' + Head);
        SourceAliasID := MTI and $00000FFF;
        if MTI and $10000000 = $10000000 then
          Layer := ol_OpenLCB
        else
          Layer := ol_CAN;

        FDataCount := 0;
        i := n;
        while i < SemiColon do
        begin
          ByteStr := MessageStr[i] + MessageStr[i+1];
          Data[FDataCount] := StrToInt('$'+ByteStr);
          Inc(i, 2);
          Inc(FDataCount);
        end;
      end
    end;
  end;
end;

function TOpenLCBMessageHelper.Encode: AnsiString;
var
  i: Integer;
  FullMTI: DWord;
begin
  FullMTI := MTI or SourceAliasID;
  if Layer = ol_OpenLCB then
    FullMTI := FullMTI or $10000000;
  Result := ':X' + IntToHex(FullMTI, 8) + 'N';
  for i := 0 to DataCount - 1 do
     Result := Result + IntToHex(Data[i], 2);
  Result := Result  + ';'
end;

procedure TOpenLCBMessageHelper.Load(ALayer: TOpenLCBLayer; AMTI: DWord;
  ASourceAlias: Word; ADestinationAlias: Word; ADataCount: Integer; AData0,
  AData1, AData2, AData3, AData4, AData5, AData6, AData7: Byte);
begin
  Layer := ALayer;
  MTI := AMTI;
  DataCount := ADataCount;
  SourceAliasID := ASourceAlias;
  DestinationAliasID := ADestinationAlias;
  Data[0] := AData0;
  Data[1] := AData1;
  Data[2] := AData2;
  Data[3] := AData3;
  Data[4] := AData4;
  Data[5] := AData5;
  Data[6] := AData6;
  Data[7] := AData7;

end;


end.

