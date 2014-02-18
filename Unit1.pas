unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, contnrs, jpeg, Math;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    FImages: TObjectList;
    FNamen: TStringList;
    FIsDragging: Boolean;
    FOldPos: TPoint;
    procedure MoveImage(x: Integer; n: Integer);
    //True wenn fertig
    function MoveImageWhenDelete(i, iMax: Integer; n: Integer; distance: Integer): Boolean;
    function CanMoveImage(x, n: Integer): Boolean;
    procedure OnStartDrag(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
    procedure OnDrag(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
    procedure OnEndDrag(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
  public
    procedure deletePicture(pIndex: Integer);
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
  //self.Height := round(TImage(FImages[0]).height+100);
  temp := TImage(self.FImages[self.FImages.Count-1]);
  temp.cursor := crHandPoint;
  temp.OnMouseDown := OnStartDrag;
  temp.OnMouseMove := OnDrag;
  temp.OnMouseUp := OnEndDrag;

end;

procedure TForm1.deletePicture(pIndex: Integer);
var i, iMax, distance: Integer;
    altImage, neuImage, tempImage: TImage;
    entfernenBildFertig, verschiebenBilderFertig: Boolean;
begin
  neuImage := TImage(self.FImages.Last);
  neuImage.Cursor := crHandPoint;
  neuImage.OnMouseDown := OnStartDrag;
  neuImage.OnMouseMove := OnDrag;
  neuImage.OnMouseUp := onEndDrag;

  altImage := TImage(self.FImages[pIndex]);
  altImage.Cursor := crHandPoint;
  altImage.OnMouseDown := nil;
  altImage.OnMouseMove := nil;
  altImage.OnMouseUp := nil;
  // Alte und neue Karte animieren

  if pIndex = self.FImages.Count-1 then
  begin
    distance := 0;
  end else
  begin
    neuImage := TImage(self.FImages[pIndex+1]);
    distance := neuImage.Left - altImage.Left;
  end;
  self.FNamen.Delete(pIndex);
  self.FImages.Delete(pIndex);
  iMax := 30;
  for i := pIndex to self.FImages.Count-1 do
  begin
    tempImage := TImage(self.FImages[i]);
    tempImage.tag := tempImage.left;
  end;
  i := 1;
  entfernenBildFertig := false;
  verschiebenBilderFertig := false;
  //Alte Position in Tag speichern, wird später gebraucht. Durch den Tag kann man auf ein Array verzichten
  if pIndex <= self.FImages.Count -1 then
  begin
    NeuImage := TImage(self.FImages[pIndex]);
    NeuImage.Tag := neuImage.Left;
  end;
  while not entfernenBildFertig or not verschiebenBilderFertig do
  begin
    altImage.Top := altImage.Top - 7;
    altImage.Left := altImage.Left + 1;
    if altImage.Top + altImage.Height <= 0 then
    begin
      entfernenBildFertig := true;
    end;
    verschiebenBilderFertig := self.moveImageWhenDelete(i, iMax, pIndex, distance);
    application.ProcessMessages;
    sleep(5);
    inc(i);
  end;
  altImage.Free;;
end;

function TForm1.MoveImageWhenDelete(i, iMax: Integer; n: Integer; distance: Integer): Boolean;
var tempImage: TImage;
    currentDistance, newIndex: Integer;
    temp: Boolean;
begin
  temp := false;
  if distance = 0 then
  begin
    result := true;
    exit;
  end;
  result := false;
  tempImage := TImage(self.FImages[n]);
  currentDistance := tempImage.tag - tempImage.left;
  if currentDistance < distance then
  begin
    tempImage.Left := tempImage.Tag - round(distance/ln(iMax+1)*ln(i+1));
    temp := true;
  end;
  currentDistance := tempImage.tag - tempImage.left;
  if currentDistance >= ((1.0/2.0)*distance) then
  begin
    if n <= self.FImages.Count-2 then
    begin
      newIndex :=  floor(Math.Power(Exp(1.0), (1*ln(iMax+1)/(2.0*distance)*distance)));
      result := self.MoveImageWhenDelete(i-newIndex+1, iMax, n+1,distance);
    end else
    begin
      if currentDistance >= distance then
      begin
        result := true;
      end;
    end;
  end else
  begin
    if not temp then
    begin
      result := true;
    end;
  end;
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

procedure TForm1.Button1Click(Sender: TObject);
begin
  self.deletePicture(StrToInt(edit1.Text));
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
    place, difference, temp, rounded: Integer;
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
      factor := 0.5;
      place := minVisible;
    end;
    if x > 0  then
    begin
      factor := 0.5;
      place := maxVisible;
    end;
    if ((abs(actualImage.Left - previousImage.Left) < place) and (x > 0)) or
      ((abs(actualImage.Left - previousImage.Left) > place) and (x < 0)) then
    begin
      difference := 0;
      if ((actualImage.Left + x - previousImage.Left) > place) and (x > 0) then
      begin
        temp := maxVisible - actualImage.Left + previousImage.Left;
        difference := -abs(x-temp);
        x := temp;
      end;
      if ((actualImage.Left + x - previousImage.Left) < place) and (x < 0) then
      begin
        temp := minVisible - actualImage.Left + previousImage.Left;
        difference := abs(x-temp-x);
        x := temp;
      end;
      TImage(self.FImages[n]).Left := TImage(self.FImages[n]).Left + x;
      if self.CanMoveImage(x, n-1) then
      begin
        if x < 0 then
        begin
          rounded := ceil(factor*x+difference);
        end else
        begin
          rounded := floor(factor*x+difference);
        end;
        self.MoveImage(rounded, n-1);
      end;
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
