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
    g_number_ports  : INTEGER RANGE 1 TO 16 := 2;
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
  SIGNAL s_s_avalon_wr    : t_avalon_slave_in_matrix(g_number_ports-1 DOWNTO 0);
  SIGNAL s_s_avalon_rd    : t_avalon_slave_out_matrix(g_number_ports-1 DOWNTO 0);
  -- master (post arbitration)
  SIGNAL s_avalon_select  : STD_LOGIC;
  SIGNAL s_m_avalon_wr    : t_avalon_master_out;
  SIGNAL s_m_avalon_rd    : t_avalon_master_in;

  SIGNAL s_dummy_bytenea  : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL s_dummy_burstcount : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL r_readdatavalid    : STD_LOGIC_VECTOR(g_number_ports-1 DOWNTO 0);
  SIGNAL r_readdata         : t_slv32_matrix(g_number_ports-1 DOWNTO 0);

  SIGNAL id : AlertLogIDType;

  -- avalon masters
  TYPE logger_t_matrix      IS ARRAY (0 TO g_number_ports-1) OF logger_t;
  TYPE actor_t_matrix       IS ARRAY (0 TO g_number_ports-1) OF actor_t;
  TYPE bus_master_t_matrix  IS ARRAY (0 TO g_number_ports-1) OF bus_master_t;

  IMPURE FUNCTION f_set_master_logger RETURN logger_t_matrix IS 
    VARIABLE v_temp : logger_t_matrix;
  BEGIN
    FOR i IN v_temp'RANGE LOOP
      v_temp(I) := get_logger("master" & to_string(I));
    END LOOP;
    RETURN v_temp;
  END FUNCTION;

  IMPURE FUNCTION f_set_master_actor RETURN actor_t_matrix IS 
    VARIABLE v_temp : actor_t_matrix;
  BEGIN
    FOR i IN v_temp'RANGE LOOP
      v_temp(I) := new_actor("avalon-MM Master " & TO_STRING(i));
    END LOOP;
    RETURN v_temp;
  END FUNCTION;

  IMPURE FUNCTION f_set_bus_handle(
    logger  : logger_t_matrix;
    actor   : actor_t_matrix
  ) RETURN bus_master_t_matrix IS 
    VARIABLE v_temp : bus_master_t_matrix;
  BEGIN 
    FOR i IN v_temp'RANGE LOOP
      v_temp(I) := new_bus(data_length => 32, 
                          address_length => 32, 
                          logger => logger(I), 
                          actor => actor(I));
    END LOOP;
    RETURN v_temp;
  END FUNCTION;

  CONSTANT c_master_logger    : logger_t_matrix     := f_set_master_logger;
  CONSTANT c_master_actor     : actor_t_matrix      := f_set_master_actor;
  CONSTANT c_master_bus_handle: bus_master_t_matrix := f_set_bus_handle(c_master_logger, c_master_actor);

  -- avalon slave 
  constant memory : memory_t := new_memory;
  constant buf : buffer_t := allocate(memory, 128*1024);
  constant c_avalon_slave : avalon_slave_t :=
      new_avalon_slave(memory => memory,
        name => "avlmm_vc",
        readdatavalid_high_probability => 1.0,
        waitrequest_high_probability => 0.0 
      );
  SIGNAL s_dummy_byteenable_slave : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '1');
  SIGNAL s_dummy_burstcount_slave : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
  
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
      WAIT FOR 10 ns;
      FOR C IN 0 TO g_number_ports-1 LOOP
        Log(id, "Write/Read from master " & TO_STRING(C));
        v_val := STD_LOGIC_VECTOR(TO_UNSIGNED(123 + C, v_val'LENGTH));
        --        net   handle    addr  data
        write_bus(net, c_master_bus_handle(C), C*4, v_val);
        WaitForClock(i_clock, 10);
        read_bus(net, c_master_bus_handle(C), C*4, v_tmp);
        AffirmIfEqual(id, v_tmp , v_val, "read error at " & TO_STRING(C*4));
        WaitForClock(i_clock, 10);
      END LOOP;
    END IF;
    --
    IF run("mulit_wr_rd_access") THEN
      WAIT FOR 10 ns;
      FOR C IN 0 TO g_number_ports-1 LOOP
        Log(id, "Write/Read from master " & TO_STRING(C));
        v_val := STD_LOGIC_VECTOR(TO_UNSIGNED(123 + C, v_val'LENGTH));
        --        net   handle    addr  data
        write_bus(net, c_master_bus_handle(C), C*4, v_val);
      END LOOP;

      WaitForClock(i_clock, 10);
        
      FOR C IN 0 TO g_number_ports-1 LOOP
        v_val := STD_LOGIC_VECTOR(TO_UNSIGNED(123 + C, v_val'LENGTH));
        read_bus(net, c_master_bus_handle(C), C*4, v_tmp);
        AffirmIfEqual(id, v_tmp , v_val, "read error at " & TO_STRING(C*4));
      END LOOP;

      WaitForClock(i_clock, 10);
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
  GEN_MASTERS: FOR I IN 0 TO g_number_ports-1 GENERATE
    inst_avl_master: ENTITY vunit_lib.avalon_master
      GENERIC MAP(
        bus_handle              => c_master_bus_handle(I),
        write_high_probability  => 1.0,
        read_high_probability   => 1.0
      )
      PORT MAP(
        clk                     => i_clock,
        address                 => s_s_avalon_wr(I).address,
        byteenable              => s_dummy_bytenea,
        burstcount              => s_dummy_burstcount,
        write                   => s_s_avalon_wr(I).write,
        writedata               => s_s_avalon_wr(I).writedata,
        read                    => s_s_avalon_wr(I).read,
        readdata                => r_readdata(I), --s_s_avalon_rd(I).readdata,
        readdatavalid           => r_readdatavalid(I),
        waitrequest             => s_s_avalon_rd(I).waitrequest
      );
  END GENERATE;

  proc_gen_readdatavalid: PROCESS(i_clock)
  BEGIN 
    IF RISING_EDGE(i_clock) THEN 
      FOR i IN r_readdatavalid'RANGE LOOP 
        r_readdatavalid(I)  <= s_s_avalon_wr(I).read AND NOT s_s_avalon_rd(I).waitrequest;
        r_readdata(I)       <= s_s_avalon_rd(I).readdata;
      END LOOP;
    END IF;
  END PROCESS;


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
      o_s_avalon_rd     => s_s_avalon_rd, 
      --
      o_m_avalon_select => s_avalon_select, 
      o_m_avalon_wr     => s_m_avalon_wr, 
      i_m_avalon_rd     => s_m_avalon_rd
    );



  --====================================================================
  --= avalon slave 
  --====================================================================
  inst_slave : ENTITY WORK.avl_ram
    GENERIC MAP(
      g_addr_width      => 16,
      g_data_width      => 32
    )
    PORT MAP(
      i_clock             => i_clock,
      i_reset             => i_reset,
      i_avalon_select     => s_avalon_select,
      i_avalon_wr         => s_m_avalon_wr,
      o_avalon_rd         => s_m_avalon_rd
    );

--  inst_slv: ENTITY vunit_lib.avalon_slave 
--    GENERIC MAP(
--      avalon_slave      => c_avalon_slave
--    )
--    PORT MAP(
--      clk               => i_clock, 
--      address           => s_m_avalon_wr.address(15 DOWNTO 0),
--      byteenable        => s_dummy_byteenable_slave,
--      burstcount        => s_dummy_burstcount_slave,
--      write             => s_m_avalon_wr.write AND s_avalon_select,
--      writedata         => s_m_avalon_wr.writedata, 
--      read              => s_m_avalon_wr.read AND s_avalon_select,
--      readdata          => s_m_avalon_rd.readdata, 
--      readdatavalid     => OPEN,
--      waitrequest       => s_m_avalon_rd.waitrequest
--    );

END ARCHITECTURE;
