 {
  Long Period Zen Timer v2.31 (IMPROOVED AND OPTIMIZED 32 BITS VERSION)
  From the book "Zen of Assembly Language" Volume 1, Knowledge
  by Michael Abrash

  Modifications by Kendall Bennett
  Copyright (C) 1996 SciTech Software

  Improove (optimized for i80386, DPMI 16 and LZDelay added) and port to
  Turbo/Borland Pascal 7.0 by Vadim Bodrov, Russia (2:5011/5.3@fidonet)

  This tersion of Zen Timer will work on i80386 and higher
  in Real Mode and under DPMI16!
 }

 {$g+,n-,d-,l-,b-,r-,o+,f+,s-,a+,e-,p-,q-,t+,v-,x+,i-}

 unit ZenTimer;

 interface

 procedure LZTimerOn;
 function  LZTimerLap: Longint;
 procedure LZTimerOff;
 function  LZTimerCount: Longint;
 procedure LZDelay(Value: LongInt);

 implementation

 var
  StartBIOSCount,EndBIOSCount: Longint;
  EndTimedCount: Word;

 procedure LZTimerOn; assembler;
      asm
        mov     al,$34
        out     $43,al
        db      $EB,$00,$EB,$00,$EB,$00
        xor     ax,ax
        out     $40,al
        db      $EB,$00,$EB,$00,$EB,$00
        out     $40,al
        mov     es,SEG0040
        cli
        db      $66
        mov     ax,es:[$6C]
        sti
        db      $66
        mov     word ptr [StartBIOSCount],ax
        mov     al,$34
        out     $43,al
        db      $EB,$00,$EB,$00,$EB,$00
        xor     ax,ax
        out     $40,al
        db      $EB,$00,$EB,$00,$EB,$00
        out     $40,al
 end;

 procedure LZTimerOff; assembler;
      asm
        xor     al,al
        out     $43,al
        cli
        mov     es,SEG0040
        db      $66
        mov     ax,es:[$6C]
        db      $66
        mov     word ptr [EndBIOSCount],ax
        in      al,$40
        db      $EB,$00,$EB,$00,$EB,$00
        mov     ah,al
        in      al,$40
        xchg    ah,al
        neg     ax
        mov     [EndTimedCount],ax
        sti
 end;

 function  LZTimerLap: Longint; assembler;
      asm
        xor     al,al
        out     $43,al
        cli
        mov     es,SEG0040
        db      $66
        mov     ax,es:[$6C]
        db      $66
        mov     word ptr [EndBIOSCount],ax
        in      al,$40
        db      $EB,$00,$EB,$00,$EB,$00
        mov     ah,al
        in      al,$40
        xchg    ah,al
        neg     ax
        mov     [EndTimedCount],ax
        sti
        db      $66
        mov     ax,word ptr [EndBIOSCount]
        db      $66
        cmp     ax,word ptr [StartBIOSCount]
        jae     @CalcBIOSTime
        add     word ptr [EndBIOSCount],$B0
        adc     word ptr [EndBIOSCount+2],$18
@CalcBIOSTime:
        mov     ax,word ptr [EndBIOSCount]
        sub     ax,word ptr [StartBIOSCount]
        mov     dx,54925
        mul     dx
        xchg    bx,ax
        xchg    cx,dx
        mov     ax,[EndTimedCount]
        mov     si,8381
        mul     si
        mov     si,10000
        div     si
        add     ax,bx
        adc     cx,0
        mov     dx,cx
 end;

 function  LZTimerCount: Longint; assembler;
      asm
        db      $66
        mov     ax,word ptr [EndBIOSCount]
        db      $66
        cmp     ax,word ptr [StartBIOSCount]
        jae     @CheckForHour
        add     word ptr [EndBIOSCount],$B0
        adc     word ptr [EndBIOSCount+2],$18
@CheckForHour:
        mov     ax,word ptr [StartBIOSCount+2]
        cmp     ax,word ptr [EndBIOSCount+2]
        je      @CalcBIOSTime
        inc     ax
        cmp     ax,word ptr [EndBIOSCount+2]
        jne     @TestTooLong
        mov     ax,word ptr [EndBIOSCount]
        cmp     ax,word ptr [StartBIOSCount]
        jb      @CalcBIOSTime
@TestTooLong:
        mov     ax,$FFFF
        mov     dx,$FFFF
        ret
@CalcBIOSTime:
        mov     ax,word ptr [EndBIOSCount]
        sub     ax,word ptr [StartBIOSCount]
        mov     dx,54925
        mul     dx
        xchg    bx,ax
        xchg    cx,dx
        mov     ax,[EndTimedCount]
        mov     si,8381
        mul     si
        mov     si,10000
        div     si
        add     ax,bx
        adc     cx,0
        mov     dx,cx
 end;

 procedure LZDelay(Value: LongInt);
 var CurValue: LongInt;
 begin
  CurValue:=LZTimerLap+Value;
  while LZTimerLap<CurValue do
 end;

 begin
 end.
