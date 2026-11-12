library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity randgen is
    port (
        clock : in std_logic := '0';
        data : out unsigned(7 downto 0) := (others => '0')
    );
end entity randgen;

architecture Rtl of randgen is
    signal count : unsigned(7 downto 0) := (others => '0');
begin
    process (clock) is
        variable k : unsigned(16 downto 0) := (others => '0');
    begin
        if (rising_edge(clock)) then
            if (to_integer(count) = 240) then
                count <= (others => '0');
            else
                count <= count + 1;
            end if; -- 241 distinct values, to break up cycles
            k := k + 997;
            k(15 downto 5) := k(13 downto 3) xor k(10 downto 0);
            k := shift_right(k, 1);
            k := k + count;
            data <= k(7 downto 0);
        end if;
    end process;

end architecture;