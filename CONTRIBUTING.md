# Contributing to DiskAnalyzer

Vielen Dank für dein Interesse an DiskAnalyzer! Wir freuen uns über Beiträge von der Community.

## 📋 Richtlinien

### Vor dem Starten
- Stelle sicher, dass du Delphi XE 11 oder höher installiert hast
- Lese die [README.md](README.md) und [DOCUMENTATION_DE.txt](DOCUMENTATION_DE.txt)
- Überprüfe offene Issues und Pull Requests

### Schritt-für-Schritt Anleitung

1. **Fork das Repository**
   ```bash
   git clone https://github.com/dein-username/DiskAnalyzer.git
   cd DiskAnalyzer
   ```

2. **Feature-Branch erstellen**
   ```bash
   git checkout -b feature/meine-neue-funktion
   ```

3. **Änderungen vornehmen**
   - Halte dich an den existierenden Code-Stil
   - Nutze aussagekräftige Commit-Messages
   - Teste deine Änderungen gründlich

4. **Commit & Push**
   ```bash
   git add .
   git commit -m "Describe: Meine neue Funktion"
   git push origin feature/meine-neue-funktion
   ```

5. **Pull Request erstellen**
   - Beschreibe deine Änderungen klar
   - Referenziere relevante Issues
   - Stelle sicher, dass dein Code kompiliert

## 🎯 Arten von Beiträgen

### Bug-Fixes
- Öffne ein Issue mit Reproduktionsschritten
- Fork das Repository
- Behebe den Bug mit Tests
- Erstelle einen Pull Request

### Neue Features
- Diskutiere das Feature zuerst in den Issues
- Implementiere es in einem Feature-Branch
- Schreibe Dokumentation
- Erstelle einen Pull Request

### Dokumentation
- Verbessere README oder DOCUMENTATION_DE.txt
- Füge Code-Beispiele hinzu
- Korrigiere Typos

## 📝 Code-Style

### Naming Convention (Delphi)
```pascal
// Klassen
type
  TMyClassName = class(TObject)
  private
    FPrivateField: string;
  protected
    procedure ProtectedMethod;
  public
    procedure PublicMethod;
  end;

// Interfaces
type
  IMyInterface = interface
    procedure SomeMethod;
  end;

// Konstanten
const
  MY_CONSTANT = 42;
  MY_STRING = 'Hello';

// Variablen
var
  MyVariable: string;
```

### Documentation
```pascal
/// <summary>
///   Beschreibung der Funktion
/// </summary>
/// <param name="AParam">Parameter-Beschreibung</param>
/// <returns>Rückgabewert</returns>
function MyFunction(AParam: string): Integer;
```

## 🧪 Testing

- Teste deine Änderungen im Debug und Release Mode
- Teste auf verschiedenen Windows-Versionen
- Überprüfe auf Memory Leaks

```bash
// Kompilieren
F9

// Ausführen
F10

// Debugging
Ctrl+G
```

## 📦 Packages Integration

Falls du Packages wie Spring4D, JVCL, FireDAC integrierst:
- Dokumentiere die neue Abhängigkeit
- Mache es optional, wenn möglich
- Aktualisiere die README

## 🐛 Bugs berichten

### Einen Bug-Report erstellen:
1. Gehe zu [Issues](../../issues)
2. Klicke "New Issue"
3. Nutze das Template
4. Beschreibe:
   - Delphi-Version
   - Windows-Version
   - Reproduktionsschritte
   - Erwartetes vs. Tatsächliches Verhalten
   - Fehler-Messages

## 💬 Fragen?

- Schreibe in den [Discussions](../../discussions)
- Öffne ein Issue mit dem Label `question`
- Kontaktiere die Maintainer

## ✅ Checkliste für Pull Requests

- [ ] Mein Code folgt dem Projekt-Style
- [ ] Ich habe die Dokumentation aktualisiert
- [ ] Ich habe meine Änderungen getestet
- [ ] Mein Code hat keine neuen Warnings
- [ ] Ich habe aussagekräftige Commit-Messages verwendet
- [ ] Mein Branch ist aktuell mit master
- [ ] Ich habe relevante Issues referenziert

## 📄 Lizenz

Mit deinem Beitrag stimmst du zu, dass dieser unter der [MIT License](LICENSE) verfügbar ist.

## 🙏 Danke!

Danke, dass du zu DiskAnalyzer beiträgst! Deine Beiträge machen dieses Projekt besser.

---

Fragen? Öffne ein Issue oder stelle eine Frage in den Discussions!
