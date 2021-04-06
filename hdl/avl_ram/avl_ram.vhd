LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

LIBRARY WORK;
USE WORK.avalon_pkg.ALL;

ENTITY avl_ram IS
  GENERIC(
    g_addr_width    : INTEGER :=  8;
    g_data_width    : INTEGER := 32
  );
  PORT(
    i_clock         : IN  STD_LOGIC;
    i_reset         : IN  STD_LOGIC;
    i_avalon_select : IN  STD_LOGIC;
    i_avalon_wr     : IN  t_avalonf_slave_in;
    o_avalon_rd     : OUT t_avalonf_slave_out;
    --
    i_wrreq         : IN  STD_LOGIC := '0';
    i_rdreq         : IN  STD_LOGIC := '0';
    i_addr          : IN  STD_LOGIC_VECTOR(g_addr_width-1 DOWNTO 0) := (OTHERS => '0');
    i_din           : IN  STD_LOGIC_VECTOR(g_data_width-1 DOWNTO 0) := (OTHERS => '0');
    o_dout          : OUT STD_LOGIC_VECTOR(g_data_width-1 DOWNTO 0)
  );
END ENTITY avl_ram;

ARCHITECTURE rtl OF avl_ram IS

BEGIN

  inst_ram : ENTITY WORK.ram_tdp
    GENERIC MAP(
      g_addr_width  => g_addr_width,
      g_data_width  => g_data_width
    )
    PORT MAP(
      clock_a         => i_clock,
      clock_b         => i_clock,
      address_a       => i_avalon_wr.address(g_addr_width+2-1 DOWNTO 2),
      address_b       => i_addr,
      data_a          => i_avalon_wr.writedata,
      data_b          => i_din,
      wren_a          => i_avalon_wr.write AND i_avalon_select,
      wren_b          => i_wrreq,
      q_a             => o_avalon_rd.readdata,
      q_b             => o_dout
    );

  proc_readhandling: PROCESS(i_clock)
  BEGIN
    IF RISING_EDGE(i_clock) THEN
      o_avalon_rd.waitrequest   <= '0'; --r_waitrequest;
      o_avalon_rd.readdatavalid <= i_avalon_wr.read AND i_avalon_select ;
    END IF;
  END PROCESS;


END ARCHITECTURE;
