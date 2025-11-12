unit DiskAnalyzer_Scanner;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Winapi.Windows, DiskAnalyzer_Models;

type
  TScanCompleteEvent = procedure(Sender: TObject; ANode: TDirectoryNode) of object;
  TScanProgressEvent = procedure(Sender: TObject; const APath: string; AFileCount: Integer) of object;
  
  TDiskScannerThread = class(TThread)
  private
    FRootPath: string;
    FRootNode: TDirectoryNode;
    FOnScanComplete: TScanCompleteEvent;
    FOnScanProgress: TScanProgressEvent;
    FOnError: TNotifyEvent;
    FErrorMessage: string;
    FTotalFilesScanned: Integer;
    FMaxDepth: Integer;
    FCurrentDepth: Integer;
    
    procedure DoScanProgress;
    procedure DoScanComplete;
    procedure DoError;
  protected
    procedure Execute; override;
  public
    constructor Create(const ARootPath: string);
    destructor Destroy; override;
    
    procedure ScanDirectory(ANode: TDirectoryNode; ADepth: Integer = 0);
    
    property RootNode: TDirectoryNode read FRootNode;
    property OnScanComplete: TScanCompleteEvent read FOnScanComplete write FOnScanComplete;
    property OnScanProgress: TScanProgressEvent read FOnScanProgress write FOnScanProgress;
    property OnError: TNotifyEvent read FOnError write FOnError;
    property ErrorMessage: string read FErrorMessage;
    property TotalFilesScanned: Integer read FTotalFilesScanned;
    property MaxDepth: Integer read FMaxDepth write FMaxDepth;
  end;

implementation

constructor TDiskScannerThread.Create(const ARootPath: string);
begin
  inherited Create(True); // Suspended = True
  FRootPath := IncludeTrailingPathDelimiter(ARootPath);
  FTotalFilesScanned := 0;
  FMaxDepth := 999; // Unbegrenzte Tiefe per default
  FCurrentDepth := 0;
  
  // Erstelle Root-Node
  FRootNode := TDirectoryNode.Create(ExtractFileName(ExcludeTrailingPathDelimiter(FRootPath)), FRootPath);
  FRootNode.IsScanned := False;
  
  FreeOnTerminate := False;
end;

destructor TDiskScannerThread.Destroy;
begin
  if Assigned(FRootNode) then
    FRootNode.Free;
  inherited;
end;

procedure TDiskScannerThread.Execute;
begin
  try
    if not DirectoryExists(FRootPath) then
    begin
      FErrorMessage := Format('Verzeichnis nicht gefunden: %s', [FRootPath]);
      Synchronize(DoError);
      Exit;
    end;
    
    FRootNode.IsScanned := True;
    FCurrentDepth := 0;
    ScanDirectory(FRootNode, 0);
    FRootNode.SortBySize;
    
    Synchronize(DoScanComplete);
  except
    on E: Exception do
    begin
      FErrorMessage := E.Message;
      Synchronize(DoError);
    end;
  end;
end;

procedure TDiskScannerThread.ScanDirectory(ANode: TDirectoryNode; ADepth: Integer = 0);
var
  SearchRec: TSearchRec;
  SubNode: TDirectoryNode;
  SubDirPath: string;
  FileSize: Int64;
begin
  if Terminated or (ADepth > FMaxDepth) then
    Exit;
    
  try
    if FindFirst(ANode.FullPath + '*.*', faAnyFile, SearchRec) = 0 then
    begin
      repeat
        if Terminated then
          Break;
          
        // Überspringe . und ..
        if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
          Continue;
        
        Inc(FTotalFilesScanned);
        
        // Progress-Update für UI
        if (FTotalFilesScanned mod 100) = 0 then
          Synchronize(DoScanProgress);
        
        if (SearchRec.Attr and faDirectory) = faDirectory then
        begin
          // Verzeichnis - rekursiv scannen
          SubDirPath := ANode.FullPath + SearchRec.Name;
          SubNode := TDirectoryNode.Create(SearchRec.Name, IncludeTrailingPathDelimiter(SubDirPath), ANode);
          ANode.AddSubDir(SubNode);
          
          ScanDirectory(SubNode, ADepth + 1);
        end
        else
        begin
          // Datei - Größe addieren
          FileSize := SearchRec.Size;
          ANode.TotalSize := ANode.TotalSize + FileSize;
          ANode.FileCount := ANode.FileCount + 1;
        end;
        
      until (FindNext(SearchRec) <> 0) or Terminated;
      System.SysUtils.FindClose(SearchRec);
    end;

    // Addiere Größen von Unterverzeichnissen
//    var SubNode: TDirectoryNode;
    for SubNode in ANode.SubDirs do
    begin
      ANode.TotalSize := ANode.TotalSize + SubNode.TotalSize;
      ANode.FileCount := ANode.FileCount + SubNode.FileCount;
    end;
    
  except
    on E: Exception do
    begin
      // Ignoriere Fehler bei Zugriff verweigert, etc.
      // Optional: Fehler loggen
    end;
  end;
end;

procedure TDiskScannerThread.DoScanProgress;
begin
  if Assigned(FOnScanProgress) then
    FOnScanProgress(Self, FRootPath, FTotalFilesScanned);
end;

procedure TDiskScannerThread.DoScanComplete;
begin
  if Assigned(FOnScanComplete) then
    FOnScanComplete(Self, FRootNode);
end;

procedure TDiskScannerThread.DoError;
begin
  if Assigned(FOnError) then
    FOnError(Self);
end;

end.
