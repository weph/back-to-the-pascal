TPC = tpc
TPCFLAGS = -M -UUNITS;BUILD -EBUILD -OBUILD -$G+ -$D+ -$L+ -V

TASM = tasm
#TASMFLAGS = /zi /ml

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

OBJS = BUILD\MODEX.OBJ BUILD\ZBUF.OBJ
DEMOS = DEMOS\B-CALL.PAS DEMOS\B-ISO.PAS DEMOS\KEYS.PAS DEMOS\T-ZBUFC.PAS \
        DEMOS\B-DRAW.PAS DEMOS\B-MAPSCR.PAS DEMOS\T-SCROLL.PAS DEMOS\VMEMCPY.PAS

all: main demos

main: $(OBJS)
    $(TPC) $(TPCFLAGS) MAIN.PAS

{UNITS}.ASM{BUILD}.OBJ:
    $(TASM) $(TASMFLAGS) $< BUILD\$&.obj

demos: $(OBJS) build_demos

build_demos: $(DEMOS)
    &$(TPC) $(TPCFLAGS) $**

clean:
    del BUILD\*.OBJ
    del BUILD\*.TPU
    del BUILD\*.EXE
    del UNITS\DRAW.ASM
    del UNITS\DRAWZ.ASM

BUILD\MODEX.OBJ: UNITS\MODEX.ASM UNITS\GLOBALS.ASM UNITS\DRAW.ASM UNITS\DRAWZ.ASM

BUILD\ZBUF.OBJ: UNITS\ZBUF.ASM UNITS\GLOBALS.ASM

UNITS\DRAW.ASM: BUILD\CODEGEN.EXE
    BUILD\CODEGEN

UNITS\DRAWZ.ASM: BUILD\CODEGEN.EXE
    BUILD\CODEGEN

BUILD\CODEGEN.EXE: TOOLS\CODEGEN.PAS
    $(TPC) $(TPCFLAGS) TOOLS\CODEGEN.PAS
