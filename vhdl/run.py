import cocotb
from cocotb.triggers import *
from cocotb.handle import *
import random

async def pulseH(pin, dur):
    pin.value = 0
    await Timer(dur//2, unit="ns")
    pin.value = 1
    await Timer(dur//2, unit="ns")
    pin.value = 0
    cocotb.log.debug("pulsed")



import tkinter as tk
import time
interface = tk.Tk()

DISP_W = 64
DISP_H = 32
PIX = 20
canv = tk.Canvas(interface, bg="black",height=DISP_H*PIX,width=DISP_W*PIX)

displayGrid = []
for x in range(DISP_W):
    v=[]
    for y in range(DISP_H):
        r = canv.create_rectangle(x*PIX, y*PIX, (x+1)*PIX, (y+1)*PIX,fill="white",width=0,outline="#333")
        v.append(r)
    displayGrid.append(v)

canv.pack()


fontData = bytearray([
    0xF0, 0x90, 0x90, 0x90, 0xF0, 
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
    0xF0, 0x80, 0xF0, 0x80, 0x80 
])
fontAddress = 0x50


progFile = "../programs/single.ch8"
progData = None
with open(progFile, "rb") as f:
    progData = bytearray(f.read())  
progAddress = 0x200

clockSimHz = 1e5
realClockHz = 40

def reg(i):
    return "V"+hex(i)[2::]

@cocotb.test
async def run(main):

    chip = main.chipdut
    ram = main.ramdut

    #callbacks
    cocotb.start_soon(displayUpdate(chip))
    cocotb.start_soon(monitor(main))

    main.clockMain.value = 0

    chip.chipEN.value = 0
    await write_ram(main,fontData,fontAddress)
    await write_ram(main,progData,progAddress)

    chip.PC.value = 0x200
    await pulseH(main.clockMain,1e9/clockSimHz)
    await pulseH(main.clockMain,1e9/clockSimHz)


    chip.chipEN.value = 1

    await dump_ram(ram,80,0x1F0)

    lastClock = 0
    clockVal = 1
    cycles = 0


    while True:
        interface.update()
        if (time.time() - lastClock > 1/realClockHz/2):
            #sync chip time with real time
            await Timer(1000/clockSimHz/2, unit='ms')
            clockVal = 1-clockVal
            main.clockMain.value = clockVal

            lastClock = time.time()
            if (clockVal == 1):
                cocotb.log.info("RE "+str(cycles))
                cycles +=1
                await Timer(100,unit='ns')
                if (chip.err.value != 0):
                    cocotb.log.error(f"chip error signal {chip.err.value}")
                cocotb.log.info(f"instruction {chip.instruction.value} , substep {chip.subcounter.value}")
                cocotb.log.info(f"PC @ {chip.pc.value}, raw instruction {chip.ibytes_sig.value}")
                cocotb.log.info(f"{main.Sram_address.value} => ram => {ram.dataout.value}")
                cocotb.log.info(" ".join([ f"{reg(i)}: {hex(chip[reg(i)].value)[2::]}," for i in range(16)]))
    pass

async def monitor(dut):
    while True:
        await RisingEdge(dut.clockMain)
        await Timer(1, unit="ns")

async def displayUpdate(dut):
    """A background monitor task."""
    while True:
        await RisingEdge(dut.display_clk)
        signal = dut.display_dout.value
        cocotb.log.info(f"Display Signal: {signal}")
        val = list(signal[15:8]) #VVVVVVVVPPPPPPPP
        pos = int(signal[7:0])
        posX = (pos*8) % 64
        posY = (pos*8) // 64
        cocotb.log.info(f"{signal[15:8]} {posX} {posY}")

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