library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity bcdconv is
    port (
        hx : in unsigned(7 downto 0);
        BCD : out unsigned(11 downto 0) := (others => '0')
    );
end entity bcdconv;

architecture Rtl of bcdconv is
    function c4add3(
        bits : unsigned(3 downto 0)
    ) return unsigned is
    begin
        -- if (bits(3) and (bits(2) or bits(1) or bits(0)))
        if (bits > 4) then
            return bits + 3;
        else
            return bits;
        end if;
    end function;

    signal c0 : unsigned(11 downto 0) := (others => '0');
    signal c1 : unsigned(7 downto 0) := (others => '0');
    signal c2 : unsigned(7 downto 0) := (others => '0');
    signal c3 : unsigned(7 downto 0) := (others => '0');
begin
    BCD(0) <= hx(0);
    BCD(4 downto 1) <= c4add3(c0(3 downto 0));
    BCD(8 downto 5) <= c4add3(c0(7 downto 4));
    --BCD(12 downto 9) <= c4add3(c0(11 downto 8));
    -- only bit 9 actually set
    BCD(11 downto 10) <= "00";
    BCD(9) <= c4add3(c0(11 downto 8)) (0);

    c0(0) <= hx(1);
    c0(4 downto 1) <= c4add3(c1(3 downto 0));
    c0(8 downto 5) <= c4add3(c1(7 downto 4));

    c1(0) <= hx(2);
    c1(4 downto 1) <= c4add3(c2(3 downto 0));
    c1(6 downto 5) <= c2(5 downto 4);

    c2(0) <= hx(3);
    c2(4 downto 1) <= c4add3(c3(3 downto 0));
    c2(5) <= c3(4);

    c3(0) <= hx(4);
    c3(4 downto 1) <= c4add3('0' & hx(7 downto 5));
end architecture;