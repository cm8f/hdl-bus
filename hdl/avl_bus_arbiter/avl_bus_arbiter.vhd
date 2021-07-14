LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_MISC.ALL;

USE WORK.avalon_pkg.ALL;

ENTITY avalon_bus_arbiter IS 
  GENERIC(
    g_number_masters    : POSITIVE  := 1
  );
  PORT(
    i_clock             : IN  STD_LOGIC;
    i_reset             : IN  STD_LOGIC;
    -- 
    i_s_avalon_wr       : IN  t_avalonf_slave_in_matrix(g_number_masters-1 DOWNTO 0);
    o_s_avalon_rd       : OUT t_avalonf_slave_out_matrix(g_number_masters-1 DOWNTO 0);
    -- 
    o_m_avalon_select   : OUT STD_LOGIC;
    o_m_avalon_wr       : OUT t_avalonf_master_out;
    i_m_avalon_rd       : IN  t_avalonf_master_in
  );
BEGIN 
END ENTITY;

ARCHITECTURE rtl OF avalon_bus_arbiter IS 

  SIGNAL s_request  : STD_LOGIC_VECTOR(g_number_masters-1 DOWNTO 0);
  SIGNAL s_grant    : STD_LOGIC_VECTOR(g_number_masters-1 DOWNTO 0);

BEGIN 

  --====================================================================
  --= generate request 
  --====================================================================
  proc_gen_req: PROCESS(ALL)
  BEGIN 
    FOR i IN 0 TO g_number_masters-1 LOOP
      s_request(I)  <= i_s_avalon_wr(I).read OR i_s_avalon_wr(I).write;
    END LOOP;
  END PROCESS;



  --====================================================================
  --= arbiter instance
  --====================================================================
  inst_arbiter_rr : ENTITY WORK.arbiter_rr
    GENERIC MAP(
      g_number_ports => g_number_masters
    )
    PORT MAP(
      i_clock   => i_clock,
      i_reset   => i_reset,
      --
      i_request => s_request, 
      o_grant   => s_grant
    );



  --====================================================================
  --= ouptut assignament 
  --====================================================================
  proc_assign: PROCESS(ALL)
  BEGIN
    o_m_avalon_select <= '0';
    o_m_avalon_wr     <= c_avalonf_slave_in_init;
    o_s_avalon_rd     <= (OTHERS => c_avalonf_slave_out_init);

    FOR I IN 0 TO g_number_masters-1 LOOP 
      o_m_avalon_select <= OR_REDUCE(s_request); 
      IF s_grant(I) THEN 
        o_m_avalon_wr <= i_s_avalon_wr(I);
        o_s_avalon_rd(I) <= i_m_avalon_rd; 
      END IF;
    END LOOP;
  END PROCESS;
  


  

END ARCHITECTURE;
    
