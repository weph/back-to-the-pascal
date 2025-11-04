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

begin
end.