%TITLE  "Mode X routines"

IDEAL
MODEL   TPASCAL
P386

LogicalScreenHeight     EQU     272
ColumnWidth             EQU     8
PlaneWidth              EQU     96
ZBufColumnCopyWidth     EQU     (PlaneWidth - 8) SHR 2

EXTRN   ZBuffer:DWORD

CODESEG

PUBLIC  X_ClearZBufFirstCol
PUBLIC  X_ClearZBufLastCol

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

END
