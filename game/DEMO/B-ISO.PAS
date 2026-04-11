program DrawBenchmarkIso;
uses Globals, VGA, ModeX, Zentimer, PCXImg, Image, Debug, Drivers;

type
    TDrawFunc = procedure(Page: Byte; X, Y: Word; Image: PImage);

const
     Cols = LogicalScreenWidth div 32;
     Rows = LogicalScreenHeight div 8;
     Iterations = 5;

var
   Profiler: TProfiler;

procedure FillScreen(Draw: TDrawFunc; Tile: PImage);
var
   Row, Col: Word;
begin
     for Row := 0 to Rows - 1 do begin
         for Col := 0 to Cols - 1 do begin
             if Row mod 2 = 0 then
                 Draw(0, Col * 32, Row * 8, Tile)
             else
                 Draw(0, Col * 32 + 16, Row * 8, Tile);
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

     SourceImage.Init('assets\iso2.pcx');

     TileAlpha := SourceImage.ImageAt(32, 0, 32, 16);

     RunBenchmark('X_DrawAlpha', X_DrawAlpha, TileAlpha);

     SetVideoMode(3);

     Profiler.Print;

     ReadLn;
end.