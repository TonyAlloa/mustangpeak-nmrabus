unit nodeexplorer_settings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DOM, XMLRead, XMLWrite, FileUtil;

const
  SETTINGS_FILENAME = 'Settings.xml';

type
{ TSettings }

  TSettings = class
  private
    FBaudRate: DWord;
    FComPort: String;
    FProxyNodeAlias: Word;
    FProxyNodeID: Int64;
    FTargetNodeAlias: Word;
    FTargetNodeID: Int64;
    FXMLSettings: TXMLDocument;
  public
    property ProxyNodeAlias: Word read FProxyNodeAlias write FProxyNodeAlias;
    property ProxyNodeID: Int64 read FProxyNodeID write FProxyNodeID;
    property TargetNodeAlias: Word read FTargetNodeAlias write FTargetNodeAlias;
    property TargetNodeID: Int64 read FTargetNodeID write FTargetNodeID;
    property ComPort: String read FComPort write FComPort;
    property BaudRate: DWord read FBaudRate write FBaudRate;
    property XMLSettings: TXMLDocument read FXMLSettings write FXMLSettings;
    constructor Create;
    procedure ReadSettings;
    procedure WriteSettings;
  end;

var
  Settings: TSettings;

implementation

{ TSettings }

constructor TSettings.Create;
begin
  inherited Create;
  FProxyNodeAlias := $0AAA;
  FProxyNodeID := $010203040506;
  FBaudRate := 333333;
  FComPort := 'COM4';
  FXMLSettings := nil;
end;

procedure TSettings.ReadSettings;
var
  NodeSettings, NodeIDs, NodeCOM, NodeID, NodeAlias, NodeCOMPort, NodeBaudRate: TDOMNode;
begin
  if FileExistsUTF8(GetAppConfigDir(True)+SETTINGS_FILENAME) then
  begin
    ReadXMLFile(FXMLSettings, UTF8ToSys(GetAppConfigDir(True)+SETTINGS_FILENAME));
    NodeSettings := XMLSettings.FindNode('Settings');
    if Assigned(NodeSettings) then
    begin
      NodeIDs := NodeSettings.FindNode('Node');
      if Assigned(NodeIDs) then
      begin
        NodeID := NodeIDs.FindNode('ID');
        if Assigned(NodeID) then
          FProxyNodeID := StrToInt64(NodeID.FirstChild.NodeValue);
        NodeAlias := NodeIDs.FindNode('Alias');
        if Assigned(NodeAlias) then
          FProxyNodeAlias := StrToInt(NodeAlias.FirstChild.NodeValue);
      end;
      NodeCOM := NodeSettings.FindNode('COM');
      if Assigned(NodeCOM) then
      begin
        NodeCOMPort := NodeCOM.FindNode('Port');
        if Assigned(NodeCOMPort) then
          FComPort := NodeCOMPort.FirstChild.NodeValue;
        NodeBaudRate := NodeCOM.FindNode('Baud');
        if Assigned(NodeBaudRate) then
          FBaudRate := StrToInt(NodeBaudRate.FirstChild.NodeValue);
      end;
    end;
  end;
end;

procedure TSettings.WriteSettings;
begin
  WriteXMLFile(FXMLSettings, GetAppConfigDir(True)+SETTINGS_FILENAME);
end;

initialization
  Settings := TSettings.Create;

finalization
  FreeAndNil(Settings);

end.

