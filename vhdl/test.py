import cocotb
from cocotb.triggers import Timer
import random
async def pulseH(pin, dur):
    pin.value = 0
    await Timer(dur//2, unit="ns")
    pin.value = 1
    await Timer(dur//2, unit="ns")
    pin.value = 0
    cocotb.log.debug("pulsed")

@cocotb.test
async def test_hello_world(dut):
    cocotb.log.info("Hello, World!")

@cocotb.test
async def test_ram(dut):
    address = random.randint(0,2**8-7)
    await write_ram(dut,bytes("testhii",encoding="ascii"),address)

    out = await read_ram(dut,8,address)
    cocotb.log.info("read:")
    cocotb.log.info(out)

async def write_ram(device,data,start):
    cocotb.log.info("writing "+str(len(data))+" bytes at "+hex(start))
    device.we.value = True
    for i in range(len(data)):
        device.address.value = start+i

        await Timer(100, unit="ns")

        device.datain.value = data[i]

        await pulseH(device.clock,100)
    device.we.value = True

async def read_ram(device,bytes,start):
    cocotb.log.info("reading "+str(bytes)+" bytes at "+hex(start))
    device.we.value = False
    data = bytearray(bytes)
    for i in range(bytes):
        device.address.value = i+start
        await pulseH(device.clock,100)
        data[i] = device.dataout.value
        await Timer(100, unit="ns")

    return data