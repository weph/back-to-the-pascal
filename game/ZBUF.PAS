program ZBuf;
uses
    Globals,
    Malloc,
    VGA,
    ModeX,
    PCXImg,
    Image,
    Debug;

var
   ZBuffer: array[0..3] of Pointer;

procedure InitZBuffer;
var
   i: Byte;
begin
     for i := 0 to 3 do begin
         M_Alloc(ZBuffer[i], PlaneWidth * LogicalScreenHeight);
         FillChar(ZBuffer[i]^, PlaneWidth * LogicalScreenHeight, 0);
     end;
end;

procedure FreeZBuffer;
var
   i: Byte;
begin
     for i := 0 to 3 do begin
         M_Free(ZBuffer[i], PlaneWidth * LogicalScreenHeight);
     end;
end;

procedure PutPixel(X, Y: Word; Z: Byte; Color: Byte);
var
   Plane: Byte;
   Pos: Word;
begin
     Plane := X mod 4;

     Pos := Y * PlaneWidth + (X div 4);

     if Ord(PChar(ZBuffer[Plane])[Pos]) >= Z then Exit;

     PChar(ZBuffer[Plane])[Pos] := Chr(Z);

     X_PutPixel(0, X, Y, Color);
end;

procedure DrawRect(X1, Y1, X2, Y2: Word; Z: Byte; Color: Byte);
var
   X, Y: Word;
begin
     for Y := Y1 to Y2 do begin
         for X := X1 to X2 do begin
             PutPixel(X, Y, Z, Color);
         end;
     end;
end;

procedure DrawAlpha(X, Y: Word; Z: Byte; Image: PImage);
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
   PZBuffer: Pointer;
begin
     ImageData := Image^.Data;
     EndOffset := Ofs(Image^.Data^) + Image^.MemSize;
     LineOffset := PlaneWidth - (Image^.Width div 4);
     Plane := 0;
     StartYOffset := Y * PlaneWidth + X div 4;
     Height := Image^.Height;
     Width := Image^.Width shr 2;


     PlaneShift := X mod 4;
     for i := 0 to 3 do begin
         PlaneData[i] := (1 shl ((i + PlaneShift) mod 4) shl 8) or (Ord(i + PlaneShift > 3));
     end;

     PPlaneData := @PlaneData;
     PZBuffer := @ZBuffer;

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

     @StartOver:
        mov dx, Width

     @MainLoop:
        lodsw
        or ax, ax
        jz @NextLine

        or al, al
        jz @SkipPixels

     @Draw:
        push bx

        mov cl, al
        sub dx, cx
        dec si

        mov bx, 0 { continuous pixel counter }

     @NextPixel:
        mov al, es:[di+bx]
        cmp al, Z
        ja @SkipPixel

        mov al, Z
        mov es:[di+bx], al

        inc bx

        jmp @Check

     @SkipPixel:
        cmp bx, 0
        je @MoveOn

        push cx
        push es
        mov ax, $a000
        mov es, ax
        mov cx, bx
        {shr cx, 2
        db 66h
        rep movsw
        mov cl, bl
        and cl, 3}
        rep movsb
        pop es
        pop cx

     @MoveOn:
        inc si
        inc di

     @Check:
        dec cl
        jnz @NextPixel

        push cx
        push es
        mov ax, $a000
        mov es, ax
        mov cx, bx
        {shr cx, 2
        db 66h
        rep movsw
        mov cl, bl
        and cl, 3}
        rep movsb
        pop es
        pop cx

        pop bx
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

procedure DrawAlpha2(X, Y: Word; Z: Byte; Image: PImage);
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
   PZBuffer: Pointer;
begin
     ImageData := Image^.Data;
     EndOffset := Ofs(Image^.Data^) + Image^.MemSize;
     LineOffset := PlaneWidth - (Image^.Width div 4);
     Plane := 0;
     StartYOffset := Y * PlaneWidth + X div 4;
     Height := Image^.Height;
     Width := Image^.Width shr 2;


     PlaneShift := X mod 4;
     for i := 0 to 3 do begin
         PlaneData[i] := (1 shl ((i + PlaneShift) mod 4) shl 8) or (Ord(i + PlaneShift > 3));
     end;

     PPlaneData := @PlaneData;
     PZBuffer := @ZBuffer;

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

     @NextPixel:
        push bx

        mov bl, es:[di]
        cmp bl, Z
        ja @SkipPixel

        {mov bh, 0
        mov bl, Z
        mov es:[di], bx}

        push es
        mov ax, $a000
        mov es, ax
        movsb
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



var
   Img: PCXImage;
   Tile: PImage;
   Player: PImage;
   DirtyRect: PImage;
   X, Y: Word;
   FPS: FPSInfo;
   SW: PStopwatch;

begin
     FPS.Init(30);
     InitZBuffer;
     InitModeX;
     SetScreenWidth(LogicalScreenWidth);

     Img.Init('assets\iso2.pcx');
     Tile := Img.ImageAt(64, 0, 32, 24);
     Img.Destroy;

     Img.Init('assets\player.pcx');
     Player := Img.ImageAt(0, 0, 32, 32);
     Img.Destroy;

     New(DirtyRect, New(32, 32));

     SW := Profiler^.Stopwatch('Fill Screen');
     SW^.Start;
     for Y := 0 to 240 div 8 do begin
         for X := 0 to 320 div 32 do begin
             if Y mod 2 = 0 then
                DrawAlpha(X * 32, Y * 8, 50, Tile)
             else
                DrawAlpha(X * 32 + 16, Y * 8, 50, Tile);
         end;
     end;
     SW^.Stop;

     DrawAlpha(128, 136, 150, Tile);
     DrawAlpha(128, 128, 150, Tile);
     DrawAlpha(128, 120, 150, Tile);

     X_CopyToSysMem(0, 99, 104, 32, 32, DirtyRect^.Data);

     Y := 110;

     for X := 0 to 288 do begin
         FPS.Update(0);
         FPS.Draw(0);

         X_CopyToSysMem(0, X, Y, 32, 32, DirtyRect^.Data);

         DrawAlpha2(X, Y, 100, Player);

         WaitForVRetrace;

         X_DrawOpaque(
             0,
             X,
             Y,
             DirtyRect
         );

     end;

     SetVideoMode(3);
     FreeZBuffer;
     Dispose(Tile, Destroy);
     Dispose(Player, Destroy);

     Profiler^.Print;
     M_Debug;

     ReadLn;
end.