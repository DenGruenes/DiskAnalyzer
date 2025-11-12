unit DiskAnalyzer_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Buttons, Vcl.ToolWin, System.ImageList, Vcl.ImgList,
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
    procedure btnScanClick(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure btnClearClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FScannerThread: TDiskScannerThread;
    FRootNode: TDirectoryNode;
    FNodeMap: TDictionary<Pointer, TDirectoryNode>;

    // VERBESSERT: Neue Events für Live-Updates
    procedure OnScanProgress(Sender: TObject; const APath: string; AFileCount: Integer);
    procedure OnScanComplete(Sender: TObject; ANode: TDirectoryNode);
    procedure OnScanError(Sender: TObject);
    procedure OnDirectoryAdded(Sender: TObject; ANode: TDirectoryNode; AParentNode: TDirectoryNode);

    function GetTreeNodeForDirectoryNode(ADirNode: TDirectoryNode): TTreeNode;
    procedure UpdateNodeInfo(ADirNode: TDirectoryNode);
    procedure StopScanning;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FNodeMap := TDictionary<Pointer, TDirectoryNode>.Create;
  edtPath.Text := 'C:\';
  lblStatus.Caption := 'Bereit zum Scannen';
  btnStop.Enabled := False;
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

  // Leere TreeView
  TreeView1.Items.Clear;
  FNodeMap.Clear;
  MemoInfo.Clear;

  // Erstelle und starte Scanner-Thread
  FScannerThread := TDiskScannerThread.Create(edtPath.Text);
  FScannerThread.OnScanProgress := OnScanProgress;
  FScannerThread.OnScanComplete := OnScanComplete;
  FScannerThread.OnError := OnScanError;
  FScannerThread.OnDirectoryAdded := OnDirectoryAdded;  // VERBESSERT: Live-Updates

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
end;

procedure TMainForm.StopScanning;
begin
  if Assigned(FScannerThread) then
  begin
    FScannerThread.Terminate;
    FScannerThread.WaitFor;
    FScannerThread.Free;
    FScannerThread := nil;
  end;

  btnScan.Enabled := True;
  btnStop.Enabled := False;
  btnBrowse.Enabled := True;
  edtPath.Enabled := True;
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
begin
  // Finde den TreeNode für den Parent
  ParentTreeNode := GetTreeNodeForDirectoryNode(AParentNode);

  if ParentTreeNode = nil then
    Exit;

  // Erstelle neuen TreeNode für das Sub-Verzeichnis
  NewTreeNode := TreeView1.Items.AddChild(ParentTreeNode,
    Format('%s (%s, %d Dateien)',
      [ANode.Name,
       TDiskUtils.FormatFileSize(ANode.TotalSize),
       ANode.FileCount]));

  NewTreeNode.ImageIndex := 1;
  NewTreeNode.SelectedIndex := 1;
  FNodeMap.Add(Pointer(NewTreeNode), ANode);

  // Auto-Expand Parent
  ParentTreeNode.Expand(False);
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
  if TreeView1.Items.Count = 0 then
  begin
    RootNode := TreeView1.Items.Add(nil, Format('%s (%s)', [ANode.Name, TDiskUtils.FormatFileSize(ANode.TotalSize)]));
    RootNode.ImageIndex := 0;
    RootNode.SelectedIndex := 0;
    FNodeMap.Add(Pointer(RootNode), ANode);
  end;

  lblStatus.Caption := Format('Scan abgeschlossen. %d Dateien gescannt', [FScannerThread.TotalFilesScanned]);
  lblTotalSize.Caption := TDiskUtils.FormatFileSize(ANode.TotalSize);
  ProgressBar1.Position := 100;

  btnScan.Enabled := True;
  btnStop.Enabled := False;
  btnBrowse.Enabled := True;
  edtPath.Enabled := True;
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
begin
  if Node = nil then
    Exit;

  if FNodeMap.TryGetValue(Pointer(Node), DirNode) then
  begin
    UpdateNodeInfo(DirNode);
  end;
end;

procedure TMainForm.UpdateNodeInfo(ADirNode: TDirectoryNode);
var
  TotalPercentage: Double;
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
end;

end.

