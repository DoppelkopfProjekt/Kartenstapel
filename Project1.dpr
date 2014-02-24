program Project1;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  mTKartenstapel in 'mTKartenstapel.pas';

{$R *.res}

begin
  Application.Initialize;
  {$IFDEF VER230}
   Application.MainFormOnTaskbar := True;
  {$ENDIF}
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
