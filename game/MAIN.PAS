{$R-,S-}
program Main;
uses
    Crt,
    GameMap,
    VGA,
    Image,
    PCXImg,
    Drivers,
    Debug,
    ModeX,
    Types,
    Player,
    Keyboard,
    Malloc,
    Globals,
    Renderer,
    TopDown;

var
   Frame: LongInt;

procedure UpdateMapScroll(var Player: TPlayer; var MapOrigin: TCoordinate);
var
   MaxScrollX, MaxScrollY: Word;
begin
     MaxScrollX := (Map.Width * TileWidth) - 320 - 2 * TileWidth;
     MaxScrollY := (Map.Height * TileHeight) - 240 - 2 * TileHeight;

     if Player.X < 160 then
         MapOrigin.X := 0
     else if (Player.X - 160) > MaxScrollX then
         MapOrigin.X := MaxScrollX
     else
         MapOrigin.X := Player.X - 160;

     if Player.Y < 120 then
         MapOrigin.Y := 0
     else if (Player.Y - 120) > MaxScrollY then
         MapOrigin.Y := MaxScrollY
     else
         MapOrigin.Y := Player.Y - 120;
end;

procedure MainLoop;
var
   Running: Boolean;
   Page: Byte;
   Player: TPlayer;
   MapScroll: TCoordinate;
   Break: Boolean;
   MaxScrollX, MaxScrollY: Word;
   PTileX, PTileY, PTileXE, PTileYE: Integer;
   FPS: FPSInfo;
begin
     FPS.Init(60);

     Frame := 0;
     Running := true;
     Page := 0;

     MaxScrollX := (Map.Width * TileWidth) - 320 - TileWidth;
     MaxScrollY := (Map.Height * TileHeight) - 240 - TileHeight;

     Player.Init(@Map, 'assets\player.pcx');
     Player.D := S;
     Player.X := 16;
     Player.Y := 16;

     UpdateMapScroll(Player, MapScroll);

     X_Fill(0);

     R_AddSprite(@Player);
     R_AddSprite(@FPS);

     R_InitScreen;

     SetVideoStartAddress(PageOffset[0] + ScreenOffset, 0);

     Page := 0;
     Break := false;
     while Running do begin
           FPS.Update(Frame);
           Player.Update(Frame);
           UpdateMapScroll(Player, MapScroll);

           FPS.X := MapScroll.X + 16;
           FPS.Y := MapScroll.Y + 16;

           R_Render(Page, MapScroll);

           SetVideoStartAddress(
               PageOffset[Page] + ScreenOffset + (MapScroll.Y * PlaneWidth) + MapScroll.X shr 2,
               MapScroll.X
           );

           Page := (Page + 1) and 1;

           if Keys[$10] then Running := False;
           if Keys[$1e] then Player.Turn(Frame, -1);
           if Keys[$20] then Player.Turn(Frame, 1);
           if Keys[$19] then Player.Push;
           if Keys[$39] then Player.Ollie;

           Inc(Frame);
     end;

     Player.Destroy;
end;

var
   MapRenderer: TTopDownMapRenderer;

begin
     InitModeX;
     SetScreenWidth(LogicalScreenWidth);
     X_Fill(0);

     Map.Init('assets\race2.map');
     MapRenderer.Init(@Map, 'assets\race2.pcx');
     R_Init(@MapRenderer);

     MainLoop;

     SetVideoMode(3);

     MapRenderer.Destroy;
     Map.Destroy;
     R_Destroy;

     Profiler^.Print;
     M_Debug;
end.
