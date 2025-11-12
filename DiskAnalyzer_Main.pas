unit DiskAnalyzer_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Buttons, Vcl.ToolWin, System.ImageList, Vcl.ImgList,
  DiskAnalyzer_Models, DiskAnalyzer_Scanner, DiskAnalyzer_Utils, System.Generics.Collections,
  Vcl.FileCtrl;

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
    
    procedure OnScanProgress(Sender: TObject; const APath: string; AFileCount: Integer);
    procedure OnScanComplete(Sender: TObject; ANode: TDirectoryNode);
    procedure OnScanError(Sender: TObject);
    
    procedure PopulateTree(ATreeNode: TTreeNode; ADirNode: TDirectoryNode);
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
  
  ProgressBar1.Position := 0;
  lblStatus.Caption := 'Scanne Verzeichnis...';
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

procedure TMainForm.OnScanComplete(Sender: TObject; ANode: TDirectoryNode);
var
  RootNode: TTreeNode;
begin
  FRootNode := ANode;
  
  // Root-Node in TreeView
  RootNode := TreeView1.Items.Add(nil, Format('%s (%s)', [ANode.Name, TDiskUtils.FormatFileSize(ANode.TotalSize)]));
  RootNode.ImageIndex := 0;
  RootNode.SelectedIndex := 0;
  FNodeMap.Add(Pointer(RootNode), ANode);
  
  // Rekursiv alle Child-Nodes hinzufügen
  PopulateTree(RootNode, ANode);
  
  RootNode.Expand(True); // Alle Nodes ausklappen
  
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

procedure TMainForm.PopulateTree(ATreeNode: TTreeNode; ADirNode: TDirectoryNode);
var
  SubDir: TDirectoryNode;
  ChildNode: TTreeNode;
begin
  for SubDir in ADirNode.SubDirs do
  begin
    ChildNode := TreeView1.Items.AddChild(ATreeNode, 
      Format('%s (%s, %d Dateien)', 
        [SubDir.Name, 
         TDiskUtils.FormatFileSize(SubDir.TotalSize),
         SubDir.FileCount]));
    
    ChildNode.ImageIndex := 1;
    ChildNode.SelectedIndex := 1;
    FNodeMap.Add(Pointer(ChildNode), SubDir);
    
    // Rekursiv für Unterverzeichnisse
    if SubDir.SubDirs.Count > 0 then
      PopulateTree(ChildNode, SubDir);
  end;
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
