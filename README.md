# Back to the Pascal

**Back to the Pascal** is about a game I wanted to build in the early '90s, but couldn't, because I wasn't a good enough
programmer yet.
35 years later, I decided to see if I could finally pull it off using the same hardware (i386) and programming
language (Turbo Pascal) I used back then.

If you want to learn more about the backstory, check out this video:

[![Finishing the Game I Started 35 Years Ago](https://weph.dev/back-to-the-pascal/yt-bttp.jpg)](https://www.youtube.com/watch?v=EeAz5rUbE9A&list=PLpqQb-X-yll7K1JUmslRWf2i6rKuqdNp_)

## Project Structure

```
.
|-- game                 // game root folder 
|   |-- ASSETS              // game assets (tiles, sprites, maps)
|   |-- DEMO                // demo programs (experiments, benchmarks)
|   |-- MAIN.PAS            // the actual game
|   |-- UNITS               // units
`-- tiled-exporter       // Map export plugin for Tiled
```

## Running the Code

To run the code you need an **IBM‑compatible PC** (or DOSBox) and a copy of **Turbo Pascal 7**.
My development system is a 386DX-40.

If you use DOSBox, the following settings give roughly the same performance:

- **CPU Type:** 386
- **CPU Cycles:** 8000

### Using Borland Make

1. Enter the game's root folder
2. Run `make all` (run `make` without arguments to see all available targets)
3. Run `build\main` (or any of the other executables)

### From Turbo Pascal's IDE

1. **Start Turbo Pascal** from the game’s root folder.
2. Add the `UNITS` directory to the list of unit directories (`Options → Directories`).
3. Open `MAIN.PAS` (or any file in the `DEMO` folder) and run it with **Ctrl+F9** (or `Run → Run`).
