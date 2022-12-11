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
      -- clk, en, rst
      clk_i : IN STD_LOGIC;
      en_i : IN STD_LOGIC;
      srst_i : IN STD_LOGIC;

      -- Input Stream
      is_data_i : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      write_latch_i : IN STD_LOGIC;

      -- Output Stream
      os_data_o : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
      read_latch_i : IN STD_LOGIC;
      read_ack_i : IN STD_LOGIC;

      -- Config
      nm1_bytes_i : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      nm1_pre_i : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      nm1_sfd_i : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      det_th_i : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
      pll_kp_i : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
      pll_ki_i : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
      sigma_i : IN STD_LOGIC_VECTOR (15 DOWNTO 0)
    );
  END COMPONENT;

  -- signals
  SIGNAL tb_dut_clk_i : STD_LOGIC := '1';
  SIGNAL tb_dut_en_i : STD_LOGIC;
  SIGNAL tb_dut_srst_i : STD_LOGIC;
  SIGNAL tb_dut_is_data_i : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL tb_dut_write_latch_i : STD_LOGIC;
  SIGNAL tb_dut_os_data_o : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL tb_dut_read_latch_i : STD_LOGIC;
  SIGNAL tb_dut_read_ack_i : STD_LOGIC;
  SIGNAL tb_dut_det_th_i : STD_LOGIC_VECTOR (15 DOWNTO 0);
  SIGNAL tb_dut_pll_kp_i : STD_LOGIC_VECTOR (15 DOWNTO 0);
  SIGNAL tb_dut_pll_ki_i : STD_LOGIC_VECTOR (15 DOWNTO 0);
  SIGNAL tb_dut_sigma_i : STD_LOGIC_VECTOR (15 DOWNTO 0);

  SIGNAL tb_dut_clk_slow_i : STD_LOGIC := '1';
  SIGNAL tb_dut_is_data_aux_i : STD_LOGIC_VECTOR(7 DOWNTO 0);
---
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

  SIGNAL cambio_s : STD_LOGIC := '0';
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
    write_latch_i => tb_dut_write_latch_i,
    -- Output Stream
    os_data_o => tb_dut_os_data_o,
    read_latch_i => tb_dut_read_latch_i,
    read_ack_i => tb_dut_read_ack_i,
    -- Config
    det_th_i => tb_dut_det_th_i,
    pll_kp_i => tb_dut_pll_kp_i,
    pll_ki_i => tb_dut_pll_ki_i,
    sigma_i => tb_dut_sigma_i,

    nm1_bytes_i => "00000011",
    nm1_pre_i => "00001111",
    nm1_sfd_i => "00000001"
  );
  ------------------------------------------------------------
  -- END DUT
  ------------------------------------------------------------
  ------------------------------------------------------------
  -- BEGIN STIMULUS
  ------------------------------------------------------------
  -- clock
  tb_dut_clk_i <= NOT tb_dut_clk_i AFTER SAMPLE_PERIOD/2;

  tb_dut_clk_slow_i <= NOT tb_dut_clk_slow_i AFTER SAMPLE_PERIOD*4;
  --

  tb_dut_pll_kp_i <= x"A000";
  tb_dut_pll_ki_i <= x"9000";
  tb_dut_sigma_i <= x"0000";
  tb_dut_det_th_i <= x"0040";

  tb_dut_is_data_i <= tb_dut_is_data_aux_i;

  PROCESS
  BEGIN
    tb_dut_en_i <= '1';
    tb_dut_srst_i <= '1';
    WAIT FOR 3 * SAMPLE_PERIOD;
    tb_dut_en_i <= '1';
    tb_dut_srst_i <= '0';

    WAIT;
  END PROCESS;
-----
DATA_GENERATOR: PROCESS (tb_dut_clk_slow_i)
  VARIABLE data_var : INTEGER := 255;
BEGIN
  IF cambio_s = '1' THEN
    data_var := data_var -1;
    tb_dut_is_data_aux_i <= std_logic_vector(to_unsigned(data_var,8));
    tb_dut_write_latch_i <= '1';   
  ELSE
    tb_dut_write_latch_i <= '0';
  END IF;
  cambio_s <= not cambio_s;
END PROCESS;

-----
  PROCESS (tb_dut_clk_i)
    VARIABLE i_v : INTEGER := 0;
    VARIABLE byte_v : INTEGER := 255;
    VARIABLE l : line;
    VARIABLE aux_v : STD_LOGIC_VECTOR(7 DOWNTO 0) := "01101010";
  BEGIN

    IF rising_edge(tb_dut_clk_i) THEN
      IF (tb_clock_counter_s MOD 1600) = 20 THEN
        tb_dut_send_i <= '1';
      ELSE
        tb_dut_send_i <= '0';
      END IF;
    END IF;
    i_v := i_v + 1;

    IF i_v >= N_TX * 4 THEN
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
        dut_os_dv_d1_s <= '0';
        os_dv_delay_s <= (OTHERS => '0');
      ELSE
        os_dv_delay_s <= os_dv_delay_s(os_dv_delay_s'high - 1 DOWNTO 0) & dut_os_dv_flank_s;
      END IF;
    END IF;
  END PROCESS;

  ------------------------------------------------------------
  -- END STIMULUS
  ------------------------------------------------------------

END ARCHITECTURE;