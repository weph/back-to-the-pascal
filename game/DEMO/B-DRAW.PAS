program DrawBenchmark;
uses VGA, ModeX, Zentimer, PCXImg, Image, Debug, Drivers;

type
    TDrawFunc = procedure(Page: Byte; X, Y: Word; Image: PImage);

const
     Cols = LogicalScreenWidth div TileWidth;
     Rows = LogicalScreenHeight div TileHeight;
     Iterations = 5;

var
   Profiler: TProfiler;

procedure FillScreen(Draw: TDrawFunc; Tile: PImage);
var
   Row, Col: Word;
begin
     for Row := 0 to Rows - 1 do begin
         for Col := 0 to Cols - 1 do begin
             Draw(0, Col * TileWidth, Row * TileHeight, Tile);
         end;
     end;
end;

procedure RunBenchmark(Title: String; Draw: TDrawFunc; Tile: PImage);
var
   i: Byte;
   Stopwatch: PStopwatch;
   Num: String;
begin
     for i := 0 to Iterations - 1 do begin
         X_Fill(7);

         Str(i, Num);

         Stopwatch := Profiler.Stopwatch(Title + ' #' + Num);
         Stopwatch^.Start;

         FillScreen(Draw, Tile);

         Stopwatch^.Stop;
     end;

     ReadLn;
end;

var
   SourceImage: PCXImage;
   TileOpaque, TileAlpha: PImage;

begin
     Profiler.Init;

     InitModeX;
     SetScreenWidth(LogicalScreenWidth);
     SetVideoStartAddress(0, 0);

     SourceImage.Init('demo\b-draw.pcx');

     TileOpaque := SourceImage.ImageAt(0, 0, 16, 16);
     TileAlpha := SourceImage.ImageAt(16, 0, 16, 16);

     RunBenchmark('X_DrawOpaque', X_DrawOpaque, TileOpaque);
     RunBenchmark('X_Draw16x16Opaque', X_Draw16x16Opaque, TileOpaque);
     RunBenchmark('X_DrawAlpha', X_DrawAlpha, TileAlpha);

     SetVideoMode(3);

     Profiler.Print;

     ReadLn;
end.