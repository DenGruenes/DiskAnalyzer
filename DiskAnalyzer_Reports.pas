unit DiskAnalyzer_Reports;

interface

uses
  System.SysUtils, System.Classes, DiskAnalyzer_Models;

type
  TReportFormat = (rfCSV, rfJSON, rfHTML, rfText);
  
  TDiskReport = class
  private
    FRootNode: TDirectoryNode;
    FMaxItems: Integer;
    FMinSizePercentage: Double;
    
    function GenerateCSV: string;
    function GenerateJSON: string;
    function GenerateHTML: string;
    function GenerateText: string;
    
    procedure ExportNodeToCSV(ANode: TDirectoryNode; var AOutput: TStringList; ADepth: Integer = 0);
    procedure ExportNodeToJSON(ANode: TDirectoryNode; var AOutput: TStringList; ADepth: Integer = 0);
  public
    constructor Create(ARootNode: TDirectoryNode);
    
    procedure GenerateReport(const AFilename: string; AFormat: TReportFormat);
    function GetReportAsString(AFormat: TReportFormat): string;
    
    property MaxItems: Integer read FMaxItems write FMaxItems;
    property MinSizePercentage: Double read FMinSizePercentage write FMinSizePercentage;
  end;

implementation

constructor TDiskReport.Create(ARootNode: TDirectoryNode);
begin
  inherited Create;
  FRootNode := ARootNode;
  FMaxItems := 100;
  FMinSizePercentage := 1.0; // Nur Items über 1% Anteil
end;

procedure TDiskReport.GenerateReport(const AFilename: string; AFormat: TReportFormat);
var
  ReportContent: string;
begin
  ReportContent := GetReportAsString(AFormat);
  
  var FileStream := TStringStream.Create(ReportContent);
  try
    FileStream.SaveToFile(AFilename);
  finally
    FileStream.Free;
  end;
end;

function TDiskReport.GetReportAsString(AFormat: TReportFormat): string;
begin
  case AFormat of
    rfCSV:
      Result := GenerateCSV;
    rfJSON:
      Result := GenerateJSON;
    rfHTML:
      Result := GenerateHTML;
    rfText:
      Result := GenerateText;
  else
    Result := GenerateText;
  end;
end;

function TDiskReport.GenerateText: string;
var
  Output: TStringList;
  procedure ExportNodeToText(ANode: TDirectoryNode; ADepth: Integer);
  var
    Indent: string;
    Percentage: Double;
    SubNode: TDirectoryNode;
    Count: Integer;
  begin
    Indent := StringOfChar(' ', ADepth * 2);
    
    if FRootNode.TotalSize > 0 then
      Percentage := (ANode.TotalSize / FRootNode.TotalSize) * 100
    else
      Percentage := 0;
    
    if (Count < FMaxItems) and (Percentage >= FMinSizePercentage) then
    begin
      Output.Add(Format('%s%s: %s (%.2f%%) [%d Dateien]',
        [Indent, ANode.Name, 
         IntToStr(ANode.TotalSize),
         Percentage,
         ANode.FileCount]));
      
      Inc(Count);
      
      for SubNode in ANode.SubDirs do
        ExportNodeToText(SubNode, ADepth + 1);
    end;
  end;
  
begin
  Output := TStringList.Create;
  try
    Output.Add('═════════════════════════════════════════════════════════');
    Output.Add('DISK ANALYSIS REPORT');
    Output.Add('═════════════════════════════════════════════════════════');
    Output.Add('');
    Output.Add('Pfad: ' + FRootNode.FullPath);
    Output.Add('Gesamtgröße: ' + IntToStr(FRootNode.TotalSize) + ' Bytes');
    Output.Add('Dateianzahl: ' + IntToStr(FRootNode.FileCount));
    Output.Add('Scan-Datum: ' + DateTimeToStr(Now));
    Output.Add('');
    Output.Add('───────────────────────────────────────────────────────');
    Output.Add('');
    
    var Count := 0;
    ExportNodeToText(FRootNode, 0);
    
    Result := Output.Text;
  finally
    Output.Free;
  end;
end;

function TDiskReport.GenerateCSV: string;
begin
  var Output := TStringList.Create;
  try
    Output.Add('Pfad,Größe (Bytes),Dateien,Prozentanteil');
    ExportNodeToCSV(FRootNode, Output);
    Result := Output.Text;
  finally
    Output.Free;
  end;
end;

procedure TDiskReport.ExportNodeToCSV(ANode: TDirectoryNode; var AOutput: TStringList; ADepth: Integer = 0);
var
  Percentage: Double;
  SubNode: TDirectoryNode;
  EscapedPath: string;
begin
  if ADepth > 10 then Exit; // Depth-Limit
  
  EscapedPath := '"' + ANode.FullPath + '"';
  
  if FRootNode.TotalSize > 0 then
    Percentage := (ANode.TotalSize / FRootNode.TotalSize) * 100
  else
    Percentage := 0;
  
  if Percentage >= FMinSizePercentage then
  begin
    AOutput.Add(Format('%s,%d,%d,%.2f%%',
      [EscapedPath, ANode.TotalSize, ANode.FileCount, Percentage]));
    
    for SubNode in ANode.SubDirs do
      ExportNodeToCSV(SubNode, AOutput, ADepth + 1);
  end;
end;

function TDiskReport.GenerateJSON: string;
begin
  var Output := TStringList.Create;
  try
    Output.Add('{');
    Output.Add('  "report": {');
    Output.Add('    "path": "' + FRootNode.FullPath + '",');
    Output.Add('    "totalSize": ' + IntToStr(FRootNode.TotalSize) + ',');
    Output.Add('    "fileCount": ' + IntToStr(FRootNode.FileCount) + ',');
    Output.Add('    "scanDate": "' + DateTimeToStr(Now) + '",');
    Output.Add('    "directories": [');
    
    ExportNodeToJSON(FRootNode, Output);
    
    Output.Add('    ]');
    Output.Add('  }');
    Output.Add('}');
    
    Result := Output.Text;
  finally
    Output.Free;
  end;
end;

procedure TDiskReport.ExportNodeToJSON(ANode: TDirectoryNode; var AOutput: TStringList; ADepth: Integer = 0);
var
  Percentage: Double;
  SubNode: TDirectoryNode;
  IsFirst: Boolean;
  Count: Integer;
begin
  if ADepth > 10 then Exit;
  
  if FRootNode.TotalSize > 0 then
    Percentage := (ANode.TotalSize / FRootNode.TotalSize) * 100
  else
    Percentage := 0;
  
  Count := 0;
  IsFirst := True;
  
  for SubNode in ANode.SubDirs do
  begin
    if (Count >= FMaxItems) then Break;
    if (Percentage < FMinSizePercentage) then Continue;
    
    if not IsFirst then
      AOutput[AOutput.Count - 1] := AOutput[AOutput.Count - 1] + ','
    else
      IsFirst := False;
    
    AOutput.Add(Format('      {"name": "%s", "size": %d, "files": %d, "path": "%s"}',
      [ANode.Name, ANode.TotalSize, ANode.FileCount, ANode.FullPath]));
    
    Inc(Count);
  end;
end;

function TDiskReport.GenerateHTML: string;
var
  Output: TStringList;
  
  procedure ExportNodeToHTML(ANode: TDirectoryNode; ADepth: Integer);
  var
    Percentage: Double;
    SubNode: TDirectoryNode;
  begin
    if ADepth > 10 then Exit;
    
    if FRootNode.TotalSize > 0 then
      Percentage := (ANode.TotalSize / FRootNode.TotalSize) * 100
    else
      Percentage := 0;
    
    if Percentage >= FMinSizePercentage then
    begin
      Output.Add('<tr>');
      Output.Add(Format('<td>%s</td>', [ANode.Name]));
      Output.Add(Format('<td>%s</td>', [IntToStr(ANode.TotalSize)]));
      Output.Add(Format('<td>%d</td>', [ANode.FileCount]));
      Output.Add(Format('<td>%.2f%%</td>', [Percentage]));
      Output.Add('</tr>');
      
      for SubNode in ANode.SubDirs do
        ExportNodeToHTML(SubNode, ADepth + 1);
    end;
  end;
  
begin
  Output := TStringList.Create;
  try
    Output.Add('<!DOCTYPE html>');
    Output.Add('<html>');
    Output.Add('<head>');
    Output.Add('<meta charset="UTF-8">');
    Output.Add('<title>Disk Analysis Report</title>');
    Output.Add('<style>');
    Output.Add('body { font-family: Arial, sans-serif; }');
    Output.Add('table { border-collapse: collapse; width: 100%; }');
    Output.Add('th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }');
    Output.Add('th { background-color: #4CAF50; color: white; }');
    Output.Add('tr:nth-child(even) { background-color: #f2f2f2; }');
    Output.Add('</style>');
    Output.Add('</head>');
    Output.Add('<body>');
    Output.Add('<h1>Disk Analysis Report</h1>');
    Output.Add(Format('<p><strong>Path:</strong> %s</p>', [FRootNode.FullPath]));
    Output.Add(Format('<p><strong>Total Size:</strong> %s bytes</p>', [IntToStr(FRootNode.TotalSize)]));
    Output.Add(Format('<p><strong>Scan Date:</strong> %s</p>', [DateTimeToStr(Now)]));
    Output.Add('<table>');
    Output.Add('<tr><th>Name</th><th>Size (Bytes)</th><th>Files</th><th>Percentage</th></tr>');
    
    ExportNodeToHTML(FRootNode, 0);
    
    Output.Add('</table>');
    Output.Add('</body>');
    Output.Add('</html>');
    
    Result := Output.Text;
  finally
    Output.Free;
  end;
end;

end.
