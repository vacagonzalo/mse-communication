library ieee;
use ieee.std_logic_1164.all;

entity tb_alpha_core is
end tb_alpha_core;

architecture tb of tb_alpha_core is

    component alpha_core
        port (clk_i       : in std_logic;
              en_i        : in std_logic;
              srst_i      : in std_logic;
              is_data_i   : in std_logic_vector (7 downto 0);
              is_dv_i     : in std_logic;
              is_rfd_o    : out std_logic;
              os_data_o   : out std_logic_vector (7 downto 0);
              os_dv_o     : out std_logic;
              os_rfd_i    : in std_logic;
              nm1_bytes_i : in std_logic_vector (7 downto 0);
              nm1_pre_i   : in std_logic_vector (7 downto 0);
              nm1_sfd_i   : in std_logic_vector (7 downto 0);
              det_th_i    : in std_logic_vector (15 downto 0);
              pll_kp_i    : in std_logic_vector (15 downto 0);
              pll_ki_i    : in std_logic_vector (15 downto 0);
              sigma_i     : in std_logic_vector (15 downto 0);
              send_i      : in std_logic;
              tx_rdy_o    : out std_logic;
              rx_ovf_o    : out std_logic);
    end component;

    signal clk_i       : std_logic;
    signal en_i        : std_logic;
    signal srst_i      : std_logic;
    signal is_data_i   : std_logic_vector (7 downto 0);
    signal is_dv_i     : std_logic;
    signal is_rfd_o    : std_logic;
    signal os_data_o   : std_logic_vector (7 downto 0);
    signal os_dv_o     : std_logic;
    signal os_rfd_i    : std_logic;
    signal nm1_bytes_i : std_logic_vector (7 downto 0);
    signal nm1_pre_i   : std_logic_vector (7 downto 0);
    signal nm1_sfd_i   : std_logic_vector (7 downto 0);
    signal det_th_i    : std_logic_vector (15 downto 0);
    signal pll_kp_i    : std_logic_vector (15 downto 0);
    signal pll_ki_i    : std_logic_vector (15 downto 0);
    signal sigma_i     : std_logic_vector (15 downto 0);
    signal send_i      : std_logic;
    signal tx_rdy_o    : std_logic;
    signal rx_ovf_o    : std_logic;

    constant TbPeriod : time := 1000 ns;
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : alpha_core
    port map (clk_i       => clk_i,
              en_i        => en_i,
              srst_i      => srst_i,
              is_data_i   => is_data_i,
              is_dv_i     => is_dv_i,
              is_rfd_o    => is_rfd_o,
              os_data_o   => os_data_o,
              os_dv_o     => os_dv_o,
              os_rfd_i    => os_rfd_i,
              nm1_bytes_i => nm1_bytes_i,
              nm1_pre_i   => nm1_pre_i,
              nm1_sfd_i   => nm1_sfd_i,
              det_th_i    => det_th_i,
              pll_kp_i    => pll_kp_i,
              pll_ki_i    => pll_ki_i,
              sigma_i     => sigma_i,
              send_i      => send_i,
              tx_rdy_o    => tx_rdy_o,
              rx_ovf_o    => rx_ovf_o);

    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    clk_i <= TbClock;

    stimuli : process
    begin
        en_i <= '0';
        is_data_i <= (others => '0');
        is_dv_i <= '0';
        os_rfd_i <= '0';
        nm1_bytes_i <= (others => '0');
        nm1_pre_i <= (others => '0');
        nm1_sfd_i <= (others => '0');
        det_th_i <= (others => '0');
        pll_kp_i <= (others => '0');
        pll_ki_i <= (others => '0');
        sigma_i <= (others => '0');
        send_i <= '0';

        srst_i <= '1';
        wait for 100 ns;
        srst_i <= '0';
        wait for 100 ns;

        wait for 100 * TbPeriod;

        TbSimEnded <= '1';
        wait;
    end process;

end tb;

configuration cfg_tb_alpha_core of tb_alpha_core is
    for tb
    end for;
end cfg_tb_alpha_core;