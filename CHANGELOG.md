# Changelog

Alle wesentlichen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

## [1.0.0] - 2025-01-15

### Added
- Initial Release
- Multithreaded Disk Scanning Engine
- TreeView-basierte Benutzeroberfläche
- Größen-Sortierung nach Festplattennutzung
- Echtzeit-Progress-Anzeige
- CSV, JSON, HTML, Text Report-Generierung
- Konfigurierbare Scanner-Optionen
- Support für Verzeichnis-Ausschlüsse
- Support für Dateiendung-Filter
- Detaillierte Verzeichnis-Statistiken
- Error-Handling für "Access Denied" Fehler

### Features
- **DiskAnalyzer_Models.pas**: Hierarchische Datenstruktur (TDirectoryNode)
- **DiskAnalyzer_Scanner.pas**: Multithreaded Scanning mit TThread
- **DiskAnalyzer_Utils.pas**: Formatierung (B, KB, MB, GB, TB)
- **DiskAnalyzer_Config.pas**: Konfigurationsmanagement
- **DiskAnalyzer_Reports.pas**: Multi-Format Report-Export
- **DiskAnalyzer_Examples.pas**: Code-Beispiele für Erweiterungen

### Platform Support
- Windows XE 11+
- Win64 und Win32 Builds
- Android Multi-Platform (Basis-Support)

### Integration Examples
- Spring4D (Dependency Injection)
- JVCL Components
- FireDAC + Firebird
- FastReport

## [Geplant für 1.1.0]

### Planned Features
- [ ] GUI-Improvements
  - [ ] Context-Menu im TreeView
  - [ ] Drag & Drop Support
  - [ ] Favorites/Bookmarks
  
- [ ] Performance-Verbesserungen
  - [ ] Parallel Scanning mit TParallel
  - [ ] Caching für schnellere Wiederholunscan
  - [ ] Incremental Scanning
  
- [ ] Report-Features
  - [ ] PDF Export (mit FastReport)
  - [ ] Excel Export (mit TMS Components)
  - [ ] Scheduled Reports
  
- [ ] Monitoring
  - [ ] Real-time Disk Monitoring
  - [ ] Alerts bei Kapazitätsgrenzwerten
  - [ ] Logging in Firebird
  
- [ ] Advanced
  - [ ] Duplicate File Finder
  - [ ] Network Share Scanning
  - [ ] Mobile App (Android)

## [Geplant für 1.2.0]

### Advanced Features
- [ ] Graphische Darstellung (Charts)
- [ ] Vergleich mehrerer Scans
- [ ] Integration mit Cloud-Speicher
- [ ] REST-API für Remote-Monitoring
- [ ] Web-Frontend (Electron)

---

## Versioning Format

### Major.Minor.Patch
- **Major**: Große Funktionserweiterungen oder Breaking Changes
- **Minor**: Neue Features, Bugfixes, keine Breaking Changes
- **Patch**: Kleine Bugfixes und Patches

### Beispiele
- `1.0.0` → Initial Release
- `1.1.0` → New Features added
- `1.1.1` → Bugfix in 1.1.0
- `2.0.0` → Major Overhaul

---

## Wie man Updates verfolgt

1. **GitHub Watch**: Notifications für Releases erhalten
2. **RSS-Feed**: https://github.com/[username]/DiskAnalyzer/releases.atom
3. **Releases Tab**: Detaillierte Release-Notes
4. **Discussions**: Community-Feedback und Feature-Requests

---

## Beiträge

Möchtest du zu diesem Projekt beitragen? Siehe [CONTRIBUTING.md](CONTRIBUTING.md)

## Lizenz

Dieses Projekt ist unter der [MIT License](LICENSE) lizenziert.
