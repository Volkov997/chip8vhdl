# Chip-8 implementation using VHDL

This is a project made for hackclub [chipper](https://chipper.hackclub.com/), designing a chip-8 interpreter in VHDL. Since this is my very first time using a HDL, this is not really aimed to be an actual FPGA-ready design ( although i am making it fully synthesizable for simulation ).

The interface portion of the language is implemented using cocotb in python. This handles loading the program data into a RAM component and letting the user interact with the simulated circuit with a gui.

### Component ports

These are the connections which the Simulated chip uses to interact with external components:

- `clock` and `chipEN`
- `ram_address`, `ram_din`/`ram_dout` and `ram_we`
    - read/writing single bytes from a synchronous RAM, using a 12 bit address (4096 locations)
- `display_dout`, `display_sig`
    - contains 12 bits of data to write to the display + a write signal
    - highest bit is black/white value, remaining specify the position in a 64x32 grid
- `beep`
    - output signal to the buzzer
- `keypad`
    - 16bit signal with 1bit per key, might change to matrix adressing instead to match a common keypad ( 4 input columns, 4 output rows ) or implement a seperate component to do that

### Status

#### Working test interface

Interface harness can load and dump the connected RAM, aswell as recieve a rudimentary display signal from the simulation. Currently the chip just outputs a test signal, writing white pixels into diagonal lines.

( Image after 610 clock cycles, pixels are displayed in color just to look fancy :p )
![image of diagonal lines on a display initerface](assets/disptest.png)
