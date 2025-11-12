unit DiskAnalyzer_Scanner;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.SyncObjs,
  Winapi.Windows, DiskAnalyzer_Models;

type
  TScanCompleteEvent = procedure(Sender: TObject; ANode: TDirectoryNode) of object;
  TScanProgressEvent = procedure(Sender: TObject; const APath: string; AFileCount: Integer) of object;
  TScanDirectoryAddedEvent = procedure(Sender: TObject; ANode: TDirectoryNode; AParentNode: TDirectoryNode) of object;
  TDirectoryStatusEvent = procedure(Sender: TObject; ANode: TDirectoryNode) of object;
  TScanProgressSummaryEvent = procedure(Sender: TObject; Completed, Total: Integer) of object;

  TDiskScannerThread = class;

  TDirectoryScanWorker = class(TThread)
  private
    FOwner: TDiskScannerThread;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TDiskScannerThread);
  end;

  TDiskScannerThread = class(TThread)
  private
    FRootPath: string;
    FRootNode: TDirectoryNode;
    FOnScanComplete: TScanCompleteEvent;
    FOnScanProgress: TScanProgressEvent;
    FOnError: TNotifyEvent;
    FOnDirectoryAdded: TScanDirectoryAddedEvent;
    FOnDirectoryStatus: TDirectoryStatusEvent;
    FOnDirectoryTotals: TDirectoryStatusEvent;
    FOnProgressSummary: TScanProgressSummaryEvent;
    FErrorMessage: string;
    FTotalFilesScanned: Integer;
    FProgressCounter: Integer;
    FQueue: TQueue<TDirectoryNode>;
    FQueueLock: TObject;
    FQueueEvent: TEvent;
    FWorkers: TObjectList<TThread>;
    FWorkerCount: Integer;
    FActiveWorkers: Integer;
    FDirectoriesTotal: Integer;
    FDirectoriesCompleted: Integer;
    FStopRequested: Boolean;

    procedure InitializeInfrastructure;
    procedure FinalizeInfrastructure;
    procedure EnqueueDirectory(ANode: TDirectoryNode);
    function TryAcquireDirectory(out ANode: TDirectoryNode): Boolean;
    procedure ProcessDirectory(ANode: TDirectoryNode);
    procedure EnumerateDirectory(ANode: TDirectoryNode);
    procedure NotifyDirectoryAddedSync(ANode, AParent: TDirectoryNode);
    procedure NotifyDirectoryStatusSync(ANode: TDirectoryNode);
    procedure NotifyDirectoryTotalsSync(ANode: TDirectoryNode);
    procedure NotifyProgressSummarySync;
    procedure NotifyScanProgressSync;
    procedure HandleCompletion(ANode: TDirectoryNode);
    procedure IncrementActiveWorkers;
    procedure DecrementActiveWorkers;
    function QueueCount: Integer;
    function AllWorkCompleted: Boolean;
    procedure StartWorkers;
    procedure StopWorkers;
  protected
    procedure Execute; override;
  public
    constructor Create(const ARootPath: string);
    destructor Destroy; override;

    function DetachRootNode: TDirectoryNode;

    property RootNode: TDirectoryNode read FRootNode;
    property OnScanComplete: TScanCompleteEvent read FOnScanComplete write FOnScanComplete;
    property OnScanProgress: TScanProgressEvent read FOnScanProgress write FOnScanProgress;
    property OnError: TNotifyEvent read FOnError write FOnError;
    property OnDirectoryAdded: TScanDirectoryAddedEvent read FOnDirectoryAdded write FOnDirectoryAdded;
    property OnDirectoryStatus: TDirectoryStatusEvent read FOnDirectoryStatus write FOnDirectoryStatus;
    property OnDirectoryTotals: TDirectoryStatusEvent read FOnDirectoryTotals write FOnDirectoryTotals;
    property OnProgressSummary: TScanProgressSummaryEvent read FOnProgressSummary write FOnProgressSummary;
    property ErrorMessage: string read FErrorMessage;
    property TotalFilesScanned: Integer read FTotalFilesScanned;
  end;

implementation

{ TDirectoryScanWorker }

constructor TDirectoryScanWorker.Create(AOwner: TDiskScannerThread);
begin
  inherited Create(False);
  FOwner := AOwner;
  FreeOnTerminate := False;
end;

procedure TDirectoryScanWorker.Execute;
var
  Node: TDirectoryNode;
begin
  inherited;
  while not Terminated do
  begin
    if not FOwner.TryAcquireDirectory(Node) then
    begin
      if Terminated or FOwner.Terminated or FOwner.AllWorkCompleted then
        Break;
      Sleep(25);
      Continue;
    end;

    if Node = nil then
      Break;

    FOwner.ProcessDirectory(Node);
  end;
end;

{ TDiskScannerThread }

constructor TDiskScannerThread.Create(const ARootPath: string);
begin
  inherited Create(True);
  FRootPath := IncludeTrailingPathDelimiter(ARootPath);
  FWorkerCount := 10;
  FProgressCounter := 0;
  InitializeInfrastructure;

  FRootNode := TDirectoryNode.Create(ExtractFileName(ExcludeTrailingPathDelimiter(FRootPath)), FRootPath);
  FRootNode.ResetForScan;
  FreeOnTerminate := False;
end;

destructor TDiskScannerThread.Destroy;
begin
  StopWorkers;
  FinalizeInfrastructure;
  if Assigned(FRootNode) then
    FRootNode.Free;
  inherited;
end;

procedure TDiskScannerThread.InitializeInfrastructure;
begin
  FQueueLock := TObject.Create;
  FQueue := TQueue<TDirectoryNode>.Create;
  FQueueEvent := TEvent.Create(nil, False, False, '');
  FWorkers := TObjectList<TThread>.Create(True);
  FActiveWorkers := 0;
  FDirectoriesTotal := 0;
  FDirectoriesCompleted := 0;
  FStopRequested := False;
end;

procedure TDiskScannerThread.FinalizeInfrastructure;
begin
  FWorkers.Free;
  FQueueEvent.Free;
  FQueue.Free;
  FQueueLock.Free;
end;

function TDiskScannerThread.DetachRootNode: TDirectoryNode;
begin
  Result := FRootNode;
  FRootNode := nil;
end;

procedure TDiskScannerThread.EnqueueDirectory(ANode: TDirectoryNode);
begin
  if Terminated or FStopRequested then
    Exit;

  TMonitor.Enter(FQueueLock);
  try
    FQueue.Enqueue(ANode);
    FQueueEvent.SetEvent;
  finally
    TMonitor.Exit(FQueueLock);
  end;
end;

function TDiskScannerThread.QueueCount: Integer;
begin
  TMonitor.Enter(FQueueLock);
  try
    Result := FQueue.Count;
  finally
    TMonitor.Exit(FQueueLock);
  end;
end;

function TDiskScannerThread.TryAcquireDirectory(out ANode: TDirectoryNode): Boolean;
var
  WaitResult: TWaitResult;
begin
  Result := False;
  ANode := nil;

  while not Terminated do
  begin
    if AllWorkCompleted then
      Exit(False);

    WaitResult := FQueueEvent.WaitFor(100);
    if WaitResult = wrSignaled then
    begin
      TMonitor.Enter(FQueueLock);
      try
        if FQueue.Count > 0 then
        begin
          ANode := FQueue.Dequeue;
          if FQueue.Count = 0 then
            FQueueEvent.ResetEvent
          else
            FQueueEvent.SetEvent;
          Exit(True);
        end
        else
          FQueueEvent.ResetEvent;
      finally
        TMonitor.Exit(FQueueLock);
      end;
    end
    else if WaitResult = wrError then
      Exit(False)
    else if Terminated or FStopRequested then
      Exit(False);
  end;
end;

procedure TDiskScannerThread.IncrementActiveWorkers;
begin
  TInterlocked.Increment(FActiveWorkers);
end;

procedure TDiskScannerThread.DecrementActiveWorkers;
begin
  TInterlocked.Decrement(FActiveWorkers);
end;

function TDiskScannerThread.AllWorkCompleted: Boolean;
begin
  Result := (TInterlocked.CompareExchange(FDirectoriesCompleted, 0, 0) >=
    TInterlocked.CompareExchange(FDirectoriesTotal, 0, 0)) and (QueueCount = 0) and
    (TInterlocked.CompareExchange(FActiveWorkers, 0, 0) = 0);
end;

procedure TDiskScannerThread.NotifyDirectoryAddedSync(ANode, AParent: TDirectoryNode);
begin
  if Assigned(FOnDirectoryAdded) then
    FOnDirectoryAdded(Self, ANode, AParent);
end;

procedure TDiskScannerThread.NotifyDirectoryStatusSync(ANode: TDirectoryNode);
begin
  if Assigned(FOnDirectoryStatus) then
    FOnDirectoryStatus(Self, ANode);
end;

procedure TDiskScannerThread.NotifyDirectoryTotalsSync(ANode: TDirectoryNode);
begin
  if Assigned(FOnDirectoryTotals) then
    FOnDirectoryTotals(Self, ANode);
end;

procedure TDiskScannerThread.NotifyProgressSummarySync;
begin
  if Assigned(FOnProgressSummary) then
    FOnProgressSummary(Self, TInterlocked.CompareExchange(FDirectoriesCompleted, 0, 0),
      TInterlocked.CompareExchange(FDirectoriesTotal, 0, 0));
end;

procedure TDiskScannerThread.NotifyScanProgressSync;
begin
  if Assigned(FOnScanProgress) then
    FOnScanProgress(Self, FRootPath, TInterlocked.CompareExchange(FTotalFilesScanned, 0, 0));
end;

procedure TDiskScannerThread.ProcessDirectory(ANode: TDirectoryNode);
var
  Completed: Boolean;
begin
  if Terminated or FStopRequested then
    Exit;

  IncrementActiveWorkers;
  try
    ANode.MarkScanning;
    Synchronize(
      procedure
      begin
        NotifyDirectoryStatusSync(ANode);
      end);

    EnumerateDirectory(ANode);

    Synchronize(
      procedure
      begin
        NotifyDirectoryTotalsSync(ANode);
      end);

    Completed := ANode.MarkEnumerated;
    Synchronize(
      procedure
      begin
        NotifyDirectoryStatusSync(ANode);
      end);

    if Completed then
      HandleCompletion(ANode);
  finally
    DecrementActiveWorkers;
  end;
end;

procedure TDiskScannerThread.EnumerateDirectory(ANode: TDirectoryNode);
var
  SearchRec: TSearchRec;
  SubNode: TDirectoryNode;
  SubDirPath: string;
  LocalSize: Int64;
  LocalFileCount: Integer;
  FileDelta: Integer;
  ParentNode: TDirectoryNode;
  FileResult: Integer;
  ProgressUpdate: Boolean;
begin
  LocalSize := 0;
  LocalFileCount := 0;
  FileDelta := 0;
  ParentNode := ANode;
  ProgressUpdate := False;

  FileResult := FindFirst(ANode.FullPath + '*.*', faAnyFile, SearchRec);
  try
    while (FileResult = 0) and not Terminated and not FStopRequested do
    begin
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        if (SearchRec.Attr and faDirectory) = faDirectory then
        begin
          SubDirPath := IncludeTrailingPathDelimiter(ANode.FullPath + SearchRec.Name);
          SubNode := TDirectoryNode.Create(SearchRec.Name, SubDirPath, ParentNode);
          SubNode.ResetForScan;
          ANode.AddSubDir(SubNode);
          ANode.RegisterPendingChild;

          TInterlocked.Increment(FDirectoriesTotal);
          Synchronize(
            procedure
            begin
              NotifyProgressSummarySync;
              NotifyDirectoryAddedSync(SubNode, ANode);
            end);

          EnqueueDirectory(SubNode);
        end
        else
        begin
          Inc(LocalFileCount);
          Inc(FileDelta);
          LocalSize := LocalSize + SearchRec.Size;
        end;
      end;

      if FileDelta >= 64 then
      begin
        TInterlocked.Add(FTotalFilesScanned, FileDelta);
        Inc(FProgressCounter, FileDelta);
        FileDelta := 0;
        ProgressUpdate := True;
        while FProgressCounter >= 100 do
        begin
          Dec(FProgressCounter, 100);
          Synchronize(NotifyScanProgressSync);
          ProgressUpdate := False;
        end;
      end;

      FileResult := FindNext(SearchRec);
    end;
  finally
    if SearchRec.FindHandle <> INVALID_HANDLE_VALUE then
      System.SysUtils.FindClose(SearchRec);
  end;

  if FileDelta > 0 then
  begin
    TInterlocked.Add(FTotalFilesScanned, FileDelta);
    Inc(FProgressCounter, FileDelta);
    ProgressUpdate := True;
  end;

  while FProgressCounter >= 100 do
  begin
    Dec(FProgressCounter, 100);
    Synchronize(NotifyScanProgressSync);
    ProgressUpdate := False;
  end;

  if ProgressUpdate then
    Synchronize(NotifyScanProgressSync);

  ANode.UpdateDirectTotals(LocalSize, LocalFileCount);
end;

procedure TDiskScannerThread.HandleCompletion(ANode: TDirectoryNode);
var
  Parent: TDirectoryNode;
  ParentCompleted: Boolean;
begin
  if not Assigned(ANode) then
    Exit;

  if ANode.CheckAndFlagCompleted then
  begin
    TInterlocked.Increment(FDirectoriesCompleted);
    Synchronize(
      procedure
      begin
        NotifyDirectoryTotalsSync(ANode);
        NotifyDirectoryStatusSync(ANode);
        NotifyProgressSummarySync;
      end);
  end;

  Parent := ANode.Parent;
  if Assigned(Parent) then
  begin
    ParentCompleted := Parent.ChildFinished(ANode);
    Synchronize(
      procedure
      begin
        NotifyDirectoryTotalsSync(Parent);
        if ParentCompleted then
          NotifyDirectoryStatusSync(Parent);
      end);

    if ParentCompleted then
      HandleCompletion(Parent);
  end;
end;

procedure TDiskScannerThread.StartWorkers;
var
  I: Integer;
  Worker: TDirectoryScanWorker;
begin
  for I := 1 to FWorkerCount do
  begin
    Worker := TDirectoryScanWorker.Create(Self);
    FWorkers.Add(Worker);
  end;
end;

procedure TDiskScannerThread.StopWorkers;
var
  Worker: TThread;
begin
  FStopRequested := True;
  FQueueEvent.SetEvent;

  for Worker in FWorkers do
  begin
    Worker.Terminate;
    FQueueEvent.SetEvent;
    Worker.WaitFor;
  end;

  FWorkers.Clear;
end;

procedure TDiskScannerThread.Execute;
begin
  try
    if not DirectoryExists(FRootPath) then
    begin
      FErrorMessage := Format('Verzeichnis nicht gefunden: %s', [FRootPath]);
      Synchronize(
        procedure
        begin
          if Assigned(FOnError) then
            FOnError(Self);
        end);
      Exit;
    end;

    FDirectoriesTotal := 1;
    Synchronize(
      procedure
      begin
        NotifyDirectoryStatusSync(FRootNode);
        NotifyProgressSummarySync;
      end);

    ProcessDirectory(FRootNode);

    if Terminated or FStopRequested then
      Exit;

    StartWorkers;

    while not Terminated do
    begin
      if AllWorkCompleted then
        Break;
      Sleep(50);
    end;

    StopWorkers;

    if not Terminated then
      Synchronize(
        procedure
        begin
          if Assigned(FOnScanComplete) then
            FOnScanComplete(Self, FRootNode);
        end);
  except
    on E: Exception do
    begin
      FErrorMessage := E.Message;
      Synchronize(
        procedure
        begin
          if Assigned(FOnError) then
            FOnError(Self);
        end);
    end;
  end;
end;

end.
