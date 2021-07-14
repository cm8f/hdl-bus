LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.math_real.ALL;
USE WORK.avalon_pkg.ALL;
LIBRARY OSVVM;
CONTEXT OSVVM.osvvmcontext;
LIBRARY vunit_lib;
CONTEXT vunit_lib.vunit_context;
CONTEXT vunit_lib.com_context;
CONTEXT vunit_lib.vc_context;

ENTITY tb_avl_bus_arbiter IS 
  GENERIC (
    runner_cfg  : string;
    g_number_ports  : INTEGER RANGE 1 TO 16 := 1;
    -- master config
    g_master_write_high_prob  : REAL := 1.0;
    g_master_read_high_prob   : REAL := 1.0;
    -- slave config
    g_slave_waitrequest_prob  : REAL := 0.0;
    g_slave_readvalid_prob    : REAL := 0.5
  );
END ENTITY;

ARCHITECTURE tb OF tb_avl_bus_arbiter IS
  CONSTANT c_period               : TIME    := 10 ns;

  SIGNAL i_clock      : STD_LOGIC;
  SIGNAL i_reset      : STD_LOGIC;
  -- slave (pre arbitration)
  SIGNAL s_s_avalon_wr    : t_avalonf_slave_in_matrix(g_number_ports-1 DOWNTO 0);
  SIGNAL s_s_avalon_rd    : t_avalonf_slave_out_matrix(g_number_ports-1 DOWNTO 0);
  -- master (post arbitration)
  SIGNAL s_avalon_select  : STD_LOGIC;
  SIGNAL s_m_avalon_wr    : t_avalonf_master_out;
  SIGNAL s_m_avalon_rd    : t_avalonf_master_in;

  SIGNAL id : AlertLogIDType;
BEGIN 
  --====================================================================
  --= clocking
  --====================================================================
  CreateClock(i_clock, c_period);
  CreateReset(i_reset, '1', i_clock, 10*c_period, 1 ns);


  proc_stim: PROCESS
    VARIABLE v_val : STD_LOGIC_VECTOR(p_avl_mm_data_width-1 DOWNTO 0);
    VARIABLE v_tmp : STD_LOGIC_VECTOR(p_avl_mm_data_width-1 DOWNTO 0);
    CONSTANT c_data_queue   : queue_t := new_queue;
    CONSTANT c_rd_ref_queue : queue_t := new_queue;
  BEGIN
    test_runner_setup(runner, runner_cfg);
    id <= GetAlertLogID(PathTail(tb_avl_bus_arbiter'INSTANCE_NAME));
    WAIT FOR 0 ns;
    SetLogEnable(PASSED, TRUE);

    WaitForLevel(i_reset, '1');
    WaitForLevel(i_reset, '0');
    WaitForClock(i_clock, 1);

    IF run("single_wr_rd_access") THEN
      Alert(id, " not implemented yet");

    END IF;

    ReportAlerts;
    check(GetAffirmCount > 0,  "not selfchecking");
    check_equal(GetAlertCount, 0, "error occured");
    test_runner_cleanup(runner);
  END PROCESS;
  test_runner_watchdog(runner, 2 ms);

  --====================================================================
  --= avalon masters 
  --====================================================================


  --====================================================================
  --= avalon arbiter 
  --====================================================================
  inst_dut: ENTITY WORK.avalon_bus_arbiter 
    GENERIC MAP(
      g_number_masters => g_number_ports
    )
    PORT MAP(
      i_clock           => i_clock, 
      i_reset           => i_reset,
      --
      i_s_avalon_wr     => s_s_avalon_wr, 
      i_s_avalon_rd     => s_s_avalon_rd, 
      --
      o_m_avalon_select => s_avalon_select, 
      o_m_avalon_wr     => s_m_avalon_wr, 
      i_m_avalon_rd     => s_m_avalon_rd
    );



  --====================================================================
  --= avalon slave 
  --====================================================================
  inst_slv: ENTITY WORK.vunit_lib.avalon_slave 
    GENERIC MAP(
      avalon_slave      => avalon_slave
    )
    PORT MAP(
      clk               => i_clock, 
      address           => s_m_avalon_wr.address(15 DOWNTO 0),
      byteenable        => s_m_avalon_wr.byteenable,
      burstcount        => s_m_avalon_wr.burstcount,
      write             => s_m_avalon_wr.write AND s_avalon_select,
      writedata         => s_m_avalon_wr.writedata, 
      read              => s_m_avalon_wr.read AND s_avalon_select,
      readdata          => s_m_avalon_rd.readdata, 
      readdatavalid     => s_m_avalon_rd.readdatavalid,
      waitrequest       => s_m_avalon_rd.waitrequest
    );

END ARCHITECTURE;
