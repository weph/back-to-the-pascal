%TITLE  "Mode X routines"

IDEAL
MODEL   TPASCAL
P386

INCLUDE "UNITS\GLOBALS.ASM"

EXTRN   ZBufferSegment:WORD, VMemOffset:WORD

CODESEG

PUBLIC  X_PutPixel
PUBLIC  X_PutPixelZ

PUBLIC  X_DrawOpaque
PUBLIC  X_DrawAlpha
PUBLIC  X_DrawAlphaZ
PUBLIC  X_CopyToSysMem

;--------------------------------------------------------------------------
; Set current video memory offset for page
;--------------------------------------------------------------------------
; Input:
;      page
; Output:
;      target
; Registers:
;      ax, bx
;--------------------------------------------------------------------------
MACRO   SetVMemOffset page, target
        movzx   bx, [page]
        shl     bx, 1
        mov     ax, [VMemOffset+bx]
        mov     target, ax
ENDM    SetVMemOffset

PROC    X_PutPixel FAR
        ARG     page:BYTE, x:WORD, y:WORD, color:BYTE = ArgSize

        ; calculate plane
        ; ax = 1 shl (x mod 4)
        mov     cx, [x]
        and     cx, 3
        mov     ax, 1
        shl     ax, cl

        ; set plane
        shl     ax, 8
        mov     al, 2
        mov     dx, ScIndex
        out     dx, ax

        ; di = VMemOffset + y * PlaneWidth + x / 4
        mov     bx, PlaneWidth
        mov     ax, [y]
        mul     bx
        mov     dx, [x]
        shr     dx, 2
        add     ax, dx
        movzx   bx, [page]
        shl     bx, 1
        mov     dx, [VMemOffset+bx]
        add     ax, dx
        mov     di, ax

        mov     ax, 0a000h
        mov     es, ax
        mov     al, [color]
        mov     [es:di], al

        ret
ENDP    X_PutPixel

PROC    X_PutPixelZ FAR
        ARG     page:BYTE, x:WORD, y:WORD, z:BYTE, color:BYTE = ArgSize

        ; gs = z-buffer segment for current plane
        mov     ax, 1000h
        mov     bx, [x]
        and     bx, 3
        mul     bx
        add     ax, [ZBufferSegment]
        mov     gs, ax

        ; di = VMemOffset + y * PlaneWidth + x / 4
        mov     ax, [y]
        mov     bx, PlaneWidth
        mul     bx
        mov     dx, [x]
        shr     dx, 2
        add     ax, dx
        mov     di, ax
        movzx   bx, [page]
        shl     bx, 1
        mov     ax, [VMemOffset+bx]
        add     di, ax

        mov     dh, [z]
        cmp     dh, [gs:di]
        jb      @@End

        mov     [gs:di], dh

        ; calculate plane
        ; ax = 1 shl (x mod 4)
        mov     cx, [x]
        and     cx, 3
        mov     ax, 1
        shl     ax, cl

        ; set plane
        shl     ax, 8
        mov     al, 2
        mov     dx, ScIndex
        out     dx, ax

        mov     ax, 0a000h
        mov     es, ax
        mov     al, [color]
        mov     [es:di], al

@@End:
        ret
ENDP    X_PutPixelZ

PROC    X_DrawOpaque FAR
        ARG     page:BYTE, x:WORD, y:WORD, image:DWORD = ArgSize
        LOCAL   Width:WORD, Height:WORD, StartY:WORD, Remaining:WORD = StackSize

        push    ds

        les     di, [image]

        ; Remaining = PlaneWidth - (image.width / 4)
        mov     ax, [es:di]
        shr     ax, 2
        mov     bx, PlaneWidth
        sub     bx, ax
        mov     [Remaining], bx

        ; Width = image.width / 4
        mov     ax, [es:di]
        shr     ax, 2
        mov     [Width], ax

        ; Height = image.height
        mov     ax, [es:di+2]
        mov     [Height], ax

        SetVMemOffset page, [StartY]

        mov     ax, [x]
        shr     ax, 2
        add     [StartY], ax

        mov     ax, [y]
        mov     bx, PlaneWidth
        mul     bx
        add     [StartY], ax

        mov     ds, [es:di+8]
        mov     si, [es:di+6]

        mov     ax, 0a000h
        mov     es, ax

        mov     bx, 0

@DrawPlane:
        ; calculate effective plane
        ; ax = 1 shl ((plane + planeshift) mod 4)
        mov     cx, [x]
        and     cx, 3
        add     cx, bx
        and     cx, 3
        mov     ax, 1
        shl     ax, cl

        ; set plane
        shl     ax, 8
        mov     al, 2
        mov     dx, ScIndex
        out     dx, ax

        mov     dx, [Height]

        mov     di, [StartY]

        mov     cx, [x]
        and     cx, 3
        add     cx, bx
        cmp     cx, 3
        jle     @DrawRow
        add     di, 1

@DrawRow:
        mov     ax, [Width]
        mov     cx, ax
        shr     cx, 2
        rep     movsd
        mov     cl, al
        and     cl, 3
        rep     movsb

        add     di, [Remaining]     ; next line in video memory

        dec     dx
        jnz     @DrawRow

        add     bl, 1               ; next plane
        cmp     bl, 4
        jne     @DrawPlane

        pop     ds

        ret
ENDP    X_DrawOpaque

PROC    X_DrawAlpha FAR
        ARG     page:BYTE, x:WORD, y:WORD, z:BYTE, image:DWORD = ArgSize
        LOCAL   imageseg:WORD, imageofs:WORD, Start:WORD, Height:BYTE, plane:BYTE, pwidth:BYTE, LineOffset:WORD = StackSize

        push    ds

        ; Start = CurPageOffset + y * PlaneWidth + x / 4
        SetVMemOffset page, [Start]
        mov     bx, PlaneWidth
        mov     ax, [y]
        mul     bx
        add     [Start], ax
        mov     ax, [x]
        shr     ax, 2
        add     [Start], ax

        lds     si, [image]

        ; Height = image.height
        mov     al, [ds:si+2]
        mov     [Height], al

        ; pwidth = image.width / 4
        mov     al, [ds:si]
        shr     al, 2
        mov     [pwidth], al

        ; LineOffset = PlaneWidth - pwidth
        mov     [LineOffset], PlaneWidth
        sub     [LineOffset], ax

        mov     [plane], 0

        ; image data => ds:si
        mov     ax, [ds:si+8]
        mov     [imageseg], ax
        mov     si, [ds:si+6]

        mov     ax, 0a000h
        mov     es, ax

; bh: Count down number of pixels in current block
; bl: image height
; cx: Count up number of pixels to draw
; dh: z-value
; dl: image plane width
;
; ds: image
; es: video memory
; gs: z-buffer

@@DrawPlane:
        pop     ds
        push    bx

        ; gs = z-buffer segment for current plane
        mov     ax, 1000h
        movzx   cx, [plane]
        mov     bx, [x]
        and     bx, 3
        add     bx, cx
        and     bx, 3
        mul     bx
        add     ax, [ZBufferSegment]
        mov     gs, ax

        ; calculate effective plane
        ; ax = 1 shl ((plane + planeshift) mod 4)
        movzx   bx, [plane]
        mov     cx, [x]
        and     cx, 3
        add     cx, bx
        and     cx, 3
        mov     ax, 1
        shl     ax, cl

        ; set plane
        shl     ax, 8
        mov     al, 2
        mov     dx, ScIndex
        out     dx, ax

        mov     di, [Start]

        mov     cx, [x]
        and     cx, 3
        add     cx, bx
        cmp     cx, 3
        jle     @@Next

        add     di, 1

@@Next:
        pop     bx

        mov     bl, [Height]

        mov     dh, [z]

        push    ds
        mov     ds, [imageseg]

        mov     cx, 0               ; number of pixels to draw

@@StartOver:
        mov     dl, [pwidth]

@@MainLoop:
        lodsw
        or      ax, ax
        jz      @@NextLine

        or      al, al
        jz      @@SkipPixels

@@Draw:
        mov     bh, al              ; number of pixels in current block
        sub     dl, bh
        dec     si

@@NextPixel:
        cmp     dh, [gs:[di]]
        jb      @@SkipPixel

        inc     cl
        inc     di

        dec     bh
        jnz     @@NextPixel

        sub     di, cx
        rep     movsb

        jmp     @@MainLoop

@@SkipPixel:
        sub     di, cx
        rep     movsb

        inc     si
        inc     di

        dec     bh
        jnz     @@NextPixel

        jmp     @@MainLoop

@@SkipPixels:
        movzx   ax, ah
        add     di, ax
        sub     dl, al

        jmp     @@MainLoop

@@NextLine:
        add     di, [LineOffset]
        movzx   ax, dl
        add     di, ax

        dec     bl
        jnz     @@StartOver

        inc     [plane]
        cmp     [plane], 4
        jb      @@DrawPlane

        pop     ds

        ret
ENDP    X_DrawAlpha

PROC    X_DrawAlphaZ FAR
        ARG     page:BYTE, x:WORD, y:WORD, z:BYTE, image:DWORD = ArgSize
        LOCAL   imageseg:WORD, imageofs:WORD, Start:WORD, Height:BYTE, plane:BYTE, pwidth:BYTE, LineOffset:WORD = StackSize

        push    ds

        ; Start = CurPageOffset + y * PlaneWidth + x / 4
        SetVMemOffset page, [Start]
        mov     bx, PlaneWidth
        mov     ax, [y]
        mul     bx
        add     [Start], ax
        mov     ax, [x]
        shr     ax, 2
        add     [Start], ax

        lds     si, [image]

        ; Height = image.height
        mov     al, [ds:si+2]
        mov     [Height], al

        ; pwidth = image.width / 4
        mov     al, [ds:si]
        shr     al, 2
        mov     [pwidth], al

        ; LineOffset = PlaneWidth - pwidth
        mov     [LineOffset], PlaneWidth
        sub     [LineOffset], ax

        mov     [plane], 0

        ; image data => ds:si
        mov     ax, [ds:si+8]
        mov     [imageseg], ax
        mov     si, [ds:si+6]

        mov     ax, 0a000h
        mov     es, ax

; bh: Count down number of pixels in current block
; bl: image height
; cx: Count up number of pixels to draw
; dh: z-value
; dl: image plane width
;
; ds: image
; es: video memory
; gs: z-buffer

@@DrawPlane:
        pop     ds

        ; gs = z-buffer segment for current plane
        mov     ax, 1000h
        movzx   cx, [plane]
        mul     cx
        add     ax, [ZBufferSegment]
        mov     gs, ax

        ; set plane
        mov     ax, 0102h
        shl     ah, cl
        mov     dx, ScIndex
        out     dx, ax

        mov     di, [Start]         ; start address

        mov     bl, [Height]

        mov     dh, [z]

        push    ds
        mov     ds, [imageseg]

        mov     cx, 0               ; number of pixels to draw

@@StartOver:
        mov     dl, [pwidth]

@@MainLoop:
        lodsw
        or      ax, ax
        jz      @@NextLine

        or      al, al
        jz      @@SkipPixels

@@Draw:
        mov     bh, al              ; number of pixels in current block
        sub     dl, bh
        dec     si

@@NextPixel:
        cmp     dh, [gs:[di]]
        jb      @@SkipPixel

        mov     [gs:[di]], dh
        inc     cl
        inc     di

        dec     bh
        jnz     @@NextPixel

        sub     di, cx
        rep     movsb

        jmp     @@MainLoop

@@SkipPixel:
        sub     di, cx
        rep     movsb

        inc     si
        inc     di

        dec     bh
        jnz     @@NextPixel

        jmp     @@MainLoop

@@SkipPixels:
        movzx   ax, ah
        add     di, ax
        sub     dl, al

        jmp     @@MainLoop

@@NextLine:
        add     di, [LineOffset]
        movzx   ax, dl
        add     di, ax

        dec     bl
        jnz     @@StartOver

        inc     [plane]
        cmp     [plane], 4
        jb      @@DrawPlane

        pop     ds

        ret
ENDP    X_DrawAlphaZ

;-------------------------------------------------------------------------
; Copy up to 256x256 pixels from video memory to system memory
;
; ds:si video memory
; es:di destination
;
; ah   plane (start plane-start plane+3)
;      start plane is derived from X (e.g. 1 if X=5, 2 if X=18)
; al   actual plane (0-3) (essentially ah mod 4)
; bh   plane counter
; bl   line height
; cx   line width
; dx   gc index/data
;-------------------------------------------------------------------------
PROC    X_CopyToSysMem FAR
        ARG     page:BYTE, x:WORD, y:WORD, width:BYTE, height:BYTE, target:DWORD = ArgSize
        LOCAL   StartOffset:WORD, LineWidth:WORD, LineOffset:WORD = StackSize

        push    ds

        SetVMemOffset page, [StartOffset]

        mov     ax, [x]
        shr     ax, 2
        add     [StartOffset], ax

        mov     ax, [y]
        mov     bx, PlaneWidth
        mul     bx
        add     [StartOffset], ax

        movzx   ax, [width]
        shr     ax, 2
        mov     [LineWidth], ax

        mov     bx, PlaneWidth
        sub     bx, ax
        mov     [LineOffset], bx

        ; video segment => ds
        mov     ax, 0a000h
        mov     ds, ax

        ; target memory => es:di
        les     di, [target]

        ; select read map select register in gc index
        mov     dx, GcIndex
        mov     al, 4
        out     dx, al

        mov     ax, [x]             ; store start plane in ah
        and     ax, 3
        shl     ax, 8

        mov     bh, 4               ; set number of planes

        mov     dx, GcData

@@GetPlane:
        ; write actual plane (ah mod 4) to gc data
        mov     al, ah
        and     al, 3
        out     dx, al

        mov     bl, [height]        ; number of lines to copy

        mov     si, [StartOffset]   ; start offset in video memory

        ; shift start offset by one if plane wraps around
        cmp     ah, 4
        jl      @@NextRow
        inc     si

@@NextRow:
        ; copy line
        mov     cx, [LineWidth]
        rep     movsb

        ; go to next line in video memory
        add     si, [LineOffset]

        ; repeat for all lines
        dec     bl
        jnz     @@NextRow

        ; repeat for all planes
        inc     ah
        dec     bh
        jnz     @@GetPlane

        pop     ds

        ret
ENDP    X_CopyToSysMem

END
