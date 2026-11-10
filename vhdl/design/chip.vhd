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
        display_dout : out std_logic_vector (15 downto 0); -- 1 byte of values, 1 byte position
        display_clk : out std_logic := '0'; -- display write signal
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

    signal display_buf : std_logic_vector(0 to 64 * 32) := (others => '0');
    signal display_update : std_logic := '0';

    type I_TYPE is
    (EMPTY, I_00E0, I_1NNN, I_6XNN, I_7XNN, I_ANNN, I_DXYN);
    signal instruction : I_TYPE := EMPTY;
    signal subcounter : unsigned(11 downto 0) := (others => '0');

    --debug signal
    signal ibytes_sig : std_logic_vector(15 downto 0) := (others => '0');

    signal XSel : unsigned(3 downto 0) := (others => '0');
    signal YSel : unsigned(3 downto 0) := (others => '0');
    signal VXS : unsigned(7 downto 0) := (others => '0');
    signal VYS : unsigned(7 downto 0) := (others => '0');
begin
    dispdriver : entity work.dispdriver
        port map(
            clock => clock,
            update => display_update,
            buf => display_buf,
            dispClk => display_clk,
            data => display_dout
        );

    --read from VX/VY
    with to_integer(XSel) select
    VXS <= V0 when 0, V1 when 1, V2 when 2, V3 when 3,
           V4 when 4, V5 when 5, V6 when 6, V7 when 7,
           V8 when 8, V9 when 9, VA when 10, VB when 11,
           VC when 12, VD when 13, VE when 14, VF when others;
    with to_integer(YSel) select
    VYS <= V0 when 0, V1 when 1, V2 when 2, V3 when 3,
           V4 when 4, V5 when 5, V6 when 6, V7 when 7,
           V8 when 8, V9 when 9, VA when 10, VB when 11,
           VC when 12, VD when 13, VE when 14, VF when others;

    Exec : process (clock, chipEN) is
        variable Q : unsigned(3 downto 0) := (others => '0');
        variable X : unsigned(3 downto 0) := (others => '0');
        variable Y : unsigned(3 downto 0) := (others => '0');
        variable N : unsigned(3 downto 0) := (others => '0');
        variable NN : unsigned(7 downto 0) := (others => '0');
        variable NNN : unsigned(11 downto 0) := (others => '0');
        variable ibytes : std_logic_vector(15 downto 0) := (others => '0');
        --variable calc : unsigned(8 downto 0) := (others => '0');
        variable VX : unsigned(7 downto 0) := (others => '0');
        variable VY : unsigned(7 downto 0) := (others => '0');
        variable wVX : std_logic := '0';
        variable wVY : std_logic := '0';

        variable drawBufPos : unsigned(10 downto 0);

    begin
        if (chipEN = '1' and rising_edge(clock)) then
            case instruction is

                when I_00E0 => -- clear screen
                    display_buf <= (others => '0');
                    display_update <= '1';
                    instruction <= EMPTY;

                when I_1NNN => -- jump to NNN
                    PC(11 downto 0) <= NNN;
                    instruction <= EMPTY;

                when I_6XNN => -- set VX to NN
                    VX := NN;
                    wVX := '1';
                    instruction <= EMPTY;

                when I_7XNN => -- increment VX by NN
                    VX := VXS + NN;
                    wVX := '1';
                    instruction <= EMPTY;

                when I_ANNN =>
                    I(11 downto 0) <= NNN;
                    instruction <= EMPTY;

                when I_DXYN =>
                    subcounter <= subcounter + 1; -- rows only go up to 31, so last 5 bytes for addressing
                    ram_address <= std_logic_vector(I(11 downto 0) + subcounter(4 downto 0));

                    if (to_integer(subcounter) = 0) then
                        ram_we <= '0';
                        VF <= (others => '0');
                    elsif (to_integer(subcounter) = 1) then
                        --empty pulse waiting for RAM to output first byte
                    else
                        drawBufPos := (VY(4 downto 0) + subcounter(4 downto 0)) & VX(5 downto 0);
                        display_buf(to_integer(drawBufPos) to to_integer(drawBufPos) + 7) <= ram_din xor display_buf(to_integer(drawBufPos) to to_integer(drawBufPos) + 7);
                        if not "00000000" = (ram_din and display_buf(to_integer(drawBufPos) to to_integer(drawBufPos) + 7)) then
                            report "collision";
                        end if;
                    end if;
                    if (to_integer(subcounter) > N) then
                        subcounter <= (others => '0');
                        instruction <= EMPTY;
                        display_update <= '1';
                    end if;

                when EMPTY =>
                    subcounter <= subcounter + 1;

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
                            subcounter <= (others => '0');

                            Q := unsigned(ibytes(15 downto 12));
                            X := unsigned(ibytes(11 downto 8));
                            Y := unsigned(ibytes(7 downto 4));
                            N := unsigned(ibytes(3 downto 0));
                            NN := unsigned(ibytes(7 downto 0));
                            NNN := unsigned(ibytes(11 downto 0));

                            if ibytes = x"00E0" then
                                instruction <= I_00E0;
                            elsif Q = x"1" then
                                instruction <= I_1NNN;
                            elsif Q = x"6" then
                                instruction <= I_6XNN;
                            elsif Q = x"7" then
                                instruction <= I_7XNN;
                            elsif Q = x"A" then
                                instruction <= I_ANNN;
                            elsif Q = x"D" then
                                instruction <= I_DXYN;
                            end if;
                        when others => null;
                    end case; --subcase
                when others =>
                    err(3) <= '1';
                    instruction <= EMPTY;
            end case; -- instruction case

            ibytes_sig <= ibytes;

            if (wVX = '1') then
                --write to VX/VY
                case to_integer(X) is
                    when 0 => V0 <= VX;
                    when 1 => V1 <= VX;
                    when 2 => V2 <= VX;
                    when 3 => V3 <= VX;
                    when 4 => V4 <= VX;
                    when 5 => V5 <= VX;
                    when 6 => V6 <= VX;
                    when 7 => V7 <= VX;
                    when 8 => V8 <= VX;
                    when 9 => V9 <= VX;
                    when 10 => VA <= VX;
                    when 11 => VB <= VX;
                    when 12 => VC <= VX;
                    when 13 => VD <= VX;
                    when 14 => VE <= VX;
                    when others => VF <= VX;
                end case;
            end if;
            if (wVY = '1') then
                case to_integer(Y) is
                    when 0 => V0 <= VY;
                    when 1 => V1 <= VY;
                    when 2 => V2 <= VY;
                    when 3 => V3 <= VY;
                    when 4 => V4 <= VY;
                    when 5 => V5 <= VY;
                    when 6 => V6 <= VY;
                    when 7 => V7 <= VY;
                    when 8 => V8 <= VY;
                    when 9 => V9 <= VY;
                    when 10 => VA <= VY;
                    when 11 => VB <= VY;
                    when 12 => VC <= VY;
                    when 13 => VD <= VY;
                    when 14 => VE <= VY;
                    when others => VF <= VY;
                end case;
            end if;
            wVX := '0';
            wVY := '0';
            XSel <= X;
            YSel <= Y;

            if display_update = '1' then
                display_update <= '0';
            end if;
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