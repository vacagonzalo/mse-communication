LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY send_logic IS
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
END ENTITY send_logic;

ARCHITECTURE rtl OF send_logic IS

    SIGNAL modem_send_s : STD_LOGIC;
    SIGNAL pipe_data_counter_s : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

    state_machine : PROCESS (clk_i)
    BEGIN
        IF rising_edge(clk_i) THEN
            IF srst_i = '1' THEN
                pipe_data_counter_s <= (OTHERS => '0');
                modem_send_s <= '0';
                -- modem_tx_rdy_d10_s <= (others => '0');
            ELSE
                IF uart_os_dv_i = '1' AND
                    uart_os_rfd_i = '1' AND
                    modem_is_dv_i = '1' AND
                    modem_is_rfd_i = '1'
                    THEN
                    pipe_data_counter_s <= pipe_data_counter_s;
                ELSIF modem_is_dv_i = '1' AND
                    modem_is_rfd_i = '1'
                    THEN
                    pipe_data_counter_s <= STD_LOGIC_VECTOR(unsigned(pipe_data_counter_s) - 1);
                ELSIF uart_os_dv_i = '1' AND
                    uart_os_rfd_i = '1'
                    THEN
                    pipe_data_counter_s <= STD_LOGIC_VECTOR(unsigned(pipe_data_counter_s) + 1);
                END IF;
                IF modem_send_s = '1' THEN
                    modem_send_s <= '0';
                ELSE
                    IF unsigned(pipe_data_counter_s) > unsigned(nm1_bytes_i) THEN
                        modem_send_s <= '1';
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS state_machine;

    modem_send_o <= modem_send_s;

END ARCHITECTURE rtl;
