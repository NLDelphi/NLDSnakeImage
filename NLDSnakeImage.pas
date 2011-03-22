unit NLDSnakeImage;

interface

uses
  Windows, SysUtils, Classes, Controls, Messages, Graphics, Math, Contnrs, Jpeg;

type
  TRGB = record
    R: Byte;
    G: Byte;
    B: Byte;
  end;

  TBezier = array[0..3] of TPoint;
  TPointArray = array of TPoint;

  TSnake = class(TCustomControl)
  private
    FBezier: TBezier;
    FBuffer: TBitmap;
    FHeadClr: TRGB;
    FHeadColor: TColor;
    FHeadIndex: Integer;
    FMargin: Integer;
    FPointCount: Integer;
    FPoints: TPointArray;
    FSnakeLength: Integer;
    FSnakeWidth: Integer;
    FTailClr: TRGB;
    function GetTailColor: TColor;
    procedure Grow;
    procedure SetHeadColor(Value: TColor);
    procedure SetSnakeWidth(Value: Integer);
    procedure SetTailColor(Value: TColor);
    procedure Sneak;
    function WidthToColor(Cur, Max: Integer): COLORREF;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
    procedure Resize; override;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Start; virtual;
    procedure Stop; virtual;
  published
    property HeadColor: TColor read FHeadColor write SetHeadColor
      default clBlack;
    property SnakeWidth: Integer read FSnakeWidth write SetSnakeWidth
      default 20;
    property TailColor: TColor read GetTailColor write SetTailColor
      default clBtnFace;
  end;

  TSplash = class(TObject)
  private
    FCenter: TPoint;
    FCoords: TPointArray;
    FStartTick: Cardinal;
  protected
    constructor Create(const ACenter: TPoint; MaxRadius: Integer);
  end;

  TSplashes = class(TObjectList)
  private
    function GetItem(Index: Integer): TSplash;
  public
    property Items[Index: Integer]: TSplash read GetItem; default;
  end;

  TNLDSnakeImage = class(TSnake)
  private
    FBlendFunc: TBlendFunction;
    FImage: TBitmap;
    FPicture: TPicture;
    FPrevTick: Cardinal;
    FSplashes: TSplashes;
    FGraphicFileName: String;
    function IsPictureStored: Boolean;
    procedure PictureChanged(Sender: TObject);
    procedure SetGraphicFileName(const Value: String);
    procedure SetPicture(Value: TPicture);
    procedure Splash;
    procedure UpdateImage;
  protected
    procedure AdjustSize; override;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Start; override;
    procedure Stop; override;
  published
    property GraphicFileName: String read FGraphicFileName
      write SetGraphicFileName;
    property Picture: TPicture read FPicture write SetPicture stored IsPictureStored;
  published
    property Align;
    property Anchors;
    property AutoSize;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property OnCanResize;
    property OnClick;
    property OnConstrainedResize;
    property OnContextPopup;
    property OnDblClick;
    property OnDockDrop;
    property OnDockOver;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
  end;

implementation

function ColorToRGB(AColor: TColor): TRGB;
begin
  AColor := Graphics.ColorToRGB(AColor);
  Result.R := GetRValue(AColor);
  Result.G := GetGValue(AColor);
  Result.B := GetBValue(AColor);
end;

function FitRect(const Boundary: TRect; Width, Height: Integer;
  CanGrow: Boolean): TRect;
var
  W: Integer;
  H: Integer;
  Scale: Single;
  Offset: TPoint;
begin
  W := Boundary.Right - Boundary.Left;
  H := Boundary.Bottom - Boundary.Top;
  if CanGrow then
    Scale := Min(W / Width, H / Height)
  else
    Scale := Min(1, Min(W / Width, H / Height));
  Offset.X := (W - Round(Width * Scale)) div 2;
  Offset.Y := (H - Round(Height * Scale)) div 2;
  with Boundary do
    Result := Rect(Left + Offset.X, Top + Offset.Y, Right - Offset.X,
      Bottom - Offset.Y);
end;

{ TSnake }

const
  AvgLineLength = 10;

constructor TSnake.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if csDesigning in ComponentState then
    ControlStyle := [csAcceptsControls, csClickEvents, csDoubleClicks]
  else
    ControlStyle := [csAcceptsControls, csClickEvents, csOpaque, csDoubleClicks,
      csDisplayDragImage];
  FBuffer := TBitmap.Create;
  FSnakeWidth := 20;
  SetHeadColor(clBlack);
  SetTailColor(clBtnFace);
end;

procedure TSnake.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
    WindowClass.style := WindowClass.style and not (CS_HREDRAW or CS_VREDRAW);
end;

destructor TSnake.Destroy;
begin
  Stop;
  FBuffer.Free;
  inherited Destroy;
end;

function TSnake.GetTailColor: TColor;
begin
  Result := Color;
end;

procedure TSnake.Grow;
var
  Points: TPointArray;
  Types: array of Byte;
  Growth: Integer;
begin
  FBezier[0] := FBezier[3];
  FBezier[1].X := FBezier[0].X - FBezier[2].X + FBezier[3].X;
  FBezier[1].Y := FBezier[0].Y - FBezier[2].Y + FBezier[3].Y;
  FBezier[2].X := FMargin + Random(Width - 2 * FMargin);
  FBezier[2].Y := FMargin + Random(Height - 2 * FMargin);
  FBezier[3].X := FMargin + Random(Width - 2 * FMargin);
  FBezier[3].Y := FMargin + Random(Height - 2 * FMargin);
  SetLength(Points, 1);
  SetLength(Types, 1);
  BeginPath(Canvas.Handle);
  PolyBezier(Canvas.Handle, FBezier[0], 4);
  EndPath(Canvas.Handle);
  FlattenPath(Canvas.Handle);
  Growth := GetPath(Canvas.Handle, Points[0], Types[0], 0);
  SetLength(Points, Growth);
  SetLength(Types, Growth);
  GetPath(Canvas.Handle, Points[0], Types[0], Growth);
  if Growth > 1 then
  begin
    SetLength(FPoints, FPointCount + Growth - 1);
    Move(Points[1], FPoints[FPointCount], (Growth - 1) * SizeOf(TPoint));
    Inc(FPointCount, Growth - 1);
  end;
end;

procedure TSnake.Paint;
var
  DC: HDC;
  LogBrush: TLogBrush;
  MaxWidth: Integer;
  Pen: HPEN;
  SegmentLength: Integer;
  FromIndex: Integer;

  procedure GradientCircle(Center: TPoint);
  var
    R: Integer;
  begin
    R := MaxWidth div 2;
    while R > 0 do
    begin
      Pen := CreatePen(PS_SOLID, 2, WidthToColor(2 * R, MaxWidth));
      DeleteObject(SelectObject(DC, Pen));
      with Center do
        Arc(DC, X - R, Y - R, X + R, Y + R, X, Y - R, X, Y - R);
      Dec(R);
    end;
  end;

  procedure GradientPolyLine(From, Count: Integer);
  var
    W: Integer;
  begin
    W := MaxWidth;
    while W > 0 do
    begin
      LogBrush.lbColor := WidthToColor(W, MaxWidth);
      Pen := ExtCreatePen(PS_GEOMETRIC or PS_SOLID or PS_ENDCAP_FLAT or
        PS_JOIN_ROUND, W, LogBrush, 0, nil);
      DeleteObject(SelectObject(DC, Pen));
      Polyline(DC, FPoints[From], Count);
      Dec(W);
    end;
  end;

begin
  if HasParent and (FPointCount > 0) then
  begin
    DC := FBuffer.Canvas.Handle;
    LogBrush.lbStyle := BS_SOLID;
    LogBrush.lbHatch := 0;
    if FHeadIndex < (FSnakeLength - 1) then
      MaxWidth := Ceil(FSnakeWidth * (FHeadIndex / FSnakeLength))
    else
      MaxWidth := FSnakeWidth;
    GradientCircle(FPoints[FHeadIndex]);
    SegmentLength := FSnakeLength div FSnakeWidth;
    FromIndex := FHeadIndex - MaxWidth * SegmentLength;
    MaxWidth := 1;
    while FromIndex < FHeadIndex do
    begin
      if FromIndex < 0 then
        GradientPolyLine(0, FromIndex + SegmentLength + 1)
      else if (FromIndex + SegmentLength) = FHeadIndex then
        GradientPolyLine(FromIndex, SegmentLength + 1)
      else
        GradientPolyLine(FromIndex, SegmentLength + 2);
      Inc(FromIndex, SegmentLength);
      Inc(MaxWidth);
    end;
    DeleteObject(Pen);
  end;
end;

procedure TSnake.Resize;
begin
  inherited Resize;
  FBuffer.Width := Width;
  FBuffer.Height := Height;
  FMargin := Min(Width, Height) div 10;
  if FPointCount = 0 then
  begin
    FSnakeLength := Round(Sqrt(Sqr(Width) + Sqr(Height)) / AvgLineLength);
    FBezier[3].X := FMargin + Random(Width - 2 * FMargin);
    FBezier[3].Y := FMargin + Random(Height - 2 * FMargin);
  end;
end;

procedure TSnake.SetHeadColor(Value: TColor);
begin
  if FHeadColor <> Value then
  begin
    FHeadColor := Value;
    FHeadClr := ColorToRGB(FHeadColor);
    Invalidate;
  end;
end;

procedure TSnake.SetSnakeWidth(Value: Integer);
begin
  if FSnakeWidth <> Value then
  begin
    Stop;
    FSnakeWidth := Max(0, Min(Value, 50));
    Invalidate;
  end;
end;

procedure TSnake.SetTailColor(Value: TColor);
begin
  if TailColor <> Value then
  begin
    Color := Value;
    FTailClr := ColorToRGB(Color);
    Brush.Color := Color;
    Canvas.Brush.Color := Color;
    Invalidate;
  end;
end;

procedure TSnake.Sneak;
var
  MoveCount: Integer;
begin
  Inc(FHeadIndex);
  if FHeadIndex >= (FPointCount - 2) then
    Grow;
  MoveCount := FSnakeLength + FPointCount - FHeadIndex - 1;
  if (MoveCount) < (FHeadIndex - FSnakeLength) then
  begin
    Move(FPoints[FHeadIndex - FSnakeLength + 1], FPoints[0],
      MoveCount * SizeOf(TPoint));
    FPointCount := MoveCount;
    SetLength(FPoints, FPointCount);
    FHeadIndex := FSnakeLength - 1;
  end;
end;

procedure TSnake.Start;
begin
  if HandleAllocated then
    SetTimer(Handle, 0, 20, nil);
end;

procedure TSnake.Stop;
begin
  if HandleAllocated then
    KillTimer(Handle, 0);
  FPointCount := 0;
  SetLength(FPoints, 0);
  FHeadIndex := 0;
end;

function TSnake.WidthToColor(Cur, Max: Integer): COLORREF;
var
  Color: TRGB;
begin
  with Color do
  begin
    R := FTailClr.R +
      Round((FHeadClr.R - FTailClr.R) * (Max - Cur) / FSnakeWidth);
    G := FTailClr.G +
      Round((FHeadClr.G - FTailClr.G) * (Max - Cur) / FSnakeWidth);
    B := FTailClr.B +
      Round((FHeadClr.B - FTailClr.B) * (Max - Cur) / FSnakeWidth);
    Result := RGB(R, G, B);
  end;
end;

procedure TSnake.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  if csDesigning in ComponentState then
    inherited
  else
    Message.Result := 1;
end;

procedure TSnake.WndProc(var Message: TMessage);
begin
  if Message.Msg = WM_TIMER then
  begin
    Sneak;
    Paint;
  end
  else
    inherited WndProc(Message);
end;

{ TSplash }

constructor TSplash.Create(const ACenter: TPoint; MaxRadius: Integer);
var
  Angle: Integer;
  I: Integer;
  R: Integer;
begin
  inherited Create;
  FCenter := ACenter;
  Angle := 0;
  I := 0;
  while Angle < 360 do
  begin
    if Odd(I) then
      R := Round(0.5 * MaxRadius) + Random(Round(0.5 * MaxRadius))
    else
      R := Round(0.25 * MaxRadius) + Random(Round(0.25 * MaxRadius));
    SetLength(FCoords, I + 1);
    FCoords[I].X := FCenter.X + Round(R * Cos(DegToRad(Angle)));
    FCoords[I].Y := FCenter.Y + Round(R * Sin(DegToRad(Angle)));
    Inc(I);
    Inc(Angle, 5 + Random(MaxRadius div 5));
  end;
  FStartTick := GetTickCount;
end;

{ TSplashes }

function TSplashes.GetItem(Index: Integer): TSplash;
begin
  Result := TSplash(inherited Items[Index]);
end;

{ TNLDSnakeImage }

procedure TNLDSnakeImage.AdjustSize;
begin
  if AutoSize and (FPicture.Graphic <> nil) then
    UpdateBoundsRect(Bounds(Left, Top, FPicture.Width, FPicture.Height));
  inherited AdjustSize;
end;

function TNLDSnakeImage.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  Result := inherited CanAutoSize(NewWidth, NewHeight) or
    (FPicture.Graphic <> nil);
  if FPicture.Graphic <> nil then
  begin
    NewWidth := Max(NewWidth, FPicture.Width);
    NewHeight := Max(NewHeight, FPicture.Height);
  end;
end;

constructor TNLDSnakeImage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBlendFunc.BlendOp := AC_SRC_OVER;
  FPicture := TPicture.Create;
  FPicture.OnChange := PictureChanged;
  FImage := TBitmap.Create;
  FSplashes := TSplashes.Create(True);
end;

destructor TNLDSnakeImage.Destroy;
begin
  Stop;
  FreeAndNil(FSplashes);
  FImage.Free;
  FPicture.Free;
  inherited Destroy;
end;

function TNLDSnakeImage.IsPictureStored: Boolean;
begin
  Result := FGraphicFileName = '';
end;

procedure TNLDSnakeImage.Paint;
var
  DC: HDC;
  Brush: HBRUSH;
  R: TRect;
  I: Integer;
  MSecs: Cardinal;
  Pen: HPEN;
  Radius: Integer;

  procedure DrawFade;
  begin
    BeginPath(DC);
    Polygon(DC, FSplashes[I].FCoords[0], Length(FSplashes[I].FCoords));
    EndPath(DC);
    SelectClipPath(DC, RGN_COPY);
    FillRect(DC, R, Brush);
    FBlendFunc.SourceConstantAlpha := Round(255 * (MSecs / 1000));
    AlphaBlend(DC, 0, 0, Width, Height, FImage.Canvas.Handle, 0, 0, Width,
      Height, FBlendFunc);
  end;

  procedure DrawPolygon;
  begin
    BeginPath(DC);
    Polygon(DC, FSplashes[I].FCoords[0], Length(FSplashes[I].FCoords));
    EndPath(DC);
    SelectClipPath(DC, RGN_COPY);
    BitBlt(DC, 0, 0, Width, Height, FImage.Canvas.Handle, 0, 0, SRCCOPY);
    Pen := CreatePen(PS_SOLID, Round(4 * (MSecs - 1000) / 100), clBlack);
    DeleteObject(SelectObject(DC, Pen));
    BeginPath(DC);
    Polygon(DC, FSplashes[I].FCoords[0], Length(FSplashes[I].FCoords));
    EndPath(DC);
    WidenPath(DC);
    SelectClipPath(DC, RGN_COPY);
    BitBlt(DC, 0, 0, Width, Height, FImage.Canvas.Handle, 0, 0, SRCCOPY);
  end;

  procedure DrawCircle;
  begin
    SetLength(FSplashes[I].FCoords, 0);
    Radius := Min(Max(Width, Height),
      Round(0.75 * FMargin + 2 * (MSecs - 1000) / 100));
    BeginPath(DC);
    with FSplashes[I].FCenter do
      Arc(DC, X - Radius, Y - Radius, X + Radius, Y + Radius, X, 0, X, 0);
    EndPath(DC);
    SelectClipPath(DC, RGN_COPY);
    BitBlt(DC, 0, 0, Width, Height, FImage.Canvas.Handle, 0, 0, SRCCOPY);
  end;

begin
  if csDesigning in ComponentState then
  begin
    if FPicture.Graphic <> nil then
      BitBlt(Canvas.Handle, 0, 0, Width, Height, FImage.Canvas.Handle, 0, 0,
        SRCCOPY)
    else
    begin
      Canvas.Pen.Style := psDash;
      Canvas.Brush.Style := bsClear;
      Canvas.Rectangle(0, 0, Width, Height);
    end;
  end
  else if HasParent and (FPointCount > 0) then
  begin
    if (FSplashes.Count < 15) and (GetTickCount > (FPrevTick + 2000)) then
      Splash;
    DC := FBuffer.Canvas.Handle;
    Brush := CreateSolidBrush(TailColor);
    DeleteObject(SelectObject(DC, Brush));
    R := Rect(0, 0, Width, Height);
    FillRect(DC, R, Brush);
    Brush := CreateSolidBrush(HeadColor);
    DeleteObject(SelectObject(DC, Brush));
    SetPolyFillMode(DC, WINDING);
    for I := 0 to FSplashes.Count - 1 do
    begin
      MSecs := GetTickCount - FSplashes[I].FStartTick;
      if MSecs < 1001 then
        DrawFade
      else if MSecs < 20000 then
        DrawPolygon
      else
        DrawCircle;
      SelectClipRgn(DC, 0);
    end;
    DeleteObject(Brush);
    DeleteObject(Pen);
    inherited Paint;
    BitBlt(Canvas.Handle, 0, 0, Width, Height, DC, 0, 0, SRCCOPY);
  end
  else if HasParent and (FPointCount = 0) then
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := Color;
    Canvas.FillRect(Rect(0, 0, Width, Height));
  end;
end;

procedure TNLDSnakeImage.PictureChanged(Sender: TObject);
begin
  AdjustSize;
  UpdateImage;
end;

procedure TNLDSnakeImage.Resize;
begin
  UpdateImage;
  inherited Resize;
end;

procedure TNLDSnakeImage.SetGraphicFileName(const Value: String);
begin
  if FGraphicFileName <> Value then
  begin
    FGraphicFileName := Value;
    FPicture.LoadFromFile(Value);
  end;
end;

procedure TNLDSnakeImage.SetPicture(Value: TPicture);
begin
  FPicture.Assign(Value);
  FGraphicFileName := '';
end;

procedure TNLDSnakeImage.Splash;
begin
  if PtInRect(Rect(0, 0, Width, Height), FPoints[FHeadIndex]) then
  begin
    FSplashes.Add(TSplash.Create(FPoints[FHeadIndex], FMargin));
    FPrevTick := GetTickCount;
  end;
end;

procedure TNLDSnakeImage.Start;
begin
  FPrevTick := GetTickCount;
  inherited Start;
end;

procedure TNLDSnakeImage.Stop;
begin
  inherited Stop;
  if FSplashes <> nil then
    FSplashes.Clear;
  Invalidate;
end;

procedure TNLDSnakeImage.UpdateImage;
var
  R: TRect;
begin
  if FPicture.Graphic <> nil then
  begin
    R := Rect(0, 0, Width, Height);
    FImage.Width := Width;
    FImage.Height := Height;
    FImage.Canvas.Brush.Color := TailColor;
    FImage.Canvas.FillRect(R);
    R := FitRect(R, FPicture.Width, FPicture.Height, True);
    FImage.Canvas.StretchDraw(R, FPicture.Graphic);
    Invalidate;
  end;
end;

initialization
  Randomize;

end.
