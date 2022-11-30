library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_beta_core is
end tb_beta_core;

architecture tb of tb_beta_core is

    component beta_core
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

    -- signals
  signal tb_dut_clk_i      : std_logic := '1';
  signal tb_dut_en_i       : std_logic;
  signal tb_dut_srst_i     : std_logic;
  signal tb_dut_is_data_i  : std_logic_vector(7 downto 0);
  signal tb_dut_is_dv_i    : std_logic;
  signal tb_dut_is_rfd_o   : std_logic;
  signal tb_dut_os_data_o  : std_logic_vector(7 downto 0);
  signal tb_dut_os_dv_o    : std_logic;
  signal tb_dut_os_rfd_i   : std_logic;
  signal tb_dut_tx_rdy_o   : std_logic;
  signal tb_dut_det_th_i    : std_logic_vector (15 downto 0);
  signal tb_dut_pll_kp_i    : std_logic_vector (15 downto 0):= x"A000";
  signal tb_dut_pll_ki_i    : std_logic_vector (15 downto 0):= x"9000";
  signal tb_dut_sigma_i     : std_logic_vector (15 downto 0):= x"0000";

  signal tb_clock_counter_s : integer := 0;
  signal os_dv_delay_s      : std_logic_vector(8 downto 0);
  signal dut_os_dv_d1_s     : std_logic;
  signal dut_os_dv_flank_s  : std_logic;

  signal tb_dut_rx_ovf_o : std_logic;
  signal tb_dut_tx_ovf_o : std_logic;
  signal tb_dut_send_i : std_logic;
  signal TbSimEnded : std_logic := '0';
  constant SAMPLE_PERIOD   : time    := 62500 ps;
  constant N_TX            : integer := 5;
  constant N_ZEROS         : integer := 123;

begin

  ------------------------------------------------------------
  -- Clock counter (DEBUG)
  u_clk_counter : process(tb_dut_clk_i)
  begin
    if rising_edge(tb_dut_clk_i) then
      tb_clock_counter_s <= tb_clock_counter_s + 1;
    end if;
  end process;
  ------------------------------------------------------------

  ------------------------------------------------------------
  -- BEGIN DUT
  ------------------------------------------------------------
  dut : beta_core
  port map (
    -- clk, en, rst
    clk_i         => tb_dut_clk_i,
    en_i          => tb_dut_en_i,
    srst_i        => tb_dut_srst_i,
    -- Input Stream
    is_data_i     => tb_dut_is_data_i,
    is_dv_i       => tb_dut_is_dv_i,
    is_rfd_o      => tb_dut_is_rfd_o,
    -- Output Stream
    os_data_o     => tb_dut_os_data_o,
    os_dv_o       => tb_dut_os_dv_o,
    os_rfd_i      => tb_dut_os_rfd_i,
    det_th_i    => tb_dut_det_th_i,
    pll_kp_i    => tb_dut_pll_kp_i,
    pll_ki_i    => tb_dut_pll_ki_i,
    sigma_i     => tb_dut_sigma_i,
    send_i      => tb_dut_send_i,
    rx_ovf_o    => tb_dut_rx_ovf_o,
    nm1_bytes_i => "00000011",  
    nm1_pre_i   => "00001111"  ,  
    nm1_sfd_i   => "00000001" , 
    -- Others
    tx_rdy_o      => tb_dut_tx_rdy_o
  );
  ------------------------------------------------------------
  -- END DUT
  ------------------------------------------------------------


  ------------------------------------------------------------
  -- BEGIN STIMULUS
  ------------------------------------------------------------
  -- clock
  tb_dut_clk_i <= not tb_dut_clk_i after SAMPLE_PERIOD/2;
  --
  process
  begin
   tb_dut_en_i       <= '1';
   tb_dut_srst_i     <= '1';
   wait for 1*SAMPLE_PERIOD;
   tb_dut_en_i       <= '1';
   tb_dut_srst_i     <= '0';

    wait;
  end process;
  
  
  tb_dut_is_dv_i   <= '1';
  process (tb_dut_clk_i)
    variable i_v    : integer := 0;
    variable byte_v : integer := 255;
    variable l      : line;
    variable aux_v  : std_logic_vector(7 downto 0) := "01101010";
  begin
    tb_dut_is_data_i <= std_logic_vector(to_unsigned(byte_v,8));
    
    if rising_edge(tb_dut_clk_i) then
      if tb_dut_is_rfd_o = '1' then
        report "[INFO] Byte número " & integer'image(i_v);
        i_v    := i_v+1;
        byte_v := byte_v-1;
        aux_v  := not(aux_v);
      end  if;
    end if;
    if i_v >= N_TX*4 and tb_dut_tx_rdy_o = '1' then
      -- END OF SIMULATION
      write(l,string'("                                 ")); writeline(output,l);
      write(l,string'("#################################")); writeline(output,l);
      write(l,string'("#                               #")); writeline(output,l);
      write(l,string'("#  ++====    ++\  ++    ++=\\   #")); writeline(output,l);
      write(l,string'("#  ||        ||\\ ||    ||  \\  #")); writeline(output,l);
      write(l,string'("#  ||===     || \\||    ||  ||  #")); writeline(output,l);
      write(l,string'("#  ||        ||  \||    ||  //  #")); writeline(output,l);
      write(l,string'("#  ++====    ++   ++    ++=//   #")); writeline(output,l);
      write(l,string'("#                               #")); writeline(output,l);
      write(l,string'("#################################")); writeline(output,l);
      write(l,string'("                                 ")); writeline(output,l);
      assert false -- este assert se pone para abortar la simulacion
        report "[INFO] Fin de la simulacion"
        severity failure;
    end if;
  end process;
  --
  --


  process(tb_dut_clk_i)
  begin
    if rising_edge(tb_dut_clk_i) then
      if tb_dut_srst_i = '1' then
        tb_dut_os_rfd_i <= '0';
        dut_os_dv_d1_s  <= '0';
        os_dv_delay_s   <= (others => '0');
      else
        tb_dut_os_rfd_i   <= os_dv_delay_s(os_dv_delay_s'high);
        dut_os_dv_d1_s    <= tb_dut_os_dv_o;
        os_dv_delay_s     <= os_dv_delay_s(os_dv_delay_s'high-1 downto 0) & dut_os_dv_flank_s;
      end if;
    end if;
  end process;
  dut_os_dv_flank_s <= not dut_os_dv_d1_s and tb_dut_os_dv_o;
  
  ------------------------------------------------------------
  -- END STIMULUS
  ------------------------------------------------------------

end architecture;
