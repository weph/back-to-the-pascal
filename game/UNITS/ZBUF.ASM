IDEAL
MODEL   TPASCAL
P386

INCLUDE "UNITS\GLOBALS.ASM"

EXTRN   ZBufferSegment:WORD, VMemOffset:WORD

CODESEG

PUBLIC  ZBuf_Allocate
PUBLIC  ZBuf_Destroy
PUBLIC  ZBuf_Draw
PUBLIC  ZBuf_Clear
PUBLIC  ZBuf_ClearFirstCol
PUBLIC  ZBuf_ClearLastCol
PUBLIC  ZBuf_ClearFirstRow
PUBLIC  ZBuf_ClearLastRow

PROC    ZBuf_Allocate
        mov     ah, 48h
        mov     bx, 4000h
        int     21h
        jc      @@error

        mov     [ZBufferSegment], ax

        ; return true
        mov     ax, 1
        jmp     @@end

@@error:
        ; return false
        mov     ax, 0

@@end:
        ret
ENDP    ZBuf_Allocate

PROC    ZBuf_Destroy
        mov     ah, 49h
        mov     es, [ZBufferSegment]
        int     21h

        ret
ENDP    ZBuf_Destroy

PROC    ZBuf_Draw
        ARG     page:BYTE

        push    ds

        mov     dx, PaletteMask
        mov     al, 0ffh
        out     dx, al

        mov     al, 0
        mov     cx, 0ffh
@@NextColor:
        mov     dx, PaletteWrite
        out     dx, al
        mov     dx, PaletteData
        out     dx, al
        out     dx, al
        out     dx, al
        inc     al
        loop    @@NextColor

        movzx   bx, [page]
        shl     bx, 1
        mov     ax, [VMemOffset+bx]
        mov     bx, ax

        mov     ax, 0a000h
        mov     es, ax

        mov     ax, [ZBufferSegment]
        mov     ds, ax

        IRP plane, <0,1,2,3>
            ; set plane
            mov     ax, &(0100h SHL plane + 02h)
            mov     dx, ScIndex
            out     dx, ax

            mov     di, bx
            mov     si, bx

            mov     cx, &(PlaneSize / 4)
            rep     movsd

            mov     ax, ds
            add     ax, 1000h
            mov     ds, ax
        ENDM

        pop     ds

        ret
ENDP    ZBuf_Draw

PROC    ZBuf_Clear
        mov     bx, 0

        cld

@@NextPlane:
        mov     ax, [ZBufferSegment]
        add     ax, bx
        mov     es, ax

        mov     di, 0
        mov     eax, 0
        mov     cx, 0ffffh / 4
        rep     stosd

        add     bx, 1000h
        cmp     bx, 4000h
        jb      @@NextPlane

        ret
ENDP    ZBuf_Clear

MACRO   ClearZBufCol page, offset
        mov     dx, [WORD PTR ZBufferSegment]

        cld

        movzx   bx, page
        shl     bx, 1

        mov     eax, 0
        REPT 4
            mov     es, dx
            mov     di, [VMemOffset+bx]
            add     di, offset

            row = 0
            REPT LogicalScreenHeight
                mov     [es:di+(row*PlaneWidth)], eax
                mov     [es:di+4+(row*PlaneWidth)], eax
                row = row + 1
            ENDM

            add     dx, 1000h
        ENDM
ENDM

MACRO   ClearZBufRow page, offset
        mov     dx, [WORD PTR ZBufferSegment]

        cld

        movzx   bx, page
        shl     bx, 1

        mov     eax, 0
        REPT 4
            mov     es, dx
            mov     di, [VMemOffset+bx]
            add     di, offset

            REPT RowHeight
                mov     cx, PlaneWidth SHR 2
                rep     stosd
            ENDM

            add     dx, 1000h
        ENDM
ENDM

PROC    ZBuf_ClearFirstCol
        ARG     page:BYTE

        ClearZBufCol [page], 0
        ret
ENDP    ZBuf_ClearFirstCol

PROC    ZBuf_ClearLastCol
        ARG     page:BYTE

        ClearZBufCol [page], %(PlaneWidth  - 8)

        ret
ENDP    ZBuf_ClearLastCol

PROC    ZBuf_ClearFirstRow
        ARG     page:BYTE

        ClearZBufRow [page], 0

        ret
ENDP    ZBuf_ClearFirstRow

PROC    ZBuf_ClearLastRow
        ARG     page:BYTE

        ClearZBufRow [page], %(PlaneWidth * (LogicalScreenHeight - RowHeight))

        ret
ENDP    ZBuf_ClearLastRow

END
