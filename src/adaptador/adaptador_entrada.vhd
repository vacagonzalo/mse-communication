LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY adaptador_entrada IS
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
END ENTITY adaptador_entrada;

ARCHITECTURE rtl OF adaptador_entrada IS

    SIGNAL output_candidate_s : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL rx_os_data_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL rx_os_dv_s : STD_LOGIC;
    SIGNAL rx_ovf_s : STD_LOGIC;

    TYPE edge_t IS (WAITING_RISE, DETECTED, WAITING_DOWN);

    SIGNAL latch_edge_s : edge_t := WAITING_RISE;
    SIGNAL rfd_edge_s : edge_t := WAITING_RISE;

BEGIN

    state_machine : PROCESS (clk_i, srst_i)
    BEGIN
        IF srst_i = '1' THEN
            output_candidate_s <= (OTHERS => '0');

            latch_edge_s <= WAITING_RISE;
            rfd_edge_s <= WAITING_RISE;

            rx_os_data_s <= (OTHERS => '0');
            rx_os_dv_s <= '0';
            rx_ovf_s <= '0';

        ELSIF rising_edge(clk_i) THEN
            IF en_i = '1' THEN

                CASE latch_edge_s IS
                    WHEN WAITING_RISE =>
                        IF latch_i = '1' THEN
                            latch_edge_s <= DETECTED;
                            rx_os_data_o <= data_i;
                            rx_os_dv_o <= '1';

                        END IF;

                    WHEN DETECTED =>
                        latch_edge_s <= WAITING_DOWN;
                        IF rx_os_rfd_i = '1' THEN
                            rx_os_dv_o <= '0';
                        END IF;

                    WHEN WAITING_DOWN =>
                        IF latch_i = '0' THEN
                            latch_edge_s <= WAITING_RISE;
                        END IF;
                        IF rx_os_rfd_i = '1' THEN
                            rx_os_dv_o <= '0';
                        END IF;
                END CASE;

                -- CASE rfd_edge_s IS
                --     WHEN WAITING_RISE =>
                --         IF rx_os_rfd_i = '1' THEN
                --             rfd_edge_s <= DETECTED;
                --         END IF;

                --     WHEN DETECTED =>
                --         rx_os_data_s <= output_candidate_s;
                --         rfd_edge_s <= WAITING_DOWN;

                --     WHEN WAITING_DOWN =>
                --         IF rx_os_rfd_i = '0' THEN
                --             rfd_edge_s <= WAITING_RISE;
                --         END IF;
                -- END CASE;

                -- rx_os_dv_s <= '1';
            ELSE
                rx_os_dv_o <= '0';
            END IF;
        END IF;
    END PROCESS state_machine;

    -- -- Conexiones de salida de la entidad
    -- rx_os_data_o <= rx_os_data_s;
    -- rx_os_dv_o <= rx_os_dv_s;

END ARCHITECTURE rtl;
