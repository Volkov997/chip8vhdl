import cocotb
from cocotb.triggers import *
from cocotb.handle import *
from cocotb.clock import Clock
import random


# --- parameters 

progFile = "../programs/Wall.ch8"
realClockHz = 200


# --- GUI

import tkinter as tk
import time
interface = tk.Tk()
interface_closed = False

def interface_on_close():
    global interface_closed
    interface_closed = True
    interface.destroy()

interface.protocol("WM_DELETE_WINDOW", interface_on_close)
interface.bind("<Escape>", lambda _: interface_on_close())


# canvas
DISP_W = 64
DISP_H = 32
PIX = 15
canv = tk.Canvas(interface, bg="black",height=DISP_H*PIX,width=DISP_W*PIX)

displayGrid = []
for x in range(DISP_W):
    v=[]
    for y in range(DISP_H):
        r = canv.create_rectangle(x*PIX, y*PIX, (x+1)*PIX, (y+1)*PIX,fill="black",width=1,outline="#333")
        v.append(r)
    displayGrid.append(v)

canv.pack()


# buttons

button_layout = [
    1   ,2  ,3  ,0xC,
    4   ,5  ,6  ,0xD,
    7   ,8  ,9  ,0xE,
    0xA ,0  ,0xB,0xF
]

buttons = []
button_data = 0x0000
button_frame = tk.Frame(interface)
button_frame.pack(expand=True)
def button_callback (n,pressed):
    global button_data
    if (pressed):
        button_data = (button_data | (1<<n))
    else:
        button_data = (button_data & ~(1<<n))

__pixel = tk.PhotoImage(width=1, height=1) #workaround for button size not being in pixels
for i in range(16):
    n = button_layout[i] # button value
    b = tk.Button(button_frame,text=hex(n)[2::].capitalize(),image=__pixel,width=PIX*2,height=2*PIX, compound="c")

    b.bind("<ButtonPress>", lambda _, n=n: button_callback(n,True))
    b.bind("<ButtonRelease>", lambda _, n=n: button_callback(n,False))
    
    b.grid(
        row=i//4,
        column=i%4,
        sticky="w"
    )

    buttons.append(b)


key_buttons_data = 0x0000
key_debounce_time = [-1]*16

# called each clock rising edge, guaranteeing buttons are pressed for at least 1 cycle 
def update_debounce():
    global key_buttons_data
    key_buttons_data = 0x0000
    for i in range(16):
        n = button_layout[i]
        if (key_debounce_time[i] != -1):
            key_buttons_data |= (1<<n)
            if (key_debounce_time[i] == -2): #pressed but not yet released
                return
            if (1000*(time.time()-key_debounce_time[i]) > 50): # 50ms debounce for key repeat
                key_debounce_time[i] = -1

def key_handler(event,down=True):
    code = event.keycode
    # key codes for key to button map (1-4 down to y-v)
    # 10 - 13
    # 24 
    # 38
    # 52 - 55 
    if ((code-10)//14 <4 and (code-10)%14 <4):
        button_num = ((code-10)//14) * 4 + (code-10)%14
        if (down):
            key_debounce_time[button_num] = -2
        else:
            key_debounce_time[button_num] = time.time() # debounce after release

interface.bind("<KeyPress>", lambda _: key_handler(_,True))
interface.bind("<KeyRelease>", lambda _: key_handler(_,False))




# beeper
beeper_vis_canvas = tk.Canvas(button_frame,height=2*PIX,width=2*PIX)
beeper_vis = beeper_vis_canvas.create_oval(2,2,2*PIX-2,2*PIX-2,fill="black",width=2,outline="black")
beeper_vis_canvas.grid(
    row=0, column=4
)
async def beeperUpdate(dut):
    while True:
        await Edge(dut.beep)
        if (dut.beep.value == 1):
            beeper_vis_canvas.itemconfig(beeper_vis, fill="red")
        else:
            beeper_vis_canvas.itemconfig(beeper_vis, fill="black")

# --- 

# --- Simulation


fontData = bytearray([
    0xF0, 0x90, 0x90, 0x90, 0xF0,  #0
    0x20, 0x60, 0x20, 0x20, 0x70, 
    0xF0, 0x10, 0xF0, 0x80, 0xF0, 
    0xF0, 0x10, 0xF0, 0x10, 0xF0, 
    0x90, 0x90, 0xF0, 0x10, 0x10, 
    0xF0, 0x80, 0xF0, 0x10, 0xF0, 
    0xF0, 0x80, 0xF0, 0x90, 0xF0, 
    0xF0, 0x10, 0x20, 0x40, 0x40, 
    0xF0, 0x90, 0xF0, 0x90, 0xF0, 
    0xF0, 0x90, 0xF0, 0x10, 0xF0, 
    0xF0, 0x90, 0xF0, 0x90, 0x90, 
    0xE0, 0x90, 0xE0, 0x90, 0xE0, 
    0xF0, 0x80, 0x80, 0x80, 0xF0, 
    0xE0, 0x90, 0x90, 0x90, 0xE0, 
    0xF0, 0x80, 0xF0, 0x80, 0xF0,
    0xF0, 0x80, 0xF0, 0x80, 0x80   #F
])
fontAddress = 0x50

progData = None
with open(progFile, "rb") as f:
    progData = bytearray(f.read())  
progAddress = 0x200


clockSimHz = 1e5

def reg(i):
    return "V"+hex(i)[2::]

@cocotb.test
async def run(main):

    chip = main.chipdut
    ram = main.ramdut

    #callbacks
    cocotb.start_soon(displayUpdate(chip))
    cocotb.start_soon(beeperUpdate(chip))

    #faster clock for display
    dclock = Clock(chip.dispdriver.clock, 100, unit="ns")
    cocotb.start_soon(dclock.start())

    main.clockMain.value = 0

    chip.chipEN.value = 0
    await write_ram(main,fontData,fontAddress)
    await write_ram(main,progData,progAddress)

    chip.PC.value = 0x200
    await pulseH(main.clockMain,1e9/clockSimHz)
    await pulseH(main.clockMain,1e9/clockSimHz)


    chip.chipEN.value = 1

    await dump_ram(ram,160,0x200)

    lastClock = 0
    clockVal = 1
    cycles = 0

    dTsmooth = 1

    while True:
        if (interface_closed):
            break
        interface.update()
        if (time.time() - lastClock > 1/realClockHz/2):

            dTsmooth = dTsmooth*0.9 + (time.time() - lastClock)*0.1
            lastClock = time.time()

            clockVal = 1-clockVal

            # key can either be pressed on interface or keyboard
            if (clockVal == 1):
                update_debounce()
                chip.keypad.value = button_data | key_buttons_data

            
            main.clockMain.value = clockVal
            #sync chip time with real time
            await Timer(1000/clockSimHz/2, unit='ms')
       
            if (clockVal == 1):
                cocotb.log.info("RE "+str(cycles))
                cocotb.log.info(f"keypad {chip.keypad.value}, timers D{chip.timer1.value}, S{chip.timer2.value} > {chip.beep.value}")
                if (chip.err.value != 0):
                    cocotb.log.error(f"chip error signal {chip.err.value}")
                    break
                cocotb.log.info(f"instruction {chip.instruction.value} , substep {chip.subcounter.value}, stack <= {hex(chip.stackP.value)}, I @ {hex(chip.I.value)}")
                cocotb.log.info(f"PC @ {hex(chip.pc.value)}, raw instruction {chip.ibytes_sig.value} = {hex(chip.ibytes_sig.value) + ("?" if chip.instruction.value == 0 else "")}")
                cocotb.log.info(f"{main.Sram_address.value} => ram => {ram.dataout.value}")
                cocotb.log.info(" ".join([ f"{reg(i)}: {hex(chip[reg(i)].value)[2::]}," for i in range(16)]))

                cocotb.log.info(f"running at ~{int(10/(2*(dTsmooth)))/10}Hz")
                cocotb.log.info("\n")

                #await dump_ram(ram,80,0x200)
                cycles +=1

# ---

# --- helpers

async def pulseH(pin, dur):
    pin.value = 0
    await Timer(dur//2, unit="ns")
    pin.value = 1
    await Timer(dur//2, unit="ns")
    pin.value = 0
    cocotb.log.debug("pulsed")


async def displayUpdate(dut):
    while True:
        await RisingEdge(dut.display_clk)
        signal = dut.display_dout.value
        #cocotb.log.info(f"Display Signal: {signal}")
        val = list(signal[15:8]) #VVVVVVVVPPPPPPPP
        pos = int(signal[7:0])
        posX = (pos*8) % 64
        posY = (pos*8) // 64
        #cocotb.log.info(f"{signal[15:8]} {posX} {posY}")

        for o in range(8):
            target = displayGrid[posX+o][posY]
            p,q = [(posX+o)/63,posY/31]
            color = "black" if val[o]==0 else "#" + "".join(f"{int(255 * c):02x}" for c in [p,1-p*q,q] )
            canv.itemconfig(target, fill=color)

async def write_ram(device,data,start):
    cocotb.log.info("writing "+str(len(data))+" bytes at "+hex(start))
    device.Sram_we.value = Force(True)
    for i in range(len(data)):
        device.Sram_address.value = Force(start+i)
        device.Sram_dw.value = Force(data[i])
        await pulseH(device.clockMain,1e9/clockSimHz)
    device.Sram_we.value = Release()
    device.Sram_address.value = Release()
    device.Sram_dw.value = Release()
"""
async def read_ram(device,bytes,start):
    cocotb.log.info("reading "+str(bytes)+" bytes at "+hex(start))
    device.we.value = False
    data = bytearray(bytes)
    for i in range(bytes):
        device.address.value = i+start
        await pulseH(device.clock,1e9/clockSimHz)
        data[i] = device.dataout.value

    return data
"""

async def dump_ram(device,bytes,start):
    data = device.ram_i.value[start:start+bytes]
    dump = ""
    line = ""
    for i in range(bytes):
        if i % 16 == 0:
            line += "\t" +hex(i+start) + "\t"
        if (data[i+start][0] in [0,1]):
            line += hex(data[i+start])[2:]
        else:
            line += "UU"
        line += " "
        if i % 16 == 15:
            dump += line+"\n"
            line = ""

    cocotb.log.info(dump)

# ---