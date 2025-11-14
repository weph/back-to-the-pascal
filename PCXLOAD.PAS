program PcxLoader;
uses Crt, PcxImg, Screen;

var
   Image: ^PcxImage;
   Sprite: PChar;
   Video: PCanvas;

begin
     Video := VGA;

     New(Image, Init('img\marty.pcx'));
     Sprite := Image^.SpriteAt(32, 0, 16, 16);

     Video^.Draw(0, 0, Image^.Width, Image^.Height, Image^.Data);
     Video^.Draw(160, 100, 16, 16, Sprite);

     ReadLn;

     FreeMem(Sprite, SizeOf(Sprite));
     Dispose(Image, Destroy);
     Dispose(VGA);
end.