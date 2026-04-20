unit Player;

interface

uses Types, IsoMap, Image, Sprite;

type
    PPlayer = ^TPlayer;
    TPlayer = object(TSprite)
        D: TDirection;
        Speed: Byte;
        OllieCycle: Byte;
        PushCycle: Byte;
        Map: PGameMap;
        LastTurn: LongInt;
        Sprites: array[TDirection] of PImage;
        DirtyRect: array[0..1] of TDirtyRect;
        MapX, MapY: Word;
        MapScroll: TCoordinate;

        constructor Init(TheMap: PGameMap; SpritesFilename: String);
        destructor Destroy;
        procedure Push;
        procedure Update(Page: Byte; Frame: LongInt); virtual;
        procedure Draw(Page: Byte); virtual;
        procedure Turn(Frame: LongInt; Steps: ShortInt);
        procedure Ollie;
    end;

implementation

uses Globals, ModeX, PCXImg;

const
     PushCycleLength = 52;
     PushCycleSteps: array[0..PushCycleLength - 1] of Byte = (
         3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
         2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
         1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
         0
     );

     OllieCycleLength = 23;
     OllieCycleSteps: array[0..OllieCycleLength - 1] of Byte = (
         0, 1, 3, 8, 15, 18, 18, 18, 18, 18, 18, 18, 18, 18, 15, 14, 13, 12, 10, 8, 3, 2, 0
     );

function HasCollision(Map: PGameMap; X1, Y1, X2, Y2: Word): Boolean;
var
   Tx1, Tx2, Ty1, Ty2: Word;
   X, Y: Word;
begin
     Tx1 := X1 div TileWidth;
     Ty1 := Y1 div TileHeight;
     Tx2 := X2 div TileWidth;
     Ty2 := Y2 div TileHeight;

     for Y := Ty1 to Ty2 do begin
         for X := Tx1 to Tx2 do begin
             if not Map^.IsWalkable(X, Y) then begin
                HasCollision := true;
                Exit;
             end;
         end;
     end;

     HasCollision := false;
end;

constructor TPlayer.Init(TheMap: PGameMap; SpritesFilename: String);
var
   Img: PCXImage;
begin
     inherited Init(0, 0, 0, 32, 32);

     Map := TheMap;

     Img.Init(SpritesFilename);

     Sprites[S] := Img.ImageAt(0, 0, 32, 32);
     Sprites[SW] := Img.ImageAt(32, 0, 32, 32);
     Sprites[W] := Img.ImageAt(64, 0, 32, 32);
     Sprites[NW] := Img.ImageAt(96, 0, 32, 32);
     Sprites[N] := Img.ImageAt(128, 0, 32, 32);
     Sprites[NE] := Img.ImageAt(160, 0, 32, 32);
     Sprites[E] := Img.ImageAt(192, 0, 32, 32);
     Sprites[SE] := Img.ImageAt(224, 0, 32, 32);

     Img.Destroy;

     New(DirtyRect[0].Image, New(32, 32));
     New(DirtyRect[1].Image, New(32, 32));

     D := S;
     Speed := 0;
     OllieCycle := 0;
     PushCycle := 0;
     LastTurn := 0;
end;

destructor TPlayer.Destroy;
begin
     Dispose(Sprites[S], Destroy);
     Dispose(Sprites[SW], Destroy);
     Dispose(Sprites[W], Destroy);
     Dispose(Sprites[NW], Destroy);
     Dispose(Sprites[N], Destroy);
     Dispose(Sprites[NE], Destroy);
     Dispose(Sprites[E], Destroy);
     Dispose(Sprites[SE], Destroy);

     Dispose(DirtyRect[0].Image, Destroy);
     Dispose(DirtyRect[1].Image, Destroy);
end;

procedure TPlayer.Push;
begin
     {PushCycle := PushCycleLength;}
     PushCycle := 3;
end;

procedure TPlayer.Turn(Frame: LongInt; Steps: ShortInt);
var
   Next: ShortInt;
begin
     if Frame - LastTurn < 10 then Exit;

     Next := (Ord(D) + Steps) mod 8;

     if Next < 0 then
        D := TDirection(8 + Next)
     else
         D := TDirection(Next);

     LastTurn := Frame;
end;

procedure TPlayer.Ollie;
begin
     if OllieCycle > 0 then Exit;

     OllieCycle := OllieCycleLength;
end;

procedure TPlayer.Update;
var
   Next: TCoordinate;
begin
     Next.X := MapX;
     Next.Y := MapY;

     if (Frame mod 8 = 0) and (Z > 0) then Dec(Z);

     with Next do begin
          case D of
               N: Dec(Y, Speed);
               NE: begin
                   Inc(X, Speed);
                   Dec(Y, Speed);
               end;
               E: Inc(X, Speed);
               SE: begin
                   Inc(X, Speed);
                   Inc(Y, Speed);
               end;
               S: Inc(Y, Speed);
               SW: begin
                   Dec(X, Speed);
                   Inc(Y, Speed);
               end;
               W: Dec(X, Speed);
               NW: begin
                   Dec(X, Speed);
                   Dec(Y, Speed);
               end;
          end;
     end;

     {if (Z < 8) and (HasCollision(Map, Next.X + 8, Next.Y + 8, Next.X + 24, Next.Y + 24)) then begin
        Exit;
     end;}

     if OllieCycle > 0 then begin
        Z := OllieCycleSteps[OllieCycleLength - OllieCycle];
        Dec(OllieCycle);
     end;

     if PushCycle > 0 then begin
        Speed := PushCycleSteps[PushCycleLength - PushCycle];
        Dec(PushCycle);
     end;

     MapX := Next.X;
     MapY := Next.Y;

     if MapX < 16 then MapX := 16;
     if MapY < 16 then MapY := 16;
     if MapX > (Map^.Width * TileWidth - 48) then
        MapX := Map^.Width * TileWidth - 48;
     if MapY > (Map^.Height * TileHeight - 48) then
        MapY := Map^.Height * TileHeight - 48;

     X := MapX - ScrollOffset[Page].X;
     Y := MapY - ScrollOffset[Page].Y;
end;

procedure TPlayer.Draw(Page: Byte);
begin
     X_DrawAlpha(Page, X, Y - Z, (MapY + 32) div 8, Sprites[D]);
end;


end.