program SnakeImageDemo;

uses
  Forms,
  Controls,
  FMain in 'FMain.pas' {MainForm},
  FSplash in 'FSplash.pas' {SplashForm},
  NLDSnakeImage in '..\NLDSnakeImage.pas';

{$R *.res}

type
  TSplashHelper = class(TObject)
    procedure SplashActive(Sender: TObject);
  end;

procedure TSplashHelper.SplashActive(Sender: TObject);
begin
  Application.CreateForm(TMainForm, MainForm);
end;

var
  Helper: TSplashHelper;
  SplashOk: Boolean;

begin
  Application.Initialize;
  Helper := TSplashHelper.Create;
  with TSplashForm.Create(nil) do
    try
      OnActivate := Helper.SplashActive;
      SplashOk := ShowModal = mrOk;
    finally
      Free;
      Helper.Free;
    end;
  if SplashOk then
    Application.Run;
end.
