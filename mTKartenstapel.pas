unit mTKartenstapel;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, contnrs, jpeg, Math, mmsystem;

type

  TLegeKarteHandler = function(var destinationImage: TImage): Boolean of object;

  TKartenstapel = class(TObject)
  private
    FTop: Integer;
    FLeft: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FMinVisiblePixel: Integer;
    FMaxVisiblePixel: Integer;

    FLegeKarteHandler: TLegeKarteHandler;
    FImages: TObjectList;
    FNamen: TStringList;
    FIsDragging: Boolean;
    FOldPos: TPoint;
    FSelectedImage: TImage;
    FTest: Integer;
    FWirdGelegt: Boolean;
    FLastMovement: Integer;
    FAbklingenTimer: TTimer;
    FIsDeleting: Boolean;
    FBackCardName: string;
    FIsSelecting: Boolean;
   // FOldImageTop: Integer;
    FIsReallyDragging: Boolean;
    FParentForm: TForm;
   // procedure setupKartenStapel(LegeKarteHandler: TNotifyEvent);
    procedure MoveImage(x: Integer; n: Integer);
    procedure LegeKarte(Sender: TObject);
    function logarithmAnimation(x, distance, xMax: Integer): double;
    //True wenn fertig
    function MoveImageWhenDelete(i, iMax: Integer; n: Integer; distance: Integer): Boolean;
    function CanMoveImage(x, n: Integer): Boolean;
    procedure AbklingenLassen(Sender: TObject);
    procedure OnStartDrag(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
    procedure OnDrag(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
    procedure OnEndDrag(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
    procedure SelectImage(Sender: TObject);
    procedure deletePicture(pIndex: Integer; destinationImage: TImage);
  public
    constructor Create(pParentForm: TForm; pLegeKarteHandler: TLegeKarteHandler; left, top, width, height: Integer);
    procedure setKarten(pKarten: TStringList; Animate: Boolean);
    property backCardName: string read FBackCardName write FBackCardName;
  end;

implementation

const minVisibleRelation = 1.0/6.0;
      maxVisibleRelation = 0.4;

function TKartenstapel.logarithmAnimation(x: Integer; distance: Integer; xMax: Integer): double;
begin
  result := distance/ln(xMax+1)*ln(x+1);
end;

procedure TKartenstapel.setKarten(pKarten: TStringList; Animate: Boolean);
var i: Integer;
    temp: TImage;
    posX: Integer;
begin
  self.FNamen := pKarten;

  self.FSelectedImage := nil;
  FImages := TObjectList.Create;
  FImages.OwnsObjects := False;
  self.FIsSelecting := false;

  posX := self.FLeft;
  FIsDragging := False;
  self.FIsReallyDragging := False;

  self.FMinVisiblePixel := round(self.FWidth * minVisibleRelation);
  self.FMaxVisiblePixel := round(self.FHeight * maxVisibleRelation);

  for i := 0 to 9 do
  begin
    temp := TImage.Create(self.FParentForm);
   // temp.Height := round(105*1.5);
    temp.Width :=self.FWidth;
    //temp.Height := round(temp.Width * 105.0/73);
    temp.Height := self.FHeight;
    temp.Picture.LoadFromFile('Karten/' + FNamen[i] + '.jpg');
   // temp.Visible := true;
    temp.Parent := self.FParentForm;
    temp.Stretch := true;
    temp.Left := posX;
    temp.Top := self.FTop;
    temp.OnClick := SelectImage;
    posX := posX + round((1/3) * temp.Width);
    FImages.Add(temp);
    temp.OnDblClick := LegeKarte;
  end;

 // self.Width := posX + 25 + TImage(FImages[0]).width;
  //self.Height := round(TImage(FImages[0]).height+100);
  temp := TImage(self.FImages[self.FImages.Count-1]);
  temp.cursor := crHandPoint;
  temp.OnMouseDown := OnStartDrag;
  temp.OnMouseMove := OnDrag;
  temp.OnMouseUp := OnEndDrag;

  self.FWirdGelegt := false;
  self.FLastMovement := 0;

  self.FAbklingenTimer := TTimer.Create(self.FParentForm);
  self.FAbklingenTimer.Interval := 45;
  self.FAbklingenTimer.Enabled := false;
  self.FAbklingenTimer.OnTimer := AbklingenLassen;
  self.FIsDeleting := false;
end;

procedure TKartenstapel.LegeKarte(Sender: TObject);
var index: integer;
    destImage: TImage;
begin
  destImage := nil;
  if not self.FIsReallyDragging and self.FLegeKarteHandler(destImage) then
  begin
    index := self.FImages.IndexOf(sender);
    self.FWirdGelegt := true;
  if self.FSelectedImage <> nil then
  begin
    self.FSelectedImage.Top := TImage(self.FImages[(index+1) mod (self.FImages.Count)]).Top;
    self.FSelectedImage := nil;
  end;
  if Sender = self.FImages.Last then
  begin
    //Drag beenden
    self.OnEndDrag(sender, mbLeft, [], 0, 0);
  end;
  self.deletePicture(index, destImage);
  end;
end;

constructor TKartenstapel.Create(pParentForm: TForm; pLegeKarteHandler: TLegeKarteHandler; left, top, width, height: Integer);
begin
  self.FParentForm := pParentForm;
  self.FParentForm.DoubleBuffered := true;
  self.FLegeKarteHandler := pLegeKarteHandler;
  self.FTop := top;
  self.FLeft := left;
  self.FHeight := height;
  self.FWidth := width;
end;

procedure TKartenstapel.SelectImage(Sender: TObject);
var
  i, distance, iMax: Integer;
  image: TImage;
begin
  if not self.FIsReallyDragging and not self.FIsDeleting and (self.FImages.Count > 1) then
  begin
  self.FIsSelecting := true;
  FTest := getTickCount;
  sndPlaySound(pChar('Sound.wav'), SND_ASYNC);
  self.FWirdGelegt := false;
  image := TImage(sender);
  iMax := 30;
  distance := 30;
  image.Tag := image.Top;
  if self.FSelectedImage <> nil then
  begin
    self.FSelectedImage.Tag := self.FSelectedImage.Top;
  end;
  for i := 1 to iMax do
  begin
    if not self.FWirdGelegt then
    begin
      if sender <> self.FSelectedImage then
      begin
        image.Top := image.Tag - round(self.logarithmAnimation(i, distance, iMax));
      end;
    end;
      if self.FSelectedImage <> nil then
      begin
        self.FSelectedImage.Top := self.FSelectedImage.tag + round(self.logarithmAnimation(i, distance, iMax));
      end;
      sleep(5);
      application.ProcessMessages;
  end;
  self.FIsSelecting := false;
  if not self.FWirdGelegt and (sender <> self.FSelectedImage) then
  begin
    self.FSelectedImage := image;
  end else
  begin
    self.FSelectedImage := nil;
  end;
  self.FWirdGelegt := false;
  end;
end;

procedure TKartenstapel.deletePicture(pIndex: Integer; destinationImage: TImage);
var i, k, iMax, kMax, distance, startTop: Integer;
    altImage, neuImage, tempImage(*, destinationImage*): TImage;
    entfernenBildFertig, verschiebenBilderFertig: Boolean;
    a, b, c, temp: double;
begin
if not self.FIsDeleting then
begin
  self.FIsDeleting := true;
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
  if self.FImages.Count > 0 then
  begin
    neuImage := TImage(self.FImages.Last);
    neuImage.Cursor := crHandPoint;
    neuImage.OnMouseDown := OnStartDrag;
    neuImage.OnMouseMove := OnDrag;
    neuImage.OnMouseUp := onEndDrag;
  end;
  iMax := 30;
  for i := pIndex to self.FImages.Count-1 do
  begin
    tempImage := TImage(self.FImages[i]);
    tempImage.tag := tempImage.left;
  end;
  i := 1;
  k := 0;
  entfernenBildFertig := false;
  verschiebenBilderFertig := false;
  if self.FImages.Count = 0 then
  begin
    verschiebenBilderFertig := true;
  end;
  //Alte Position in Tag speichern, wird später gebraucht. Durch den Tag kann man auf ein Array verzichten
  if pIndex <= self.FImages.Count -2 then
  begin
    NeuImage := TImage(self.FImages[pIndex]);
    NeuImage.Tag := neuImage.Left;
  end;
  startTop := altImage.Top;
  altImage.Tag := altImage.Top;
  kMax := (destinationImage.Left - altImage.Left);
  a := (-5*destinationImage.Height-destinationImage.Top - altImage.Top)/power(kMax, 2);
 // a := (-4*destinationImage.Height + 6 * altImage.Top + 2 * destinationImage.Top)/power(kMax, 2);
  b := (destinationImage.top - altImage.top - a * power(kMax, 2))/kMax;
  c := altImage.top;
  while not entfernenBildFertig or not verschiebenBilderFertig do
  begin
    //temp := k/kMax;
    altImage.Top := altImage.Tag - round(a * k*k + b*k + c)(*+ round(temp*10)*);
    altImage.Left := altImage.Left + 12;
    inc(k, 12);
    if k > kMax then
    begin
      entfernenBildFertig := true;
    end;
    if self.FImages.Count > 0 then
    begin
      verschiebenBilderFertig := self.moveImageWhenDelete(i, iMax, pIndex, distance);
    end;
    application.ProcessMessages;
    sleep(4);
    inc(i);
  end;
  destinationImage.Picture.Assign(altImage.Picture);
  altImage.Free;
  self.FSelectedImage := nil;
  self.FIsDeleting := false;
end;
end;

function TKartenstapel.MoveImageWhenDelete(i, iMax: Integer; n: Integer; distance: Integer): Boolean;
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
    tempImage.Left := tempImage.Tag - round(self.logarithmAnimation(i, distance, iMax));
    temp := true;
  end;
  currentDistance := tempImage.tag - tempImage.left;
  if currentDistance >= ((1.0/2.0)*distance) then
  begin
    if n <= self.FImages.Count-2 then
    begin
      newIndex :=  floor(Exp(1*ln(iMax+1)/(2.0*distance)*distance));
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

procedure TKartenstapel.OnStartDrag(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  self.FIsDragging := True;
  getCursorPos(FOldPos);
end;

procedure TKartenstapel.AbklingenLassen(Sender: TObject);
var move, i: Integer;
    k, doubleMove: double;
begin
 //Bewegung abklingen lassen
 TTimer(sender).enabled := false;
 k := 0.09;
 move := self.FLastMovement;
 i := 1;
 while abs(move) > 0 do
 begin
   doubleMove := (self.FLastMovement * EXP(-k*i));
   if doubleMove > 0 then
   begin
     move := floor(doubleMove);
   end else
   begin
     move := ceil(doubleMove);
   end;
   inc(i);
   self.MoveImage(move, self.FImages.Count-1);
   application.processMessages;
   sleep(10);
 end;
end;

procedure TKartenstapel.OnDrag(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var NewPos: TPoint;
begin
  if self.FIsDragging and not self.FIsSelecting then
  begin
    getCursorPos(newPos);
    if abs(NewPos.X - FOldPos.X) >= 2 then
    begin
      self.FIsReallyDragging := True;
      self.FAbklingenTimer.Enabled := false;
      self.FLastMovement := Newpos.X - FOldPos.X;
      self.MoveImage(NewPos.X - FOldPos.X, self.FImages.Count-1);
      FOldPos := NewPos;
      self.FAbklingenTimer.Enabled := true;
    end;
  end;
end;

procedure TKartenstapel.OnEndDrag(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  self.FIsDragging := False;
  self.FIsReallyDragging := False;
end;

function TKartenstapel.CanMoveImage(x, n: Integer): Boolean;
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
           place := self.FMinVisiblePixel;
          end;
          if x > 0  then
          begin
            place := self.FMaxVisiblePixel;
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

procedure TKartenstapel.MoveImage(x: Integer; n: Integer);
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
      place := self.FMinVisiblePixel;
    end;
    if x > 0  then
    begin
      factor := 0.5;
      place := self.FMaxVisiblePixel;
    end;
    if ((abs(actualImage.Left - previousImage.Left) < place) and (x > 0)) or
      ((abs(actualImage.Left - previousImage.Left) > place) and (x < 0)) then
    begin
      difference := 0;
      if ((actualImage.Left + x - previousImage.Left) > place) and (x > 0) then
      begin
        temp := self.FMaxVisiblePixel - actualImage.Left + previousImage.Left;
        difference := -abs(x-temp);
        x := temp;
      end;
      if ((actualImage.Left + x - previousImage.Left) < place) and (x < 0) then
      begin
        temp := self.FMinVisiblePixel - actualImage.Left + previousImage.Left;
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
          x := self.FMaxVisiblePixel - actualImage.Left + previousImage.Left;
        end;
        if ((actualImage.Left + x - previousImage.Left) < place) and (x < 0) then
        begin
          x := self.FMinVisiblePixel - actualImage.Left + previousImage.Left;
        end;
        TImage(self.FImages[n]).Left := TImage(self.FImages[n]).Left + x;
      end;
    end;
  end;
end;

end.
