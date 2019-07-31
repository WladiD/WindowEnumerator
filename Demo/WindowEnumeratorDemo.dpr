program WindowEnumeratorDemo;

uses
  Vcl.Forms,
  Main in 'Main.pas' {MainForm},
  WindowEnumerator in 'WindowEnumerator.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
