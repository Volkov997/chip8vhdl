ghdl -a --workdir=work design/rom.vhd
ghdl -a -fsynopsys --std=08 --workdir=work design/romtb.vhd

ghdl -e --workdir=work ROM
ghdl -e -fsynopsys --std=08 --workdir=work tb_rom

ghdl -r -fsynopsys --std=08 --workdir=work tb_rom