unit ModeX;


interface

uses Image;

const
     TileWidth = 16;
     TileHeight = 16;

     LogicalScreenWidth = 320 + 2 * TileWidth;
     LogicalScreenHeight = 240 + 2 * TileHeight;

     PlaneWidth = LogicalScreenWidth div 4;
     PageSize = PlaneWidth * LogicalScreenHeight;
     PageOffset: array[0..1] of Word = (0, PageSize);

     ScreenOffset = (TileHeight * PlaneWidth) + (TileWidth div 4);


procedure X_Fill(Color: Byte);

procedure X_PutPixel(Page: Byte; X, Y: Word; Color: Byte);

procedure X_PutChar(Page: Byte; X, Y: Word; C: Char);

procedure X_PutString(Page: Byte; X, Y: Word; S: String);

procedure X_DrawRect(Page: Byte; X1, Y1, X2, Y2: Word; Color: Byte);

procedure X_Draw(Page: Byte; X, Y: Word; Image: PImage);

procedure X_DrawOpaque(Page: Byte; X, Y: Word; Image: PImage);

procedure X_Draw16x16Opaque(Page: Byte; X, Y: Word; Image: PImage);

procedure X_DrawAlpha(Page: Byte; X, Y: Word; Image: PImage);

procedure X_CopyToSysMem(Page: Byte; X, Y: Word; Width, Height: Byte; Target: Pointer);


implementation

uses VGA;

procedure X_Fill(Color: Byte);
begin
     SelectPlanes($f);
     FillChar(Mem[$a000:$0000], 65535, Color);
end;

procedure X_PutPixel(Page: Byte; X, Y: Word; Color: Byte);
var
   Plane: Byte;
begin
     Plane := X and 3;

     SelectPlanes(1 shl Plane);
     Mem[$a000:PageOffset[Page] + Y * PlaneWidth + X shr 2] := Color;
end;

procedure X_PutChar(Page: Byte; X, Y: Word; C: Char);
var
   Cx, Cy, Mask, Color: Byte;
   Chars: array[0..255*8] of byte absolute $f000:$fa6e;
begin
     for Cy := 0 to 7 do
     begin
          Mask := $80;
          for Cx := 0 to 7 do
          begin
               if Chars[Ord(C) * 8 + Cy] and Mask = Mask then
                   Color := 31
               else
                   Color := 0;

               X_PutPixel(Page, X + Cx, Y + Cy, Color);

               Mask := Mask shr 1;
          end;
     end;
end;

procedure X_PutString(Page: Byte; X, Y: Word; S: String);
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

procedure X_Draw(Page: Byte; X, Y: Word; Image: PImage);
begin
     if Image^.TransparencyEncoded then
         X_DrawAlpha(Page, X, Y, Image)
     else
         X_Draw16x16Opaque(Page, X, Y, Image);
end;

procedure X_DrawOpaque(Page: Byte; X, Y: Word; Image: PImage);
var
   ImageData: PChar;
   Width, Height, StartY, RemPlaneWidth: Word;
   i: Byte;
   Plane: Byte;
   PlaneShift: Byte;
   PlaneData: array[0..3] of Word;
   PPlaneData: Pointer;
begin
     Width := Image^.Width shr 3;
     Height := Image^.Height;
     ImageData := Image^.Data;
     StartY := PageOffset[Page] + Y * PlaneWidth + (X shr 2);
     RemPlaneWidth := PlaneWidth - Image^.Width shr 2;

     Plane := 0;
     PlaneShift := X mod 4;
     for i := 0 to 3 do begin
         PlaneData[i] := (1 shl ((i + PlaneShift) mod 4) shl 8) or (Ord(i + PlaneShift > 3));
     end;

     PPlaneData := @PlaneData;

     asm
        push ds

        lds si, ImageData

        mov ax, $a000
        mov es, ax

        mov bx, 0

     @DrawPlane:
        push es
        push di

        les di, PPlaneData

        mov al, 2                { select plane operation }
        mov ah, es:[di+bx+1]     { actual plane }

        mov dx, ScIndex          { set plane }
        out dx, ax

        mov dl, es:[di+bx]       { store x-offset in dx }
        mov dh, 0

        pop di
        pop es

        mov di, StartY           { start address }
        add di, dx               { + x-offset }

        mov dx, Height           { number of rows }
     @DrawRow:
        mov cx, Width            { copy row }
        rep movsw

        add di, RemPlaneWidth    { next line in video memory }

        dec dx
        jnz @DrawRow

        add bl, 2                { next plane }
        cmp bl, 8
        jne @DrawPlane

        pop ds
     end;
end;

procedure X_Draw16x16Opaque(Page: Byte; X, Y: Word; Image: PImage);
const
    RemPlaneWidth = PlaneWidth - 4;
var
    ImageData: PChar;
    StartY: Word;
begin
     ImageData := Image^.Data;
     StartY := PageOffset[Page] + Y * PlaneWidth + (X shr 2);

     asm
        push ds

        lds si, ImageData

        mov ax, $a000
        mov es, ax

        mov al, 2
        mov ah, 1

        mov dx, ScIndex
        out dx, ax

        mov di, StartY

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        shl ah, 1
        out dx, ax

        mov di, StartY

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        shl ah, 1
        out dx, ax

        mov di, StartY

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        shl ah, 1
        out dx, ax

        mov di, StartY

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        mov cx, 2
        rep movsw
        add di, RemPlaneWidth

        pop ds
     end;
end;

procedure X_DrawAlpha(Page: Byte; X, Y: Word; Image: PImage);
var
   ImageData: Pointer;
   Plane: Byte;
   StartYOffset: Word;
   LineOffset: Word;
   EndOffset: Word;
   Height: Byte;
   Width: Word;
   PlaneData: array[0..3] of Word;
   PPlaneData: Pointer;
   i: Byte;
   PlaneShift: Byte;
begin
     ImageData := Image^.Data;
     EndOffset := Ofs(Image^.Data^) + Image^.MemSize;
     LineOffset := PlaneWidth - (Image^.Width div 4);
     Plane := 0;
     StartYOffset := PageOffset[Page] + Y * PlaneWidth + (X div 4);
     Height := Image^.Height;
     Width := Image^.Width shr 2;


     PlaneShift := X mod 4;
     for i := 0 to 3 do begin
         PlaneData[i] := (1 shl ((i + PlaneShift) mod 4) shl 8) or (Ord(i + PlaneShift > 3));
     end;

     PPlaneData := @PlaneData;

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

        mov ax, $a000
        mov es, ax

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

        mov al, 2                { select plane operation }
        mov ah, ds:[si+bx+1]     { actual plane }

        pop bx
        pop si
        pop ds

        mov dx, ScIndex
        out dx, ax

        mov bl, Height

     @StartOver:
        mov dx, Width

     @MainLoop:
        lodsw
        or ax, ax
        jz @NextLine

        or al, al
        jz @SkipPixels

     @Draw:
        mov cl, al
        sub dx, cx
        dec si

        shr cx, 2
        db 66h
        rep movsw
        mov cl, al
        and cl, 3
        rep movsb

        jmp @MainLoop

     @SkipPixels:
        mov al, ah
        xor ah, ah
        add di, ax
        sub dx, ax
        jmp @MainLoop

     @NextLine:
        add di, LineOffset
        add di, dx

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
     StartOffset := PageOffset[Page] + Y * PlaneWidth + (X shr 2);
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


end.