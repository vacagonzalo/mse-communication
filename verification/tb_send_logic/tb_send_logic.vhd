library ieee;
use ieee.std_logic_1164.all;

entity tb_send_logic is
end tb_send_logic;

architecture tb of tb_send_logic is

    component send_logic
        port (clk_i          : in std_logic;
              en_i           : in std_logic;
              srst_i         : in std_logic;
              nm1_bytes_i    : in std_logic_vector (7 downto 0);
              uart_os_dv_i   : in std_logic;
              uart_os_rfd_i  : in std_logic;
              modem_is_dv_i  : in std_logic;
              modem_is_rfd_i : in std_logic;
              modem_send_o   : out std_logic);
    end component;

    signal clk_i          : std_logic;
    signal en_i           : std_logic;
    signal srst_i         : std_logic;
    signal nm1_bytes_i    : std_logic_vector (7 downto 0);
    signal uart_os_dv_i   : std_logic := '0';
    signal uart_os_rfd_i  : std_logic := '0';
    signal modem_is_dv_i  : std_logic := '0';
    signal modem_is_rfd_i : std_logic := '0';
    signal modem_send_o   : std_logic;

    constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';
    signal tb_counter_s : integer := 0;

begin

    dut : send_logic
    port map (clk_i          => clk_i,
              en_i           => en_i,
              srst_i         => srst_i,
              nm1_bytes_i    => "00000111",
              uart_os_dv_i   => uart_os_dv_i,
              uart_os_rfd_i  => uart_os_rfd_i,
              modem_is_dv_i  => modem_is_dv_i,
              modem_is_rfd_i => modem_is_rfd_i,
              modem_send_o   => modem_send_o);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk_i is really your main clock signal
    clk_i <= TbClock;
    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        nm1_bytes_i <= (others => '0');
        en_i <= '1';

        -- Reset generation
        -- EDIT: Check that srst_i is really your reset signal
        srst_i <= '1';
        wait for 1000 ns;
        srst_i <= '0';
        wait for 1000 ns;

        -- EDIT Add stimuli here
        wait for 100 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;
    ----
    process (clk_i)
    begin
        if rising_edge(clk_i) then
            tb_counter_s <= tb_counter_s + 1;
            if tb_counter_s > 30 then
                uart_os_dv_i <= '1';
                uart_os_rfd_i <= '1';
                modem_is_dv_i <= '1';
                modem_is_rfd_i <= '1';
            elsif tb_counter_s > 15 then
                uart_os_dv_i <= '0';
                uart_os_rfd_i <= '0';
                modem_is_dv_i <= '1';
                modem_is_rfd_i <= '1';
            else
                uart_os_dv_i <= '1';
                uart_os_rfd_i <= '1';
                modem_is_dv_i <= '0';
                modem_is_rfd_i <= '0';
            end if;
        end if;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_send_logic of tb_send_logic is
    for tb
    end for;
end cfg_tb_send_logic;