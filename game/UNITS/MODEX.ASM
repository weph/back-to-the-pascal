%TITLE  "Mode X routines"

IDEAL
MODEL   TPASCAL
P386

LogicalScreenHeight     EQU     272
ColumnWidth             EQU     8
RowHeight               EQU     16
PlaneWidth              EQU     96
RowSize                 EQU     PlaneWidth * RowHeight
ZBufColumnCopyWidth     EQU     (PlaneWidth - 8) SHR 2
ZBufRowCopyWidth        EQU     PlaneWidth SHR 2
ScIndex                 EQU     03c4h

EXTRN   ZBuffer:DWORD, VMemOffset:WORD

CODESEG

PUBLIC  X_ClearZBufFirstCol
PUBLIC  X_ClearZBufLastCol
PUBLIC  X_ClearZBufFirstRow
PUBLIC  X_ClearZBufLastRow

PUBLIC  X_DrawOpaque

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
        mov     [target], ax
ENDM    SetVMemOffset

MACRO   ClearZBufCol Op, StartAddress, Page
        push    ds

        movzx   dx, [Page]
        shl     dx, 4

        mov     eax, 0              ; value used by stosd to clear column

        IFIDNI <Op>, <add>
            cld
        ELSE
            std
        ENDIF

        plane = 0
        REPT 4
            pop     ds
            mov     bx, plane
            shl     bx, 2
            add     bx, dx
            mov     es, [WORD PTR ZBuffer+bx+2]

            mov     bx, es
            push    ds
            mov     ds, bx

            mov     si, StartAddress
            Op      si, ColumnWidth

            mov     di, StartAddress

            REPT LogicalScreenHeight
                mov     cx, ZBufColumnCopyWidth
                rep     movsd

                stosd
                stosd

                Op      si, ColumnWidth
            ENDM

            plane = plane + 1
        ENDM

        pop     ds
ENDM

MACRO   ClearZBufRow Op, StartAddress, Page
        push    ds

        movzx   dx, [page]
        shl     dx, 4

        mov     eax, 0              ; value used by stosd to clear column

        IFIDNI <Op>, <add>
            cld
        ELSE
            std
        ENDIF

        plane = 0
        REPT 4
            pop     ds
            mov     bx, plane
            shl     bx, 2
            add     bx, dx
            mov     es, [WORD PTR ZBuffer+bx+2]

            mov     bx, es
            push    ds
            mov     ds, bx

            mov     si, StartAddress
            Op      si, RowSize

            mov     di, StartAddress

            REPT LogicalScreenHeight - RowHeight
                mov     cx, ZBufRowCopyWidth
                rep     movsd
            ENDM

            REPT RowHeight
                mov     cx, ZBufRowCopyWidth
                rep     stosd
            ENDM

            plane = plane + 1
        ENDM

        pop     ds
ENDM

PROC    X_ClearZBufFirstCol FAR
        ARG     page:BYTE = ArgSize

        ClearZBufCol sub, %(PlaneWidth * LogicalScreenHeight) - 4, page

        ret
ENDP    X_ClearZBufFirstCol

PROC    X_ClearZBufLastCol FAR
        ARG     page:BYTE = ArgSize

        ClearZBufCol add, 0, page

        ret
ENDP    X_ClearZBufLastCol

PROC    X_ClearZBufFirstRow FAR
        ARG     page:BYTE = ArgSize

        ClearZBufRow sub, %(PlaneWidth * LogicalScreenHeight) - 4, page

        ret
ENDP    X_ClearZBufFirstRow

PROC    X_ClearZBufLastRow FAR
        ARG     page:BYTE = ArgSize

        ClearZBufRow add, 0, page

        ret
ENDP    X_ClearZBufLastRow

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

        SetVMemOffset page, StartY

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

END
