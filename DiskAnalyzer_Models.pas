unit DiskAnalyzer_Models;

interface

uses
  System.Generics.Collections, System.Generics.Defaults, System.SysUtils, Winapi.Windows;

type
  TScanStatus = (ssPending, ssScanning, ssWaiting, ssComplete, ssFailed);

  TFileInfo = record
    Name: string;
    Size: Int64;
    IsDirectory: Boolean;
    FullPath: string;
    FileCount: Integer;
    procedure Clear;
  end;

  TDirectoryNode = class
  private
    FName: string;
    FFullPath: string;
    FTotalSize: Int64;
    FFileCount: Integer;
    FSubDirs: TList<TDirectoryNode>;
    FIsScanned: Boolean;
    FParent: TDirectoryNode;
    FDirectSize: Int64;
    FPendingChildren: Integer;
    FEnumerationFinished: Boolean;
    FStatus: TScanStatus;
    FSync: TObject;
    FCompletionNotified: Boolean;
    function GetTotalSize: Int64;
    procedure SetTotalSize(const Value: Int64);
    function GetFileCount: Integer;
    procedure SetFileCount(const Value: Integer);
    function GetStatus: TScanStatus;
    procedure SetStatus(const Value: TScanStatus);
    function GetPendingChildren: Integer;
  public
    constructor Create(const AName, AFullPath: string; AParent: TDirectoryNode = nil);
    destructor Destroy; override;

    procedure AddSubDir(ANode: TDirectoryNode);
    procedure SortBySize;
    procedure ResetForScan;
    procedure RegisterPendingChild;
    procedure UpdateDirectTotals(const ASize: Int64; const AFiles: Integer);
    procedure MarkScanning;
    function ChildFinished(AChild: TDirectoryNode): Boolean;
    function MarkEnumerated: Boolean;
    procedure MarkFailed;
    function CheckAndFlagCompleted: Boolean;

    property Name: string read FName;
    property FullPath: string read FFullPath;
    property TotalSize: Int64 read GetTotalSize write SetTotalSize;
    property FileCount: Integer read GetFileCount write SetFileCount;
    property SubDirs: TList<TDirectoryNode> read FSubDirs;
    property IsScanned: Boolean read FIsScanned write FIsScanned;
    property Parent: TDirectoryNode read FParent;
    property Status: TScanStatus read GetStatus write SetStatus;
    property PendingChildren: Integer read GetPendingChildren;
    property DirectSize: Int64 read FDirectSize;
  end;

implementation

procedure TFileInfo.Clear;
begin
  Name := '';
  Size := 0;
  IsDirectory := False;
  FullPath := '';
  FileCount := 0;
end;

constructor TDirectoryNode.Create(const AName, AFullPath: string; AParent: TDirectoryNode = nil);
begin
  inherited Create;
  FName := AName;
  FFullPath := AFullPath;
  FParent := AParent;
  FTotalSize := 0;
  FFileCount := 0;
  FIsScanned := False;
  FSubDirs := TList<TDirectoryNode>.Create;
  FDirectSize := 0;
  FPendingChildren := 0;
  FEnumerationFinished := False;
  FStatus := ssPending;
  FSync := TObject.Create;
end;

destructor TDirectoryNode.Destroy;
var
  Node: TDirectoryNode;
begin
  for Node in FSubDirs do
    Node.Free;
  FSubDirs.Free;
  FSync.Free;
  inherited;
end;

procedure TDirectoryNode.AddSubDir(ANode: TDirectoryNode);
begin
  FSubDirs.Add(ANode);
end;

procedure TDirectoryNode.SortBySize;
var
  Node: TDirectoryNode;
begin
  // Sortiere Unterverzeichnisse nach Größe (absteigend)
  FSubDirs.Sort(
    TComparer<TDirectoryNode>.Construct(
      function(const L, R: TDirectoryNode): Integer
      begin
        if L.TotalSize > R.TotalSize then
          Result := -1
        else if L.TotalSize < R.TotalSize then
          Result := 1
        else
          Result := 0;
      end
    )
  );
  
  // Rekursiv für alle Unterkinder sortieren
  for Node in FSubDirs do
    Node.SortBySize;
end;

procedure TDirectoryNode.ResetForScan;
begin
  TMonitor.Enter(FSync);
  try
    FDirectSize := 0;
    FTotalSize := 0;
    FFileCount := 0;
    FPendingChildren := 0;
    FEnumerationFinished := False;
    FStatus := ssPending;
    FCompletionNotified := False;
  finally
    TMonitor.Exit(FSync);
  end;
end;

procedure TDirectoryNode.RegisterPendingChild;
begin
  TMonitor.Enter(FSync);
  try
    Inc(FPendingChildren);
    if FStatus = ssComplete then
      FStatus := ssWaiting;
  finally
    TMonitor.Exit(FSync);
  end;
end;

procedure TDirectoryNode.UpdateDirectTotals(const ASize: Int64; const AFiles: Integer);
begin
  TMonitor.Enter(FSync);
  try
    FDirectSize := ASize;
    FFileCount := AFiles;
    FTotalSize := FDirectSize;
  finally
    TMonitor.Exit(FSync);
  end;
end;

function TDirectoryNode.ChildFinished(AChild: TDirectoryNode): Boolean;
begin
  TMonitor.Enter(FSync);
  try
    if FPendingChildren > 0 then
      Dec(FPendingChildren);
    Inc(FTotalSize, AChild.TotalSize);
    Inc(FFileCount, AChild.FileCount);
    Result := FEnumerationFinished and (FPendingChildren = 0) and (FStatus <> ssFailed);
    if Result then
      FStatus := ssComplete
    else if FStatus = ssScanning then
      FStatus := ssWaiting;
  finally
    TMonitor.Exit(FSync);
  end;
end;

function TDirectoryNode.MarkEnumerated: Boolean;
begin
  TMonitor.Enter(FSync);
  try
    FEnumerationFinished := True;
    Result := (FPendingChildren = 0) and (FStatus <> ssFailed);
    if Result then
      FStatus := ssComplete
    else if FStatus = ssScanning then
      FStatus := ssWaiting;
  finally
    TMonitor.Exit(FSync);
  end;
end;

procedure TDirectoryNode.MarkFailed;
begin
  TMonitor.Enter(FSync);
  try
    FStatus := ssFailed;
    FCompletionNotified := True;
  finally
    TMonitor.Exit(FSync);
  end;
end;

procedure TDirectoryNode.MarkScanning;
begin
  TMonitor.Enter(FSync);
  try
    if FStatus in [ssPending, ssWaiting] then
      FStatus := ssScanning;
  finally
    TMonitor.Exit(FSync);
  end;
end;

function TDirectoryNode.GetTotalSize: Int64;
begin
  TMonitor.Enter(FSync);
  try
    Result := FTotalSize;
  finally
    TMonitor.Exit(FSync);
  end;
end;

procedure TDirectoryNode.SetTotalSize(const Value: Int64);
begin
  TMonitor.Enter(FSync);
  try
    FTotalSize := Value;
  finally
    TMonitor.Exit(FSync);
  end;
end;

function TDirectoryNode.GetFileCount: Integer;
begin
  TMonitor.Enter(FSync);
  try
    Result := FFileCount;
  finally
    TMonitor.Exit(FSync);
  end;
end;

procedure TDirectoryNode.SetFileCount(const Value: Integer);
begin
  TMonitor.Enter(FSync);
  try
    FFileCount := Value;
  finally
    TMonitor.Exit(FSync);
  end;
end;

function TDirectoryNode.GetStatus: TScanStatus;
begin
  TMonitor.Enter(FSync);
  try
    Result := FStatus;
  finally
    TMonitor.Exit(FSync);
  end;
end;

procedure TDirectoryNode.SetStatus(const Value: TScanStatus);
begin
  TMonitor.Enter(FSync);
  try
    FStatus := Value;
  finally
    TMonitor.Exit(FSync);
  end;
end;

function TDirectoryNode.GetPendingChildren: Integer;
begin
  TMonitor.Enter(FSync);
  try
    Result := FPendingChildren;
  finally
    TMonitor.Exit(FSync);
  end;
end;

function TDirectoryNode.CheckAndFlagCompleted: Boolean;
begin
  TMonitor.Enter(FSync);
  try
    Result := (FStatus = ssComplete) and not FCompletionNotified;
    if Result then
      FCompletionNotified := True;
  finally
    TMonitor.Exit(FSync);
  end;
end;

end.
