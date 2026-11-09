library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity envelope is
    port (
        clockMain : in std_logic;
        display_dout : out std_logic_vector (11 downto 0);
        display_w : out std_logic := '0';
        beep : out std_logic := '0';
        keypad : in std_logic_vector (15 downto 0);
        chipEN : in std_logic := '1'
    );
end entity envelope;
architecture Rtl of envelope is

    component chip is
        port (
            clock : in std_logic;
            ram_we : out std_logic := '0';
            ram_address : inout std_logic_vector (11 downto 0);
            ram_din : in std_logic_vector (7 downto 0);
            ram_dout : out std_logic_vector (7 downto 0);
            display_dout : out std_logic_vector (11 downto 0);
            display_w : out std_logic := '0';
            beep : out std_logic := '0';
            keypad : in std_logic_vector (15 downto 0);
            chipEN : in std_logic := '1'
        );
    end component;
    component ram is
        generic (
            address_size : integer
        );
        port (
            clock : in std_logic;
            we : in std_logic;
            address : in std_logic_vector;
            datain : in std_logic_vector;
            dataout : out std_logic_vector
        );
    end component;
    signal Sram_address : std_logic_vector (11 downto 0);
    signal Sram_dr : std_logic_vector (7 downto 0);
    signal Sram_dw : std_logic_vector (7 downto 0);
    signal Sram_we : std_logic := '0';
begin
    chipdut : chip
    port map(
        clock => clockMain,
        ram_we => Sram_we,
        ram_address => Sram_address,
        ram_din => Sram_dr,
        ram_dout => Sram_dw,
        display_dout => display_dout,
        display_w => display_w,
        beep => beep,
        keypad => keypad,
        chipEN => chipEN
    );
    ramdut : ram
    generic map(
        address_size => 12
    )
    port map(
        clock => clockMain,
        we => Sram_we,
        address => Sram_address,
        datain => Sram_dw,
        dataout => Sram_dr
    );

end architecture;