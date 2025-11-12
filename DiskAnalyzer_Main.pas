unit DiskAnalyzer_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,
  System.Variants, System.Classes, System.Types, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  Vcl.ToolWin, System.ImageList, Vcl.ImgList,
  DiskAnalyzer_Models, DiskAnalyzer_Scanner, DiskAnalyzer_Utils,
  System.Generics.Collections, Vcl.FileCtrl;

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
    pnlTreeHeader: TPanel;
    lblHeaderUsage: TLabel;
    lblHeaderSize: TLabel;
    lblHeaderName: TLabel;
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
    procedure pnlTreeHeaderResize(Sender: TObject);
  private
    FScannerThread: TDiskScannerThread;
    FRootNode: TDirectoryNode;
    FNodeMap: TDictionary<Pointer, TDirectoryNode>;
    FDiskCapacity: Int64;
    FSizeColumnLeft: Integer;
    FUsageColumnLeft: Integer;
    FSizeColumnWidth: Integer;
    FUsageColumnWidth: Integer;

    // VERBESSERT: Neue Events für Live-Updates
    procedure OnScanProgress(Sender: TObject; const APath: string; AFileCount: Integer);
    procedure OnScanComplete(Sender: TObject; ANode: TDirectoryNode);
    procedure OnScanError(Sender: TObject);
    procedure OnDirectoryAdded(Sender: TObject; ANode: TDirectoryNode; AParentNode: TDirectoryNode);

    function GetTreeNodeForDirectoryNode(ADirNode: TDirectoryNode): TTreeNode;
    function GetDirectoryDisplayName(ADirNode: TDirectoryNode): string;
    procedure UpdateNodeInfo(ADirNode: TDirectoryNode);
    procedure StopScanning;
    procedure UpdateColumnLayout;
    procedure InvalidateTree;
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

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FNodeMap := TDictionary<Pointer, TDirectoryNode>.Create;
  edtPath.Text := 'C:\';
  lblStatus.Caption := 'Bereit zum Scannen';
  btnStop.Enabled := False;
  FDiskCapacity := 0;
  TDiskUtils.LoadSystemIcons(ImageList1);
  UpdateColumnLayout;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  StopScanning;

  if Assigned(FRootNode) then
    FRootNode.Free;

  FNodeMap.Free;
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
  MemoInfo.Clear;

  FDiskCapacity := TDiskUtils.GetDriveCapacity(edtPath.Text);

  // Erstelle und starte Scanner-Thread
  FScannerThread := TDiskScannerThread.Create(edtPath.Text);
  FScannerThread.OnScanProgress := OnScanProgress;
  FScannerThread.OnScanComplete := OnScanComplete;
  FScannerThread.OnError := OnScanError;
  FScannerThread.OnDirectoryAdded := OnDirectoryAdded;  // VERBESSERT: Live-Updates

  FRootNode := FScannerThread.RootNode;
  if FRootNode <> nil then
  begin
    DisplayName := GetDirectoryDisplayName(FRootNode);
    RootTreeNode := TreeView1.Items.Add(nil, DisplayName);
    RootTreeNode.ImageIndex := 0;
    RootTreeNode.SelectedIndex := 1;
    FNodeMap.Add(Pointer(RootTreeNode), FRootNode);
  end;

  ProgressBar1.Position := 0;
  lblStatus.Caption := 'Scanne Verzeichnis...';
  lblTotalSize.Caption := '0 B';
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
  lblStatus.Caption := Format('Dateianzahl gescannt: %d', [AFileCount]);
  ProgressBar1.Position := (AFileCount mod 100);
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
    FNodeMap.Add(Pointer(NewTreeNode), ANode);
  finally
    TreeView1.Items.EndUpdate;
  end;

  if Assigned(TopItem) then
    TreeView1.TopItem := TopItem;

  if Assigned(SelectedNode) then
    TreeView1.Selected := SelectedNode;

  InvalidateTree;
end;

function TMainForm.GetTreeNodeForDirectoryNode(ADirNode: TDirectoryNode): TTreeNode;
var
  Node: TTreeNode;
  i: Integer;
begin
  Result := nil;

  // Suche in der Hauptebene
  for i := 0 to TreeView1.Items.Count - 1 do
  begin
    Node := TreeView1.Items[i];
    if FNodeMap.ContainsKey(Pointer(Node)) then
    begin
      if FNodeMap[Pointer(Node)] = ADirNode then
      begin
        Result := Node;
        Exit;
      end;
    end;
  end;
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
    FNodeMap.Add(Pointer(RootNode), ANode);
  end;

  RootNode.Text := GetDirectoryDisplayName(ANode);

  lblStatus.Caption := Format('Scan abgeschlossen. %d Dateien gescannt', [FScannerThread.TotalFilesScanned]);
  lblTotalSize.Caption := TDiskUtils.FormatFileSize(ANode.TotalSize);
  ProgressBar1.Position := 100;

  btnScan.Enabled := True;
  btnStop.Enabled := False;
  btnBrowse.Enabled := True;
  edtPath.Enabled := True;

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
begin
  MemoInfo.Clear;
  MemoInfo.Lines.Add('=== Verzeichnisinformationen ===');
  MemoInfo.Lines.Add('');
  MemoInfo.Lines.Add('Pfad: ' + ADirNode.FullPath);
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
begin
  DefaultDraw := True;
  if Stage <> cdPostPaint then
    Exit;

  if not FNodeMap.TryGetValue(Pointer(Node), DirNode) then
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

  SizeText := TDiskUtils.FormatFileSize(DirNode.TotalSize);

  TreeView1.Canvas.Brush.Style := bsClear;
  TreeView1.Canvas.Font.Color := clWindowText;
  DrawText(TreeView1.Canvas.Handle, PChar(SizeText), Length(SizeText), SizeRect,
    DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_RIGHT);

  // Draw usage bar
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
  BarRect.Right := BarRect.Left + BarWidth;

  if PercentValue >= 90 then
    UsageColor := clRed
  else if PercentValue >= 70 then
    UsageColor := clOlive
  else
    UsageColor := clGreen;

  if BarWidth > 0 then
  begin
    TreeView1.Canvas.Brush.Color := UsageColor;
    TreeView1.Canvas.FillRect(BarRect);
  end;

  TreeView1.Canvas.Brush.Style := bsClear;
  TreeView1.Canvas.Pen.Color := clGray;
  TreeView1.Canvas.Rectangle(BarRect);

  PercentText := Format('%.1f%%', [PercentValue]);
  DrawText(TreeView1.Canvas.Handle, PChar(PercentText), Length(PercentText), UsageRect,
    DT_SINGLELINE or DT_VCENTER or DT_CENTER);
end;

procedure TMainForm.pnlTreeHeaderResize(Sender: TObject);
begin
  UpdateColumnLayout;
  InvalidateTree;
end;

procedure TMainForm.UpdateColumnLayout;
begin
  FSizeColumnLeft := lblHeaderSize.Left + (COLUMN_PADDING div 2);
  FUsageColumnLeft := lblHeaderUsage.Left + (COLUMN_PADDING div 2);

  if lblHeaderSize.Width > COLUMN_PADDING then
    FSizeColumnWidth := lblHeaderSize.Width - COLUMN_PADDING
  else
    FSizeColumnWidth := lblHeaderSize.Width;

  if lblHeaderUsage.Width > COLUMN_PADDING then
    FUsageColumnWidth := lblHeaderUsage.Width - COLUMN_PADDING
  else
    FUsageColumnWidth := lblHeaderUsage.Width;
end;

procedure TMainForm.InvalidateTree;
begin
  if TreeView1.HandleAllocated then
    TreeView1.Invalidate;
end;

end.

