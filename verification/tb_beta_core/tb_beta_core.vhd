LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;
USE std.textio.ALL;

ENTITY tb_beta_core IS
END tb_beta_core;

ARCHITECTURE tb OF tb_beta_core IS

  COMPONENT beta_core
    PORT (
      clk_i : IN STD_LOGIC;
      en_i : IN STD_LOGIC;
      srst_i : IN STD_LOGIC;
      is_data_i : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      is_dv_i : IN STD_LOGIC;
      is_rfd_o : OUT STD_LOGIC;
      os_data_o : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
      os_dv_o : OUT STD_LOGIC;
      os_rfd_i : IN STD_LOGIC;
      nm1_bytes_i : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      nm1_pre_i : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      nm1_sfd_i : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      det_th_i : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
      pll_kp_i : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
      pll_ki_i : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
      sigma_i : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
      send_i : IN STD_LOGIC;
      tx_rdy_o : OUT STD_LOGIC;
      rx_ovf_o : OUT STD_LOGIC);
  END COMPONENT;

  -- signals
  SIGNAL tb_dut_clk_i : STD_LOGIC := '1';
  SIGNAL tb_dut_en_i : STD_LOGIC;
  SIGNAL tb_dut_srst_i : STD_LOGIC;
  SIGNAL tb_dut_is_data_i : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL tb_dut_is_dv_i : STD_LOGIC;
  SIGNAL tb_dut_is_rfd_o : STD_LOGIC;
  SIGNAL tb_dut_os_data_o : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL tb_dut_os_dv_o : STD_LOGIC;
  SIGNAL tb_dut_os_rfd_i : STD_LOGIC;
  SIGNAL tb_dut_tx_rdy_o : STD_LOGIC;
  SIGNAL tb_dut_det_th_i : STD_LOGIC_VECTOR (15 DOWNTO 0);
  SIGNAL tb_dut_pll_kp_i : STD_LOGIC_VECTOR (15 DOWNTO 0);
  SIGNAL tb_dut_pll_ki_i : STD_LOGIC_VECTOR (15 DOWNTO 0);
  SIGNAL tb_dut_sigma_i : STD_LOGIC_VECTOR (15 DOWNTO 0);

  SIGNAL tb_clock_counter_s : INTEGER := 0;
  SIGNAL os_dv_delay_s : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL dut_os_dv_d1_s : STD_LOGIC;
  SIGNAL dut_os_dv_flank_s : STD_LOGIC;

  SIGNAL tb_dut_rx_ovf_o : STD_LOGIC;
  SIGNAL tb_dut_tx_ovf_o : STD_LOGIC;
  SIGNAL tb_dut_send_i : STD_LOGIC;
  SIGNAL TbSimEnded : STD_LOGIC := '0';
  CONSTANT SAMPLE_PERIOD : TIME := 1000 ns;--62500 ps;
  CONSTANT N_TX : INTEGER := 68;
  CONSTANT N_ZEROS : INTEGER := 123;

BEGIN

  ------------------------------------------------------------
  -- Clock counter (DEBUG)
  u_clk_counter : PROCESS (tb_dut_clk_i)
  BEGIN
    IF rising_edge(tb_dut_clk_i) THEN
      tb_clock_counter_s <= tb_clock_counter_s + 1;
    END IF;
  END PROCESS;
  ------------------------------------------------------------

  ------------------------------------------------------------
  -- BEGIN DUT
  ------------------------------------------------------------
  dut : beta_core
  PORT MAP(
    -- clk, en, rst
    clk_i => tb_dut_clk_i,
    en_i => tb_dut_en_i,
    srst_i => tb_dut_srst_i,
    -- Input Stream
    is_data_i => tb_dut_is_data_i,
    is_dv_i => tb_dut_is_dv_i,
    is_rfd_o => tb_dut_is_rfd_o,
    -- Output Stream
    os_data_o => tb_dut_os_data_o,
    os_dv_o => tb_dut_os_dv_o,
    os_rfd_i => tb_dut_os_rfd_i,
    --
    det_th_i => tb_dut_det_th_i,
    pll_kp_i => tb_dut_pll_kp_i,
    pll_ki_i => tb_dut_pll_ki_i,
    sigma_i => tb_dut_sigma_i,
    send_i => tb_dut_send_i,
    rx_ovf_o => tb_dut_rx_ovf_o,
    nm1_bytes_i => "00000011",
    nm1_pre_i => "00001111",
    nm1_sfd_i => "00000001",
    -- Others
    tx_rdy_o => tb_dut_tx_rdy_o
  );
  ------------------------------------------------------------
  -- END DUT
  ------------------------------------------------------------
  ------------------------------------------------------------
  -- BEGIN STIMULUS
  ------------------------------------------------------------
  -- clock
  tb_dut_clk_i <= NOT tb_dut_clk_i AFTER SAMPLE_PERIOD/2;
  --

  tb_dut_pll_kp_i <= x"A000";
  tb_dut_pll_ki_i <= x"9000";
  tb_dut_sigma_i <= x"0000";
  tb_dut_det_th_i <= x"0040";

  PROCESS
  BEGIN
    tb_dut_en_i <= '1';
    tb_dut_srst_i <= '1';
    WAIT FOR 3 * SAMPLE_PERIOD;
    tb_dut_en_i <= '1';
    tb_dut_srst_i <= '0';

    WAIT;
  END PROCESS;
  tb_dut_is_dv_i <= '1';
  PROCESS (tb_dut_clk_i)
    VARIABLE i_v : INTEGER := 0;
    VARIABLE byte_v : INTEGER := 255;
    VARIABLE l : line;
    VARIABLE aux_v : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01101010";
  BEGIN
    tb_dut_is_data_i <= STD_LOGIC_VECTOR(to_unsigned(byte_v MOD 256, 8));

    IF rising_edge(tb_dut_clk_i) THEN
      IF (tb_clock_counter_s MOD 1600) = 20 THEN
        tb_dut_send_i <= '1';
      ELSE
        tb_dut_send_i <= '0';
      END IF;
      IF tb_dut_is_rfd_o = '1' THEN
        REPORT "[INFO] Byte número " & INTEGER'image(i_v);
        i_v := i_v + 1;
        byte_v := byte_v - 1;
        aux_v := NOT(aux_v);
      END IF;
    END IF;
    IF i_v >= N_TX * 4 AND tb_dut_tx_rdy_o = '1' THEN
      -- END OF SIMULATION
      write(l, STRING'("                                 "));
      writeline(output, l);
      write(l, STRING'("#################################"));
      writeline(output, l);
      write(l, STRING'("#                               #"));
      writeline(output, l);
      write(l, STRING'("#  ++====    ++\  ++    ++=\\   #"));
      writeline(output, l);
      write(l, STRING'("#  ||        ||\\ ||    ||  \\  #"));
      writeline(output, l);
      write(l, STRING'("#  ||===     || \\||    ||  ||  #"));
      writeline(output, l);
      write(l, STRING'("#  ||        ||  \||    ||  //  #"));
      writeline(output, l);
      write(l, STRING'("#  ++====    ++   ++    ++=//   #"));
      writeline(output, l);
      write(l, STRING'("#                               #"));
      writeline(output, l);
      write(l, STRING'("#################################"));
      writeline(output, l);
      write(l, STRING'("                                 "));
      writeline(output, l);
      ASSERT false -- este assert se pone para abortar la simulacion
      REPORT "[INFO] Fin de la simulacion"
        SEVERITY failure;
    END IF;
  END PROCESS;
  --
  --
  PROCESS (tb_dut_clk_i)
  BEGIN
    IF rising_edge(tb_dut_clk_i) THEN
      IF tb_dut_srst_i = '1' THEN
        tb_dut_os_rfd_i <= '0';
        dut_os_dv_d1_s <= '0';
        os_dv_delay_s <= (OTHERS => '0');
      ELSE
        tb_dut_os_rfd_i <= os_dv_delay_s(os_dv_delay_s'high);
        dut_os_dv_d1_s <= tb_dut_os_dv_o;
        os_dv_delay_s <= os_dv_delay_s(os_dv_delay_s'high - 1 DOWNTO 0) & dut_os_dv_flank_s;
      END IF;
    END IF;
  END PROCESS;
  dut_os_dv_flank_s <= NOT dut_os_dv_d1_s AND tb_dut_os_dv_o;

  ------------------------------------------------------------
  -- END STIMULUS
  ------------------------------------------------------------

END ARCHITECTURE;