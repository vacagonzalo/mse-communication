LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY adaptador_salida IS
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
END ENTITY adaptador_salida;

ARCHITECTURE rtl OF adaptador_salida IS

    SIGNAL output_axi_s : STD_LOGIC_VECTOR(7 DOWNTO 0);


    TYPE edge_t IS (WAITING_RISE, DETECTED, WAITING_DOWN);

    SIGNAL latch_edge_s : edge_t := WAITING_RISE;
    SIGNAL ack_edge_s : edge_t := WAITING_RISE;

    SIGNAL tx_is_data_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tx_is_dv_s : STD_LOGIC;
    SIGNAL tx_is_rfd_s : STD_LOGIC;

BEGIN

    data_o <= output_axi_s;

    tx_is_data_s <= tx_is_data_i;
    tx_is_dv_s <= tx_is_dv_i;
    tx_is_rfd_o <= tx_is_rfd_s;

    state_machine : PROCESS (clk_i, srst_i)
    BEGIN
        IF srst_i = '1' THEN
            output_axi_s <= (OTHERS => '0');

            latch_edge_s <= WAITING_RISE;
            ack_edge_s <= WAITING_RISE;

            tx_is_data_s <= (OTHERS => '0');
            tx_is_dv_s <= '0';
            tx_is_rfd_s <= '0';

        ELSIF rising_edge(clk_i) THEN
            IF en_i = '1' THEN

                CASE latch_edge_s IS
                WHEN WAITING_RISE =>
                    IF latch_i = '1' THEN
                        latch_edge_s <= DETECTED;
                    END IF;

                WHEN DETECTED =>
                    output_axi_s <= tx_is_data_i;
                    latch_edge_s <= WAITING_DOWN;

                WHEN WAITING_DOWN =>
                    IF latch_i = '0' THEN
                        latch_edge_s <= WAITING_RISE;
                    END IF;
                END CASE;

                CASE ack_edge_s IS
                    WHEN WAITING_RISE =>
                        IF ack_i = '1' THEN
                        ack_edge_s <= DETECTED;
                        END IF;

                    WHEN DETECTED =>
                        tx_is_rfd_s <= '1';
                        ack_edge_s <= WAITING_DOWN;

                    WHEN WAITING_DOWN =>
                        tx_is_rfd_s <= '0';
                        IF ack_i = '0' THEN
                            ack_edge_s <= WAITING_RISE;
                        END IF;
                END CASE;

            END IF;
        END IF;
    END PROCESS state_machine;

END ARCHITECTURE rtl;
