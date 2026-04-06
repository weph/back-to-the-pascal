unit TopDown;

interface

uses
    Globals,
    Types,
    MapRendr,
    Image,
    GameMap,
    Sprite;

type
    TTopDownMapRenderer = object(TMapRenderer)
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
            Tiles: array[1..255] of PImage;
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
   TilePositions: array[0..MapRows-1,0..MapCols-1] of TCoordinate;

constructor TTopDownMapRenderer.Init(_Map: PGameMap; TilesetFilename: String);
var
   Img: PCXImage;
   i, X, Y, Page: Byte;
begin
     inherited Init(_Map);

     Img.Init(TilesetFilename);
     for i := 0 to 255 do begin
         SetColor(i, Img.Palette[i]);
     end;

     for Y := 0 to 11 do begin
         for X := 0 to 19 do begin
             Tiles[Y * 20 + X + 1] := Img.ImageAt(X * 16, Y * 16, 16, 16);
         end;
     end;

     Img.Destroy;
end;

destructor TTopDownMapRenderer.Destroy;
var
   X, Y: Byte;
begin
     for Y := 0 to 11 do begin
         for X := 0 to 19 do begin
             Dispose(Tiles[Y * 20 + X + 1], Destroy);
         end;
     end;
end;

procedure TTopDownMapRenderer.DrawPartialMap(
    Page: Byte;
    Offset: TCoordinate;
    StartLayer, EndLayer: Byte;
    StartCol, EndCol: Word;
    StartRow, EndRow: Word;
    Start: TCoordinate
);
var
   Z, Col, Row: Word;
   Tile: Byte;
begin
     for Z := StartLayer to EndLayer do begin
         for Row := StartRow to EndRow do begin
             for Col := StartCol to EndCol do begin
                 Tile := Map^.TileAt(Offset.X + Col, Offset.Y + Row, Z);

                 if Tile = 0 then continue;

                 with TilePositions[Row][Col] do begin
                      X_Draw(Page, Start.X + X, Start.Y + Y, Tiles[Tile]);
                 end;
             end;
         end;
     end;
end;

procedure InitTilePositions;
var
   Row, Col: Word;
begin
     for Row := 0 to MapRows - 1 do begin
         for Col := 0 to MapCols - 1 do begin
             with TilePositions[Row][Col] do begin
                  X := Col * TileWidth;
                  Y := Row * TileHeight;
             end;
         end;
     end;
end;

begin
     InitTilePositions;
end.