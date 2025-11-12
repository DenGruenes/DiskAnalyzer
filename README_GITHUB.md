# 💾 DiskAnalyzer - TreeSize Alternative

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Delphi XE 11+](https://img.shields.io/badge/Delphi-XE%2011+-blue)](https://www.embarcadero.com/products/delphi)
[![Platform Windows](https://img.shields.io/badge/Platform-Windows-blue)](https://www.microsoft.com/windows)
[![Status Active](https://img.shields.io/badge/Status-Active-brightgreen)](#)
[![GitHub Issues](https://img.shields.io/github/issues/dein-username/DiskAnalyzer)](../../issues)
[![GitHub Stars](https://img.shields.io/github/stars/dein-username/DiskAnalyzer?style=social)](../../stargazers)

Eine hochperformante Festplattenanalyse-Anwendung für Windows, ähnlich wie das bekannte Programm **TreeSize**.

![DiskAnalyzer Screenshot](Resources/Screenshots/main-window.png)

## 🎯 Features

| Feature | Status | Beschreibung |
|---------|--------|-------------|
| **Multithreading** | ✅ | Non-blocking UI während Scan |
| **TreeView** | ✅ | Hierarchische Darstellung mit Sortierung |
| **Reports** | ✅ | CSV, JSON, HTML, Text Export |
| **Konfiguration** | ✅ | Flexible Filter & Exclusions |
| **Spring4D** | ✅ | Dependency Injection Support |
| **FireDAC** | ✅ | Firebird Database Integration |
| **Android** | 🚧 | Multi-Platform Support (WIP) |
| **Duplikat-Finder** | 🚧 | Geplant für 1.1.0 |
| **Real-time Monitor** | 🚧 | Geplant für 1.1.0 |

## 🚀 Quick Start

### Voraussetzungen
- **Delphi XE 11** oder höher
- **Windows 10/11** (64-bit oder 32-bit)
- Mindestens 4 GB RAM

### Installation

```bash
# Repository klonen
git clone https://github.com/dein-username/DiskAnalyzer.git
cd DiskAnalyzer

# In Delphi öffnen
# Datei → Öffnen → DiskAnalyzer.dpr

# Kompilieren
F9

# Ausführen
F10
```

### Verwendung

1. **Laufwerk/Pfad wählen**
   ```
   Gib einen Pfad ein oder nutze "..." zum Durchsuchen
   ```

2. **Scan starten**
   ```
   Klicke "Scan starten" und warte auf Fertigstellung
   ```

3. **Ergebnisse analysieren**
   ```
   Klicke auf Verzeichnisse zum Expandieren
   Details werden im rechten Panel angezeigt
   ```

## 📁 Projektstruktur

```
DiskAnalyzer/
├── Source/
│   ├── DiskAnalyzer.dpr              # Hauptprojekt
│   ├── DiskAnalyzer_Main.pas         # Benutzeroberfläche
│   ├── DiskAnalyzer_Scanner.pas      # Threading-Engine
│   ├── DiskAnalyzer_Models.pas       # Datenmodelle
│   ├── DiskAnalyzer_Config.pas       # Konfiguration
│   ├── DiskAnalyzer_Reports.pas      # Export-Funktionen
│   └── DiskAnalyzer_Examples.pas     # Code-Beispiele
├── Docs/
│   ├── DOCUMENTATION_DE.txt          # Detaillierte Dokumentation
│   ├── ARCHITECTURE.md               # Architektur
│   └── EXAMPLES.md                   # Codebeispiele
├── Resources/
│   ├── Icons/
│   └── Screenshots/
└── Tests/                             # Geplant
```

## 🏗️ Architektur

```
┌─────────────────────────────────────┐
│      Benutzeroberfläche (VCL)       │
│  TreeView + StatusBar + ProgressBar │
└────────────┬────────────────────────┘
             │ nutzt
┌────────────▼────────────────────────┐
│    Scanning Engine (TThread)        │
│  - Asynchrones Verzeichnis-Scanning │
│  - Größen-Aggregation               │
│  - Progress-Callbacks               │
└────────────┬────────────────────────┘
             │ erzeugt
┌────────────▼────────────────────────┐
│   Datenmodell (TDirectoryNode)      │
│  - Hierarchische Baumstruktur       │
│  - Sortierung nach Größe            │
│  - Statistiken & Metadaten          │
└─────────────────────────────────────┘
```

## 💻 Technische Details

### Performance
| Metric | Value |
|--------|-------|
| Thread-basiert | ✓ |
| UI-Responsive | ✓ |
| Memory-Optimiert | ✓ |
| Durchschn. Scan 100k Dateien | ~10 sec |

### Kompatibilität
- **Delphi**: XE 11, 11.1, 11.2, 11.3+
- **Windows**: 10, 11 (Home, Pro, Enterprise)
- **Architektur**: x64, x86

### Abhängigkeiten (Optional)
- [Spring4D](https://github.com/spring4d/spring4d) - Dependency Injection
- [JVCL](https://sourceforge.net/projects/jvcl/) - VCL Extensions
- [FireDAC](https://www.embarcadero.com/products/delphi) - Datenbankanbindung

## 📚 Dokumentation

- **[README.md](README.md)** - Übersicht und Schnellstart
- **[DOCUMENTATION_DE.txt](DOCUMENTATION_DE.txt)** - Detaillierte Dokumentation
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Beitrags-Richtlinien
- **[CHANGELOG.md](CHANGELOG.md)** - Versions-Historie
- **[PROJECT_STRUCTURE.txt](PROJECT_STRUCTURE.txt)** - Dateistruktur

## 🔧 Erweiterungen

### Spring4D Integration
```pascal
var Container: TContainer := TContainer.Create;
Container.RegisterSingleton<TScannerConfig>;
```

### FireDAC Integration
```pascal
Query.SQL.Text := 'INSERT INTO DISK_SCANS (PATH, SIZE) VALUES (:P,:S)';
Query.ParamByName('P').AsString := ANode.FullPath;
```

### Report-Generierung
```pascal
var Report := TDiskReport.Create(FRootNode);
Report.GenerateReport('analysis.csv', rfCSV);
```

## 🤝 Contributing

Beiträge sind willkommen! Siehe [CONTRIBUTING.md](CONTRIBUTING.md) für Details.

### Schnelle Schritte
1. Fork das Projekt
2. Feature-Branch erstellen (`git checkout -b feature/AmazingFeature`)
3. Änderungen committen (`git commit -m 'Add some AmazingFeature'`)
4. Zu Branch pushen (`git push origin feature/AmazingFeature`)
5. Pull Request öffnen

## 📋 Roadmap

### Version 1.1.0 (Q2 2025)
- [ ] Erweiterte UI (Dark Mode)
- [ ] Parallel Scanning
- [ ] Duplikat-Finder
- [ ] PDF-Reports

### Version 1.2.0 (Q3 2025)
- [ ] Graphische Charts
- [ ] Real-time Monitoring
- [ ] Web-Interface

### Version 2.0.0 (Q4 2025)
- [ ] Cloud Integration
- [ ] REST-API
- [ ] Mobile App

## 🐛 Bug-Reports & Feature-Requests

- **Bugs**: [Öffne einen Bug-Report](../../issues/new?template=bug_report.md)
- **Features**: [Erstelle einen Feature-Request](../../issues/new?template=feature_request.md)
- **Diskussionen**: [GitHub Discussions](../../discussions)

## 📄 Lizenz

Dieses Projekt ist unter der [MIT License](LICENSE) lizenziert. Siehe [LICENSE](LICENSE) Datei für Details.

```
MIT License

Copyright (c) 2025 DiskAnalyzer Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software...
```

## 🙏 Danksagungen

- Inspiriert von [TreeSize](https://www.jam-software.com/treesize)
- Gebaut mit [Delphi](https://www.embarcadero.com/)
- Icons von [Icons8](https://icons8.com/)

## 📞 Support

- 📧 Email: [support@example.com]
- 💬 Discussions: [GitHub Discussions](../../discussions)
- 📖 Wiki: [Project Wiki](../../wiki)

---

<div align="center">

**[⬆ Oben](#-diskanalyzer---treesize-alternative)**

Made with ❤️ by DiskAnalyzer Contributors

</div>
