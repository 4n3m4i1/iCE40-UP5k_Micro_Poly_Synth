## Build Instructions
- Ensure your `pico-sdk` is installed correctly and can produce `.uf2` output
- Create `build` directory in this folder
- `cd` into build
- On Linux (and mac? idk) run `cmake ..`
- On Windows (using Shawn Hymel MINGW install method): `cmake -G "MinGW Makefiles" ..`
- That's it! Upload `{executable name}.uf2` to the board to run 