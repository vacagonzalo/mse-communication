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
        rx_os_rfd_i : IN STD_LOGIC;

        -- Modulator
        rx_ovf_o : OUT STD_LOGIC;

        -- Control
        send_o : OUT STD_LOGIC
    );
END ENTITY adaptador_entrada;

ARCHITECTURE rtl OF adaptador_entrada IS

    SIGNAL output_candidate_s : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL latch_rising_edge_s : STD_LOGIC;
    SIGNAL latch0_s : STD_LOGIC;
    SIGNAL latch1_s : STD_LOGIC;

    SIGNAL rfd_rising_edge_s : STD_LOGIC;
    SIGNAL rfd0_s : STD_LOGIC;
    SIGNAL rfd1_s : STD_LOGIC;

    SIGNAL rx_os_data_s : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL rx_os_dv_s : STD_LOGIC;
    SIGNAL rx_ovf_s : STD_LOGIC;
    SIGNAL send_s : STD_LOGIC;

BEGIN

    state_machine : PROCESS (clk_i, srst_i)
    BEGIN
        IF srst_i = '1' THEN
            rx_os_dv_s <= '0';
            rx_ovf_s <= '0';
            send_s <= '0';

            output_candidate_s <= (OTHERS => '0');
            rx_os_data_s <= (OTHERS => '0');

            latch_rising_edge_s <= '0';
            latch0_s <= '0';
            latch1_s <= '0';

            rfd_rising_edge_s <= '0';
            rfd0_s <= '0';
            rfd1_s <= '0';

        ELSIF rising_edge(clk_i) THEN
            IF en_i = '1' THEN
                latch0_s <= latch_i;
                latch1_s <= latch0_s;

                rfd0_s <= rx_os_rfd_i;
                rfd1_s <= rfd0_s;

                IF latch_rising_edge_s = '1' THEN
                    output_candidate_s <= data_i;
                END IF;

                IF rfd_rising_edge_s = '1' THEN
                    rx_os_data_s <= output_candidate_s;
                END IF;

                rx_os_dv_s <= '1';
            ELSE
                rx_os_dv_s <= '0';
            END IF;
        END IF;
    END PROCESS state_machine;

    -- Detector de flanco ascendente del latch_i
    latch_rising_edge_s <= NOT latch1_s AND latch0_s;

    -- Detector de flanco ascendente del rx_os_rfd_i
    rfd_rising_edge_s <= NOT rfd1_s AND rfd0_s;

    -- Conexiones de salida de la entidad
    rx_os_data_o <= rx_os_data_s;
    rx_os_dv_o <= rx_os_dv_s;
    rx_ovf_o <= rx_ovf_s;
    send_o <= send_s;

END ARCHITECTURE rtl;


--   u_send_logic : process(clk_i)
--   begin
--     if rising_edge(clk_i) then
--       if srst_s = '1' then
--         pipe_data_counter_s <= (others => '0');
--         modem_send_s <= '0';
--         -- modem_tx_rdy_d10_s <= (others => '0');
--       else
--         if  uart_os_dv_s   = '1' and
--             uart_os_rfd_s  = '1' and
--             modem_is_dv_s  = '1' and
--             modem_is_rfd_s = '1'
--         then
--           pipe_data_counter_s <= pipe_data_counter_s;
--         elsif  modem_is_dv_s  = '1' and
--                modem_is_rfd_s = '1'
--         then
--           pipe_data_counter_s <= std_logic_vector(unsigned(pipe_data_counter_s)-1);
--         elsif  uart_os_dv_s   = '1' and
--                uart_os_rfd_s  = '1'
--         then
--           pipe_data_counter_s <= std_logic_vector(unsigned(pipe_data_counter_s)+1);
--         end if;
--         if modem_send_s = '1' then
--           modem_send_s <= '0';
--         else
--           if unsigned(pipe_data_counter_s) > unsigned(nm1_bytes_i) and modem_tx_rdy_s = '1' then
--             modem_send_s <= '1';
--           end if;
--         end if;
--       end if;
--     end if;
--   end process;
