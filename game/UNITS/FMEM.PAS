unit FMem;

interface

procedure FastMove(var Src, Dst; Size: Word);

implementation

procedure FastMove;
begin
     asm
        push ds
        lds si, Src
        les di, Dst
        mov cx, Size
        mov ax, cx
        cld
        shr cx, 2
        db 66h
        rep movsw
        mov cl, al
        and cl, 3
        rep movsb
        pop ds
     end;
end;

end.