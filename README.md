FireTrack ADJI Support Utility
==============================

Implements a custom joystick handler for FireTrack to support the ADJI interface.

This only works on the BBC Master and requires the enhanced version of FireTrack that uses sideways ram.

You do not need to use any other ADJI ROM commands, this is a direct integration of the ADJI API

Special thanks to this disassembly https://www.level7.org.uk/miscellany/firetrack-disassembly.txt.

Download from the `/dist` in this repository for the latest.

Usage
-----

Run `!FTADJI` before booting the game or add it to the `!BOOT` file.

The following usage defaults to joystrick number 1 (aka &FCC0 address for ADJI)

`*!FTADJI`

The following usage sets to joystrick number 2 (so the code uses &FCD0 address), same works for 3 and 4.

`*!FTADJI 2`

The following runs the test routine that outputs characters as the stick is moved, press any key to exit.

`*!FTADJI TEST`

Finally, the above parameters can be combined, for example

`*!FTADJI 3 TEST`