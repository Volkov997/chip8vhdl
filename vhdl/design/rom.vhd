library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM is
    port (
        iAdd : in UNSIGNED(3 downto 0) ;
        oDat : out UNSIGNED(3 downto 0)
    );
end entity ROM;

architecture Rtl of ROM is
begin
    with iAdd select
        oDat <= x"6" when x"0",
                x"9" when x"1",
                x"4" when x"2",
                x"2" when x"3",
                x"0" when x"4",
            x"F" when others;
end architecture;