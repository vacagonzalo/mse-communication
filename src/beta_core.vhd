LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY beta_core IS
    PORT (
        -- clk, en, rst
        clk_i : IN STD_LOGIC;
        en_i : IN STD_LOGIC;
        srst_i : IN STD_LOGIC;
        -- Input Stream
        is_data_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        is_dv_i : IN STD_LOGIC;
        is_rfd_o : OUT STD_LOGIC;
        -- Output Stream
        os_data_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        os_dv_o : OUT STD_LOGIC;
        os_rfd_i : IN STD_LOGIC;
        -- Config
        nm1_bytes_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        nm1_pre_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        nm1_sfd_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        det_th_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        pll_kp_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        pll_ki_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        sigma_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        -- Control
        send_i : IN STD_LOGIC;
        -- State
        tx_rdy_o : OUT STD_LOGIC;
        rx_ovf_o : OUT STD_LOGIC
    );
END ENTITY beta_core;

ARCHITECTURE rtl OF beta_core IS

    COMPONENT sif_fifo IS
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
    END COMPONENT sif_fifo;

    COMPONENT bb_modulator IS
        PORT (
            -- clk, en, rst
            clk_i : IN STD_LOGIC;
            en_i : IN STD_LOGIC;
            srst_i : IN STD_LOGIC;
            -- Input Stream
            is_data_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            is_dv_i : IN STD_LOGIC;
            is_rfd_o : OUT STD_LOGIC;
            -- Output Stream
            os_data_o : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
            os_dv_o : OUT STD_LOGIC;
            os_rfd_i : IN STD_LOGIC;
            -- Config, control and state
            nm1_bytes_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            nm1_pre_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            nm1_sfd_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            send_i : IN STD_LOGIC;
            tx_rdy_o : OUT STD_LOGIC
        );
    END COMPONENT bb_modulator;

    COMPONENT bb_channel IS
        PORT (
            -- clk, en, rst
            clk_i : IN STD_LOGIC;
            en_i : IN STD_LOGIC;
            srst_i : IN STD_LOGIC;
            -- Input Stream
            is_data_i : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            is_dv_i : IN STD_LOGIC;
            is_rfd_o : OUT STD_LOGIC;
            -- Output Stream
            os_data_o : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
            os_dv_o : OUT STD_LOGIC;
            os_rfd_i : IN STD_LOGIC;
            -- Control
            sigma_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    END COMPONENT bb_channel;

    COMPONENT bb_demodulator IS
        PORT (
            -- clk, en, rst
            clk_i : IN STD_LOGIC;
            en_i : IN STD_LOGIC;
            srst_i : IN STD_LOGIC;
            -- Input Stream
            is_data_i : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            is_dv_i : IN STD_LOGIC;
            is_rfd_o : OUT STD_LOGIC;
            -- Output Stream
            os_data_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            os_dv_o : OUT STD_LOGIC;
            os_rfd_i : IN STD_LOGIC;
            -- Config
            nm1_bytes_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            nm1_pre_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            nm1_sfd_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            det_th_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            pll_kp_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            pll_ki_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            -- State
            rx_ovf_o : OUT STD_LOGIC
        );
    END COMPONENT bb_demodulator;

    CONSTANT mem_size_c : POSITIVE := 256;
    CONSTANT reset_active_level_c : STD_LOGIC := '1';
    CONSTANT sync_read_c : BOOLEAN := true;

    -- Control signals
    SIGNAL system_enable_s : STD_LOGIC;
    SIGNAL system_reset_s : STD_LOGIC;

    -- Channel/Modulator connections
    SIGNAL first_os_dv_s : STD_LOGIC;
    SIGNAL first_os_full_data_s : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL first_os_rfd_s : STD_LOGIC;

    SIGNAL input_queue_os_data_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL input_queue_os_dv_s : STD_LOGIC;
    SIGNAL input_queue_os_rfd_s : STD_LOGIC;

    SIGNAL output_queue_os_data_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL output_queue_os_dv_s : STD_LOGIC;
    SIGNAL output_queue_os_rfd_s : STD_LOGIC;

    SIGNAL rx_ovf_s : STD_LOGIC;

    -- Channel/Demodulator connections
    SIGNAL second_os_dv_s : STD_LOGIC;
    SIGNAL second_os_full_data_s : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL second_os_rfd_s : STD_LOGIC;

    -- Demodulator/Output_queue connections
    SIGNAL third_os_data_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL third_os_dv_s : STD_LOGIC;
    SIGNAL third_os_rfd_s : STD_LOGIC;

    SIGNAL tx_rdy_s : STD_LOGIC;

BEGIN

    tx_rdy_o <= tx_rdy_s;
    rx_ovf_o <= rx_ovf_s;

    system_enable_s <= en_i;
    system_reset_s <= srst_i;

    output_queue_os_rfd_s <= os_rfd_i;

    os_data_o <= output_queue_os_data_s;
    os_dv_o <= output_queue_os_dv_s;

    input_queue : sif_fifo
    GENERIC MAP(
        RESET_ACTIVE_LEVEL => reset_active_level_c,
        MEM_SIZE => mem_size_c,
        SYNC_READ => sync_read_c
    )
    PORT MAP(
        -- clk, srst
        clk_i => clk_i,
        srst_i => system_reset_s,
        -- Input Stream Interface
        is_data_i => is_data_i,
        is_dv_i => is_dv_i,
        is_rfd_o => is_rfd_o,
        -- Output Stream Interface
        os_data_o => input_queue_os_data_s,
        os_dv_o => input_queue_os_dv_s,
        os_rfd_i => input_queue_os_rfd_s,
        -- Status
        empty_o => OPEN,
        full_o => rx_ovf_s,
        data_count_o => OPEN
    );

    modulator : bb_modulator
    PORT MAP(
        -- clk, en, rst
        clk_i => clk_i,
        en_i => system_enable_s,
        srst_i => system_reset_s,
        -- Input Stream
        is_data_i => input_queue_os_data_s,
        is_dv_i => input_queue_os_dv_s,
        is_rfd_o => input_queue_os_rfd_s,
        -- Output Stream
        os_data_o => first_os_full_data_s,
        os_dv_o => first_os_dv_s,
        os_rfd_i => first_os_rfd_s,
        -- Config, control and state
        nm1_bytes_i => nm1_bytes_i,
        nm1_pre_i => nm1_pre_i,
        nm1_sfd_i => nm1_sfd_i,
        send_i => send_i,
        tx_rdy_o => tx_rdy_s
    );

    channel : bb_channel
    PORT MAP(
        -- clk, en, rst
        clk_i => clk_i,
        en_i => system_enable_s,
        srst_i => system_reset_s,
        -- Input Stream
        is_data_i => first_os_full_data_s,
        is_dv_i => first_os_dv_s,
        is_rfd_o => first_os_rfd_s,
        -- Output Stream
        os_data_o => second_os_full_data_s,
        os_dv_o => second_os_dv_s,
        os_rfd_i => second_os_rfd_s,
        -- Control
        sigma_i => sigma_i
    );

    demodulator : bb_demodulator
    PORT MAP(
        -- clk, en, rst
        clk_i => clk_i,
        en_i => system_enable_s,
        srst_i => system_reset_s,
        -- Input Stream
        is_data_i => second_os_full_data_s,
        is_dv_i => second_os_dv_s,
        is_rfd_o => second_os_rfd_s,
        -- Output Stream
        os_data_o => third_os_data_s,
        os_dv_o => third_os_dv_s,
        os_rfd_i => third_os_rfd_s,
        -- Config
        nm1_bytes_i => nm1_bytes_i,
        nm1_pre_i => nm1_pre_i,
        nm1_sfd_i => nm1_sfd_i,
        det_th_i => det_th_i,
        pll_kp_i => pll_kp_i,
        pll_ki_i => pll_ki_i,
        -- State
        rx_ovf_o => OPEN
    );

    output_queue : sif_fifo
    GENERIC MAP(
        RESET_ACTIVE_LEVEL => reset_active_level_c,
        MEM_SIZE => mem_size_c,
        SYNC_READ => sync_read_c
    )
    PORT MAP(
        -- clk, srst
        clk_i => clk_i,
        srst_i => system_reset_s,
        -- Input Stream Interface
        is_data_i => third_os_data_s,
        is_dv_i => third_os_dv_s,
        is_rfd_o => third_os_rfd_s,
        -- Output Stream Interface
        os_data_o => output_queue_os_data_s,
        os_dv_o => output_queue_os_dv_s,
        os_rfd_i => output_queue_os_rfd_s,
        -- Status
        empty_o => OPEN,
        full_o => OPEN,
        data_count_o => OPEN
    );

END ARCHITECTURE rtl;