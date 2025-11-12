program DiskAnalyzer;

uses
  Vcl.Forms,
  DiskAnalyzer_Main in 'DiskAnalyzer_Main.pas' {MainForm},
  DiskAnalyzer_Models in 'DiskAnalyzer_Models.pas',
  DiskAnalyzer_Scanner in 'DiskAnalyzer_Scanner.pas',
  DiskAnalyzer_Utils in 'DiskAnalyzer_Utils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
