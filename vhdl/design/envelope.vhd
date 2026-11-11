library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity envelope is
    port (
        clockMain : in std_logic
    );
end entity envelope;
architecture Rtl of envelope is
    signal Sram_address : std_logic_vector (11 downto 0);
    signal Sram_dr : std_logic_vector (7 downto 0);
    signal Sram_dw : std_logic_vector (7 downto 0);
    signal Sram_we : std_logic := '0';
begin
    chipdut : entity work.chip
        generic map(CLOCK_DIV => 240)
        port map(
            clock => clockMain,
            ram_we => Sram_we,
            ram_address => Sram_address,
            ram_din => Sram_dr,
            ram_dout => Sram_dw,
            display_dout => open,
            display_clk => open,
            beep => open,
            keypad => (others => '0'),
            chipEN => open,
            err => open
        );
    ramdut : entity work.ram
        --generic map(address_size => 12)
        port map(
            clock => clockMain,
            we => Sram_we,
            address => Sram_address,
            datain => Sram_dw,
            dataout => Sram_dr
        );

end architecture;