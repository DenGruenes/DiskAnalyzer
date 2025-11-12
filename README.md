# DiskAnalyzer - TreeSize Alternative für Delphi XE 11+

Eine hochperformante Festplattenanalyse-Anwendung in Delphi, ähnlich wie das bekannte Programm **TreeSize**.

## 🎯 Features

- **Multithreaded Scanning**: Non-blocking UI während der Festplattenanalyse
- **Baumansicht mit Sortierung**: Verzeichnisse sortiert nach Dateigröße  
- **Echtzeit-Progress**: Live-Feedback während des Scans
- **Detaillierte Statistiken**: Größe, Dateizahl, Prozentanteil pro Verzeichnis
- **Export-Funktionen**: CSV, JSON, HTML, Text-Reports
- **Flexible Konfiguration**: Exclusions, Depth-Limits, Filter
- **Windows-Optimiert**: Native Windows API für Best Performance

## 📁 Dateistruktur

```
DiskAnalyzer/
├── DiskAnalyzer.dpr                  # Hauptprojekt-Datei
├── DiskAnalyzer_Main.pas             # Hauptformular & UI
├── DiskAnalyzer_Main.dfm             # Formular-Definition
├── DiskAnalyzer_Models.pas           # Datenmodelle (TDirectoryNode)
├── DiskAnalyzer_Scanner.pas          # Threading-Engine
├── DiskAnalyzer_Utils.pas            # Utility-Funktionen
├── DiskAnalyzer_Config.pas           # Konfigurationsoptionen
├── DiskAnalyzer_Reports.pas          # Report-Generierung
└── DOCUMENTATION_DE.txt              # Erweiterte Dokumentation
```

## 🚀 Schnellstart

### 1. Projekt in Delphi öffnen
```
Datei → Öffnen → DiskAnalyzer.dpr
```

### 2. Kompilieren und Ausführen
```
F9 (Kompilieren)
F10 (Ausführen)
```

### 3. Verwendung
1. **Pfad eingeben** oder mit "..." durchsuchen
2. **Scan starten** - klicke "Scan starten" Button
3. **Ergebnisse durchsuchen** - Doppelklick zum Erweitern
4. **Info-Panel** - zeigt Details des ausgewählten Verzeichnisses

## 📊 Architektur-Übersicht

```
┌─────────────────────────────────────┐
│      TMainForm (UI / Formular)      │
├─────────────────────────────────────┤
│  TreeView1 (Baumansicht)            │
│  ProgressBar1 (Scan-Fortschritt)    │
│  MemoInfo (Details-Panel)           │
└────────────┬────────────────────────┘
             │
             ↓ verwendet
┌─────────────────────────────────────┐
│   TDiskScannerThread (Worker)       │
│   - Läuft in eigenem Thread         │
│   - Rekursives Verzeichnis-Scanning │
│   - Größenberechnungen              │
└────────────┬────────────────────────┘
             │
             ↓ erstellt/füllt
┌─────────────────────────────────────┐
│   TDirectoryNode (Datenmodell)      │
│   - Hierarchische Struktur          │
│   - Name, Path, Size, FileCount     │
│   - SortBySize() Methode            │
└─────────────────────────────────────┘
             │
             ↓ nutzt
┌─────────────────────────────────────┐
│   TDiskUtils (Formatter)            │
│   - FormatFileSize()                │
│   - GetPercentage()                 │
└─────────────────────────────────────┘
```

## ⚙️ Performance-Merkmale

| Feature | Beschreibung |
|---------|-------------|
| **Threading** | Hauptthread blockiert nicht |
| **Rekursion** | Effiziente Tiefe-zuerst Suche |
| **Sortierung** | Nach Scan einmalig sortieren |
| **Caching** | TDictionary für schnelle Lookups |
| **Exception-Handling** | Fehler bei "Access Denied" ignoriert |

## 🔧 Erweiterungen mit deinen Packages

### Spring4D Integration
```pascal
// Dependency Injection für Konfiguration
var
  Container: TContainer := TContainer.Create;
  Config: TScannerConfig;
begin
  Container.RegisterSingleton<TScannerConfig>;
  Config := Container.Resolve<TScannerConfig>;
end;
```

### FireDAC + Firebird
```pascal
// Scan-Ergebnisse speichern
procedure SaveScanResults(ANode: TDirectoryNode);
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  Query.Connection := FDConnection;
  Query.SQL.Text := 'INSERT INTO DISK_SCANS (PATH, SIZE, COUNT) VALUES (:P,:S,:C)';
  Query.ParamByName('P').AsString := ANode.FullPath;
  Query.ParamByName('S').AsInt64 := ANode.TotalSize;
  Query.ParamByName('C').AsInteger := ANode.FileCount;
  Query.ExecSQL;
end;
```

### JVCL Components
```pascal
// Besseres Verzeichnis-Dialog
uses JvBrowseForFolderDialog;

procedure TMainForm.btnBrowseClick(Sender: TObject);
var Dialog: TJvBrowseForFolderDialog;
begin
  Dialog := TJvBrowseForFolderDialog.Create(nil);
  if Dialog.Execute then
    edtPath.Text := Dialog.Directory;
  Dialog.Free;
end;
```

### FastReport Integration
```pascal
// Report-Generierung
procedure GenerateFastReport;
begin
  var Report := TDiskReport.Create(FRootNode);
  Report.GenerateReport('report.pdf', rfText);
  Report.Free;
end;
```

## 📝 Konfigurationsbeispiele

### Standard-Konfiguration
```pascal
var Config := TConfigPresets.GetDefaultConfig;
// Scannt alles, max 999 Ebenen
```

### Schnelle Konfiguration
```pascal
var Config := TConfigPresets.GetFastConfig;
// Max 5 Ebenen, keine versteckten/Systemdateien
```

### Detaillierte Konfiguration
```pascal
var Config := TConfigPresets.GetDetailedConfig;
// Alles inklusive Symlinks und Systemdateien
```

### Custom-Konfiguration
```pascal
var Config := TScannerConfig.Create;
Config.AddExcludeFolder('Temp');
Config.AddExcludeExtension('.log');
Config.MaxDepth := 10;
Config.IncludeSystemFiles := False;
```

## 📈 Report-Generierung

```pascal
var Report := TDiskReport.Create(FRootNode);

// CSV-Export
Report.GenerateReport('analysis.csv', rfCSV);

// JSON-Export
Report.GenerateReport('analysis.json', rfJSON);

// HTML-Export
Report.GenerateReport('analysis.html', rfHTML);

// Text-Export
Report.GenerateReport('analysis.txt', rfText);
```

## 🐛 Debugging-Tipps

### Thread-Status prüfen
```pascal
if FScannerThread.Terminated then
  ShowMessage('Scan wurde unterbrochen')
else
  ShowMessage('Scan läuft noch...');
```

### Fehlerbehandlung
```pascal
try
  FScannerThread.WaitFor;
except
  on E: Exception do
    ShowMessage('Fehler: ' + E.Message);
end;
```

### Progress-Verfolgung
```pascal
// In OnScanProgress Callback
lblStatus.Caption := Format('Gescannt: %d Dateien', [AFileCount]);
```

## 🔐 Sicherheit & Berechtigungen

Das Programm benötigt:
- ✓ Leserechte auf alle Verzeichnisse
- ✓ Keine Administratorrechte (für normale Ordner)
- ✓ Administrator für System-Verzeichnisse (C:\Windows, etc.)

**Tipp**: Starten Sie mit Administrator-Rechten für vollständige Analyse.

## 📊 Typische Scan-Zeiten (auf Standard-PC)

| Pfad | Dateien | Zeit |
|------|---------|------|
| User-Ordner | ~50k | < 5 sec |
| Alle Programme | ~100k | ~10 sec |
| Ganzes C:\ | ~500k | ~30-60 sec |

## 🎓 Best Practices

1. **Thread-Sicherheit**: Nur Synchronize() für UI-Updates nutzen
2. **Speicher**: Große Verzeichnisbäume können viel RAM benötigen
3. **Exceptions**: Graceful Error Handling bei "Access Denied"
4. **UI Responsiveness**: Progress-Updates nur notwendigerweise durchführen
5. **Sortierung**: Nach Scan, nicht während Scan sortieren

## 🚀 Mobile-Erweiterung (Android)

```pascal
{$IFDEF ANDROID}
uses Androidapi.JNI.Os;

function GetExternalStorage: string;
begin
  Result := JStringToString(
    TJEnvironment.JavaClass.getExternalStorageDirectory.getAbsolutePath);
end;
{$ENDIF}
```

Benötigte Permissions im AndroidManifest:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

## 📚 Weiterführende Dokumentation

Siehe `DOCUMENTATION_DE.txt` für:
- Advanced Threading Patterns
- Parallel-Processing mit TParallel
- Spring4D Integration
- FireDAC Integration  
- Performance-Optimierungen
- DUnit Testing

## 🤝 Contributing

Verbesserungsvorschläge:
- [ ] Cancellation Token statt Terminate-Flag
- [ ] WebView für Remote-Monitoring
- [ ] GPU-beschleunigte Sortierung
- [ ] Echtzeit-Filter und -Suche
- [ ] Network-Share Unterstützung

## 📄 Lizenz

Frei verwendbar und modifizierbar für persönliche und kommerzielle Projekte.

## ❓ FAQ

**F: Kann ich mehrere Scans gleichzeitig ausführen?**  
A: Ja, nutzen Sie mehrere TDiskScannerThread Instanzen parallel.

**F: Warum ist der Scan langsam?**  
A: Prüfen Sie Festplattenaktivität, Antivirus-Scans oder Netzwerklaufwerke.

**F: Kann ich den Scan abbrechen?**  
A: Ja, der "Stop" Button bricht den aktuellen Scan ab.

**F: Werden symbolische Links gefolgt?**  
A: Per Default nein, aber konfigurierbar in TScannerConfig.

---

**Version**: 1.0  
**Delphi**: XE 11+  
**Platform**: Windows (Desktop), Android (mit Anpassungen)  
**Status**: Production Ready
