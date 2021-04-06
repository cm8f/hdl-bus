LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
LIBRARY OSVVM;
CONTEXT OSVVM.osvvmcontext;
LIBRARY vunit_lib;
CONTEXT vunit_lib.vunit_context;
CONTEXT vunit_lib.com_context;
CONTEXT vunit_lib.vc_context;

USE WORK.interrupt_pkg.ALL;
USE WORK.avalon_pkg.ALL;

ENTITY tb_avl_irq IS
  GENERIC(
    runner_cfg    : STRING
  );
END ENTITY tb_avl_irq;

ARCHITECTURE tb OF tb_avl_irq  IS 

  CONSTANT c_period           : TIME := 20 ns;
  SIGNAL i_clock              : STD_LOGIC := '0';
  SIGNAL i_reset              : STD_LOGIC := '0';
        
  SIGNAL i_avalon_wr          : t_avalonf_slave_in;
  SIGNAL o_avalon_rd          : t_avalonf_slave_out;
  SIGNAL i_avalon_select      : STD_LOGIC := '1';
  
  SIGNAL s_input              : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL s_output             : STD_LOGIC;

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
    id <= GetAlertLogID(PathTail(tb_avl_irq'INSTANCE_NAME));
    WAIT FOR 0 ns;
    SetLogEnable(PASSED, TRUE);

    WaitForLevel(i_reset, '1');
    WaitForLevel(i_reset, '0');
    WaitForClock(i_clock, 1);

    WHILE test_suite LOOP 
      IF run("test") THEN 
        v_addr := p_addr_interrupt_reg_config0;
        v_data := x"00000003";
        write_bus(net, bus_handle, v_addr, v_data);
        WaitForClock(i_clock, 5);

        v_addr := p_addr_interrupt_reg_config1;
        v_data := x"00000007";
        write_bus(net, bus_handle, v_addr, v_data);
        WaitForClock(i_clock, 5);

        v_addr := p_addr_interrupt_reg_int;
        read_bus(net, bus_handle, v_addr, v_data);
        WaitForClock(i_clock, 5);

        -- write mask
        v_addr := p_addr_interrupt_reg_mask;
        v_data := x"00000001";
        write_bus(net, bus_handle, v_addr, v_data);
        WaitForClock(i_clock, 5);

        s_input(0) <= '1';
        WAIT UNTIL RISING_EDGE(i_clock);
        s_input(0) <= '0';
        WAIT UNTIL RISING_EDGE(i_clock);
	
        WAIT FOR 100 ns;	
        v_addr := p_addr_interrupt_reg_int;
        read_bus(net, bus_handle, v_addr, v_data);

      END IF;
    END LOOP;

    ReportAlerts;
    check(GetAffirmCount > 0, "not selfchecking");
    check_equal(GetAlertCount, 0, "errors occured");

  END PROCESS;



  --====================================================================
  --= avalon master verification COMPONENT
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



  --==========================================================================
  --= DUT
  --==========================================================================
  i_dut: ENTITY WORK.avl_interrupt_control
  PORT MAP(
    i_clock           => i_clock,
    i_reset           => i_reset,
    i_avalon_select   => '1',
    i_avalon_wr       => i_avalon_wr,
    o_avalon_rd       => o_avalon_rd,
    i_input           => s_input,
    o_interrupt       => s_output
  );

END ARCHITECTURE tb;
