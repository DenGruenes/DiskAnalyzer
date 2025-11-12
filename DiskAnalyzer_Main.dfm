object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'DiskAnalyzer - TreeSize Alternative'
  ClientHeight = 600
  ClientWidth = 1518
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
    Left = 1218
    Top = 63
    Width = 5
    Height = 537
    Align = alRight
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 1518
    Height = 36
    AutoSize = True
    ButtonHeight = 36
    ButtonWidth = 72
    Images = ImageList1
    ShowCaptions = True
    TabOrder = 0
    object btnScan: TToolButton
      Left = 0
      Top = 0
      Caption = 'Scan starten'
      ImageIndex = 2
      OnClick = btnScanClick
    end
    object btnStop: TToolButton
      Left = 72
      Top = 0
      Caption = 'Scan stoppen'
      ImageIndex = 3
      OnClick = btnStopClick
    end
    object ToolButton3: TToolButton
      Left = 144
      Top = 0
    end
    object btnClear: TToolButton
      Left = 216
      Top = 0
      Caption = 'Leeren'
      ImageIndex = 4
      OnClick = btnClearClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 36
    Width = 1518
    Height = 27
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object Label1: TLabel
      Left = 8
      Top = 6
      Width = 26
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
    Top = 63
    Width = 1218
    Height = 537
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object HeaderControl1: THeaderControl
      Left = 0
      Top = 0
      Width = 1218
      Height = 24
      Align = alTop
      Sections = <
        item
          Text = 'Ordner'
          Width = 700
        end
        item
          Text = 'Gesamtgr'#246#223'e'
          Width = 240
        end
        item
          Text = 'Auslastung'
          Width = 220
        end>
      OnSectionClick = HeaderControl1SectionClick
      OnSectionTrack = HeaderControl1SectionTrack
      OnResize = HeaderControl1Resize
    end
    object TreeView1: TTreeView
      Left = 0
      Top = 24
      Width = 1218
      Height = 483
      Align = alClient
      Images = ImageList1
      Indent = 19
      ParentDoubleBuffered = False
      DoubleBuffered = True
      ReadOnly = True
      TabOrder = 1
      OnAdvancedCustomDrawItem = TreeView1AdvancedCustomDrawItem
      OnChange = TreeView1Change
    end
    object Panel3: TPanel
      Left = 0
      Top = 507
      Width = 1218
      Height = 30
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 2
      object Label2: TLabel
        Left = 8
        Top = 7
        Width = 24
        Height = 13
        Caption = 'Info:'
      end
      object lblStatus: TLabel
        Left = 60
        Top = 7
        Width = 94
        Height = 13
        Caption = 'Bereit zum Scannen'
      end
      object Label3: TLabel
        Left = 400
        Top = 7
        Width = 50
        Height = 13
        Caption = 'Gesamtgr:'
      end
      object lblTotalSize: TLabel
        Left = 462
        Top = 7
        Width = 15
        Height = 13
        Caption = '0 B'
      end
      object ProgressBar1: TProgressBar
        Left = 0
        Top = 0
        Width = 1218
        Height = 5
        Align = alTop
        TabOrder = 0
      end
    end
  end
  object Panel4: TPanel
    Left = 1223
    Top = 63
    Width = 295
    Height = 537
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 3
    object MemoInfo: TMemo
      Left = 0
      Top = 0
      Width = 295
      Height = 537
      Align = alClient
      BorderStyle = bsNone
      ReadOnly = True
      TabOrder = 0
    end
  end
  object ImageList1: TImageList
    ColorDepth = cd32Bit
    DrawingStyle = dsTransparent
    Masked = True
    Width = 16
    Height = 16
    Left = 872
    Top = 112
  end
end
