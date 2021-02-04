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

ENTITY tb_avl_bus_splitter IS
  GENERIC (
    runner_cfg        : string;
    g_number_ports            : INTEGER RANGE 2 TO 16 := 2;
    -- master config
    g_master_write_high_prob  : REAL := 1.0;
    g_master_read_high_prob   : REAL := 1.0;
    -- slave config
    g_slave_waitrequest_prob  : REAL := 0.0;
    g_slave_readvalid_prob    : REAL := 0.5
  );
END ENTITY;

ARCHITECTURE tb OF tb_avl_bus_splitter IS

  CONSTANT c_period               : TIME    := 10 ns;
  CONSTANT c_comp_upper_bit   : INTEGER := 31;
  CONSTANT c_comp_lower_bit   : INTEGER := 16;
  CONSTANT c_address_map      : t_slv_matrix(0 TO 15)(31 DOWNTO 0) := (
                                                        0  => x"00000000",
                                                        1  => x"00010000", 
                                                        2  => x"00020000", 
                                                        3  => x"00030000", 
                                                        4  => x"00040000", 
                                                        5  => x"00050000", 
                                                        6  => x"00060000", 
                                                        7  => x"00070000", 
                                                        8  => x"00080000", 
                                                        9  => x"00090000", 
                                                        10 => x"000A0000", 
                                                        11 => x"000B0000", 
                                                        12 => x"000C0000", 
                                                        13 => x"000D0000", 
                                                        14 => x"000E0000", 
                                                        15 => x"000F0000");

  SIGNAL i_clock      : STD_LOGIC;
  SIGNAL i_reset      : STD_LOGIC;
  SIGNAL i_avalon_select  : STD_LOGIC;
  SIGNAL i_avalon_wr      : t_avalonf_slave_in;
  SIGNAL o_avalon_rd      : t_avalonf_slave_out;
  --
  SIGNAL s_select         : STD_LOGIC_VECTOR(0 TO g_number_ports-1);
  SIGNAL s_avalon_wr      : t_avalonf_master_out_matrix(0 TO g_number_ports-1);
  SIGNAL s_avalon_rd      : t_avalonf_master_in_matrix(0 TO g_number_ports-1);

  -- avlaon master verification COMPONENT
  CONSTANT master_logger    : logger_t := get_logger("master");
  CONSTANT tb_logger        : logger_t := get_logger("tb");
  CONSTANT master_actor     : actor_t   := new_actor("Avalon-MM Master");
  CONSTANT bus_handle       : bus_master_t := new_bus(
                                  data_length => p_avl_mm_data_width,
                                  address_length  => p_avl_mm_addr_width,
                                  logger          => master_logger,
                                  actor           => master_actor);



  -- avalon slave verification COMPONENT
  TYPE memory_t_matrix IS ARRAY(0 TO g_number_ports-1) OF memory_t;
  TYPE buffer_t_matrix IS ARRAY(0 TO g_number_ports-1) OF buffer_t;
  TYPE avalon_slave_t_matrix IS ARRAY(0 TO g_number_ports-1) OF avalon_slave_t;

  IMPURE FUNCTION f_set_memory RETURN memory_t_matrix IS 
    VARIABLE v_tmp : memory_t_matrix;
  BEGIN
    FOR i IN 0 TO g_number_ports-1 LOOP
      v_tmp(I) := new_memory;
    END LOOP;
    RETURN v_tmp;
  END FUNCTION;

  CONSTANT memory       : memory_t_matrix := f_set_memory;

  IMPURE FUNCTION f_set_buffer RETURN buffer_t_matrix IS 
    VARIABLE v_tmp : buffer_t_matrix;
  BEGIN
    FOR i IN 0 TO g_number_ports-1 LOOP
      v_tmp(I) := allocate(memory(I), 4096);
    END LOOP;
    RETURN v_tmp;
  END FUNCTION;

  CONSTANT buf          : buffer_t_matrix := f_set_buffer;

  IMPURE FUNCTION f_set_avl_slaves RETURN avalon_slave_t_matrix IS 
    VARIABLE v_tmp : avalon_slave_t_matrix;
  BEGIN
    FOR i IN 0 TO g_number_ports-1 LOOP
      v_tmp(I) := new_avalon_slave( 
        memory => memory(I),
        name => "avl_slave" & to_string(I),
        readdatavalid_high_probability  => g_slave_readvalid_prob,
        waitrequest_high_probability    => g_slave_waitrequest_prob
      );
    END LOOP;
    RETURN v_tmp;
  END FUNCTION;

  CONSTANT avalon_slave : avalon_slave_t_matrix := f_set_avl_slaves;

  SIGNAL id : AlertLogIDType;

BEGIN

  --====================================================================
  --= clocking
  --====================================================================
  CreateClock(i_clock, c_period);
  CreateReset(i_reset, '1', i_clock, 10*c_period, 1 ns);



  --====================================================================
  --= stim
  --====================================================================
  proc_stim: PROCESS
    VARIABLE v_val : STD_LOGIC_VECTOR(p_avl_mm_data_width-1 DOWNTO 0);
    VARIABLE v_tmp : STD_LOGIC_VECTOR(p_avl_mm_data_width-1 DOWNTO 0);
    CONSTANT c_data_queue   : queue_t := new_queue;
    CONSTANT c_rd_ref_queue : queue_t := new_queue;
  BEGIN
    test_runner_setup(runner, runner_cfg);
    id <= GetAlertLogID(PathTail(tb_avl_bus_splitter'INSTANCE_NAME));
    WAIT FOR 0 ns;
    SetLogEnable(PASSED, TRUE);

    WaitForLevel(i_reset, '1');
    WaitForLevel(i_reset, '0');
    WaitForClock(i_clock, 1);

    IF run("single_wr_single_rd") THEN
      FOR C IN 0 TO g_number_ports-1 LOOP 
        Log(id, "Write/Read from slave " & TO_STRING(C));
        v_val := STD_LOGIC_VECTOR(TO_UNSIGNED(123 + C, v_val'LENGTH));
        --        net   handle    addr  data
        write_bus(net, bus_handle, TO_INTEGER(UNSIGNED(c_address_map(C))) + 4, v_val);
        WaitForClock(i_clock, 2);
        read_bus(net, bus_handle, TO_INTEGER(UNSIGNED(c_address_map(C))) + 4, v_tmp);
        AffirmIf(id, v_tmp = v_val, TO_HSTRING(v_val) & " /= " & TO_HSTRING(v_tmp));
      END LOOP;

    END IF;

    IF run("single_wr_single_rd_burst") THEN
      FOR C IN 0 TO g_number_ports-1 LOOP
        Log(id, "Write/Read from slave " & TO_STRING(C));
        FOR I IN 0 TO 3 LOOP
          v_val := STD_LOGIC_VECTOR(TO_UNSIGNED(I+256, v_val'LENGTH));
          --        net   handle    addr  data
          Log(id, "address " & TO_HSTRING(c_address_map(C) OR STD_LOGIC_VECTOR(TO_UNSIGNED(I*4, 32))));
          write_bus(net, bus_handle, TO_INTEGER(UNSIGNED(c_address_map(C))) + I*4, v_val);
          WaitForClock(i_clock, 2);
          read_bus(net, bus_handle, TO_INTEGER(UNSIGNED(c_address_map(C))) + I*4, v_tmp);
          AffirmIf(id, v_tmp = v_val, TO_HSTRING(v_val) & " /= " & TO_HSTRING(v_tmp));
        END LOOP;
      END LOOP;
    END IF;

    IF run("burst_wr_burst_rd") THEN
      FOR C IN 0 TO g_number_ports-1 LOOP 
        Log(id, "Write/Read from slave " & TO_STRING(C));
        FOR I IN 0 TO 3 LOOP 
          push(c_data_queue, STD_LOGIC_VECTOR(TO_UNSIGNED(C+I+1234, 32)));
        END LOOP;
        --        net   handle    addr  data
        burst_write_bus(net, bus_handle, TO_INTEGER(UNSIGNED(c_address_map(C))) + 4, 4, c_data_queue);
        AffirmIf(id, is_empty(c_data_queue) = TRUE, "wr queue not flushed by master");
        WaitForClock(i_clock, 2);
        burst_read_bus(net, bus_handle, TO_INTEGER(UNSIGNED(c_address_map(C))) + 4, 4, c_data_queue);
        FOR I IN 0 TO 3 LOOP 
          v_tmp := pop(c_data_queue);
          AffirmIf(id, v_tmp = STD_LOGIC_VECTOR(TO_UNSIGNED(C+i+1234, 32)), "read error");
        END LOOP;
        AffirmIf(id, is_empty(c_data_queue) = TRUE, "rd queue not flushed by master");
      END LOOP;

    END IF;

    ReportAlerts;
    check(GetAffirmCount > 0,  "not selfchecking");
    check_equal(GetAlertCount, 0, "error occured");
    test_runner_cleanup(runner);
  END PROCESS;
  test_runner_watchdog(runner, 2 ms);


  --====================================================================
  --= verification COMPONENT
  --====================================================================
  inst_avl_master: ENTITY vunit_lib.avalon_master
    GENERIC MAP(
      bus_handle              => bus_handle,
      write_high_probability  => 1.0,
      read_high_probability   => 1.0
    )
    PORT MAP(
      clk                     => i_clock,
      address                 => i_avalon_wr.address,
      byteenable              => i_avalon_wr.byteenable,
      burstcount              => i_avalon_wr.burstcount,
      write                   => i_avalon_wr.write,
      writedata               => i_avalon_wr.writedata,
      read                    => i_avalon_wr.read,
      readdata                => o_avalon_rd.readdata,
      readdatavalid           => o_avalon_rd.readdatavalid,
      waitrequest             => o_avalon_rd.waitrequest
    );



  --====================================================================
  --= device under test
  --====================================================================
  inst_dut : ENTITY WORK.avl_bus_splitter
    GENERIC MAP (
      g_number_ports          => g_number_ports,
      g_compare_bit_upper     => c_comp_upper_bit,
      g_compare_bit_lower     => c_comp_lower_bit,
      g_address_map           => c_address_map(0 TO g_number_ports-1)
    )
    PORT MAP (
      i_clock                 => i_clock,
      i_reset                 => i_reset,
      --
      i_slave_avalon_select   => '1',
      i_slave_avalon_wr       => i_avalon_wr,
      o_slave_avalon_rd       => o_avalon_rd,
      --
      o_master_avalon_select  => s_select,
      o_master_avalon_wr      => s_avalon_wr,
      i_master_avalon_rd      => s_avalon_rd
    );



  gen_avl_slaves : FOR i IN 0 TO g_number_ports-1 GENERATE
    inst_slvX: ENTITY vunit_lib.avalon_slave
      GENERIC MAP (
        avalon_slave          => avalon_slave(I)
      )
      PORT MAP (
        clk                   => i_clock,
        address               => s_avalon_wr(I).address(15 DOWNTO 0),
        byteenable            => s_avalon_wr(I).byteenable,
        burstcount            => s_avalon_wr(I).burstcount,
        write                 => s_avalon_wr(I).write AND s_select(I),
        writedata             => s_avalon_wr(I).writedata,
        read                  => s_avalon_wr(I).read AND s_select(I),
        readdata              => s_avalon_rd(I).readdata,
        readdatavalid         => s_avalon_rd(I).readdatavalid,
        waitrequest           => s_avalon_rd(I).waitrequest
      );
  END GENERATE;


END ARCHITECTURE ;
