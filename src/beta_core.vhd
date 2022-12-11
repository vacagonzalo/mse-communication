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
        write_latch_i : IN STD_LOGIC;

        -- Output Stream
        os_data_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        read_latch_i : IN STD_LOGIC;
        read_ack_i : IN STD_LOGIC;

        -- Config
        nm1_bytes_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        nm1_pre_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        nm1_sfd_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        det_th_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        pll_kp_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        pll_ki_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        sigma_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END ENTITY beta_core;

ARCHITECTURE rtl OF beta_core IS

    COMPONENT adaptador_entrada IS
        PORT (
            -- clk, en, rst
            clk_i : IN STD_LOGIC;
            en_i : IN STD_LOGIC;
            srst_i : IN STD_LOGIC;
            -- AXI interface
            data_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            latch_i : IN STD_LOGIC; -- rising edge
            -- Input FIFO
            rx_os_data_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            rx_os_dv_o : OUT STD_LOGIC;
            rx_os_rfd_i : IN STD_LOGIC
        );
    END COMPONENT adaptador_entrada;

    COMPONENT adaptador_salida IS
        PORT (
            -- clk, en, rst
            clk_i : IN STD_LOGIC;
            en_i : IN STD_LOGIC;
            srst_i : IN STD_LOGIC;
            -- AXI interface
            data_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            latch_i : IN STD_LOGIC; -- rising edge
            ack_i : IN STD_LOGIC; -- rising edge
            -- Output FIFO
            tx_is_data_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- El dato de la fifo en sí.
            tx_is_dv_i : IN STD_LOGIC; -- La fifo diciendo que tiene algo para entregar.
            tx_is_rfd_o : OUT STD_LOGIC -- ACK (un pulso).
        );
    END COMPONENT adaptador_salida;

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

    COMPONENT send_logic IS
        PORT (
            -- clk, en, rst
            clk_i : IN STD_LOGIC;
            en_i : IN STD_LOGIC;
            srst_i : IN STD_LOGIC;
            -- NM1 CONFIGURATION
            nm1_bytes_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            -- DATA SOURCE
            uart_os_dv_i : IN STD_LOGIC;
            uart_os_rfd_i : IN STD_LOGIC;
            -- MODEM
            modem_is_dv_i : IN STD_LOGIC;
            modem_is_rfd_i : IN STD_LOGIC;
            -- OUTPUT
            modem_send_o : OUT STD_LOGIC
        );
    END COMPONENT send_logic;

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

    -- Common signals
    SIGNAL clk_s : STD_LOGIC;
    SIGNAL en_s : STD_LOGIC;
    SIGNAL srst_s : STD_LOGIC;

    -- Config
    SIGNAL nm1_bytes_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL nm1_pre_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL nm1_sfd_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL det_th_s : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL pll_kp_s : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL pll_ki_s : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL sigma_s : STD_LOGIC_VECTOR(15 DOWNTO 0);

    -- Input Stream
    SIGNAL is_data_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL write_latch_s : STD_LOGIC;

    -- Output Stream
    SIGNAL os_data_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL read_latch_s : STD_LOGIC;
    SIGNAL read_ack_s : STD_LOGIC;

    -- Internal wires ---------------------------------------------------------

    SIGNAL adapta_in_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL adapta_in_dv : STD_LOGIC;
    SIGNAL adapta_in_rfd : STD_LOGIC;

    SIGNAL fifo_in_modem_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL fifo_in_modem_dv : STD_LOGIC;
    SIGNAL fifo_in_modem_rfd : STD_LOGIC;

    SIGNAL logic_modem : STD_LOGIC;

    SIGNAL modem_channel_data : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL modem_channel_dv : STD_LOGIC;
    SIGNAL modem_channel_rfd : STD_LOGIC;

    SIGNAL channel_demodulator_data : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL channel_demodulator_dv : STD_LOGIC;
    SIGNAL channel_demodulator_rfd : STD_LOGIC;

    SIGNAL demodulator_fifo_out_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL demodulator_fifo_out_dv : STD_LOGIC;
    SIGNAL demodulator_fifo_out_rfd : STD_LOGIC;

    SIGNAL adapta_out_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL adapta_out_dv : STD_LOGIC;
    SIGNAL adapta_out_rfd : STD_LOGIC;

    ---------------------------------------------------------------------------

BEGIN

    -- Common signals
    clk_s <= clk_i;
    en_s <= en_i;
    srst_s <= srst_i;

    -- Configuration
    nm1_bytes_s <= nm1_bytes_i;
    nm1_pre_s <= nm1_pre_i;
    nm1_sfd_s <= nm1_sfd_i;
    det_th_s <= det_th_i;
    pll_kp_s <= pll_kp_i;
    pll_ki_s <= pll_ki_i;
    sigma_s <= sigma_i;

    -- Input Stream
    is_data_s <= is_data_i;
    write_latch_s <= write_latch_i;

    -- Output Stream
    os_data_o <= os_data_s;
    read_latch_s <= read_latch_i;
    read_ack_s <= read_ack_i;

    u_ain : adaptador_entrada
    PORT MAP(
        -- clk, en, rst
        clk_i => clk_s,
        en_i => en_s,
        srst_i => srst_s,

        -- AXI interface
        data_i => is_data_s,
        latch_i => write_latch_s,

        -- Input FIFO
        rx_os_data_o => adapta_in_data,
        rx_os_dv_o => adapta_in_dv,
        rx_os_rfd_i => adapta_in_rfd
    );

    input_queue : sif_fifo
    GENERIC MAP(
        RESET_ACTIVE_LEVEL => reset_active_level_c,
        MEM_SIZE => mem_size_c,
        SYNC_READ => sync_read_c
    )
    PORT MAP(
        -- clk, srst
        clk_i => clk_s,
        srst_i => srst_s,

        -- Input Stream Interface
        is_data_i => adapta_in_data,
        is_dv_i => adapta_in_dv,
        is_rfd_o => adapta_in_rfd,

        -- Output Stream Interface
        os_data_o => fifo_in_modem_data,
        os_dv_o => fifo_in_modem_dv,
        os_rfd_i => fifo_in_modem_rfd,

        -- Status
        empty_o => OPEN,
        full_o => OPEN,
        data_count_o => OPEN
    );

    u_send_logic : send_logic
    PORT MAP(
        -- clk, en, rst
        clk_i => clk_s,
        en_i => en_s,
        srst_i => srst_s,

        -- NM1 CONFIGURATION
        nm1_bytes_i => nm1_bytes_s,

        -- DATA SOURCE
        uart_os_dv_i => adapta_in_dv,
        uart_os_rfd_i => adapta_in_rfd,

        -- MODEM
        modem_is_dv_i => fifo_in_modem_dv,
        modem_is_rfd_i => fifo_in_modem_rfd,

        -- OUTPUT
        modem_send_o => logic_modem
    );

    modulator : bb_modulator
    PORT MAP(
        -- clk, en, rst
        clk_i => clk_s,
        en_i => en_s,
        srst_i => srst_s,

        -- Input Stream
        is_data_i => fifo_in_modem_data,
        is_dv_i => fifo_in_modem_dv,
        is_rfd_o => fifo_in_modem_rfd,

        -- Output Stream
        os_data_o => modem_channel_data,
        os_dv_o => modem_channel_dv,
        os_rfd_i => modem_channel_rfd,

        -- Config, control and state
        nm1_bytes_i => nm1_bytes_s,
        nm1_pre_i => nm1_pre_s,
        nm1_sfd_i => nm1_sfd_s,
        send_i => logic_modem,
        tx_rdy_o => OPEN
    );

    channel : bb_channel
    PORT MAP(
        -- clk, en, rst
        clk_i => clk_s,
        en_i => en_s,
        srst_i => srst_s,

        -- Input Stream
        is_data_i => modem_channel_data,
        is_dv_i => modem_channel_dv,
        is_rfd_o => modem_channel_rfd,

        -- Output Stream
        os_data_o => channel_demodulator_data,
        os_dv_o => channel_demodulator_dv,
        os_rfd_i => channel_demodulator_rfd,

        -- Control
        sigma_i => sigma_s
    );

    demodulator : bb_demodulator
    PORT MAP(
        -- clk, en, rst
        clk_i => clk_s,
        en_i => en_s,
        srst_i => srst_s,

        -- Input Stream
        is_data_i => channel_demodulator_data,
        is_dv_i => channel_demodulator_dv,
        is_rfd_o => channel_demodulator_rfd,

        -- Output Stream
        os_data_o => demodulator_fifo_out_data,
        os_dv_o => demodulator_fifo_out_dv,
        os_rfd_i => demodulator_fifo_out_rfd,

        -- Config
        nm1_bytes_i => nm1_bytes_s,
        nm1_pre_i => nm1_pre_s,
        nm1_sfd_i => nm1_sfd_S,
        det_th_i => det_th_s,
        pll_kp_i => pll_kp_s,
        pll_ki_i => pll_ki_s,

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
        clk_i => clk_s,
        srst_i => srst_s,

        -- Input Stream Interface
        is_data_i => demodulator_fifo_out_data,
        is_dv_i => demodulator_fifo_out_dv,
        is_rfd_o => demodulator_fifo_out_rfd,

        -- Output Stream Interface
        os_data_o => adapta_out_data,
        os_dv_o => adapta_out_dv,
        os_rfd_i => adapta_out_rfd,

        -- Status
        empty_o => OPEN,
        full_o => OPEN,
        data_count_o => OPEN
    );

    u_aout : adaptador_salida
    PORT MAP(
        -- clk, en, rst
        clk_i => clk_s,
        en_i => en_s,
        srst_i => srst_s,

        -- AXI interface
        data_o => os_data_s,
        latch_i => read_latch_s,
        ack_i => read_ack_s,

        -- Output FIFO
        tx_is_data_i => adapta_out_data,
        tx_is_dv_i => adapta_out_dv,
        tx_is_rfd_o => adapta_out_rfd
    );

END ARCHITECTURE rtl;
