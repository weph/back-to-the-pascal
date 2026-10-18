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

EXTRN   ZBuffer:DWORD

CODESEG

PUBLIC  X_ClearZBufFirstCol
PUBLIC  X_ClearZBufLastCol
PUBLIC  X_ClearZBufFirstRow
PUBLIC  X_ClearZBufLastRow

%NEWPAGE

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

END
