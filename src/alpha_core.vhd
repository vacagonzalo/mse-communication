LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY alpha_core IS
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
END ENTITY alpha_core;

ARCHITECTURE rtl OF alpha_core IS

    COMPONENT clk_wiz_0
        PORT (-- Clock in ports
            -- Clock out ports
            clk_out1 : OUT STD_LOGIC;
            -- Status and control signals
            reset : IN STD_LOGIC;
            locked : OUT STD_LOGIC;
            clk_in1 : IN STD_LOGIC
        );
    END COMPONENT;

    COMPONENT beta_core IS
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
    END COMPONENT beta_core;

    -- Clock signals
    SIGNAL fast_clk_s : STD_LOGIC;
    SIGNAL slow_clk_s : STD_LOGIC;

    -- Control signals
    SIGNAL system_enable_s : STD_LOGIC;
    SIGNAL system_reset_s : STD_LOGIC;

BEGIN

    fast_clk_s <= clk_i; -- 125Mhz (AXI clock)
    system_enable_s <= en_i;
    system_reset_s <= srst_i;

    clk_wizard : clk_wiz_0
    PORT MAP(
        -- Clock out ports
        clk_out1 => slow_clk_s,
        -- Status and control signals
        reset => system_reset_s,
        locked => OPEN,
        -- Clock in ports
        clk_in1 => fast_clk_s
    );

    the_core : beta_core
    PORT MAP(
        -- clk, en, rst
        clk_i => slow_clk_s,
        en_i => system_enable_s,
        srst_i => system_reset_s,
        -- Input Stream
        is_data_i => is_data_i,
        is_dv_i => is_dv_i,
        is_rfd_o => is_rfd_o,
        -- Output Stream
        os_data_o => os_data_o,
        os_dv_o => os_dv_o,
        os_rfd_i => os_rfd_i,
        -- Config
        nm1_bytes_i => nm1_bytes_i,
        nm1_pre_i => nm1_pre_i,
        nm1_sfd_i => nm1_sfd_i,
        det_th_i => det_th_i,
        pll_kp_i => pll_kp_i,
        pll_ki_i => pll_ki_i,
        sigma_i => sigma_i,
        -- Control
        send_i => send_i,
        -- State
        tx_rdy_o => tx_rdy_o,
        rx_ovf_o => rx_ovf_o
    );

END ARCHITECTURE rtl;