program BackToThePascal;
uses Crt, Strings;

type
    VideoBuffer = Array[0..63999] of Byte;

const
     ScreenWidth = 320;
     ScreenHeight = 200;
     TileWidth = 8;
     TileHeight = 8;
     MapWidth = 80;
     MapHeight = 25;

     Map: Array[0..(MapWidth * MapHeight)-1] of Byte = (
2,0,1,1,0,1,1,1,0,1,1,1,1,0,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,2,
3,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,4,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,

0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,

1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
     );

var
   i: Word;
   Running: Boolean;
   Tile: Array[0..4] of Array[0..63] of Byte;
   Buffer: ^VideoBuffer;
   MapBuffer: ^VideoBuffer;
   Key: Char;
   MapStartX: Byte;
   X: Integer;
   Direction: Integer;
   Auto: Boolean;
   Speed: Byte;

procedure CopyToBuffer(Source: Pointer; X, Y, Width, Height: Word);
var
   Tx, Ty: Byte;
   Video: PChar;
   Row: PChar;
   SrcSeg, SrcOfs, DstSeg, DstOfs: Word;
begin
     SrcSeg := Seg(Source^);
     SrcOfs := Ofs(Source^);

     DstSeg := Seg(Buffer^);
     DstOfs := Ofs(Buffer^) + (Y * ScreenWidth + X);

     for Ty := 0 to Height - 1 do
     begin
          Video := Ptr(SrcSeg, SrcOfs + Ty * Width);
          Row := Ptr(DstSeg, DstOfs + Ty * ScreenWidth);
          Move(Video^, Row^, Width);
     end;
end;

procedure SetVideoMode(Mode: Byte);
begin
     asm
        mov ah, 0
        mov al, Mode
        int 10h
     end;
end;

procedure DrawTile(X, Y: Word; Tile: Array of Byte);
var
   Tx, Ty: Byte;
   Video: PChar;
   Row: PChar;
begin
     if (X < ScreenWidth) then
          CopyToBuffer(@Tile, X, Y, TileWidth, TileHeight);
end;

procedure UpdateScreen;
var
   Y: Byte;
   Video: Array[0..63999] of Byte absolute $a000:$0000;
   Source, Dest: Pointer;
   XOffset: Word;
begin
     XOffset := X mod TileWidth;

     for Y := 0 to ScreenHeight - 1 do
     begin
          Source := Ptr(Seg(Buffer^), Ofs(Buffer^) + Y * ScreenWidth + XOffset);
          Dest := Ptr(Seg(Video), Ofs(Video) + Y * ScreenWidth + TileWidth);
          Move(Source^, Dest^, 304);
     end;
end;

procedure DrawMap;
var
   x, y: Byte;
begin
     for y := 0 to MapHeight - 1 do
         for x := MapStartX to MapStartX + 39 do
             DrawTile((x - MapStartX) * TileWidth, y * TileHeight, Tile[Map[y * MapWidth + x]]);
end;

procedure UpdateMap;
var
   Cx, Cy: Byte;
   Source, Dest: Pointer;
   NextMapStartX, TileOffset, Columns: Byte;
   CopyWidth, SourceOffset, DestOffset, DrawPosition: Word;
begin
     NextMapStartX := X div TileWidth;

     if MapStartX = NextMapStartX then exit;

     Columns := Abs(NextMapStartX - MapStartX);

     if NextMapStartX > MapStartX then
     begin
          SourceOffset := Columns * TileWidth;
          DestOffset := 0;
          TileOffset := 40 - Columns;
          DrawPosition := TileOffset * TileWidth;
     end
     else
     begin
          SourceOffset := 0;
          DestOffset := Columns * TileWidth;
          TileOffset := Columns;
          DrawPosition := 0;
     end;

     MapStartX := NextMapStartX;

     CopyWidth := ScreenWidth - Columns * TileWidth;

     for i := 0 to 63999 do
         MapBuffer^[i] := 0;

     for Cy := 0 to ScreenHeight do
     begin
          Source := Ptr(Seg(Buffer^), Ofs(Buffer^) + Cy * ScreenWidth + SourceOffset);
          Dest := Ptr(Seg(MapBuffer^), Ofs(MapBuffer^) + Cy * ScreenWidth + DestOffset);
          Move(Source^, Dest^, CopyWidth);
     end;

     Move(MapBuffer^, Buffer^, 64000);

     for Cy := 0 to MapHeight - 1 do
         for Cx := 0 to Columns - 1 do
             DrawTile(DrawPosition + Cx * TileWidth, Cy * TileHeight, Tile[Map[Cy * MapWidth + MapStartX + TileOffset + Cx]]);
end;

begin
     New(Buffer);
     New(MapBuffer);
     SetVideoMode($13);

     for i := 0 to 63 do
     begin
         Tile[0][i] := 9;
         Tile[1][i] := 8;
         Tile[2][i] := 2;
         Tile[3][i] := 4;
         Tile[4][i] := 5;
     end;

     for i := 0 to 63999 do
         Buffer^[i] := 0;

     Running := true;

     X := 0;
     MapStartX := 0;
     Direction := 1;
     Auto := false;
     Speed := 3;
     DrawMap;
     X := 100;
     UpdateMap;

     while Running do
     begin
          UpdateScreen;

          if KeyPressed then
          begin
               Key := ReadKey;

               case Key of
                    'q': Running := false;
                    'a': Dec(X, Speed);
                    'd': Inc(X, Speed);
                    's': Auto := not Auto;
               end;
          end;

          if Auto then
          begin
             X := X + Speed * Direction;
             if (X > ScreenWidth + TileWidth * 2) or (X < 0) then
                Direction := Direction * -1;
          end;

          if X < 0 then X := 0;

          UpdateMap;
     end;

     SetVideoMode(3);
end.