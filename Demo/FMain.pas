unit FMain;

interface

uses
  Classes, Controls, Forms, NLDSnakeImage, StdCtrls;

type
  TMainForm = class(TForm)
    StopButton: TButton;
    Thanks: TStaticText;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
  private
    FSnakeImage: TNLDSnakeImage;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FSnakeImage := TNLDSnakeImage.Create(Self);
  FSnakeImage.SetBounds((ClientWidth - 800) div 2, (ClientHeight - 600) div 2,
    800, 600);
  FSnakeImage.Anchors := [];
  FSnakeImage.HeadColor := $00AFD6E5;
  FSnakeImage.TailColor := $00076DB5;
  FSnakeImage.GraphicFileName := 'Guitar.jpg';
  FSnakeImage.Parent := Self;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  FSnakeImage.Start; 
end;

procedure TMainForm.StopButtonClick(Sender: TObject);
begin
  FSnakeImage.Stop;
  StopButton.Enabled := False;
  Thanks.Visible := True;
  FSnakeImage.SendToBack;
end;

end.
