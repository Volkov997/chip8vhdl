library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity chip is
    generic (
        CLOCK_DIV : integer := 1024 -- up to 65.535kHz, clock div for 1 sec timer
    );
    port (
        clock : in std_logic;
        ram_we : out std_logic := '0';
        ram_address : out std_logic_vector (11 downto 0);
        ram_din : in std_logic_vector (7 downto 0);
        ram_dout : out std_logic_vector (7 downto 0);
        display_dout : out std_logic_vector (15 downto 0); -- 1 byte of values, 1 byte position
        display_clk : out std_logic := '0'; -- display write signal
        beep : out std_logic := '0';
        keypad : in std_logic_vector (15 downto 0) := (others => '0');
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
    (EMPTY, I_0NNN, I_00E0, I_1NNN, I_6XNN, I_7XNN, I_ANNN, I_DXYN,
    I_2NNN, I_00EE, I_3XNN, I_4XNN, I_5XY0, I_9XY0, I_8XYN, I_BNNN,
    I_CXNN, I_EX9E, I_EXA1, I_FX07, I_FX15, I_FX18, I_FX1E, I_FX0A,
    I_FX29, I_FX33, I_FX55, I_FX66);
    signal instruction : I_TYPE := EMPTY;
    signal subcounter : unsigned(11 downto 0) := (others => '0');

    --debug signal
    signal ibytes_sig : std_logic_vector(15 downto 0) := (others => '0');

    signal XSel : unsigned(3 downto 0) := (others => '0');
    signal YSel : unsigned(3 downto 0) := (others => '0');
    signal VXr : unsigned(7 downto 0) := (others => '0');
    signal VYr : unsigned(7 downto 0) := (others => '0');

    signal drawBufPos : unsigned(10 downto 0);
    signal drawBufPosEnd : unsigned(10 downto 0);
    signal drawBufPosY : unsigned(4 downto 0);
    signal ramDrawSlice : unsigned(2 downto 0) := (others => '0');

    signal clockCount : unsigned(15 downto 0) := (others => '0');
    signal firstKey : unsigned(3 downto 0) := (others => '0');
begin
    dispdriver : entity work.dispdriver
        port map(
            clock => '0',
            update => display_update,
            buf => display_buf,
            dispClk => display_clk,
            data => display_dout
        );

    --read from VX/VY
    with to_integer(XSel) select
    VXr <= V0 when 0, V1 when 1, V2 when 2, V3 when 3,
           V4 when 4, V5 when 5, V6 when 6, V7 when 7,
           V8 when 8, V9 when 9, VA when 10, VB when 11,
           VC when 12, VD when 13, VE when 14, VF when others;
    with to_integer(YSel) select
    VYr <= V0 when 0, V1 when 1, V2 when 2, V3 when 3,
           V4 when 4, V5 when 5, V6 when 6, V7 when 7,
           V8 when 8, V9 when 9, VA when 10, VB when 11,
           VC when 12, VD when 13, VE when 14, VF when others;

    with timer2 select
        beep <= '0' when x"00",
        '1' when others;

    -- first pressed key
    firstKey <= x"0" when keypad(0) = '1' else
                x"1" when keypad(1) = '1' else
                x"2" when keypad(2) = '1' else
                x"3" when keypad(3) = '1' else
                x"4" when keypad(4) = '1' else
                x"5" when keypad(5) = '1' else
                x"6" when keypad(6) = '1' else
                x"7" when keypad(7) = '1' else
                x"8" when keypad(8) = '1' else
                x"9" when keypad(9) = '1' else
                x"a" when keypad(10) = '1' else
                x"b" when keypad(11) = '1' else
                x"c" when keypad(12) = '1' else
                x"d" when keypad(13) = '1' else
                x"e" when keypad(14) = '1' else
                x"f"; --also default case if all 0

    -- clocked process

    Exec : process (clock) is
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
        variable calc : unsigned(15 downto 0) := (others => '0');
    begin
        if (chipEN = '1' and rising_edge(clock)) then
            -- update timers
            clockCount <= clockCount + 1;
            if clockCount >= CLOCK_DIV then
                clockCount <= (others => '0');
                if not (timer1 = 0) then
                    timer1 <= timer1 - 1;
                end if;
                if not (timer2 = 0) then
                    timer2 <= timer2 - 1;
                else
                end if;
            end if;

            -- fetch/execute
            case instruction is

                when I_00E0 => -- clear screen
                    display_buf <= (others => '0');
                    display_update <= '1';
                    instruction <= EMPTY;

                when I_1NNN => -- jump to NNN
                    PC(11 downto 0) <= NNN;
                    instruction <= EMPTY;

                when I_6XNN => -- set VX to NN
                    wVX := '1';
                    VX := NN;
                    instruction <= EMPTY;

                when I_7XNN => -- increment VX by NN
                    wVX := '1';
                    VX := VXr + NN;
                    instruction <= EMPTY;

                when I_ANNN =>
                    I(11 downto 0) <= NNN;
                    instruction <= EMPTY;

                when I_DXYN =>
                    subcounter <= subcounter + 1; -- rows only go up to 31, so last 5 bytes for addressing
                    ram_address <= std_logic_vector(I(11 downto 0) + subcounter(4 downto 0));
                    drawBufPosY <= VYr(4 downto 0) + subcounter(4 downto 0); -- 1 cycles behind
                    drawBufPos <= drawBufPosY & VXr(5 downto 0); -- 2 cycles behind = synced to ram output

                    if (VXr(5 downto 0) < 56) then
                        drawBufPosEnd <= drawBufPosY & (VXr(5 downto 0) + 7);
                        ramDrawSlice <= (others => '0');
                    else
                        drawBufPosEnd <= drawBufPosY & to_unsigned(63, 6);
                        ramDrawSlice <= VXr(2 downto 0) - to_unsigned(56, 3);
                    end if;

                    if (to_integer(subcounter) = 0) then
                        --terminate immeadiatly to not wait for ram and write first line
                        if (N = 0) then
                            subcounter <= (others => '0');
                            instruction <= EMPTY;
                        end if;
                        ram_we <= '0';
                        VF <= to_unsigned(0, 8);
                    elsif (to_integer(subcounter) = 1) then
                        --empty pulse waiting for RAM to output first byte
                    else
                        --ram value in cycle 2 from address in cycle 0
                        display_buf(to_integer(drawBufPos) to to_integer(drawBufPosEnd)) <= ram_din(7 downto to_integer(ramDrawSlice)) xor display_buf(to_integer(drawBufPos) to to_integer(drawBufPosEnd));
                        --report integer'image(to_integer(unsigned((ram_din(7 downto to_integer(ramDrawSlice)) and display_buf(to_integer(drawBufPos) to to_integer(drawBufPosEnd))))));

                        if not (0 = unsigned(ram_din(7 downto to_integer(ramDrawSlice)) and display_buf(to_integer(drawBufPos) to to_integer(drawBufPosEnd)))) then
                            --report "collision";
                            VF <= to_unsigned(1, 8);
                        end if;
                        -- end if reached N, or would roll back to 0 next cycle <=> drawing in first line without VY being 0 ( cant roll over for VY <= 16 since N <= 15)
                        if (to_integer(subcounter) > N or (drawBufPosY = 0 and VYr(4) = '1')) then
                            subcounter <= (others => '0');
                            instruction <= EMPTY;
                            display_update <= '1'; -- update at end to prevent tearing
                        end if;

                    end if;

                when I_0NNN => -- unsupported
                    report "machine code instruction";
                    err(2) <= '1';
                    instruction <= EMPTY;

                when I_3XNN => -- conditional jumps
                    instruction <= EMPTY;
                    if (VXr = NN) then
                        PC <= PC + 2;
                    end if;
                when I_4XNN =>
                    instruction <= EMPTY;
                    if not (VXr = NN) then
                        PC <= PC + 2;
                    end if;
                when I_5XY0 =>
                    instruction <= EMPTY;
                    if (VXr = VYr) then
                        PC <= PC + 2;
                    end if;
                when I_9XY0 =>
                    instruction <= EMPTY;
                    if not (VXr = VYr) then
                        PC <= PC + 2;
                    end if;

                when I_8XYN => -- arithmetic
                    instruction <= EMPTY;
                    wVX := '1';
                    case N is
                        when x"0" =>
                            VX := VYr;
                        when x"1" =>
                            VX := VXr or VYr;
                        when x"2" =>
                            VX := VXr and VYr;
                        when x"3" =>
                            VX := VXr xor VYr;

                        when x"4" => -- X+Y
                            calc(8 downto 0) := ('0' & VXr) + ('0' & VYr);
                            VX := calc(7 downto 0);
                            VF <= (others => '0');
                            VF(0) <= calc(8);
                        when x"5" => -- X-Y
                            calc(8 downto 0) := ('1' & VXr) - ('0' & VYr);
                            VX := calc(7 downto 0);
                            VF <= (others => '0');
                            VF(0) <= calc(8);
                        when x"7" => -- Y-X
                            calc(8 downto 0) := ('1' & VYr) - ('0' & VXr);
                            VX := calc(7 downto 0);
                            VF <= (others => '0');
                            VF(0) <= calc(8);

                        when x"6" => -- shift VX down
                            calc(8 downto 0) := '0' & VXr;
                            VX := calc(8 downto 1);
                            VF <= (others => '0');
                            VF(0) <= calc(0);
                        when x"E" => -- shift VX up
                            calc(8 downto 0) := VXr & '0';
                            VX := calc(7 downto 0);
                            VF <= (others => '0');
                            VF(0) <= calc(8);

                        when others =>
                            err(1) <= '1';
                            VX := VXr;
                    end case;

                when I_BNNN =>
                    -- possibly jump to VX+XNN instead
                    calc := V0 + NNN;
                    I <= calc;
                    instruction <= EMPTY;

                when I_CXNN =>
                    wVX := '1';
                    VX := (others => '0'); -- TODO: actual randoom implementation !!!!
                    instruction <= EMPTY;

                when I_EX9E => -- skip if key 0-F in keypad pressed
                    instruction <= EMPTY;
                    if (keypad(to_integer(VXr(3 downto 0))) = '1') then
                        PC <= PC + 2;
                    end if;
                when I_EXA1 =>
                    instruction <= EMPTY;
                    if (keypad(to_integer(VXr(3 downto 0))) = '0') then
                        PC <= PC + 2;
                    end if;

                when I_FX0A => -- wait until key pressed
                    if (keypad = x"0000") then
                        instruction <= I_FX0A; -- loop if not
                    else
                        wVX := '1';
                        instruction <= EMPTY;
                        -- first pressed key in one instruction
                        VX(7 downto 4) := x"0";
                        VX(3 downto 0) := firstKey;
                    end if;

                when I_FX07 => -- set VX to delay timer
                    instruction <= EMPTY;
                    wVX := '1';
                    VX := timer1;

                when I_FX15 => -- set delay timer to VX
                    instruction <= EMPTY;
                    timer1 <= VXr;
                when I_FX18 => -- sound timer
                    instruction <= EMPTY;
                    timer2 <= VXr;

                when I_FX1E => -- increment I
                    calc := I + VXr;
                    I <= calc;
                    VF <= (others => '0');
                    --- overflow , maybe "not (calc(15 to 12) = x"0")"
                    if calc > x"0FFF" then
                        VF(0) <= '1';
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
                            elsif Q = x"0" then
                                instruction <= I_0NNN;

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

                            elsif Q = x"2" then
                                instruction <= I_2NNN;
                            elsif ibytes = x"00EE" then
                                instruction <= I_00EE;

                            elsif Q = x"3" then
                                instruction <= I_3XNN;
                            elsif Q = x"4" then
                                instruction <= I_4XNN;
                            elsif Q = x"5" and N = x"0" then
                                instruction <= I_5XY0;
                            elsif Q = x"9" and N = x"0" then
                                instruction <= I_9XY0;

                            elsif Q = x"8" then
                                instruction <= I_8XYN;

                            elsif Q = x"B" then
                                instruction <= I_BNNN;

                            elsif Q = x"C" then
                                instruction <= I_CXNN;

                            elsif Q = x"E" and NN = x"9E" then
                                instruction <= I_EX9E;
                            elsif Q = x"E" and NN = x"A1" then
                                instruction <= I_EXA1;

                            elsif Q = x"F" and NN = x"07" then
                                instruction <= I_FX07;
                            elsif Q = x"F" and NN = x"15" then
                                instruction <= I_FX15;
                            elsif Q = x"F" and NN = x"18" then
                                instruction <= I_FX18;

                            elsif Q = x"F" and NN = x"1E" then
                                instruction <= I_FX07;
                            elsif Q = x"F" and NN = x"0A" then
                                instruction <= I_FX0A;
                            elsif Q = x"F" and NN = x"29" then
                                instruction <= I_FX29;
                            elsif Q = x"F" and NN = x"33" then
                                instruction <= I_FX33;
                            elsif Q = x"F" and NN = x"55" then
                                instruction <= I_FX55;
                            elsif Q = x"F" and NN = x"66" then
                                instruction <= I_FX66;

                            else
                                report "undefined instruction";
                                err(1) <= '1'; --execution of a wrong or undefined instruction
                            end if;
                        when others => null;
                    end case; --subcase
                when others =>
                    report "instruction not defined";
                    err(2) <= '1'; -- instruction not implemented
                    instruction <= EMPTY;
            end case; -- instruction case

            -- post execute signal changes

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

            if display_update = '1' then -- update should get single clock pulse
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