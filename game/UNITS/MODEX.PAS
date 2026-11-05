{$L MODEX.OBJ}
unit ModeX;

interface

uses
    Globals,
    Image,
    Types,
    ZBuf;

var
    ScrollOffset: array[0..1] of TCoordinate;

procedure X_SetScrollOffset(Page: Byte; Offset: TCoordinate);

procedure X_Fill(Color: Byte);

procedure X_PutPixel(Page: Byte; X, Y: Word; Color: Byte);

procedure X_PutPixelZ(Page: Byte; X, Y: Word; Z: Byte; Color: Byte);

procedure X_PutChar(Page: Byte; X, Y: Word; C: Char);

procedure X_PutString(Page: Byte; X, Y: Word; S: string);

procedure X_DrawRect(Page: Byte; X1, Y1, X2, Y2: Word; Color: Byte);

procedure X_DrawOpaque(Page: Byte; X, Y: Word; Image: PImage);

procedure X_DrawAlpha(Page: Byte; X, Y: Word; Z: Byte; Image: PImage);

procedure X_DrawAlphaZ(Page: Byte; X, Y: Word; Z: Byte; Image: PImage);

procedure X_CopyToSysMem(Page: Byte; X, Y: Word; Width, Height: Byte; Target: Pointer);

implementation

uses
    VGA,
    Malloc,
    Debug,
    FMem;

procedure X_SetScrollOffset(Page: Byte; Offset: TCoordinate);
begin
    ScrollOffset[Page] := Offset;
    VMemOffset[Page] := PageOffset[Page] + Offset.Y * PlaneWidth + Offset.X shr 2;
end;

procedure X_Fill(Color: Byte);
begin
    SelectPlanes($f);
    FillChar(Mem[$a000: $0000], 65535, Color);
end;

procedure X_PutPixel(Page: Byte; X, Y: Word; Color: Byte); external;

procedure X_PutPixelZ(Page: Byte; X, Y: Word; Z: Byte; Color: Byte); external;

procedure X_PutChar(Page: Byte; X, Y: Word; C: Char);
var
    Cx, Cy, Mask, Color: Byte;
    Chars: array[0..255 * 8] of byte absolute $f000: $fa6e;
begin
    for Cy := 0 to 7 do begin
        Mask := $80;
        for Cx := 0 to 7 do begin
            if Chars[Ord(C) * 8 + Cy] and Mask = Mask then
                Color := 31
            else
                Color := 0;

            X_PutPixel(Page, X + Cx, Y + Cy, Color);

            Mask := Mask shr 1;
        end;
    end;
end;

procedure X_PutString(Page: Byte; X, Y: Word; S: string);
var
    i: Integer;
begin
    for i := 1 to Length(S) do
        X_PutChar(Page, X + (i - 1) * 8, Y, S[i]);
end;

procedure X_DrawRect(Page: Byte; X1, Y1, X2, Y2: Word; Color: Byte);
var
    X, Y: Word;
begin
    for X := X1 to X2 do begin
        X_PutPixel(Page, X, Y1, Color);
        X_PutPixel(Page, X, Y2, Color);
    end;

    for Y := Y1 to Y2 do begin
        X_PutPixel(Page, X1, Y, Color);
        X_PutPixel(Page, X2, Y, Color);
    end;
end;

procedure X_DrawOpaque(Page: Byte; X, Y: Word; Image: PImage); external;

procedure X_DrawAlpha(Page: Byte; X, Y: Word; Z: Byte; Image: PImage); external;

procedure X_DrawAlphaZ(Page: Byte; X, Y: Word; Z: Byte; Image: PImage); external;

procedure X_CopyToSysMem(Page: Byte; X, Y: Word; Width, Height: Byte; Target: Pointer); external;

var
    Offset: TCoordinate;

begin
    Offset.X := 0;
    Offset.Y := 0;

    X_SetScrollOffset(0, Offset);
    X_SetScrollOffset(1, Offset);
end.
