unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, contnrs, jpeg, mTKartenstapel;

type

  TForm1 = class(TForm)
    Stich1: TImage;
    Stich4: TImage;
    Stich2: TImage;
    Stich3: TImage;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FKartenstapel: TKartenstapel;
    function shouldDeletePicture(var destImage: TImage): Boolean;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

function TForm1.shouldDeletePicture(var destImage: TImage): Boolean;
begin
  destImage := stich1;
  sleep(100);
  result := true;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var Namen: TSTringList;
begin
  self.Timer1.Enabled := false;
  Namen := TStringList.Create;
  Namen.Add('HE10');
  Namen.Add('KR10');
  Namen.Add('KA10');
  Namen.Add('PI10');
  Namen.Add('KRD');
  Namen.Add('HED');
  Namen.Add('KAB');
  Namen.Add('KRB');
  Namen.Add('PIB');
  Namen.Add('HEB');
  self.FKartenstapel.setKarten(Namen, true);
end;

procedure TForm1.FormCreate(Sender: TObject);
var width: integer;
begin
  width := 120;
  self.FKartenStapel := TKartenstapel.Create(self, shouldDeletePicture, 25, 40, width, round(width * (105.0/73)));
  self.FKartenstapel.setBackCards;

  self.Stich1.Picture.LoadFromFile('Karten/' + 'Back' + '.jpg');
  self.Stich2.Picture.LoadFromFile('Karten/' + 'Back' + '.jpg');
  self.Stich3.Picture.LoadFromFile('Karten/' + 'Back' + '.jpg');
  self.Stich4.Picture.LoadFromFile('Karten/' + 'Back' + '.jpg');
end;

end.
