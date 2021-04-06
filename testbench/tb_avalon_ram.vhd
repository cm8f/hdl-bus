LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE WORK.avalon_pkg.ALL;

LIBRARY OSVVM;
CONTEXT OSVVM.osvvmcontext;

LIBRARY vunit_lib;
CONTEXT vunit_lib.vunit_context;
CONTEXT vunit_lib.com_context;
CONTEXT vunit_lib.vc_context;


ENTITY tb_avl_ram IS
  GENERIC (
    runner_cfg        : string;
    g_addr_width      : INTEGER RANGE 8 TO 15; 
    -- master config
    g_master_write_high_prob  : REAL := 1.0;
    g_master_read_high_prob   : REAL := 1.0
  );
END ENTITY;

ARCHITECTURE tb OF tb_avl_ram IS 

  CONSTANT c_period               : TIME    := 10 ns;

  SIGNAL i_clock          : STD_LOGIC := '0';
  SIGNAL i_reset          : STD_LOGIC := '0';
  SIGNAL i_avalon_select  : STD_LOGIC;
  SIGNAL i_avalon_wr      : t_avalonf_slave_in;
  SIGNAL o_avalon_rd      : t_avalonf_slave_out;
  SIGNAL id : AlertLogIDType;

  -- avlaon master verification COMPONENT
  CONSTANT master_logger    : logger_t := get_logger("master");
  CONSTANT tb_logger        : logger_t := get_logger("tb");
  CONSTANT master_actor     : actor_t   := new_actor("Avalon-MM Master");
  CONSTANT bus_handle       : bus_master_t := new_bus(
                                  data_length => p_avl_mm_data_width,
                                  address_length  => p_avl_mm_addr_width,
                                  logger          => master_logger,
                                  actor           => master_actor);
  


BEGIN

  --====================================================================
  --= clocking
  --====================================================================
  CreateClock(i_clock, c_period);
  CreateReset(i_reset, '1', i_clock, 10*c_period, 1 ns);

  i_avalon_select         <= '1';

  proc_stim: PROCESS
    VARIABLE v_val : STD_LOGIC_VECTOR(p_avl_mm_data_width-1 DOWNTO 0);
    VARIABLE v_tmp : STD_LOGIC_VECTOR(p_avl_mm_data_width-1 DOWNTO 0);
    CONSTANT c_data_queue   : queue_t := new_queue;
    CONSTANT c_rd_ref_queue : queue_t := new_queue;
  BEGIN
    test_runner_setup(runner, runner_cfg);
    id <= GetAlertLogID(PathTail(tb_avl_ram'INSTANCE_NAME));
    WAIT FOR 0 ns;
    SetLogEnable(PASSED, TRUE);

    WaitForLevel(i_reset, '1');
    WaitForLevel(i_reset, '0');
    WaitForClock(i_clock, 1);

    IF run("signle_wr_single_rd") THEN 
      v_val := x"cafeaffe";
      --        net   handle    addr  data
      write_bus(net, bus_handle, 4, v_val);
      WaitForClock(i_clock, 2);
      read_bus(net, bus_handle, 4, v_tmp);
      AffirmIf(id, v_tmp = v_val, TO_HSTRING(v_val) & " /= " & TO_HSTRING(v_tmp));
    END IF;

    IF run("multi_wr_rd") THEN 
      FOR I IN 0 TO 2**g_addr_width-1 LOOP
        Log(id, "Write/Read from slave "  );
        v_val := STD_LOGIC_VECTOR(TO_UNSIGNED(I, v_val'LENGTH));
        --        net   handle    addr  data
        write_bus(net, bus_handle, I*4, v_val);
        WaitForClock(i_clock, 2);
        read_bus(net, bus_handle, I*4, v_tmp);
        AffirmIf(id, v_tmp = v_val, TO_HSTRING(v_val) & " /= " & TO_HSTRING(v_tmp));
      END LOOP;
    END IF; 

    IF run("multi_wr_multi_rd") THEN 
      FOR I IN 0 TO 2**g_addr_width-1 LOOP
        Log(id, "Write from slave "  );
        v_val := STD_LOGIC_VECTOR(TO_UNSIGNED(I, v_val'LENGTH));
        --        net   handle    addr  data
        write_bus(net, bus_handle, I*4, v_val);
        WaitForClock(i_clock, 1);
      END LOOP;

      FOR I IN 0 TO 2**g_addr_width -1 LOOP
        WaitForClock(i_clock, 2);
        Log(id, "Read from slave "  );
        v_val := STD_LOGIC_VECTOR(TO_UNSIGNED(I, v_val'LENGTH));
        --        net   handle    addr  data
        read_bus(net, bus_handle, I*4, v_tmp);
        WaitForClock(i_clock, 3);
        AffirmIf(id, v_tmp = v_val, TO_HSTRING(v_val) & " /= " & TO_HSTRING(v_tmp));
      END LOOP;
    END IF; 

    ReportAlerts;
    check(GetAffirmCount > 0,  "not selfchecking");
    check_equal(GetAlertCount, 0, "error occured");
    test_runner_cleanup(runner);
  END PROCESS;
  test_runner_watchdog(runner, 2 ms);
  


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



  --====================================================================
  --= dut 
  --====================================================================
  inst_dut : ENTITY WORK.avl_ram
    GENERIC MAP(
      g_addr_width      => g_addr_width,
      g_data_width      => 32
    )
    PORT MAP(
      i_clock             => i_clock,
      i_reset             => i_reset,
      i_avalon_select     => i_avalon_select,
      i_avalon_wr         => i_avalon_wr,
      o_avalon_rd         => o_avalon_rd
    );
  


END ARCHITECTURE;
