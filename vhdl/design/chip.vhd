library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity chip is
    port (
        clock : in std_logic;
        ram_we : out std_logic := '0';
        ram_address : out std_logic_vector (11 downto 0);
        ram_din : in std_logic_vector (7 downto 0);
        ram_dout : out std_logic_vector (7 downto 0);
        display_dout : out std_logic_vector (11 downto 0); -- one bit of value, 11 bits of address
        display_w : out std_logic := '0'; -- write signal
        beep : out std_logic := '0';
        keypad : in std_logic_vector (15 downto 0);
        chipEN : in std_logic := '1';
        err : out std_logic_vector(3 downto 0) := (others => '0')

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

    type I_TYPE is
    (EMPTY, I_00E0, I_1NNN, I_6XNN, I_7XNN, I_ANNN, I_DXYN);
    signal instruction : I_TYPE := EMPTY;
    signal subcounter : unsigned(11 downto 0) := (others => '0');

    --debug signal
    signal ibytes_sig : std_logic_vector(15 downto 0) := (others => '0');

    signal disp_clockw : std_logic := '0';
begin

    with disp_clockw select
    display_w <= clock when '1',
    '0' when others;

    Exec : process (clock, chipEN) is
        variable Q : unsigned(3 downto 0) := (others => '0');
        variable X : unsigned(3 downto 0) := (others => '0');
        variable Y : unsigned(3 downto 0) := (others => '0');
        variable N : unsigned(3 downto 0) := (others => '0');
        variable NN : unsigned(7 downto 0) := (others => '0');
        variable NNN : unsigned(11 downto 0) := (others => '0');
        variable ibytes : std_logic_vector(15 downto 0) := (others => '0');

    begin

        --default if not assigned differently, always have ram ready to read
        if (rising_edge(clock)) then
            --;
            --ram_address <= std_logic_vector(PC(11 downto 0));
        end if;

        if (chipEN = '1' and rising_edge(clock)) then
            subcounter <= subcounter + 1;

            case instruction is

                when I_00E0 => -- clear screen
                    -- very unoptimised, taking >3s at 700Hz

                    display_dout(11) <= '0';
                    display_dout(10 downto 0) <= std_logic_vector(subcounter(10 downto 0));

                    case to_integer(subcounter) is
                        when 0 =>
                            disp_clockw <= '1'; --writes to display with every clock pulse now
                            -- position 0 written at clock pulse 1
                        when 2048 => -- last bit was written 
                            disp_clockw <= '0';
                        when others => null;
                    end case;

                when EMPTY =>
                    --only happens if not reset to 0, at the end of process

                    case to_integer(subcounter) is
                        when 0 =>
                            ram_we <= '0';
                            ram_address <= std_logic_vector(PC(11 downto 0));
                        when 1 =>
                            ram_address <= std_logic_vector(PC(11 downto 0) + 1);
                            -- first read done
                        when 2 =>
                            PC <= PC + 2;
                            ibytes(15 downto 8) := ram_din;
                            -- second read done
                        when 3 =>
                            ibytes(7 downto 0) := ram_din;
                            instruction <= EMPTY;
                            subcounter <= to_unsigned(0, subcounter'length);

                            Q := unsigned(ibytes(15 downto 12));
                            X := unsigned(ibytes(11 downto 8));
                            Y := unsigned(ibytes(7 downto 4));
                            N := unsigned(ibytes(3 downto 0));
                            NN := unsigned(ibytes(7 downto 0));
                            NNN := unsigned(ibytes(11 downto 0));

                            if ibytes = x"00E0" then
                                instruction <= I_00E0;
                            end if;
                        when others => null;
                    end case; --subcase
                when others =>
                    err(3) <= '1';
                    instruction <= EMPTY;
            end case; -- instruction case
            ibytes_sig <= ibytes;
        end if;
    end process Exec;
end architecture Rtl;

--                            case to_integer(X) is
--                                when 0 => VX <= V0;
--                                when 1 => VX <= V1;
--                                when 2 => VX <= V2;
--                                when 3 => VX <= V3;
--                                when 4 => VX <= V4;
--                                when 5 => VX <= V5;
--                                when 6 => VX <= V6;
--                                when 7 => VX <= V7;
--                                when 8 => VX <= V8;
--                                when 9 => VX <= V9;
--                                when 10 => VX <= VA;
--                                when 11 => VX <= VB;
--                                when 12 => VX <= VC;
--                                when 13 => VX <= VD;
--                                when 14 => VX <= VE;
--                                when others => VX <= VF;