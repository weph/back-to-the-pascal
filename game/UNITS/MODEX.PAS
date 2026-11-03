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

procedure X_DrawAlphaZ(Page: Byte; X, Y: Word; Z: Byte; Image: PImage);
var
    ImageData: Pointer;
    Plane: Byte;
    StartYOffset: Word;
    LineOffset: Word;
    EndOffset: Word;
    Height: Byte;
    Width: Byte;
    PPlaneData: Pointer;
    PlaneShift: Byte;
    PZBuffer: Pointer;
    CurPageOffset: Word;
begin
    ImageData := Image^.Data;
    EndOffset := Ofs(Image^.Data^) + Image^.MemSize;
    LineOffset := PlaneWidth - (Image^.Width div 4);
    Plane := 0;

    CurPageOffset := PageOffset[Page] + ScrollOffset[Page].Y * PlaneWidth + (ScrollOffset[Page].X shr 2);
    StartYOffset := Y * PlaneWidth + (X div 4);
    Height := Image^.Height;
    Width := Image^.Width shr 2;

    PlaneShift := X mod 4;
    PPlaneData := @PlaneShiftData[PlaneShift];
    PZBuffer := @ZBuffer[Page];

    {
        ds:si image data
        es:di screen
        bh    plane counter
        bl    row
        dx    ScIndex
     }
    asm
        push ds

        lds si, ImageData

        {mov ax, $a000
        mov es, ax}

        mov bh, 4              { number of planes }

        mov ch, 0

     @DrawPlane:
        push ds
        push si
        push bx

        lds si, PPlaneData

        mov bl, Plane
        mov bh, 0
        shl bx, 1

        mov al, ds:[si+bx]
        mov ah, 0
        mov di, StartYOffset
        add di, ax

        { z-buffer for current plane => es }
        push di
        push bx
        les di, PZBuffer
        mov bh, 0
        mov bl, Plane
        add bl, PlaneShift
        {add bx, ax}
        and bx, 3
        shl bx, 2
        mov ax, es:[di+bx+2]
        mov es, ax
        pop bx
        pop di

        mov al, 2                { select plane operation }
        mov ah, ds:[si+bx+1]     { actual plane }
        mov dx, ScIndex
        out dx, ax

        pop bx
        pop si
        pop ds

        mov bl, Height
        mov dh, Z

     @StartOver:
        mov dl, Width

     @MainLoop:
        lodsw
        or ax, ax
        jz @NextLine

        or al, al
        jz @SkipPixels

     @Draw:
        mov cl, al
        sub dl, cl
        dec si

     @NextPixel:
        push bx

        mov bl, es:[di]
        cmp bl, dh
        ja @SkipPixel

        mov es:[di], dh

        push es
        add di, CurPageOffset
        mov ax, $a000
        mov es, ax
        movsb
        sub di, CurPageOffset
        pop es
        jmp @Check

     @SkipPixel:
        inc si
        inc di

     @Check:
        pop bx
        dec cl
        jnz @NextPixel

        jmp @MainLoop

     @SkipPixels:
        mov al, ah
        xor ah, ah
        add di, ax
        sub dl, al
        jmp @MainLoop

     @NextLine:
        add di, LineOffset
        mov al, dl
        mov ah, 0
        add di, ax
        {inc dl}

        dec bl
        jnz @StartOver

        inc &Plane
        dec bh
        jnz @DrawPlane

        pop ds
    end;
end;

{
  Copy up to 256x256 pixels from video memory to system memory

  ds:si video memory
  es:di destination

  ah    plane (start plane-start plane+3)
        start plane is derived from X (e.g. 1 if X=5, 2 if X=18)
  al    actual plane (0-3) (essentially ah mod 4)
  bh    plane counter
  bl    line height
  cx    line width
  dx    gc index/data
}
procedure X_CopyToSysMem(Page: Byte; X, Y: Word; Width, Height: Byte; Target: Pointer);
var
    LineWidth, LineOffset: Word;
    StartOffset: Word;
begin
    StartOffset := PageOffset[Page] + (ScrollOffset[Page].Y + Y) * PlaneWidth + (ScrollOffset[Page].X + X) shr 2;
    LineWidth := Width shr 2;
    LineOffset := PlaneWidth - LineWidth;

    asm
        push ds

        mov ax, $a000       { initialize ds to video segment }
        mov ds, ax

        les di, Target      { initialize es:di to target memory }

        mov dx, $3ce        { select read map select register in gc index}
        mov al, 4
        out dx, al

        mov dx, $3cf        { set dx to gc data }

        mov ax, X           { store start plane in ah }
        and ax, 3
        shl ax, 8

        mov bh, 4           { set number of planes }

     @GetPlane:
        mov al, ah          { write actual plane (ah mod 4) to gc data }
        and al, 3
        out dx, al

        mov bl, Height      { number of lines to copy }

        mov si, StartOffset { start offset in video memory }

        cmp ah, 4           { shift start offset by one if plane wraps around }
        jl @NextRow
        inc si

     @NextRow:
        mov cx, LineWidth   { copy line }
        rep movsb

        add si, LineOffset  { go to next line in video memory }

        dec bl              { repeat for all lines }
        jnz @NextRow

        inc ah              { repeat for all planes }
        dec bh
        jnz @GetPlane

        pop ds
    end;
end;

var
    Shift, Plane: Byte;

begin
    for Shift := 0 to 3 do begin
        for Plane := 0 to 3 do begin
            PlaneShiftData[Shift][Plane] := (1 shl ((Plane + Shift) mod 4) shl 8) or (Ord(Plane + Shift > 3));
        end;
    end;
end.
