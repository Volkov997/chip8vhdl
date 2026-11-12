## Basic Instructions

### `0NNN`

execute machine language. throws error in this implementation if it occurs

### `00E0` +

clear the display buffer and set the driver to update

### `1NNN` +

jump to NNN

### `6XNN` +

set VX to NN

### `7XNN` +

add NN to VX

addition using the unsigned type

### `ANNN` +

set I to NNN

### `DXYN` draw -

draw N pixels tall sprite, at VX,VY. clip at edges
reads sprite from register I
flips pixels.
VF = 1 iff any pixels flipped to off.

### `2NNN`

push PC to stack,
jump to NNN

### `00EE`

pop PC off stack & jump back

### `3XNN` +

skip next inst when VX = NN

### `4XNN` +

skip next inst when VX != NN

### `5XY0` +

skip next inst when VX = VY

### `9XY0` +

skip next inst when VX != VY

### `8XY0` +

set VX to VY

### `8XY1` +

set VX to VX | VY

### `8XY2` +

set VX to VX & VY

### `8XY3` +

set VX to VX xor VY

### `8XY4` +

set VX to VX + VY, VF = 1 iff overflow

### `8XY5` +

set VX to VX - VY, VF = 0 iff underflow

### `8XY7` +

set VX to VY - VX, VF = 0 iff underflow

### `8XY6`/`8XYE` +

N(set VX to VY)

shift VX by 1 bit down/up
VF = shifted out bit

### `BNNN` +

jump to V0+NNN

(possibly jump to VX + NNN/XNN instead)

### `CXNN` +

VX = random between 0 and FF, & with NN

### `EX9E` +

skip inst if key (0-F) VX pressed
uses lowest 4 bits of VX only

### `EXA1` +

skip inst if key VX is not pressed

### `FX07` +

set VX to delay timer

### `FX15`/`FX18` +

set delay/sound timer to VX

### `FX1E` +

add VX to I

Y(VF set to 1 iff I > 0FFF)

### `FX0A` +

wait until key pressed, then store value to VX

### `FX29` +

point I to font character of (left)hex value in VX

### `FX33` +

store BCD of VX value into I,I+1,I+2
does not change I

### `FX55`/`FX65` +

store/load X+1 bytes of memory from/into V0-VX

N( changes I to I + X + 1)
