unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, contnrs, jpeg;

type
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    FImages: TObjectList;
    FNamen: TStringList;
    FIsDragging: Boolean;
    FOldPos: TPoint;
    procedure MoveImage(x: Integer; n: Integer);
    function CanMoveImage(x, n: Integer): Boolean;
    procedure OnStartDrag(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
    procedure OnDrag(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
    procedure OnEndDrag(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

const minVisible = 20;
      maxVisible = 65;

procedure TForm1.FormCreate(Sender: TObject);
var i: Integer;
    temp: TImage;
    posX: Integer;
begin
  self.DoubleBuffered := true;
  FNamen := TStringList.Create;
  FNamen.Add('HE10');
  FNamen.Add('KR10');
  FNamen.Add('KA10');
  FNamen.Add('PI10');
  FNamen.Add('KRD');
  FNamen.Add('HED');
  FNamen.Add('KAB');
  FNamen.Add('KRB');
  FNamen.Add('PIB');
  FNamen.Add('HEB');

  FImages := TObjectList.Create;
  FImages.OwnsObjects := False;

  posX := 25;
  FIsDragging := False;

  for i := 0 to 9 do
  begin
    temp := TImage.Create(self);
    temp.Height := round(105*1.5);
    temp.Width := round(73*1.5);
    temp.Picture.LoadFromFile('Karten/' + FNamen[i] + '.jpg');
    temp.Visible := true;
    temp.Parent := self;
    temp.Stretch := true;
    temp.Left := posX;
    temp.Top := 25;
    posX := posX + round((1/3) * temp.Width);
    FImages.Add(temp);
  end;

(*  for i := 0 to 9 do
  begin
    if (i < (self.FImages.Count-1)/2) then
    begin
      temp := TImage(self.FImages[i]);
      temp.Top := 25 - 5*i;
    end;
    if (i > (self.FImages.Count-1)/2) then
    begin
      temp := TImage(self.FImages[i]);
      temp.Top := 25 - 5*(self.FImages.Count-1-i);
    end;    
    
  end; *)
 // self.Width := posX + 25 + TImage(FImages[0]).width;
  self.Height := round(TImage(FImages[0]).height+100);
  temp := TImage(self.FImages[self.FImages.Count-1]);
  temp.cursor := crHandPoint;
  temp.OnMouseDown := OnStartDrag;
  temp.OnMouseMove := OnDrag;
  temp.OnMouseUp := OnEndDrag;
end;

procedure TForm1.OnStartDrag(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  self.FIsDragging := True;
  getCursorPos(FOldPos);
  OutputdebugString('Start drag');
end;

procedure TForm1.OnDrag(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var NewPos: TPoint;
begin
  if self.FIsDragging then
  begin
    getCursorPos(newPos);
    if abs(NewPos.X - FOldPos.X) >= 2 then
    begin
      OutputdebugString('Moving');
      self.MoveImage(NewPos.X - FOldPos.X, self.FImages.Count-1);
      FOldPos := NewPos;
    end;
  end;
end;

procedure TForm1.OnEndDrag(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  self.FIsDragging := False;
  OutputdebugString('Stop Drag');
end;

function TForm1.CanMoveImage(x, n: Integer): Boolean;
var actualImage, previousImage: TImage;
    place: Integer;
begin
  if x = 0 then result := false
  else
  begin
    if (n >= 1) then
    begin
      actualImage := TImage(self.FImages[n]);
      previousImage := TImage(self.FImages[n-1]);
        if n = 0 then
        begin
          result := false;
        end else
        begin
          place := 0;
          if x <= 0 then
          begin
           place := minVisible;
          end;
          if x > 0  then
          begin
            place := maxVisible;
          end;
          result := ((abs(actualImage.Left - previousImage.Left) < place) and (x > 0)) or
             ((abs(actualImage.Left - previousImage.Left) > place) and (x < 0)) or
             self.CanMoveImage(x, n-1);
        end;
    end else
    begin
      result := false;
    end;
  end;
end;

procedure TForm1.MoveImage(x: Integer; n: Integer);
var actualImage, previousImage: TImage;
    factor: double;
    place: Integer;
begin
  x := round(x * 1);
  if (n >= 1) then
  begin
    actualImage := TImage(self.FImages[n]);
    previousImage := TImage(self.FImages[n-1]);
    place := 0;
    factor := 0;
    if x <= 0 then
    begin
      factor := 0.25;
      place := minVisible;
    end;
    if x > 0  then
    begin
      factor := 0.25;
      place := maxVisible;
    end;
    if ((abs(actualImage.Left - previousImage.Left) < place) and (x > 0)) or
      ((abs(actualImage.Left - previousImage.Left) > place) and (x < 0)) then
    begin
      if ((actualImage.Left + x - previousImage.Left) > place) and (x > 0) then
      begin
        x := maxVisible - actualImage.Left + previousImage.Left;
      end;
      if ((actualImage.Left + x - previousImage.Left) < place) and (x < 0) then
      begin
        x := minVisible - actualImage.Left + previousImage.Left;
      end;
      TImage(self.FImages[n]).Left := TImage(self.FImages[n]).Left + x;
      self.MoveImage(round(factor*x), n-1);
    end else
    begin
      if self.CanMoveImage(x, n-1) then
      begin
        self.MoveImage(x, n-1);
        if ((actualImage.Left + x - previousImage.Left) > place) and (x > 0) then
        begin
          x := maxVisible - actualImage.Left + previousImage.Left;
        end;
        if ((actualImage.Left + x - previousImage.Left) < place) and (x < 0) then
        begin
          x := minVisible - actualImage.Left + previousImage.Left;
        end;
        TImage(self.FImages[n]).Left := TImage(self.FImages[n]).Left + x;
      end;
    end;
  end;
end;

end.
