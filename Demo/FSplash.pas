unit FSplash;

interface

uses
  Classes, Controls, Forms, ExtCtrls, NLDSnakeImage, StdCtrls;

type
  TSplashForm = class(TForm)
    Timer: TTimer;
    Manual: TStaticText;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure SnakeClick(Sender: TObject);
  private
    FClicked: Boolean;
    FSnakeImage: TNLDSnakeImage;
  end;

implementation

{$R *.dfm}

procedure TSplashForm.FormCreate(Sender: TObject);
begin
  FSnakeImage := TNLDSnakeImage.Create(Self);
  FSnakeImage.AutoSize := True;
  FSnakeImage.GraphicFileName := 'SplashScreen.jpg';
  FSnakeImage.HeadColor := $00408D1E;
  FSnakeImage.TailColor := $00F0FBEC;
  FSnakeImage.OnClick := SnakeClick;
  FSnakeImage.Parent := Self;
  Manual.BringToFront;
end;

procedure TSplashForm.FormShow(Sender: TObject);
begin
  FSnakeImage.Start;
end;

procedure TSplashForm.SnakeClick(Sender: TObject);
begin
  if FClicked then
    ModalResult := mrOk
  else
    Manual.Caption := 'But it''s worth waiting ;)';
  FClicked := True;
end;

procedure TSplashForm.TimerTimer(Sender: TObject);
begin
  ModalResult := mrOk;
end;

end.
