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

    SIGNAL latch_s : STD_LOGIC;
    SIGNAL latch0_s : STD_LOGIC;
    SIGNAL latch1_s : STD_LOGIC;

    SIGNAL ack_s : STD_LOGIC;
    SIGNAL ack0_s : STD_LOGIC;
    SIGNAL ack1_s : STD_LOGIC;

    SIGNAL tx_is_data_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tx_is_dv_s : STD_LOGIC;
    SIGNAL tx_is_rfd_s : STD_LOGIC;

BEGIN

    data_o <= output_axi_s;
    latch_s <= latch_i;
    ack_s <= ack_i;

    tx_is_data_s <= tx_is_data_i;
    tx_is_dv_s <= tx_is_dv_i;
    tx_is_rfd_o <= tx_is_rfd_s;

    state_machine : PROCESS (clk_i, srst_i)
    BEGIN
        IF srst_i = '1' THEN
            output_axi_s <= (OTHERS => '0');

            latch_s <= '0';
            latch0_s <= '0';
            latch1_s <= '0';

            ack_s <= '0';
            ack0_s <= '0';
            ack1_s <= '0';

            tx_is_data_s <= (OTHERS => '0');
            tx_is_dv_s <= '0';
            tx_is_rfd_s <= '0';

        ELSIF rising_edge(clk_i) THEN
            IF en_i = '1' THEN
                latch0_s <= latch_i;
                latch1_s <= latch0_s;

                ack0_s <= ack_i;
                ack1_s <= ack0_s;

                IF latch_s = '1' THEN
                    IF tx_is_dv_s = '1' THEN
                        output_axi_s <= tx_is_data_s;
                    ELSE
                        output_axi_s <= output_axi_s;
                    END IF;
                END IF;

                IF ack_s = '1' THEN -- rising edge del ack del axi
                    tx_is_rfd_s <= '1';
                ELSE
                    tx_is_rfd_s <= '0';
                END IF;

            END IF;
        END IF;
    END PROCESS state_machine;

    -- Detector de flanco ascendente del latch_i
    latch_s <= NOT latch1_s AND latch0_s;

    -- Detector de flanco ascendente del latch_i
    ack_s <= NOT ack1_s AND ack0_s;

END ARCHITECTURE rtl;
