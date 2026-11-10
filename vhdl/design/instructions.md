## Basic Instructions

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

### `DXYN` draw +

draw N pixels tall sprite, at VX,VY
reads sprite from register I
flips pixels. already on pixels in area set VF to 1
