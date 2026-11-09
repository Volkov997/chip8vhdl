library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity chip is
    port (
        clock : in std_logic;
        ram_we : out std_logic := '0';
        ram_address : inout std_logic_vector (11 downto 0);
        ram_din : in std_logic_vector (7 downto 0);
        ram_dout : out std_logic_vector (7 downto 0);
        display_dout : out std_logic_vector (11 downto 0); -- one bit of value, 11 bits of address
        display_w : out std_logic := '0'; -- write signal
        beep : out std_logic := '0';
        keypad : in std_logic_vector (15 downto 0);
        chipEN : in std_logic := '1'
    );
end entity chip;

architecture Rtl of chip is
    signal PC : unsigned(15 downto 0) := (others => '0');
    signal I : unsigned(15 downto 0) := (others => '0');
    signal stackP : unsigned(15 downto 0) := X"0200"; -- stack between 09F and 1FF, 176 adresses 
    signal timer1 : unsigned(7 downto 0) := (others => '0');
    signal timer2 : unsigned(7 downto 0) := (others => '0');

    signal V0 : unsigned(7 downto 0) := (others => '0');
    signal V1 : unsigned(7 downto 0) := (others => '0');
    signal V2 : unsigned(7 downto 0) := (others => '0');
    signal V3 : unsigned(7 downto 0) := (others => '0');
    signal V4 : unsigned(7 downto 0) := (others => '0');
    signal V5 : unsigned(7 downto 0) := (others => '0');
    signal V6 : unsigned(7 downto 0) := (others => '0');
    signal V7 : unsigned(7 downto 0) := (others => '0');
    signal V8 : unsigned(7 downto 0) := (others => '0');
    signal V9 : unsigned(7 downto 0) := (others => '0');
    signal VA : unsigned(7 downto 0) := (others => '0');
    signal VB : unsigned(7 downto 0) := (others => '0');
    signal VC : unsigned(7 downto 0) := (others => '0');
    signal VD : unsigned(7 downto 0) := (others => '0');
    signal VE : unsigned(7 downto 0) := (others => '0');
    signal VF : unsigned(7 downto 0) := (others => '0');

    procedure reset is
    begin

    end procedure;

begin

    Exec : process (clock, chipEN) is
        type I_TYPE is
        (EMPTY, I_00E0, I_1NNN, I_6XNN, I_7XNN, I_ANNN, I_DXYN);
        variable instruction : I_TYPE;
        variable subcounter : unsigned(7 downto 0) := (others => '0');
    begin
        if (chipEN = '0') then
            reset;
        elsif rising_edge(clock) then
            case instruction is
                when others => instruction := EMPTY;
            end case;
        end if;
    end process Exec;

end architecture Rtl;