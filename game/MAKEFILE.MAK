TPC = tpc

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

main:
    $(TPC) -B -UUNITS -EBUILD -$G+ MAIN.PAS

{DEMO}.PAS{BUILD}.EXE:
    $(TPC) -B -UUNITS -EBUILD -$G+ $<

demos: BUILD\B-CALL.EXE BUILD\B-DRAW.EXE BUILD\B-ISO.EXE BUILD\KEYS.EXE \
       BUILD\VMEMCPY.EXE BUILD\ZBUF.EXE

clean:
    del BUILD\*.*
