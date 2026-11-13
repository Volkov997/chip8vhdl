library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity dispdriver is
    port (
        clock : in std_logic := '0';
        driveClock : in std_logic := '0';
        update : in std_logic := '0';
        buf : in std_logic_vector (0 to 32 * 64) := (others => '0');
        dispClk : out std_logic := '0';
        data : out std_logic_vector (15 downto 0) := (others => '0')
    );
end entity dispdriver;

architecture Rtl of dispdriver is
    signal writing : std_logic := '0';
    signal counter : unsigned(7 downto 0) := (others => '0');
    signal schedule : std_logic := '0';
    signal resetCounter : std_logic := '0';
    signal writingDone : std_logic := '0';
begin

    with writing select
        dispClk <= driveClock when '1',
        '0' when others;
    --data <= "11001100" & std_logic_vector(counter);
    data <= buf(8 * to_integer(counter) to 8 * to_integer(counter) + 7) & std_logic_vector(counter);

    process (driveClock)
    begin
        if (rising_edge(driveClock)) then
            if (resetCounter = '1') then
                counter <= (others => '0');
                writingDone <= '0';
            end if;

            if (writing = '1' and not (counter = 255)) then
                counter <= counter + 1;
            elsif (counter = 255) then
                writingDone <= '1';
            end if;
        end if;
    end process;
    process (clock)
    begin
        if (rising_edge(clock)) then

            if (update = '1') then
                writing <= '1';
                if not (counter = 0) then
                    schedule <= '1';
                end if;
            end if;

            if (writingDone = '1') then
                resetCounter <= '1';
                writing <= '0';
            else
                if (schedule = '1') then
                    writing <= '1';
                    schedule <= '0';
                end if;
                resetCounter <= '0';
            end if;
        end if;
    end process;

end architecture;