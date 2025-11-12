object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'DiskAnalyzer - TreeSize Alternative'
  ClientHeight = 600
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 600
    Top = 49
    Width = 5
    Height = 551
    Cursor = crHSplit
    Align = alRight
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 900
    Height = 22
    EdgeBorders = []
    Images = ImageList1
    TabOrder = 0
    object btnScan: TToolButton
      Caption = 'Scan starten'
      ImageIndex = 0
      OnClick = btnScanClick
    end
    object btnStop: TToolButton
      Caption = 'Scan stoppen'
      ImageIndex = 1
      OnClick = btnStopClick
    end
    object ToolButton3: TToolButton
      Width = 8
    end
    object btnClear: TToolButton
      Caption = 'Leeren'
      ImageIndex = 2
      OnClick = btnClearClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 22
    Width = 900
    Height = 27
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object Label1: TLabel
      Left = 8
      Top = 6
      Width = 23
      Height = 13
      Caption = 'Pfad:'
    end
    object edtPath: TEdit
      Left = 37
      Top = 3
      Width = 800
      Height = 21
      TabOrder = 0
      Text = 'C:\'
    end
    object btnBrowse: TButton
      Left = 842
      Top = 2
      Width = 50
      Height = 23
      Caption = '...'
      TabOrder = 1
      OnClick = btnBrowseClick
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 49
    Width = 600
    Height = 551
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object TreeView1: TTreeView
      Left = 0
      Top = 0
      Width = 600
      Height = 521
      Align = alClient
      Indent = 19
      Images = ImageList1
      PopupMenu = nil
      TabOrder = 0
      OnChange = TreeView1Change
    end
    object Panel3: TPanel
      Left = 0
      Top = 521
      Width = 600
      Height = 30
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      object Label2: TLabel
        Left = 8
        Top = 7
        Width = 26
        Height = 13
        Caption = 'Info:'
      end
      object lblStatus: TLabel
        Left = 60
        Top = 7
        Width = 92
        Height = 13
        Caption = 'Bereit zum Scannen'
      end
      object Label3: TLabel
        Left = 400
        Top = 7
        Width = 56
        Height = 13
        Caption = 'Gesamtgr:'
      end
      object lblTotalSize: TLabel
        Left = 462
        Top = 7
        Width = 18
        Height = 13
        Caption = '0 B'
      end
      object ProgressBar1: TProgressBar
        Left = 8
        Top = -2
        Width = 584
        Height = 5
        Align = alTop
        Min = 0
        Max = 100
        TabOrder = 0
      end
    end
  end
  object Panel4: TPanel
    Left = 605
    Top = 49
    Width = 295
    Height = 551
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 3
    object MemoInfo: TMemo
      Left = 0
      Top = 0
      Width = 295
      Height = 551
      Align = alClient
      BorderStyle = bsNone
      ReadOnly = True
      TabOrder = 0
    end
  end
  object ImageList1: TImageList
    ColorDepth = cd32Bit
    DrawingStyle = dsFocus
    Height = 16
    Width = 16
    Left = 872
    Top = 112
  end
end
