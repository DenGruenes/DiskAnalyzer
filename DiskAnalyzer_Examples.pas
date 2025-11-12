unit DiskAnalyzer_Examples;

{
  PRAKTISCHE CODEBEISPIELE FÜR ERWEITERUNGEN
  
  Dieses Modul zeigt concrete Implementierungen
  für häufige Erweiterungsszenarien.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DiskAnalyzer_Models, DiskAnalyzer_Scanner;

// ============================================================================
// BEISPIEL 1: Parallel Scanning mit TParallel
// ============================================================================

{
  Mit TParallel können mehrere Verzeichnisse gleichzeitig gescannt werden.
  Warnung: Funktioniert beste bei SSDs, nicht bei HDDs!
}

uses System.Threading;

type
  TParallelDiskScanner = class
  private
    FRootPath: string;
    FSubDirs: TList<string>;
  public
    constructor Create(const ARootPath: string);
    destructor Destroy; override;
    
    procedure ScanParallel(OnComplete: TProc);
  end;

implementation

constructor TParallelDiskScanner.Create(const ARootPath: string);
begin
  FRootPath := IncludeTrailingPathDelimiter(ARootPath);
  FSubDirs := TList<string>.Create;
  
  // Sammle sofort alle ersten-Ebenen Verzeichnisse
  var SR: TSearchRec;
  if FindFirst(FRootPath + '*.*', faDirectory, SR) = 0 then
  begin
    repeat
      if (SR.Attr and faDirectory <> 0) and
         (SR.Name <> '.') and (SR.Name <> '..') then
        FSubDirs.Add(IncludeTrailingPathDelimiter(FRootPath + SR.Name));
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;

destructor TParallelDiskScanner.Destroy;
begin
  FSubDirs.Free;
  inherited;
end;

procedure TParallelDiskScanner.ScanParallel(OnComplete: TProc);
begin
  TParallel.For(0, FSubDirs.Count - 1,
    procedure(I: Integer)
    var
      Scanner: TDiskScannerThread;
    begin
      Scanner := TDiskScannerThread.Create(FSubDirs[I]);
      try
        Scanner.WaitFor;
        // Process result
      finally
        Scanner.Free;
      end;
    end);
  
  if Assigned(OnComplete) then
    OnComplete;
end;

// ============================================================================
// BEISPIEL 2: Caching für schnellere Wiederholunscan
// ============================================================================

type
  TCachedScanResult = record
    Path: string;
    Size: Int64;
    FileCount: Integer;
    ScanTime: TDateTime;
  end;

  TScanCache = class
  private
    FCache: TDictionary<string, TCachedScanResult>;
    FCacheDuration: Integer; // Minuten
  public
    constructor Create(ACacheDurationMinutes: Integer = 60);
    destructor Destroy; override;
    
    procedure Add(const APath: string; ASize: Int64; AFileCount: Integer);
    function GetCached(const APath: string): TCachedScanResult;
    function IsCacheValid(const APath: string): Boolean;
    procedure Clear;
    
    property CacheDuration: Integer read FCacheDuration write FCacheDuration;
  end;

implementation

constructor TScanCache.Create(ACacheDurationMinutes: Integer = 60);
begin
  inherited Create;
  FCache := TDictionary<string, TCachedScanResult>.Create;
  FCacheDuration := ACacheDurationMinutes;
end;

destructor TScanCache.Destroy;
begin
  FCache.Free;
  inherited;
end;

procedure TScanCache.Add(const APath: string; ASize: Int64; AFileCount: Integer);
var
  Result: TCachedScanResult;
begin
  Result.Path := APath;
  Result.Size := ASize;
  Result.FileCount := AFileCount;
  Result.ScanTime := Now;
  
  if FCache.ContainsKey(APath) then
    FCache[APath] := Result
  else
    FCache.Add(APath, Result);
end;

function TScanCache.GetCached(const APath: string): TCachedScanResult;
begin
  if FCache.TryGetValue(APath, Result) then
    Exit;
  
  Result.Path := '';
  Result.Size := 0;
  Result.FileCount := 0;
end;

function TScanCache.IsCacheValid(const APath: string): Boolean;
var
  CachedResult: TCachedScanResult;
  TimeDiff: Integer;
begin
  Result := False;
  
  if not FCache.TryGetValue(APath, CachedResult) then
    Exit;
  
  TimeDiff := Trunc((Now - CachedResult.ScanTime) * 24 * 60); // Minuten
  Result := TimeDiff < FCacheDuration;
end;

procedure TScanCache.Clear;
begin
  FCache.Clear;
end;

// ============================================================================
// BEISPIEL 3: Real-time Monitoring mit Timer
// ============================================================================

type
  TDiskMonitor = class
  private
    FInterval: Integer;
    FLastSize: Int64;
    FChangeThreshold: Int64;
    FOnSizeChanged: TProc<Int64, Int64>; // Alte Size, Neue Size
    
    procedure CheckForChanges;
  public
    constructor Create(ACheckIntervalSeconds: Integer = 300);
    
    procedure StartMonitoring(const APath: string);
    procedure StopMonitoring;
    
    property OnSizeChanged: TProc<Int64, Int64> read FOnSizeChanged write FOnSizeChanged;
    property ChangeThreshold: Int64 read FChangeThreshold write FChangeThreshold;
  end;

// ============================================================================
// BEISPIEL 4: Event-basiertes Reporting
// ============================================================================

type
  TScanStatistics = record
    TotalSize: Int64;
    TotalFiles: Int64;
    AverageFileSize: Double;
    LargestDirectory: string;
    LargestSize: Int64;
    ScannedDirectories: Integer;
    ElapsedTime: TDateTime;
  end;

  TScanStatisticsCollector = class
  private
    FStats: TScanStatistics;
    FStartTime: TDateTime;
  public
    constructor Create;
    
    procedure CollectStats(ANode: TDirectoryNode);
    function GetStatistics: TScanStatistics;
    
    procedure PrintStatistics;
  end;

implementation

constructor TScanStatisticsCollector.Create;
begin
  inherited;
  FStartTime := Now;
  ZeroMemory(@FStats, SizeOf(TScanStatistics));
end;

procedure TScanStatisticsCollector.CollectStats(ANode: TDirectoryNode);
begin
  FStats.TotalSize := ANode.TotalSize;
  FStats.TotalFiles := ANode.FileCount;
  FStats.ScannedDirectories := ANode.SubDirs.Count;
  
  if FStats.TotalFiles > 0 then
    FStats.AverageFileSize := FStats.TotalSize / FStats.TotalFiles
  else
    FStats.AverageFileSize := 0;
  
  if ANode.TotalSize > FStats.LargestSize then
  begin
    FStats.LargestSize := ANode.TotalSize;
    FStats.LargestDirectory := ANode.FullPath;
  end;
  
  FStats.ElapsedTime := Now - FStartTime;
end;

function TScanStatisticsCollector.GetStatistics: TScanStatistics;
begin
  Result := FStats;
end;

procedure TScanStatisticsCollector.PrintStatistics;
begin
  WriteLn('═══════════════════════════════════════════');
  WriteLn('SCAN STATISTIKEN');
  WriteLn('═══════════════════════════════════════════');
  WriteLn(Format('Gesamtgröße: %d Bytes', [FStats.TotalSize]));
  WriteLn(Format('Dateien: %d', [FStats.TotalFiles]));
  WriteLn(Format('Verzeichnisse: %d', [FStats.ScannedDirectories]));
  WriteLn(Format('Durchschnittliche Dateigröße: %.2f Bytes', [FStats.AverageFileSize]));
  WriteLn(Format('Größtes Verzeichnis: %s (%d Bytes)', 
    [FStats.LargestDirectory, FStats.LargestSize]));
  WriteLn(Format('Scan-Zeit: %s', [TimeToStr(FStats.ElapsedTime)]));
  WriteLn('═══════════════════════════════════════════');
end;

// ============================================================================
// BEISPIEL 5: Duplikat-Datei-Finder
// ============================================================================

type
  TFileDuplicateFinder = class
  private
    FFileHashes: TDictionary<string, TList<string>>;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure ScanForDuplicates(ANode: TDirectoryNode);
    procedure FindDuplicatesByHash;
    procedure PrintDuplicates;
  end;

implementation

constructor TFileDuplicateFinder.Create;
begin
  inherited;
  FFileHashes := TDictionary<string, TList<string>>.Create;
end;

destructor TFileDuplicateFinder.Destroy;
begin
  FFileHashes.Free;
  inherited;
end;

procedure TFileDuplicateFinder.ScanForDuplicates(ANode: TDirectoryNode);
begin
  // Implementation mit MD5-Hash
  // Würde alle Dateien hashen und speichern
end;

procedure TFileDuplicateFinder.FindDuplicatesByHash;
begin
  // Finde Hashes mit mehr als 1 Datei
end;

procedure TFileDuplicateFinder.PrintDuplicates;
begin
  for var Hash in FFileHashes.Keys do
  begin
    if FFileHashes[Hash].Count > 1 then
    begin
      WriteLn(Format('Duplikat [%s]:', [Hash]));
      for var FileName in FFileHashes[Hash] do
        WriteLn('  ' + FileName);
    end;
  end;
end;

// ============================================================================
// BEISPIEL 6: Filter-System
// ============================================================================

type
  IDirectoryFilter = interface
    function ShouldInclude(const APath: string): Boolean;
  end;

  TSizeFilterImpl = class(TInterfacedObject, IDirectoryFilter)
  private
    FMinSize: Int64;
  public
    constructor Create(AMinSize: Int64);
    function ShouldInclude(const APath: string): Boolean;
  end;

implementation

constructor TSizeFilterImpl.Create(AMinSize: Int64);
begin
  inherited Create;
  FMinSize := AMinSize;
end;

function TSizeFilterImpl.ShouldInclude(const APath: string): Boolean;
begin
  Result := GetFileSize(PChar(APath)) >= FMinSize;
end;

end.
