unit PcxImg;

interface

type
    PcxHeader = record
              HeaderField: Byte;
              Version: Byte;
              Encoding: Byte;
              PlaneBits: Byte;
              XMin, YMin, XMax, YMax: Word;
              XDpi, YDpi: Word;
              EgaPalette: Array[0..47] of Byte;
              ReservedField: Byte;
              ColorPlanes: Byte;
              BytesPerPlane: Word;
              PaletteMode: Word;
              SourceWidth, SourceHeight: Word;
              ExtraData: Array[0..53] of Byte;
    end;

    PcxImage = object
             private
                    DataLen: Word;
                    Header: PcxHeader;

             public
                   Data: PChar;

                   constructor Init(Filename: String);
                   destructor Destroy;
                   function Width: Word;
                   function Height: Word;
                   function SpriteAt(X, Y, SpriteWidth, SpriteHeight: Word): PChar;
    end;

implementation

constructor PcxImage.Init(Filename: String);
var
   Image: File;
   CurrentPos: Word;
   CurrentByte: Char;
   NextByte: Char;
   i: Byte;
begin
     Assign(Image, Filename);
     Reset(Image, 1);

     BlockRead(Image, Header, SizeOf(Header));
     DataLen := Header.SourceWidth * Header.SourceHeight;
     GetMem(Data, DataLen);

     CurrentPos := 0;

     while CurrentPos < DataLen do
     begin
          BlockRead(Image, CurrentByte, 1);

          if Ord(CurrentByte) and $C0 = $C0 then
          begin
               BlockRead(Image, NextByte, 1);

               for i := 0 to Ord(CurrentByte) - $C0 - 1 do
               begin
                    Data[CurrentPos] := NextByte;
                    Inc(CurrentPos);
               end;
          end
          else
          begin
              Data[CurrentPos] := CurrentByte;
              Inc(CurrentPos);
          end;
     end;

     Close(Image);
end;

destructor PcxImage.Destroy;
begin
     FreeMem(Data, DataLen);
end;

function PcxImage.Width;
begin
     Width := Header.SourceWidth;
end;

function PcxImage.Height;
begin
     Height := Header.SourceHeight;
end;

function PcxImage.SpriteAt(X, Y, SpriteWidth, SpriteHeight: Word): PChar;
var
   Xp, Yp, i: Word;
   Sprite: PChar;
begin
     GetMem(Sprite, SpriteWidth * SpriteHeight);

     i := 0;
     for Yp := Y to Y + SpriteHeight - 1 do
         for Xp := X to X + SpriteWidth - 1 do
         begin
             Sprite[i] := Data[Yp * Width + Xp];
             Inc(i);
         end;

     SpriteAt := Sprite;
end;

begin
end.