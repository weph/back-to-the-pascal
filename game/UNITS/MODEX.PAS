{$L MODEX.OBJ}
unit ModeX;

interface

uses
    Globals,
    Image,
    Types;

var
    ScrollOffset: array[0..1] of TCoordinate;

procedure X_SetScrollOffset(Page: Byte; Offset: TCoordinate);

procedure X_InitZBuf;

procedure X_DestroyZBuf;

procedure X_DrawZBuf(Page: Byte);

procedure X_ClearZBuf(Page: Byte);

procedure X_ClearZBufFirstCol(Page: Byte);

procedure X_ClearZBufLastCol(Page: Byte);

procedure X_ClearZBufFirstRow(Page: Byte);

procedure X_ClearZBufLastRow(Page: Byte);

procedure X_DumpZBuf(Page: Byte; X, Y, Width, Height: Word);

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

var
    PlaneShiftData: array[0..3, 0..3] of Word;
    ZBuffer: array[0..1, 0..3] of Pointer;
    VMemOffset: array[0..1] of Word;

procedure X_SetScrollOffset(Page: Byte; Offset: TCoordinate);
begin
    ScrollOffset[Page] := Offset;
    VMemOffset[Page] := PageOffset[Page] + Offset.Y * PlaneWidth + Offset.X shr 2;
end;

procedure X_InitZBuf;
var
    Page, Plane: Byte;
begin
    for Page := 0 to 1 do begin
        for Plane := 0 to 3 do begin
            M_Alloc(ZBuffer[Page][Plane], PlaneWidth * LogicalScreenHeight);
            FillChar(ZBuffer[Page][Plane]^, PlaneWidth * LogicalScreenHeight, 0);
        end;
    end;
end;

procedure X_DestroyZBuf;
var
    Page, Plane: Byte;
begin
    for Page := 0 to 1 do begin
        for Plane := 0 to 3 do begin
            M_Free(ZBuffer[Page][Plane], PlaneWidth * LogicalScreenHeight);
        end;
    end;
end;

procedure X_ClearZBuf(Page: Byte);
var
    Plane: Byte;
begin
    for Plane := 0 to 3 do begin
        FillChar(ZBuffer[Page][Plane]^, PlaneWidth * LogicalScreenHeight, 0);
    end;
end;

procedure X_ClearZBufFirstCol(Page: Byte); external;

procedure X_ClearZBufLastCol(Page: Byte); external;

procedure X_ClearZBufFirstRow(Page: Byte); external;

procedure X_ClearZBufLastRow(Page: Byte); external;

procedure X_DrawZBuf(Page: Byte);
var
    Y, X: Word;
    C: TColor;
begin
    for X := 0 to 255 do begin
        C.Red := X;
        C.Green := X;
        C.Blue := X;

        SetColor(X, C);
    end;

    for Y := 0 to LogicalScreenHeight do begin
        for X := 0 to LogicalScreenWidth do begin
            X_PutPixel(Page, X, Y, Ord(PChar(ZBuffer[Page][X and 3])[Y * PlaneWidth + X shr 2]) shl 2);
        end;
    end;
end;

procedure X_DumpZBuf(Page: Byte; X, Y, Width, Height: Word);
var
    XP, YP: Word;
begin
    for YP := Y to Y + Height do begin
        for XP := X to X + Width do begin
            Write(Ord(PChar(ZBuffer[Page][XP and 3])[YP * PlaneWidth + XP shr 2]), ' ');
        end;
        WriteLn('');
    end;
end;

procedure X_Fill(Color: Byte);
begin
    SelectPlanes($f);
    FillChar(Mem[$a000: $0000], 65535, Color);
end;

procedure X_PutPixel(Page: Byte; X, Y: Word; Color: Byte);
var
    Plane: Byte;
begin
    Plane := X and 3;

    SelectPlanes(1 shl Plane);
    Mem[$a000: PageOffset[Page] + Y * PlaneWidth + X shr 2] := Color;
end;

procedure X_PutPixelZ(Page: Byte; X, Y: Word; Z: Byte; Color: Byte);
var
    Plane: Byte;
    Offset: Word;
    PlaneZBuf: PChar;
begin
    Plane := X and 3;
    Offset := Y * PlaneWidth + X shr 2;
    PlaneZBuf := PChar(ZBuffer[Page][Plane]);

    if Ord(PlaneZBuf[Offset]) < Z then begin
        SelectPlanes(1 shl Plane);

        Mem[$a000: PageOffset[Page] + Offset] := Color;

        PlaneZBuf[Offset] := Chr(Z);
    end;
end;

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
    Shift, Plane: Byte;

begin
    for Shift := 0 to 3 do begin
        for Plane := 0 to 3 do begin
            PlaneShiftData[Shift][Plane] := (1 shl ((Plane + Shift) mod 4) shl 8) or (Ord(Plane + Shift > 3));
        end;
    end;
end.
