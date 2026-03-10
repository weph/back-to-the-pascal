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


procedure X_Draw16x16Opaque(Page: Byte; X, Y: Integer; Image: PImage);

procedure X_DrawAlpha(Page: Byte; X, Y: Integer; Image: PImage);


implementation

uses VGA;

procedure X_Draw16x16Opaque(Page: Byte; X, Y: Integer; Image: PImage);
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

procedure X_DrawAlpha(Page: Byte; X, Y: Integer; Image: PImage);
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


end.