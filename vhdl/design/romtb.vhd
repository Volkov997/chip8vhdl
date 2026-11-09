library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;

entity tb_rom is
end entity tb_rom;

architecture test of tb_rom is
component ROM is port (
        iAdd : in UNSIGNED(3 downto 0) ;
        oDat : out UNSIGNED(3 downto 0)
    );
end component;

file file_VECTORS : text;
 

signal iAdd : UNSIGNED(3 downto 0) ;
signal oDat : UNSIGNED(3 downto 0);

begin
----------------------------------------------------------
    -- Testcases
    --------------------------------------------------------------------    
    
    dut : ROM port map (
        iAdd => iAdd,
        oDat => oDat
    );

    process
    begin
        for i in 0 to 15 loop
            iAdd <= to_unsigned(i, iAdd'length);
            wait for 10 ns;
            report to_hstring(oDat);
        end loop;
    wait;
    end process;
end architecture;