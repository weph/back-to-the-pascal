unit Iso;

interface

uses
    Globals,
    Types,
    MapRendr,
    Image,
    GameMap,
    Sprite;

type
    TTile = record
        Top: PImage;
        Bottom: PImage;
        Left: PImage;
        Right: PImage;
    end;


    TIsometricMapRenderer = object(TMapRenderer)
        public
            constructor Init(_Map: PGameMap; TilesetFilename: String);
            destructor Destroy;
            procedure DrawPartialMap(
                Page: Byte;
                Offset: TCoordinate;
                StartLayer, EndLayer: Byte;
                StartCol, EndCol: Word;
                StartRow, EndRow: Word;
                Start: TCoordinate
            ); virtual;

        private
            Tiles: array[1..255] of TTile;
    end;

implementation

uses
    PCXImg,
    VGA,
    ModeX;

const
     MapCols = LogicalScreenWidth div TileWidth;
     MapRows = LogicalScreenHeight div TileHeight;

var
   TilePositions: array[0..16,0..MapRows-1,0..MapCols-1] of TCoordinate;

constructor TIsometricMapRenderer.Init(_Map: PGameMap; TilesetFilename: String);
var
   Img: PCXImage;
   i, X, Y, Page: Byte;
begin
     inherited Init(_Map);

     Img.Init(TilesetFilename);
     for i := 0 to 255 do begin
         SetColor(i, Img.Palette[i]);
     end;

     Tiles[1].Top := Img.ImageAt(0, 0, 32, 8);
     Tiles[1].Bottom := Img.ImageAt(0, 8, 32, 8);
     Tiles[1].Left := Img.ImageAt(0, 0, 16, 16);
     Tiles[1].Right := Img.ImageAt(16, 0, 16, 16);

     Tiles[2].Top := Img.ImageAt(32, 0, 32, 8);
     Tiles[2].Bottom := Img.ImageAt(32, 8, 32, 8);
     Tiles[2].Left := Img.ImageAt(32, 0, 16, 16);
     Tiles[2].Right := Img.ImageAt(48, 0, 16, 16);

     Tiles[3].Top := Img.ImageAt(64, 0, 32, 8);
     Tiles[3].Bottom := Img.ImageAt(64, 8, 32, 16);
     Tiles[3].Left := Img.ImageAt(64, 0, 16, 24);
     Tiles[3].Right := Img.ImageAt(80, 0, 16, 24);

     Tiles[4].Top := Img.ImageAt(96, 0, 32, 8);
     Tiles[4].Bottom := Img.ImageAt(96, 8, 32, 16);
     Tiles[4].Left := Img.ImageAt(96, 0, 16, 24);
     Tiles[4].Right := Img.ImageAt(114, 0, 16, 24);

     Img.Destroy;
end;

destructor TIsometricMapRenderer.Destroy;
var
   i: Byte;
begin
     for i := 1 to 2 do begin
         Dispose(Tiles[i].Top);
         Dispose(Tiles[i].Bottom);
         Dispose(Tiles[i].Left);
         Dispose(Tiles[i].Right);
     end;
end;

procedure TIsometricMapRenderer.DrawPartialMap(
    Page: Byte;
    Offset: TCoordinate;
    StartLayer, EndLayer: Byte;
    StartCol, EndCol: Word;
    StartRow, EndRow: Word;
    Start: TCoordinate
);
var
   Col, Row, TCol, TRow, Layer: Word;
   SX, SY: LongInt;
   TileTop, TileLeft, TileRight, TileBottom: Byte;
   Z: Byte;
begin
     {StartLayer := 1;}
     {EndLayer := 0;}
     for Layer := EndLayer downto StartLayer do begin
         for Row := StartRow to EndRow do begin
             for Col := StartCol to EndCol do begin
                 with TilePositions[Layer,Row,Col] do begin
                     TCol := Offset.X + Col + 1;
                     TRow := (Offset.Y + Row) shl 1;
                     TileTop := Map^.TileAt(TCol, TRow, Layer);
                     TileLeft := Map^.TileAt(TCol - 1, TRow + 1, Layer);
                     TileRight := Map^.TileAt(TCol, TRow + 1, Layer);
                     TileBottom := Map^.TileAt(TCol, TRow + 2, Layer);

                     SX := X;
                     SY := Y;

                     If (Sx < 0) or (Sy < 0) then continue;

                     Z := Row * 2;
                     if Layer > 0 then Inc(Z, Layer + 1);

                     if TileBottom <> 0 then begin
                        X_DrawAlphaZ(
                            Page,
                            SX,
                            SY + 8,
                            Z + 2,
                            Tiles[TileBottom].Top
                        );
                     end;

                     if TileRight <> 0 then begin
                         X_DrawAlphaZ(
                            Page,
                            SX + 16,
                            SY,
                            Z + 1,
                            Tiles[TileRight].Left
                        );
                     end;

                     if TileLeft <> 0 then begin
                        X_DrawAlphaZ(
                            Page,
                            SX,
                            SY,
                            Z + 1,
                            Tiles[TileLeft].Right
                        );
                     end;

                     if TileTop <> 0 then begin
                        X_DrawAlphaZ(
                            Page,
                            SX,
                            SY,
                            Z,
                            Tiles[TileTop].Bottom
                        );
                     end;
                 end;
             end;
         end;
     end;

     {for Col := StartCol to EndCol do begin
         for Row := StartRow to EndRow do begin
             with TilePositions[1,Row,Col] do begin
                 SX := Start.X + X;
                 SY := Start.Y + Y;

                 X_DrawRect(Page, SX, SY, SX + 32, SY + 16, 0);
             end;
         end;
     end;}
end;

procedure InitTilePositions;
var
   Col, Row, Layer: Word;
begin
     for Layer := 0 to 16 do begin
         for Col := 0 to MapCols-1 do begin
             for Row := 0 to MapRows-1 do begin
                 TilePositions[Layer,Row,Col].X := Col * TileWidth;
                 TilePositions[Layer,Row,Col].Y := Row * TileHeight - Layer * (TileHeight div 2);
             end;
         end;
     end;
end;

begin
     InitTilePositions;
end.