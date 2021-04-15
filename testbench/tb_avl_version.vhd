LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY OSVVM;
CONTEXT OSVVM.osvvmcontext;

LIBRARY vunit_lib;
CONTEXT vunit_lib.vunit_context;
CONTEXT vunit_lib.com_context;
CONTEXT vunit_lib.vc_context;

USE WORK.version_pkg.ALL;
USE WORK.avalon_pkg.ALL;


ENTITY tb_avl_version IS 
  GENERIC(
    runner_cfg : STRING
  );
END ENTITY;

ARCHITECTURE rtl OF tb_avl_version IS 

  CONSTANT c_period           : TIME := 20 ns;
  CONSTANT c_features         : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"cafeaffe";
  SIGNAL i_clock              : STD_LOGIC := '0';
  SIGNAL i_reset              : STD_LOGIC := '0';
        
  SIGNAL i_avalon_wr          : t_avalonf_slave_in;
  SIGNAL o_avalon_rd          : t_avalonf_slave_out;
  SIGNAL i_avalon_select      : STD_LOGIC := '1';
  
  SIGNAL id                   : AlertLogIDType;
  CONSTANT master_logger      : logger_t := get_logger("master");
  CONSTANT tb_logger          : logger_t := get_logger("tb");
  CONSTANT master_actor       : actor_t   := new_actor("Avalon-MM Master");
  CONSTANT bus_handle         : bus_master_t := new_bus(
                                  data_length => p_avl_mm_data_width,
                                  address_length  => p_avl_mm_addr_width,
                                  logger          => master_logger,
                                  actor           => master_actor);
  
BEGIN 

  CreateClock(i_clock, c_period);
  CreateReset(i_reset, '1', i_clock, 5*c_period, 0 ns);


  
  --==========================================================================
  --= source
  --==========================================================================
  proc_source: PROCESS
    VARIABLE v_addr : STD_LOGIC_VECTOR(31 DOWNTO 0);
    VARIABLE v_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
  BEGIN
    test_runner_setup(runner, runner_cfg);
    id <= GetAlertLogID(PathTail(tb_avl_version'INSTANCE_NAME));
    WAIT FOR 0 ns;
    SetLogEnable(PASSED, FALSE);

    WaitForLevel(i_reset, '1');
    WaitForLevel(i_reset, '0');
    WaitForClock(i_clock, 1);

    WHILE test_suite LOOP 
      IF run("test") THEN 
        Log(id, "check system version");
        v_addr := p_addr_version_reg_system_version;
        read_bus(net, bus_handle, v_addr, v_data);
        WaitForClock(i_clock, 5);
        AffirmIf(id, v_data = p_version_reg_system_version, "system version missmatch");

        Log(id, "check git revision");
        v_addr := p_addr_version_reg_gitversion;
        read_bus(net, bus_handle, v_addr, v_data);
        WaitForClock(i_clock, 5);
        AffirmIf(id, v_data = p_version_reg_gitversion, "GIT version missmatch");

        Log(id, "check features");
        v_addr := p_addr_version_reg_features;
        read_bus(net, bus_handle, v_addr, v_data);
        WaitForClock(i_clock, 5);
        AffirmIf(id, v_data = c_features, "features missmatch");

        Log(id, "check timestamp");
        v_addr := p_addr_version_reg_timestamp;
        read_bus(net, bus_handle, v_addr, v_data);
        WaitForClock(i_clock, 5);
        AffirmIf(id, v_data = p_version_reg_timestamp, "timestamp missmatch");

        Log(id, "check buildnumber");
        v_addr := p_addr_version_reg_buildnumber;
        read_bus(net, bus_handle, v_addr, v_data);
        WaitForClock(i_clock, 5);
        AffirmIf(id, v_data = p_version_reg_buildnumber, "buildnumber missmatch");
      END IF;
    END LOOP;

    WAIT FOR 9 us;

    ReportAlerts;
    check(GetAffirmCount > 0, "not selfchecking");
    check_equal(GetAlertCount, 0, "errors occured");
  END PROCESS;
  test_runner_watchdog(runner, 10 us);


  --====================================================================
  --= model
  --====================================================================
  inst_avl_master: ENTITY vunit_lib.avalon_master
    GENERIC MAP(
      bus_handle      => bus_handle,
      write_high_probability  => 1.0,
      read_high_probability   => 1.0
    )
    PORT MAP(
      clk               => i_clock,
      address           => i_avalon_wr.address,
      byteenable        => i_avalon_wr.byteenable,
      burstcount        => i_avalon_wr.burstcount,
      write             => i_avalon_wr.write,
      writedata         => i_avalon_wr.writedata,
      read              => i_avalon_wr.read,
      readdata          => o_avalon_rd.readdata,
      readdatavalid     => o_avalon_rd.readdatavalid,
      waitrequest       => o_avalon_rd.waitrequest
    );


  --====================================================================
  --- dut
  --====================================================================
  inst_version: ENTITY WORK.version_reg_bus_interface 
    GENERIC MAP(
      g_features      => c_features,
      g_system_version  => p_version_reg_system_version,
      g_git_revision    => p_version_reg_gitversion,
      g_timestamp       => p_version_reg_timestamp,
      g_buildnumber     => p_version_reg_buildnumber
    )
    PORT MAP(
      i_clock           => i_clock,
      i_reset           => i_reset, 
      i_avalon_select   => i_avalon_select,
      i_avalon_wr       => i_avalon_wr,
      o_avalon_rd       => o_avalon_rd
    );

END ARCHITECTURE;

