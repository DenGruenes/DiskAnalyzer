unit DiskAnalyzer_Config;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  TScannerConfig = class
  private
    FExcludeFolders: TList<string>;
    FExcludeFileExtensions: TList<string>;
    FFollowSymlinks: Boolean;
    FMaxDepth: Integer;
    FMinFileSize: Int64;
    FIncludeHiddenFiles: Boolean;
    FIncludeSystemFiles: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure AddExcludeFolder(const AFolderName: string);
    procedure AddExcludeExtension(const AExtension: string);
    procedure ClearExclusions;
    
    function ShouldExcludeFolder(const AFolderPath: string): Boolean;
    function ShouldExcludeFile(const AFileName: string): Boolean;
    
    property ExcludeFolders: TList<string> read FExcludeFolders;
    property ExcludeFileExtensions: TList<string> read FExcludeFileExtensions;
    property FollowSymlinks: Boolean read FFollowSymlinks write FFollowSymlinks;
    property MaxDepth: Integer read FMaxDepth write FMaxDepth;
    property MinFileSize: Int64 read FMinFileSize write FMinFileSize;
    property IncludeHiddenFiles: Boolean read FIncludeHiddenFiles write FIncludeHiddenFiles;
    property IncludeSystemFiles: Boolean read FIncludeSystemFiles write FIncludeSystemFiles;
  end;

  // Vordefinierte Konfigurationen
  TConfigPresets = class
  public
    class function GetDefaultConfig: TScannerConfig;
    class function GetFastConfig: TScannerConfig;
    class function GetDetailedConfig: TScannerConfig;
  end;

implementation

uses
  Winapi.Windows;

constructor TScannerConfig.Create;
begin
  inherited;
  FExcludeFolders := TList<string>.Create;
  FExcludeFileExtensions := TList<string>.Create;
  FFollowSymlinks := False;
  FMaxDepth := 999;
  FMinFileSize := 0;
  FIncludeHiddenFiles := True;
  FIncludeSystemFiles := False;
  
  // Standard-Ausschlüsse
  AddExcludeFolder('$Recycle.Bin');
  AddExcludeFolder('System Volume Information');
  AddExcludeFolder('hiberfil.sys');
  AddExcludeFolder('pagefile.sys');
end;

destructor TScannerConfig.Destroy;
begin
  FExcludeFolders.Free;
  FExcludeFileExtensions.Free;
  inherited;
end;

procedure TScannerConfig.AddExcludeFolder(const AFolderName: string);
begin
  if FExcludeFolders.IndexOf(AFolderName) < 0 then
    FExcludeFolders.Add(AFolderName);
end;

procedure TScannerConfig.AddExcludeExtension(const AExtension: string);
begin
  var Ext := AExtension;
  if not Ext.StartsWith('.') then
    Ext := '.' + Ext;
  
  if FExcludeFileExtensions.IndexOf(Ext) < 0 then
    FExcludeFileExtensions.Add(Ext);
end;

procedure TScannerConfig.ClearExclusions;
begin
  FExcludeFolders.Clear;
  FExcludeFileExtensions.Clear;
end;

function TScannerConfig.ShouldExcludeFolder(const AFolderPath: string): Boolean;
var
  FolderName: string;
  ExcludedFolder: string;
begin
  Result := False;
  FolderName := ExtractFileName(ExcludeTrailingPathDelimiter(AFolderPath));
  
  for ExcludedFolder in FExcludeFolders do
  begin
    if SameText(FolderName, ExcludedFolder) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TScannerConfig.ShouldExcludeFile(const AFileName: string): Boolean;
var
  FileExt: string;
  ExcludedExt: string;
  Attr: Integer;
begin
  Result := False;
  
  // Dateiattribute prüfen
  Attr := FileGetAttr(AFileName);
  
  // Versteckte Dateien
  if ((Attr and faHidden) <> 0) and not FIncludeHiddenFiles then
  begin
    Result := True;
    Exit;
  end;
  
  // Systemdateien
  if ((Attr and faSysFile) <> 0) and not FIncludeSystemFiles then
  begin
    Result := True;
    Exit;
  end;
  
  // Dateiendung prüfen
  FileExt := ExtractFileExt(AFileName);
  for ExcludedExt in FExcludeFileExtensions do
  begin
    if SameText(FileExt, ExcludedExt) then
    begin
      Result := True;
      Exit;
    end;
  end;
  
  // Dateigröße prüfen
  if FileSize(AFileName) < FMinFileSize then
  begin
    Result := True;
    Exit;
  end;
end;

{ TConfigPresets }

class function TConfigPresets.GetDefaultConfig: TScannerConfig;
begin
  Result := TScannerConfig.Create;
  Result.MaxDepth := 999;
  Result.IncludeHiddenFiles := True;
  Result.IncludeSystemFiles := False;
end;

class function TConfigPresets.GetFastConfig: TScannerConfig;
begin
  Result := TScannerConfig.Create;
  Result.MaxDepth := 5;  // Begrenzte Tiefe für schnelleren Scan
  Result.IncludeHiddenFiles := False;
  Result.IncludeSystemFiles := False;
  Result.AddExcludeExtension('.tmp');
  Result.AddExcludeExtension('.log');
end;

class function TConfigPresets.GetDetailedConfig: TScannerConfig;
begin
  Result := TScannerConfig.Create;
  Result.MaxDepth := 999;
  Result.IncludeHiddenFiles := True;
  Result.IncludeSystemFiles := True;
  Result.FollowSymlinks := True;
  Result.MinFileSize := 0;
end;

end.
