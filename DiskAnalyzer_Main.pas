unit DiskAnalyzer_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,
  System.Variants, System.Classes, System.Types, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  Vcl.ToolWin, System.ImageList, Vcl.ImgList,
  DiskAnalyzer_Models, DiskAnalyzer_Scanner, DiskAnalyzer_Utils,
  System.Generics.Collections, System.Math, Vcl.FileCtrl;

type
  TMainForm = class(TForm)
    ToolBar1: TToolBar;
    btnScan: TToolButton;
    btnStop: TToolButton;
    ToolButton3: TToolButton;
    btnClear: TToolButton;
    Panel1: TPanel;
    TreeView1: TTreeView;
    Panel2: TPanel;
    Label1: TLabel;
    edtPath: TEdit;
    btnBrowse: TButton;
    Panel3: TPanel;
    Label2: TLabel;
    lblStatus: TLabel;
    Label3: TLabel;
    lblTotalSize: TLabel;
    ProgressBar1: TProgressBar;
    ImageList1: TImageList;
    Splitter1: TSplitter;
    Panel4: TPanel;
    MemoInfo: TMemo;
    HeaderControl1: THeaderControl;
    procedure btnScanClick(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure btnClearClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TreeView1AdvancedCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage;
      var PaintImages, DefaultDraw: Boolean);
    procedure HeaderControl1SectionTrack(Sender: TObject;
      Section: THeaderSection; Width: Integer; State: TSectionTrackState);
    procedure HeaderControl1SectionClick(Sender: TObject; Section: THeaderSection);
    procedure HeaderControl1Resize(Sender: TObject);
  private
    FScannerThread: TDiskScannerThread;
    FRootNode: TDirectoryNode;
    FNodeMap: TDictionary<Pointer, TDirectoryNode>;
    FDirectoryToTree: TDictionary<TDirectoryNode, TTreeNode>;
    FDiskCapacity: Int64;
    FSizeColumnLeft: Integer;
    FUsageColumnLeft: Integer;
    FSizeColumnWidth: Integer;
    FUsageColumnWidth: Integer;
    FSortColumn: Integer;
    FSortDescending: Boolean;
    FLastFileProgress: Integer;
    FProgressCompleted: Integer;
    FProgressTotal: Integer;

    // VERBESSERT: Neue Events für Live-Updates
    procedure OnScanProgress(Sender: TObject; const APath: string; AFileCount: Integer);
    procedure OnScanComplete(Sender: TObject; ANode: TDirectoryNode);
    procedure OnScanError(Sender: TObject);
    procedure OnDirectoryAdded(Sender: TObject; ANode: TDirectoryNode; AParentNode: TDirectoryNode);
    procedure OnDirectoryStatus(Sender: TObject; ANode: TDirectoryNode);
    procedure OnDirectoryTotals(Sender: TObject; ANode: TDirectoryNode);
    procedure OnProgressSummary(Sender: TObject; Completed, Total: Integer);

    function GetTreeNodeForDirectoryNode(ADirNode: TDirectoryNode): TTreeNode;
    function GetDirectoryDisplayName(ADirNode: TDirectoryNode): string;
    procedure UpdateNodeInfo(ADirNode: TDirectoryNode);
    procedure StopScanning;
    procedure UpdateColumnLayout;
    procedure InvalidateTree;
    procedure UpdateTreeNodeDisplay(ATreeNode: TTreeNode); 
    procedure SortTree;
    procedure SortTreeChildren(AParent: TTreeNode);
    function CompareDirectoryNodes(const LeftNode, RightNode: TDirectoryNode): Integer;
    procedure RefreshStatusSummary;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

const
  COLUMN_PADDING = 16;
  COLUMN_TEXT_PADDING = 6;

function DirectoryStatusText(const AStatus: TScanStatus): string;
begin
  case AStatus of
    ssPending:
      Result := 'Wartet';
    ssScanning:
      Result := 'Scan läuft';
    ssWaiting:
      Result := 'Unterordner werden verarbeitet';
    ssComplete:
      Result := 'Abgeschlossen';
    ssFailed:
      Result := 'Fehler';
  else
    Result := '';
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FNodeMap := TDictionary<Pointer, TDirectoryNode>.Create;
  FDirectoryToTree := TDictionary<TDirectoryNode, TTreeNode>.Create;
  edtPath.Text := 'C:\';
  lblStatus.Caption := 'Bereit zum Scannen';
  btnStop.Enabled := False;
  FDiskCapacity := 0;
  FSortColumn := 1;
  FSortDescending := True;
  FProgressCompleted := 0;
  FProgressTotal := 0;
  FLastFileProgress := 0;
  TDiskUtils.LoadSystemIcons(ImageList1);
  UpdateColumnLayout;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  StopScanning;

  if Assigned(FRootNode) then
    FRootNode.Free;

  FNodeMap.Free;
  FDirectoryToTree.Free;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  StopScanning;
end;

procedure TMainForm.btnBrowseClick(Sender: TObject);
var
  BrowsePath: string;
begin
  BrowsePath := edtPath.Text;
  if SelectDirectory('Verzeichnis wählen', '', BrowsePath) then
    edtPath.Text := BrowsePath;
end;

procedure TMainForm.btnScanClick(Sender: TObject);
var
  RootTreeNode: TTreeNode;
  DisplayName: string;
begin
  if edtPath.Text = '' then
  begin
    ShowMessage('Bitte wählen Sie einen Pfad!');
    Exit;
  end;

  if not DirectoryExists(edtPath.Text) then
  begin
    ShowMessage('Verzeichnis nicht gefunden!');
    Exit;
  end;

  StopScanning;

  if Assigned(FRootNode) then
  begin
    FRootNode.Free;
    FRootNode := nil;
  end;

  // Leere TreeView
  TreeView1.Items.Clear;
  FNodeMap.Clear;
  FDirectoryToTree.Clear;
  MemoInfo.Clear;

  FDiskCapacity := TDiskUtils.GetDriveCapacity(edtPath.Text);

  // Erstelle und starte Scanner-Thread
  FScannerThread := TDiskScannerThread.Create(edtPath.Text);
  FScannerThread.OnScanProgress := OnScanProgress;
  FScannerThread.OnScanComplete := OnScanComplete;
  FScannerThread.OnError := OnScanError;
  FScannerThread.OnDirectoryAdded := OnDirectoryAdded;  // VERBESSERT: Live-Updates
  FScannerThread.OnDirectoryStatus := OnDirectoryStatus;
  FScannerThread.OnDirectoryTotals := OnDirectoryTotals;
  FScannerThread.OnProgressSummary := OnProgressSummary;

  FRootNode := FScannerThread.RootNode;
  if FRootNode <> nil then
  begin
    DisplayName := GetDirectoryDisplayName(FRootNode);
    RootTreeNode := TreeView1.Items.Add(nil, DisplayName);
    RootTreeNode.ImageIndex := 0;
    RootTreeNode.SelectedIndex := 1;
    FNodeMap.AddOrSetValue(Pointer(RootTreeNode), FRootNode);
    FDirectoryToTree.AddOrSetValue(FRootNode, RootTreeNode);
    UpdateTreeNodeDisplay(RootTreeNode);
  end;

  ProgressBar1.Position := 0;
  lblStatus.Caption := 'Scanne Verzeichnis...';
  lblTotalSize.Caption := '0 B';
  FProgressCompleted := 0;
  FProgressTotal := 0;
  FLastFileProgress := 0;
  btnScan.Enabled := False;
  btnStop.Enabled := True;
  btnBrowse.Enabled := False;
  edtPath.Enabled := False;

  FScannerThread.Resume;
end;

procedure TMainForm.btnStopClick(Sender: TObject);
begin
  StopScanning;
end;

procedure TMainForm.btnClearClick(Sender: TObject);
begin
  TreeView1.Items.Clear;
  FNodeMap.Clear;
  FDirectoryToTree.Clear;
  MemoInfo.Clear;
  lblStatus.Caption := 'Geleert';
  lblTotalSize.Caption := '0 B';
  ProgressBar1.Position := 0;
  if Assigned(FRootNode) then
  begin
    FRootNode.Free;
    FRootNode := nil;
  end;
  FDiskCapacity := 0;
  InvalidateTree;
end;

procedure TMainForm.StopScanning;
var
  DetachedRoot: TDirectoryNode;
begin
  if Assigned(FScannerThread) then
  begin
    FScannerThread.Terminate;
    FScannerThread.WaitFor;

    DetachedRoot := FScannerThread.DetachRootNode;
    FScannerThread.Free;
    FScannerThread := nil;

    if Assigned(DetachedRoot) then
      FRootNode := DetachedRoot;

    lblStatus.Caption := 'Scan gestoppt';
    ProgressBar1.Position := 0;
  end;

  btnScan.Enabled := True;
  btnStop.Enabled := False;
  btnBrowse.Enabled := True;
  edtPath.Enabled := True;
  InvalidateTree;
end;

procedure TMainForm.OnScanProgress(Sender: TObject; const APath: string; AFileCount: Integer);
begin
  FLastFileProgress := AFileCount;
  RefreshStatusSummary;
end;

// VERBESSERT: Neuer Event-Handler für Live-TreeView-Updates
procedure TMainForm.OnDirectoryAdded(Sender: TObject; ANode: TDirectoryNode; AParentNode: TDirectoryNode);
var
  ParentTreeNode: TTreeNode;
  NewTreeNode: TTreeNode;
  TopItem: TTreeNode;
  SelectedNode: TTreeNode;
begin
  // Finde den TreeNode für den Parent
  ParentTreeNode := GetTreeNodeForDirectoryNode(AParentNode);

  if ParentTreeNode = nil then
    Exit;

  TopItem := TreeView1.TopItem;
  SelectedNode := TreeView1.Selected;

  TreeView1.Items.BeginUpdate;
  try
    // Erstelle neuen TreeNode für das Sub-Verzeichnis
    NewTreeNode := TreeView1.Items.AddChild(ParentTreeNode, GetDirectoryDisplayName(ANode));

    NewTreeNode.ImageIndex := 0;
    NewTreeNode.SelectedIndex := 1;
    FNodeMap.AddOrSetValue(Pointer(NewTreeNode), ANode);
    FDirectoryToTree.AddOrSetValue(ANode, NewTreeNode);
    UpdateTreeNodeDisplay(NewTreeNode);
  finally
    TreeView1.Items.EndUpdate;
  end;

  SortTreeChildren(ParentTreeNode);

  if Assigned(TopItem) then
    TreeView1.TopItem := TopItem;

  if Assigned(SelectedNode) then
    TreeView1.Selected := SelectedNode;

  InvalidateTree;
end;

procedure TMainForm.OnDirectoryStatus(Sender: TObject; ANode: TDirectoryNode);
var
  TreeNode: TTreeNode;
begin
  TreeNode := GetTreeNodeForDirectoryNode(ANode);
  if Assigned(TreeNode) then
  begin
    UpdateTreeNodeDisplay(TreeNode);
    if FSortColumn <> 0 then
      SortTreeChildren(TreeNode.Parent);
    if TreeView1.Selected = TreeNode then
      UpdateNodeInfo(ANode);
  end;

  if ANode = FRootNode then
    lblTotalSize.Caption := TDiskUtils.FormatFileSize(ANode.TotalSize);

  InvalidateTree;
end;

procedure TMainForm.OnDirectoryTotals(Sender: TObject; ANode: TDirectoryNode);
var
  TreeNode: TTreeNode;
begin
  TreeNode := GetTreeNodeForDirectoryNode(ANode);
  if Assigned(TreeNode) then
  begin
    UpdateTreeNodeDisplay(TreeNode);
    if FSortColumn in [1, 2] then
    begin
      if Assigned(TreeNode.Parent) then
        SortTreeChildren(TreeNode.Parent)
      else
        SortTreeChildren(TreeNode);
    end;
    if TreeView1.Selected = TreeNode then
      UpdateNodeInfo(ANode);
  end;

  if ANode = FRootNode then
    lblTotalSize.Caption := TDiskUtils.FormatFileSize(ANode.TotalSize);

  InvalidateTree;
end;

procedure TMainForm.OnProgressSummary(Sender: TObject; Completed, Total: Integer);
var
  Percent: Integer;
begin
  FProgressCompleted := Completed;
  FProgressTotal := Total;

  if Total > 0 then
  begin
    Percent := Round((Completed / Total) * 100);
    if Percent < 0 then
      Percent := 0
    else if Percent > 100 then
      Percent := 100;
  end
  else
    Percent := 0;

  ProgressBar1.Position := Percent;
  RefreshStatusSummary;
end;

function TMainForm.GetTreeNodeForDirectoryNode(ADirNode: TDirectoryNode): TTreeNode;
begin
  Result := nil;

  if Assigned(ADirNode) then
    FDirectoryToTree.TryGetValue(ADirNode, Result);
end;

procedure TMainForm.OnScanComplete(Sender: TObject; ANode: TDirectoryNode);
var
  RootNode: TTreeNode;
begin
  FRootNode := ANode;

  // Root-Node in TreeView (falls nicht schon vorhanden)
  RootNode := GetTreeNodeForDirectoryNode(ANode);
  if RootNode = nil then
  begin
    RootNode := TreeView1.Items.Add(nil, GetDirectoryDisplayName(ANode));
    RootNode.ImageIndex := 0;
    RootNode.SelectedIndex := 1;
    FNodeMap.AddOrSetValue(Pointer(RootNode), ANode);
    FDirectoryToTree.AddOrSetValue(ANode, RootNode);
  end;

  UpdateTreeNodeDisplay(RootNode);

  FProgressCompleted := FProgressTotal;
  FLastFileProgress := FScannerThread.TotalFilesScanned;
  lblStatus.Caption := Format('Scan abgeschlossen. %d Dateien gescannt', [FScannerThread.TotalFilesScanned]);
  lblTotalSize.Caption := TDiskUtils.FormatFileSize(ANode.TotalSize);
  ProgressBar1.Position := 100;

  btnScan.Enabled := True;
  btnStop.Enabled := False;
  btnBrowse.Enabled := True;
  edtPath.Enabled := True;

  SortTree;
  RefreshStatusSummary;
  InvalidateTree;
end;

procedure TMainForm.OnScanError(Sender: TObject);
begin
  ShowMessage('Fehler beim Scannen: ' + FScannerThread.ErrorMessage);
  lblStatus.Caption := 'Fehler: ' + FScannerThread.ErrorMessage;

  btnScan.Enabled := True;
  btnStop.Enabled := False;
  btnBrowse.Enabled := True;
  edtPath.Enabled := True;
end;

procedure TMainForm.TreeView1Change(Sender: TObject; Node: TTreeNode);
var
  DirNode: TDirectoryNode;
  DiskPercentage: Double;
begin
  if Node = nil then
    Exit;

  if FNodeMap.TryGetValue(Pointer(Node), DirNode) then
  begin
    UpdateNodeInfo(DirNode);
    if FDiskCapacity > 0 then
    begin
      DiskPercentage := TDiskUtils.GetPercentage(DirNode.TotalSize, FDiskCapacity);
      lblStatus.Caption := Format('Auslastung: %.2f%% der Festplatte', [DiskPercentage]);
    end;
  end;
end;

procedure TMainForm.UpdateNodeInfo(ADirNode: TDirectoryNode);
var
  TotalPercentage: Double;
  DiskPercentage: Double;
  TotalGB: Double;
  StatusText: string;
begin
  MemoInfo.Clear;
  MemoInfo.Lines.Add('=== Verzeichnisinformationen ===');
  MemoInfo.Lines.Add('');
  MemoInfo.Lines.Add('Pfad: ' + ADirNode.FullPath);
  MemoInfo.Lines.Add('');

  StatusText := DirectoryStatusText(ADirNode.Status);
  if StatusText <> '' then
    MemoInfo.Lines.Add('Status: ' + StatusText)
  else
    MemoInfo.Lines.Add('Status: unbekannt');
  MemoInfo.Lines.Add('');

  MemoInfo.Lines.Add('Größe: ' + TDiskUtils.FormatFileSize(ADirNode.TotalSize));
  TotalGB := TDiskUtils.GetSizeInGB(ADirNode.TotalSize);
  MemoInfo.Lines.Add(Format('Größe (GB): %.2f GB', [TotalGB]));
  MemoInfo.Lines.Add('');
  MemoInfo.Lines.Add('Dateianzahl: ' + IntToStr(ADirNode.FileCount));
  MemoInfo.Lines.Add('Unterverzeichnisse: ' + IntToStr(ADirNode.SubDirs.Count));
  MemoInfo.Lines.Add('');

  if FRootNode <> nil then
  begin
    TotalPercentage := TDiskUtils.GetPercentage(ADirNode.TotalSize, FRootNode.TotalSize);
    MemoInfo.Lines.Add(Format('Anteil am Gesamt: %.2f%%', [TotalPercentage]));
  end;

  if FDiskCapacity > 0 then
  begin
    DiskPercentage := TDiskUtils.GetPercentage(ADirNode.TotalSize, FDiskCapacity);
    MemoInfo.Lines.Add(Format('Auslastung der Festplatte: %.2f%%', [DiskPercentage]));
  end;

  MemoInfo.Lines.Add('Aktive Unterverzeichnisse: ' + IntToStr(ADirNode.PendingChildren));
end;

function TMainForm.GetDirectoryDisplayName(ADirNode: TDirectoryNode): string;
var
  TrimmedPath: string;
begin
  Result := '';

  if ADirNode = nil then
    Exit;

  if ADirNode.Name <> '' then
    Result := ADirNode.Name
  else
  begin
    TrimmedPath := ExcludeTrailingPathDelimiter(ADirNode.FullPath);
    if TrimmedPath <> '' then
      Result := ExtractFileName(TrimmedPath);
    if Result = '' then
      Result := TrimmedPath;
  end;

  if Result = '' then
    Result := ADirNode.FullPath;
end;

procedure TMainForm.UpdateTreeNodeDisplay(ATreeNode: TTreeNode);
var
  DirNode: TDirectoryNode;
begin
  if not Assigned(ATreeNode) then
    Exit;

  if FNodeMap.TryGetValue(Pointer(ATreeNode), DirNode) then
    ATreeNode.Text := GetDirectoryDisplayName(DirNode);
end;

procedure TMainForm.TreeView1AdvancedCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage;
  var PaintImages, DefaultDraw: Boolean);
var
  DirNode: TDirectoryNode;
  ItemRect, SizeRect, UsageRect, BarRect: TRect;
  SizeText, PercentText: string;
  PercentValue: Double;
  BarWidth: Integer;
  UsageColor: TColor;
  FrameRect: TRect;
  Background: TColor;
begin
  DefaultDraw := True;

  if not FNodeMap.TryGetValue(Pointer(Node), DirNode) then
    Exit;

  if Stage = cdPrePaint then
  begin
    if not (cdsSelected in State) then
    begin
      ItemRect := Node.DisplayRect(False);
      ItemRect.Right := TreeView1.ClientWidth;

      case DirNode.Status of
        ssPending:
          Background := $00F4F4F4;
        ssScanning:
          Background := $00FFF6CC;
        ssWaiting:
          Background := $00FFE8A0;
        ssComplete:
          Background := clWindow;
        ssFailed:
          Background := $00F2D0D0;
      else
        Background := clWindow;
      end;

      TreeView1.Canvas.Brush.Color := Background;
      TreeView1.Canvas.FillRect(ItemRect);
    end;
    Exit;
  end;

  if Stage <> cdPostPaint then
    Exit;

  ItemRect := Node.DisplayRect(False);
  ItemRect.Right := TreeView1.ClientWidth;

  SizeRect := ItemRect;
  SizeRect.Left := FSizeColumnLeft + COLUMN_TEXT_PADDING;
  SizeRect.Right := FSizeColumnLeft + FSizeColumnWidth - COLUMN_TEXT_PADDING;
  if SizeRect.Right <= SizeRect.Left then
    Exit;

  UsageRect := ItemRect;
  UsageRect.Left := FUsageColumnLeft + COLUMN_TEXT_PADDING;
  UsageRect.Right := FUsageColumnLeft + FUsageColumnWidth - COLUMN_TEXT_PADDING;
  if UsageRect.Right <= UsageRect.Left then
    Exit;

  if DirNode.TotalSize > 0 then
    SizeText := TDiskUtils.FormatFileSize(DirNode.TotalSize)
  else
    SizeText := '–';

  TreeView1.Canvas.Brush.Style := bsClear;
  TreeView1.Canvas.Font.Color := clWindowText;
  DrawText(TreeView1.Canvas.Handle, PChar(SizeText), Length(SizeText), SizeRect,
    DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_RIGHT);

  TreeView1.Canvas.Brush.Style := bsSolid;
  TreeView1.Canvas.Brush.Color := clBtnFace;
  TreeView1.Canvas.FillRect(UsageRect);

  BarRect := UsageRect;
  InflateRect(BarRect, -4, -4);
  if BarRect.Right <= BarRect.Left then
    Exit;

  if FDiskCapacity > 0 then
    PercentValue := TDiskUtils.GetPercentage(DirNode.TotalSize, FDiskCapacity)
  else
    PercentValue := 0;

  if PercentValue > 100 then
    PercentValue := 100;

  BarWidth := Round((BarRect.Right - BarRect.Left) * (PercentValue / 100));

  FrameRect := BarRect;
  BarRect.Right := BarRect.Left + BarWidth;

  case DirNode.Status of
    ssFailed:
      UsageColor := clRed;
    ssPending:
      UsageColor := clSilver;
    ssScanning, ssWaiting:
      UsageColor := $00FFA500; // orange tone
  else
    if PercentValue >= 90 then
      UsageColor := clRed
    else if PercentValue >= 70 then
      UsageColor := clOlive
    else
      UsageColor := clGreen;
  end;

  if BarWidth > 0 then
  begin
    TreeView1.Canvas.Brush.Color := UsageColor;
    TreeView1.Canvas.FillRect(BarRect);
  end;

  TreeView1.Canvas.Brush.Style := bsClear;
  TreeView1.Canvas.Pen.Color := clGray;
  TreeView1.Canvas.Rectangle(FrameRect);

  case DirNode.Status of
    ssComplete:
      PercentText := Format('%.1f%%', [PercentValue]);
    ssFailed:
      PercentText := 'Fehler';
    ssScanning:
      PercentText := 'Scan läuft';
    ssWaiting:
      PercentText := 'Wartet';
    ssPending:
      PercentText := 'In Warteschlange';
  else
    PercentText := '';
  end;

  if PercentText <> '' then
    DrawText(TreeView1.Canvas.Handle, PChar(PercentText), Length(PercentText), UsageRect,
      DT_SINGLELINE or DT_VCENTER or DT_CENTER);

end;

procedure TMainForm.UpdateColumnLayout;
begin
  if HeaderControl1.Sections.Count < 3 then
    Exit;

  FSizeColumnLeft := HeaderControl1.Sections[0].Width;
  FSizeColumnWidth := HeaderControl1.Sections[1].Width;
  FUsageColumnLeft := FSizeColumnLeft + FSizeColumnWidth;
  FUsageColumnWidth := HeaderControl1.Sections[2].Width;
end;

procedure TMainForm.HeaderControl1Resize(Sender: TObject);
begin
  UpdateColumnLayout;
  InvalidateTree;
end;

procedure TMainForm.HeaderControl1SectionTrack(Sender: TObject;
  Section: THeaderSection; Width: Integer; State: TSectionTrackState);
begin
  UpdateColumnLayout;
  InvalidateTree;
end;

procedure TMainForm.HeaderControl1SectionClick(Sender: TObject; Section: THeaderSection);
begin
  if FSortColumn = Section.Index then
    FSortDescending := not FSortDescending
  else
  begin
    FSortColumn := Section.Index;
    if FSortColumn = 0 then
      FSortDescending := False
    else
      FSortDescending := True;
  end;

  SortTree;
  InvalidateTree;
end;

procedure TMainForm.SortTree;
var
  Root: TTreeNode;
begin
  Root := TreeView1.Items.GetFirstNode;
  while Assigned(Root) do
  begin
    SortTreeChildren(Root);
    Root := Root.GetNextSibling;
  end;
end;

procedure TMainForm.SortTreeChildren(AParent: TTreeNode);
var
  Nodes: TList<TTreeNode>;
  Child: TTreeNode;
  TopItem, SelectedNode: TTreeNode;
begin
  if not Assigned(AParent) then
    Exit;

  Nodes := TList<TTreeNode>.Create;
  try
    Child := AParent.getFirstChild;
    while Assigned(Child) do
    begin
      Nodes.Add(Child);
      Child := Child.getNextSibling;
    end;

    if Nodes.Count < 2 then
    begin
      for Child in Nodes do
        SortTreeChildren(Child);
      Exit;
    end;

    Nodes.Sort(TComparer<TTreeNode>.Construct(
      function(const L, R: TTreeNode): Integer
      var
        LeftDir, RightDir: TDirectoryNode;
      begin
        if not FNodeMap.TryGetValue(Pointer(L), LeftDir) then
          LeftDir := nil;
        if not FNodeMap.TryGetValue(Pointer(R), RightDir) then
          RightDir := nil;
        Result := CompareDirectoryNodes(LeftDir, RightDir);
      end));

    TopItem := TreeView1.TopItem;
    SelectedNode := TreeView1.Selected;

    TreeView1.Items.BeginUpdate;
    try
      for Child in Nodes do
        Child.MoveTo(AParent, naAddChildLast);
    finally
      TreeView1.Items.EndUpdate;
    end;

    if Assigned(TopItem) then
      TreeView1.TopItem := TopItem;
    if Assigned(SelectedNode) then
      TreeView1.Selected := SelectedNode;

    Child := AParent.getFirstChild;
    while Assigned(Child) do
    begin
      SortTreeChildren(Child);
      Child := Child.getNextSibling;
    end;
  finally
    Nodes.Free;
  end;
end;

function TMainForm.CompareDirectoryNodes(const LeftNode, RightNode: TDirectoryNode): Integer;
var
  LeftValue, RightValue: Double;
  LeftName, RightName: string;
begin
  if LeftNode = RightNode then
    Exit(0);

  if not Assigned(LeftNode) then
    Exit(1);
  if not Assigned(RightNode) then
    Exit(-1);

  case FSortColumn of
    1:
      begin
        if LeftNode.TotalSize > RightNode.TotalSize then
          Result := 1
        else if LeftNode.TotalSize < RightNode.TotalSize then
          Result := -1
        else
          Result := AnsiCompareText(LeftNode.Name, RightNode.Name);
      end;
    2:
      begin
        if FDiskCapacity > 0 then
        begin
          LeftValue := TDiskUtils.GetPercentage(LeftNode.TotalSize, FDiskCapacity);
          RightValue := TDiskUtils.GetPercentage(RightNode.TotalSize, FDiskCapacity);
        end
        else
        begin
          LeftValue := LeftNode.TotalSize;
          RightValue := RightNode.TotalSize;
        end;

        if LeftValue > RightValue then
          Result := 1
        else if LeftValue < RightValue then
          Result := -1
        else
          Result := AnsiCompareText(LeftNode.Name, RightNode.Name);
      end;
  else
    begin
      LeftName := LeftNode.Name;
      if LeftName = '' then
        LeftName := LeftNode.FullPath;
      RightName := RightNode.Name;
      if RightName = '' then
        RightName := RightNode.FullPath;
      Result := AnsiCompareText(LeftName, RightName);
    end;
  end;

  if FSortDescending then
    Result := -Result;
end;

procedure TMainForm.RefreshStatusSummary;
begin
  if FProgressTotal > 0 then
    lblStatus.Caption := Format('Verzeichnisse: %d/%d – Dateien gescannt: %d',
      [FProgressCompleted, FProgressTotal, FLastFileProgress])
  else if FLastFileProgress > 0 then
    lblStatus.Caption := Format('Dateien gescannt: %d', [FLastFileProgress]);
end;

procedure TMainForm.InvalidateTree;
begin
  if TreeView1.HandleAllocated then
    TreeView1.Invalidate;
end;

end.

