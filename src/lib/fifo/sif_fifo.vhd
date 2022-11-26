--------------------------------------------------------------------------------
-- TODO
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.math_real.ALL;

ENTITY sif_fifo IS
  GENERIC (
    RESET_ACTIVE_LEVEL : STD_LOGIC := '1';
    MEM_SIZE : POSITIVE;
    SYNC_READ : BOOLEAN := true
  );
  PORT (
    -- clk, srst
    clk_i : IN STD_LOGIC;
    srst_i : IN STD_LOGIC;
    -- Input Stream Interface
    is_data_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    is_dv_i : IN STD_LOGIC;
    is_rfd_o : OUT STD_LOGIC;
    -- Output Stream Interface
    os_data_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    os_dv_o : OUT STD_LOGIC;
    os_rfd_i : IN STD_LOGIC;
    -- Status
    empty_o : OUT STD_LOGIC;
    full_o : OUT STD_LOGIC;
    data_count_o : OUT STD_LOGIC_VECTOR(INTEGER(ceil(log2(real(MEM_SIZE)))) - 1 DOWNTO 0)
  );
END ENTITY sif_fifo;

ARCHITECTURE rtl OF sif_fifo IS

  COMPONENT simple_fifo IS
    GENERIC (
      RESET_ACTIVE_LEVEL : STD_LOGIC := '1';
      MEM_SIZE : POSITIVE;
      SYNC_READ : BOOLEAN := true
    );
    PORT (
      Clock : IN STD_LOGIC;
      Reset : IN STD_LOGIC;
      We : IN STD_LOGIC; --# Write enable
      Wr_data : IN STD_LOGIC_VECTOR;

      Re : IN STD_LOGIC;
      Rd_data : OUT STD_LOGIC_VECTOR;

      Empty : OUT STD_LOGIC;
      Full : OUT STD_LOGIC;
      data_count_o : OUT STD_LOGIC_VECTOR(INTEGER(ceil(log2(real(MEM_SIZE)))) - 1 DOWNTO 0)
    );
  END COMPONENT;

  -- -- UART signals
  -- signal arst_n_s     : std_logic;
  -- signal srst_s       : std_logic := '1';
  -- signal tx_data_s    : std_logic_vector(7 downto 0);
  -- signal tx_busy_s    : std_logic;
  -- signal tx_en_s      : std_logic;
  -- signal rx_data_s    : std_logic_vector(7 downto 0);
  -- signal rx_busy_s    : std_logic;
  -- signal rx_busy_d1_s : std_logic;

  -- -- UART IF signals
  -- signal uart_os_data_s     : std_logic_vector(7 downto 0);
  -- signal uart_os_dv_s       : std_logic;
  -- signal uart_os_rfd_s      : std_logic;
  -- signal uart_rx_ovf_o      : std_logic;
  -- signal uart_new_rx_data_s : std_logic;

  -- -- Modem Control
  -- signal modem_send_s        : std_logic;
  -- signal pipe_data_counter_s : std_logic_vector(7 downto 0);

  -- -- FIFO signals
  SIGNAL fifo_re_s : STD_LOGIC;
  -- signal fifo_re2_s         : std_logic;
  SIGNAL fifo_empty_s : STD_LOGIC;
  SIGNAL fifo_full_s : STD_LOGIC;
  SIGNAL fifo_data_count_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
  -- signal fifo_os_data_s     : std_logic_vector(7 downto 0);
  SIGNAL os_dv_s : STD_LOGIC;
  -- signal fifo_os_rfd_s      : std_logic;

  -- -- Modem signals
  -- signal modem_os_data_s    : std_logic_vector(7 downto 0);
  -- signal modem_os_dv_s      : std_logic;
  -- signal modem_os_rfd_s     : std_logic;
  -- -- Modem State
  -- signal modem_tx_rdy_s     : std_logic;
  -- signal modem_rx_ovf_s     : std_logic;
  -- -- signal modem_tx_rdy_d10_s : std_logic_vector(9 downto 0);

  -- -- Modulator to channel output
  -- signal mod_os_data_s  : std_logic_vector( 9 downto 0);
  -- signal mod_os_dv_s    : std_logic;
  -- signal mod_os_rfd_s   : std_logic;
  -- -- Channel output
  -- signal chan_os_data_s : std_logic_vector( 9 downto 0);
  -- signal chan_os_dv_s   : std_logic;
  -- signal chan_os_rfd_s  : std_logic;

  -- -- Modem config
  -- constant nm1_bytes_c  : std_logic_vector( 7 downto 0) := X"03";
  -- constant nm1_pre_c    : std_logic_vector( 7 downto 0) := X"07";
  -- constant nm1_sfd_c    : std_logic_vector( 7 downto 0) := X"03";
  -- constant det_th_c     : std_logic_vector(15 downto 0) := X"0040";
  -- constant pll_kp_c     : std_logic_vector(15 downto 0) := X"A000";
  -- constant pll_ki_c     : std_logic_vector(15 downto 0) := X"9000";
  -- -- Channel config
  -- constant sigma_c      : std_logic_vector(15 downto 0) := X"0040"; -- QU16.12

  -- -- ILA
  -- signal tx_s : std_logic;
  -- -- ILA component
  -- COMPONENT ila_0
  -- PORT (
  --     clk : IN STD_LOGIC;
  --     probe0 : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
  --     probe1 : IN STD_LOGIC_VECTOR(9 DOWNTO 0); 
  --     probe2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
  --     probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
  -- );
  -- END COMPONENT  ;

BEGIN
  -- Status
  full_o <= fifo_full_s;
  empty_o <= fifo_empty_s;
  -- ---------------------------------------------------------------------------
  -- FIFO
  -- ---------------------------------------------------------------------------
  u_rx_fifo : simple_fifo
  GENERIC MAP(
    MEM_SIZE => 256
  )
  PORT MAP(
    Clock => clk_i,
    Reset => srst_i,
    We => is_dv_i,
    Wr_data => is_data_i,
    Re => fifo_re_s,
    Rd_data => os_data_o,
    Empty => fifo_empty_s,
    Full => fifo_full_s,
    data_count_o => fifo_data_count_s
  );
  data_count_o <= fifo_data_count_s;
  -- fifo_os_dv_s   <= '1' when fifo_data_count_s > X"00" else '0';
  -- fifo_os_dv_s   <= '1' when fifo_data_count_s > X"00" else '0';
  -- fifo_re_s      <= fifo_os_rfd_s and fifo_os_dv_s;
  -- fifo_re_s <= uart_is_rfd_s when fifo_data_count_s > X"03" and uart_is_rfd_s = '1' else '0';
  is_rfd_o <= NOT(fifo_full_s);
  os_dv_o <= os_dv_s;
  u_fifo_os : PROCESS (clk_i)
  BEGIN
    IF rising_edge(clk_i) THEN
      IF srst_i = '1' THEN
        os_dv_s <= '0';
        -- fifo_re2_s      <= '0';
      ELSE
        -- if fifo_empty_s = '0' and fifo_os_dv_s = '0' then
        --   fifo_re2_s      <= '1';
        -- elsif fifo_empty_s = '0' and fifo_os_dv_s = '1' and fifo_os_rfd_s = '1' then
        --   fifo_re2_s      <= '1';
        -- else
        --   fifo_re2_s      <= '0';
        -- end if;
        IF fifo_re_s = '1' THEN
          IF fifo_empty_s = '0' THEN
            os_dv_s <= '1';
          ELSE
            os_dv_s <= '0';
          END IF;
        ELSE
          IF os_dv_s = '1' AND os_rfd_i = '1' THEN
            os_dv_s <= '0';
          END IF;
        END IF;
        -- if fifo_os_rfd_s = '1' then
        --   if fifo_empty_s = '1' then
        --     fifo_os_dv_s   <= '0';
        --   else
        --     fifo_os_dv_s   <= '1';
        --   end if;
        -- end if;
      END IF;
    END IF;
  END PROCESS;
  -- fifo_re_s <= fifo_re2_s and not(fifo_empty_s);
  fifo_re_s <= (NOT(fifo_empty_s) AND NOT(os_dv_s))
    OR
    (NOT(fifo_empty_s) AND os_dv_s AND os_rfd_i);
  -- ---------------------------------------------------------------------------

END ARCHITECTURE;