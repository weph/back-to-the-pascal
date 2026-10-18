TPC = tpc
TASM = tasm

help:
    @echo Usage: make [target]
    @echo.
    @echo Targets:
    @echo.
    @echo all: build main program and demos
    @echo main: build the main program
    @echo demos: build the demos/benchmarks
    @echo clean: removes all generated code
    @echo.

all: main demos

main: BUILD\MODEX.TPU
    $(TPC) -B -UUNITS -EBUILD -OBUILD -$G+ MAIN.PAS

{UNITS}.PAS{BUILD}.TPU:
    $(TPC) -B -UUNITS -EBUILD -OBUILD -$G+ $D+ $L+ $<

{UNITS}.ASM{BUILD}.OBJ:
    $(TASM) /zi /ml $< BUILD\$&.obj

{DEMO}.PAS{BUILD}.EXE:
    $(TPC) -B -UUNITS -EBUILD -OBUILD -$G+ $D+ $L+ -V $<

demos: BUILD\MODEX.TPU BUILD\B-CALL.EXE BUILD\B-DRAW.EXE BUILD\B-ISO.EXE \
       BUILD\B-MAPSCR.EXE BUILD\KEYS.EXE BUILD\T-SCROLL.EXE BUILD\T-ZBUFC.EXE \
       BUILD\VMEMCPY.EXE BUILD\ZBUF.EXE

clean:
    del BUILD\*.*

BUILD\MODEX.TPU: BUILD\MODEX.OBJ
