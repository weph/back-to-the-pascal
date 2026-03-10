unit PcxImg;


interface

uses VGA, Image;

type
    PcxHeader = record
              HeaderField: Byte;
              Version: Byte;
              Encoding: Byte;
              PlaneBits: Byte;
              XMin, YMin, XMax, YMax: Word;
              XDpi, YDpi: Word;
              EgaPalette: Array[0..15] of TColor;
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

             public
                   Header: PcxHeader;
                   Palette: Array[0..255] of TColor;
                   Data: PChar;

                   constructor Init(Filename: String);
                   destructor Destroy;
                   function Width: Word;
                   function Height: Word;
                   function ImageAt(X, Y, W, H: Word): PImage;
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
     DataLen := (Header.XMax + 1) * (Header.YMax + 1);
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

     Seek(Image, FileSize(Image) - SizeOf(Palette));
     BlockRead(Image, Palette, SizeOf(Palette));

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

function PcxImage.ImageAt;
var
   Xp, Yp, i: Word;
   Result: PImage;
   Temp: Pointer;
begin
     New(Result);
     Result^.Width := W;
     Result^.Height := H;
     Result^.MemSize := W * H;
     GetMem(Temp, W * H);

     i := 0;
     for Yp := Y to Y + H - 1 do
         for Xp := X to X + W - 1 do begin
             PChar(Temp)[i] := Data[Yp * Width + Xp];
             Inc(i);
         end;

     ImageAt := New(PImage, Init(W, H, Temp));
end;

begin
end.