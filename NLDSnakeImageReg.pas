unit NLDSnakeImageReg;

interface

uses
  Classes, NLDSnakeImage;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('NLDelphi', [TNLDSnakeImage]);
end;

end.
