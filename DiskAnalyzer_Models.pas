unit DiskAnalyzer_Models;

interface

uses
  System.Generics.Collections, System.Generics.Defaults, System.SysUtils, Winapi.Windows;

type
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
  public
    constructor Create(const AName, AFullPath: string; AParent: TDirectoryNode = nil);
    destructor Destroy; override;
    
    procedure AddSubDir(ANode: TDirectoryNode);
    procedure SortBySize;
    
    property Name: string read FName;
    property FullPath: string read FFullPath;
    property TotalSize: Int64 read FTotalSize write FTotalSize;
    property FileCount: Integer read FFileCount write FFileCount;
    property SubDirs: TList<TDirectoryNode> read FSubDirs;
    property IsScanned: Boolean read FIsScanned write FIsScanned;
    property Parent: TDirectoryNode read FParent;
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
end;

destructor TDirectoryNode.Destroy;
var
  Node: TDirectoryNode;
begin
  for Node in FSubDirs do
    Node.Free;
  FSubDirs.Free;
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
        Result := R.TotalSize + L.TotalSize;
      end
    )
  );
  
  // Rekursiv für alle Unterkinder sortieren
  for Node in FSubDirs do
    Node.SortBySize;
end;

end.
