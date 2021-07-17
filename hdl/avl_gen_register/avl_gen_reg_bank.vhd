LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE WORK.avalon_pkg.ALL;

ENTITY avl_gen_reg_bank IS
  GENERIC (
    g_registers   : INTEGER := 4;
    g_reg_width   : INTEGER := 32;
    g_addr_upper_bit  : INTEGER := 3;
    g_addr_lower_bit  : INTEGER := 2
  );
  PORT (
    i_clock           : IN  STD_LOGIC;
    i_reset           : IN  STD_LOGIC;
    --
    i_avalon_select   : IN  STD_LOGIC;
    i_avalon_wr       : IN  t_avalon_slave_in;
    o_avalon_rd       : OUT t_avalon_slave_out;
    --
    i_reg_wrreq       : IN  STD_LOGIC_VECTOR(g_registers-1 DOWNTO 0)    := (OTHERS => '0');
    i_reg_din         : IN  t_slv32_matrix(g_registers-1 DOWNTO 0)      := (OTHERS => (OTHERS => '0'));
    o_reg_dout        : OUT t_slv32_matrix(g_registers-1 DOWNTO 0);
    o_reg_valid       : OUT STD_LOGIC_VECTOR(g_registers-1 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE rtl OF avl_gen_reg_bank IS

  SIGNAL s_waitrequest  : STD_LOGIC;
  SIGNAL r_waitrequest  : STD_LOGIC;
  SIGNAL s_readdata       : STD_LOGIC_VECTOR(o_avalon_rd.readdata'RANGE);
  SIGNAL r_readdata       : STD_LOGIC_VECTOR(o_avalon_rd.readdata'RANGE);

  SIGNAL s_aselect        : STD_LOGIC_VECTOR(g_registers-1 DOWNTO 0);
  SIGNAL s_reg_addr       : INTEGER;
  SIGNAL r_registers      : t_slv32_matrix(g_registers-1 DOWNTO 0) := (OTHERS => (OTHERS => '0'));

BEGIN

  s_reg_addr <= TO_INTEGER(UNSIGNED(i_avalon_wr.address(g_addr_upper_bit DOWNTO g_addr_lower_bit)));

  proc_decoder : PROCESS(ALL)
  BEGIN
    s_waitrequest       <= '0';
    s_readdata          <=  c_avalonf_slave_out_init.readdata;
    s_aselect           <= (OTHERS => '0');

    IF i_avalon_select AND NOT r_waitrequest THEN
      s_aselect(s_reg_addr)  <= '1';
      s_readdata        <= r_registers(s_reg_addr);
    END IF;
  END PROCESS;



  proc_reg: PROCESS(i_clock)
  BEGIN
    IF RISING_EDGE(i_clock) THEN
      r_waitrequest <= '0';
      IF i_avalon_wr.read OR i_avalon_wr.write THEN
        r_waitrequest       <= s_waitrequest;
      END IF;
      r_readdata          <= s_readdata;
    END IF;
  END PROCESS;



  proc_write : PROCESS(i_reset, i_clock)
  BEGIN
    IF i_reset THEN
      r_registers <= (OTHERS => (OTHERS => '0'));
    ELSIF RISING_EDGE(i_clock) THEN
      FOR i IN 0 TO g_registers-1 LOOP
        o_reg_valid(I) <= '0';
        IF s_aselect(I) AND i_avalon_wr.write THEN
          o_reg_valid(I) <= '1';
          r_registers(I) <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(i_avalon_wr.writedata), g_reg_width));
        END IF;
        IF i_reg_wrreq(I) THEN
          r_registers(I) <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(i_reg_din(I)), g_reg_width));
        END IF;
      END LOOP;
    END IF;
  END PROCESS;



  o_avalon_rd.readdata      <= s_readdata;
  o_avalon_rd.waitrequest   <= s_waitrequest;

  o_reg_dout <= r_registers;



END ARCHITECTURE;
