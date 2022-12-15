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
    END COMPONENT beta_core;

    SIGNAL slow_clk_s : STD_LOGIC; -- 16MHz

BEGIN

    clk_wizard : clk_wiz_0
    PORT MAP(
        -- Clock out ports
        clk_out1 => slow_clk_s,
        -- Status and control signals
        reset => srst_i,
        locked => OPEN,
        -- Clock in ports
        clk_in1 => clk_i
    );

    the_core : beta_core
    PORT MAP(
        -- clk, en, rst
        clk_i => slow_clk_s,
        en_i => en_i,
        srst_i => srst_i,

        -- Input Stream
        is_data_i => is_data_i,
        write_latch_i => write_latch_i,

        -- Output Stream
        os_data_o => os_data_o,
        read_latch_i => read_latch_i,
        read_ack_i => read_ack_i,

        -- Config
        nm1_bytes_i => nm1_bytes_i,
        nm1_pre_i => nm1_pre_i,
        nm1_sfd_i => nm1_sfd_i,
        det_th_i => det_th_i,
        pll_kp_i => pll_kp_i,
        pll_ki_i => pll_ki_i,
        sigma_i => sigma_i
    );

END ARCHITECTURE rtl;
