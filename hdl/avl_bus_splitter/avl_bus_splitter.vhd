LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE WORK.avalon_pkg.ALL;

ENTITY avl_bus_splitter IS
  GENERIC (
    g_number_ports          : INTEGER RANGE 2 TO 16 := 4;
    g_compare_bit_upper     : INTEGER := 15;
    g_compare_bit_lower     : INTEGER := 14;
    g_address_map           : t_slv32_matrix
  );
  PORT(
    i_clock                 : IN STD_LOGIC;
    i_reset                 : IN STD_LOGIC;
    -- avalon input
    i_slave_avalon_select   : IN  STD_LOGIC;
    i_slave_avalon_wr       : IN  t_avalonf_slave_in;
    o_slave_avalon_rd       : OUT t_avalonf_slave_out;
    -- avalon output
    o_master_avalon_select  : OUT STD_LOGIC_VECTOR(0 TO g_number_ports-1);
    o_master_avalon_wr      : OUT t_avalonf_master_out_matrix(0 TO g_number_ports-1);
    i_master_avalon_rd      : IN  t_avalonf_master_in_matrix(0 TO g_number_ports-1)
  );
END ENTITY;

ARCHITECTURE rtl OF avl_bus_splitter IS

  SUBTYPE t_comparator IS STD_LOGIC_VECTOR(g_compare_bit_upper DOWNTO g_compare_bit_lower);
  TYPE state_t IS (idle, rd, wr);

  SIGNAL state            : state_t := idle;
  SIGNAL r_burst_counter  : INTEGER;

  SIGNAL r_avalon_rd      : t_avalonf_slave_out;
  SIGNAL r_avalon_wr      : t_avalonf_slave_in;
  SIGNAL r_avalon_select  : STD_LOGIC_VECTOR(0 TO g_number_ports-1);


  FUNCTION f_onehot2int(
    i_onehot  : STD_LOGIC_VECTOR
  ) RETURN INTEGER IS
    VARIABLE v_tmp : INTEGER := 0;
  BEGIN
    FOR i IN i_onehot'RANGE LOOP
      IF i_onehot(I) = '1' THEN
        RETURN I;
      END IF;
    END LOOP;
    RETURN 0;

  END FUNCTION;

BEGIN

  proc_sequencer: PROCESS(i_reset, i_clock)
  BEGIN
    IF i_reset = '1' THEN
      state <= idle;
    ELSIF RISING_EDGE(i_clock) THEN

      r_avalon_wr <= i_slave_avalon_wr;
      --
      CASE(state) IS
        --===================================================================
        WHEN idle =>
          state <= idle;
          r_avalon_select <= (OTHERS => '0');
          r_avalon_rd     <= c_avalonf_slave_out_init;
          r_avalon_rd.waitrequest <= '1';
          r_burst_counter         <= 0;

          IF i_slave_avalon_select = '1' THEN
            IF i_slave_avalon_wr.write = '1' THEN
              state <= wr;
              r_avalon_rd.waitrequest <= '1';
              FOR i IN 0 TO g_number_ports-1 LOOP
                IF g_address_map(I)(t_comparator'RANGE) = i_slave_avalon_wr.address(t_comparator'RANGE) THEN
                  r_avalon_select(I) <= '1';
                END IF;
              END LOOP;
            END IF;
            --
            IF i_slave_avalon_wr.read = '1' THEN
              state <= rd;
              r_avalon_rd.waitrequest <= '1';
              FOR i IN 0 TO g_number_ports-1 LOOP
                IF g_address_map(I)(t_comparator'RANGE) = i_slave_avalon_wr.address(t_comparator'RANGE) THEN
                  r_avalon_select(I) <= '1';
                END IF;
              END LOOP;
            END IF;
          END IF;
        --====================================================================
        WHEN wr =>
          state <= wr;
          r_avalon_rd.waitrequest <= i_master_avalon_rd(f_onehot2int(r_avalon_select)).waitrequest;
          IF i_master_avalon_rd(f_onehot2int(r_avalon_select)).waitrequest = '0' THEN 
            r_burst_counter <= r_burst_counter + 1;
            IF r_burst_counter = UNSIGNED(i_slave_avalon_wr.burstcount) THEN
              state <= idle;
            END IF;
          END IF;

        --====================================================================
        WHEN rd =>
          state <= rd;
          r_avalon_rd <= i_master_avalon_rd(f_onehot2int(r_avalon_select));
          IF i_master_avalon_rd(f_onehot2int(r_avalon_select)).readdatavalid = '1' THEN
            r_burst_counter <= r_burst_counter + 1;
          END IF;
          IF r_burst_counter = UNSIGNED(i_slave_avalon_wr.burstcount) THEN
            state <= idle;
          END IF;

        --====================================================================
        WHEN OTHERS =>
          NULL;
      END CASE;
    END IF;
  END PROCESS;

  -- slave interface
  o_slave_avalon_rd <= r_avalon_rd;
  -- master interface
  o_master_avalon_select <= r_avalon_select;
  gen_master_out: FOR i IN 0 TO g_number_ports-1 GENERATE
    o_master_avalon_wr(I) <= r_avalon_wr;
  END GENERATE;


END ARCHITECTURE;
