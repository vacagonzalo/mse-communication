LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;
LIBRARY work;

ENTITY simple_fifo IS
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
END ENTITY;

ARCHITECTURE rtl OF simple_fifo IS

  SIGNAL head, tail : NATURAL RANGE 0 TO MEM_SIZE - 1;
  SIGNAL dpr_we : STD_LOGIC;
  SIGNAL wraparound : BOOLEAN;

  SIGNAL empty_loc, full_loc : STD_LOGIC;

  COMPONENT dual_port_ram IS
    GENERIC (
      MEM_SIZE : POSITIVE;
      SYNC_READ : BOOLEAN := true
    );
    PORT (
      Wr_clock : IN STD_LOGIC;
      We : IN STD_LOGIC; -- Write enable
      Wr_addr : IN NATURAL RANGE 0 TO MEM_SIZE - 1;
      Wr_data : IN STD_LOGIC_VECTOR;

      Rd_clock : IN STD_LOGIC;
      Re : IN STD_LOGIC; -- Read enable
      Rd_addr : IN NATURAL RANGE 0 TO MEM_SIZE - 1;
      Rd_data : OUT STD_LOGIC_VECTOR
    );
  END COMPONENT;

BEGIN

  dpr : dual_port_ram
  GENERIC MAP(
    MEM_SIZE => MEM_SIZE,
    SYNC_READ => SYNC_READ
  )
  PORT MAP(
    Wr_clock => Clock,
    We => dpr_we,
    Wr_addr => head,
    Wr_data => Wr_data,

    Rd_clock => Clock,
    Re => Re,
    Rd_addr => tail,
    Rd_data => Rd_data
  );

  dpr_we <= '1' WHEN we = '1' AND full_loc = '0' ELSE
    '0';

  wr_rd : PROCESS (Clock) IS
    VARIABLE head_v, tail_v : NATURAL RANGE 0 TO MEM_SIZE - 1;
    VARIABLE wraparound_v : BOOLEAN;
  BEGIN

    IF rising_edge(Clock) THEN
      IF Reset = RESET_ACTIVE_LEVEL THEN
        head <= 0;
        tail <= 0;
        full_loc <= '0';
        empty_loc <= '1';
        -- Almost_full  <= '0';
        -- Almost_empty <= '0';

        wraparound <= false;

      ELSE
        head_v := head;
        tail_v := tail;
        wraparound_v := wraparound;

        IF We = '1' AND (wraparound = false OR head /= tail) THEN

          IF head_v = MEM_SIZE - 1 THEN
            head_v := 0;
            wraparound_v := true;
          ELSE
            head_v := head_v + 1;
          END IF;
        END IF;

        IF Re = '1' AND (wraparound = true OR head /= tail) THEN
          IF tail_v = MEM_SIZE - 1 THEN
            tail_v := 0;
            wraparound_v := false;
          ELSE
            tail_v := tail_v + 1;
          END IF;
        END IF;
        IF head_v /= tail_v THEN
          empty_loc <= '0';
          full_loc <= '0';
        ELSE
          IF wraparound_v THEN
            full_loc <= '1';
            empty_loc <= '0';
          ELSE
            full_loc <= '0';
            empty_loc <= '1';
          END IF;
        END IF;

        IF head_v >= tail_v THEN
          data_count_o <= STD_LOGIC_VECTOR(to_unsigned(head_v - tail_v, INTEGER(ceil(log2(real(MEM_SIZE))))));
        ELSE
          data_count_o <= STD_LOGIC_VECTOR(to_unsigned(head_v + MEM_SIZE - tail_v, INTEGER(ceil(log2(real(MEM_SIZE))))));
        END IF;
        -- if not(wraparound_v) then
        --   data_count_o <= std_logic_vector(to_unsigned(head_v - tail_v,integer(ceil(log2(real(MEM_SIZE))))));
        -- else
        --   data_count_o <= std_logic_vector(to_unsigned(head_v + MEM_SIZE-tail_v,integer(ceil(log2(real(MEM_SIZE))))));
        -- end if;

        -- Almost_full  <= '0';
        -- Almost_empty <= '0';
        -- if head_v /= tail_v then
        --   if head_v > tail_v then
        --     if Almost_full_thresh >= MEM_SIZE - (head_v - tail_v) then
        --       Almost_full <= '1';
        --     end if;
        --     if Almost_empty_thresh >= head_v - tail_v then
        --       Almost_empty <= '1';
        --     end if;
        --   else
        --     if Almost_full_thresh >= tail_v - head_v then
        --       Almost_full <= '1';
        --     end if;
        --     if Almost_empty_thresh >= MEM_SIZE - (tail_v - head_v) then
        --       Almost_empty <= '1';
        --     end if;
        --   end if;
        -- end if;
        head <= head_v;
        tail <= tail_v;
        wraparound <= wraparound_v;
      END IF;
    END IF;
  END PROCESS;

  Empty <= empty_loc;
  Full <= full_loc;

END ARCHITECTURE;