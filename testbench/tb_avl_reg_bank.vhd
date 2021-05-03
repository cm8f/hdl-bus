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

ENTITY tb_avl_gen_reg_bank IS
  GENERIC (
    runner_cfg        : string;
    g_registers       : INTEGER RANGE 4 TO 256 := 4;
    g_register_width  : INTEGER RANGE 32 TO 32  := 32
  );
END ENTITY;

ARCHITECTURE tb OF tb_avl_gen_reg_bank IS

  CONSTANT c_period               : TIME    := 10 ns;
  CONSTANT c_registers            : INTEGER := g_registers;
  CONSTANT c_register_width       : INTEGER := g_register_width;
  CONSTANT c_register_upper_bit   : INTEGER := 2 + INTEGER(ceil(log2(REAL(g_registers))));
  CONSTANT c_register_lower_bit   : INTEGER := 2;

  SIGNAL i_clock      : STD_LOGIC;
  SIGNAL i_reset      : STD_LOGIC;
  SIGNAL i_avalon_select  : STD_LOGIC;
  SIGNAL i_avalon_wr      : t_avalonf_slave_in;
  SIGNAL o_avalon_rd      : t_avalonf_slave_out;

  SIGNAL i_reg_wrreq      : STD_LOGIC_VECTOR(c_registers-1 DOWNTO 0);
  SIGNAL i_reg_din        : t_slv32_matrix(c_registers-1 DOWNTO 0);
  SIGNAL o_reg_dout       : t_slv32_matrix(c_registers-1 DOWNTO 0);
  SIGNAL o_reg_valid      : STD_LOGIC_VECTOR(c_registers-1 DOWNTO 0);


  CONSTANT master_logger    : logger_t := get_logger("master");
  CONSTANT tb_logger        : logger_t := get_logger("tb");
  CONSTANT master_actor     : actor_t   := new_actor("Avalon-MM Master");
  CONSTANT bus_handle       : bus_master_t := new_bus(
                                  data_length => p_avl_mm_data_width,
                                  address_length  => p_avl_mm_addr_width,
                                  logger          => master_logger,
                                  actor           => master_actor);

  SIGNAL id : AlertLogIDType;

BEGIN

  --====================================================================
  --= clocking
  --====================================================================
  CreateClock(i_clock, c_period);
  CreateReset(i_reset, '1', i_clock, 10*c_period, 1 ns);

  id <= GetAlertLogID(PathTail(tb_avl_gen_reg_bank'INSTANCE_NAME));


  --====================================================================
  --= stim
  --====================================================================
  proc_stim: PROCESS
    VARIABLE v_val : STD_LOGIC_VECTOR(p_avl_mm_data_width-1 DOWNTO 0);
    VARIABLE v_tmp : STD_LOGIC_VECTOR(p_avl_mm_data_width-1 DOWNTO 0);
  BEGIN
    test_runner_setup(runner, runner_cfg);
    WaitForLevel(i_reset, '1');
    WaitForLevel(i_reset, '0');
    WaitForClock(i_clock, 1);

    IF run("single_wr_single_rd") THEN
      v_val := STD_LOGIC_VECTOR(TO_UNSIGNED(123, v_val'LENGTH));
      write_bus(net, bus_handle, 0, v_val);
      WaitForClock(i_clock, 2);
      AffirmIf(id, o_reg_dout(0)(g_register_width-1 DOWNTO 0) = v_val(g_register_width-1 DOWNTO 0), "regout check failed");
      read_bus(net, bus_handle, 0, v_tmp);
      AffirmIf(id, v_tmp(g_register_width-1 DOWNTO 0) = v_val(g_register_width-1 DOWNTO 0), TO_HSTRING(v_val) & " /= " & TO_HSTRING(v_tmp));
    END IF;

    IF run("seqence_wr_sequence_rd") THEN
      FOR i IN 0 TO c_registers-1 LOOP
        v_val := STD_LOGIC_VECTOR(TO_UNSIGNED(64+I, v_val'LENGTH));
        write_bus(net, bus_handle, I*4, v_val);
        WaitForClock(i_clock, 3);
        AffirmIf(id, o_reg_dout(I)(g_register_width-1 DOWNTO 0) = v_val(g_register_width-1 DOWNTO 0), "regout check failed@" & TO_STRING(I) & "=" & TO_HSTRING(o_reg_dout(I)) );
        read_bus(net, bus_handle, I*4, v_tmp);
        AffirmIf(id, v_tmp(g_register_width-1 DOWNTO 0) = v_val(g_register_width-1 DOWNTO 0), TO_HSTRING(v_val) & " /= " & TO_HSTRING(v_tmp));
      END LOOP;
    END IF;

    IF run("ext_write_avl_read") THEN 
      i_reg_wrreq <= (OTHERS => '0');
      i_reg_din <= (OTHERS => (OTHERS => '0'));
      FOR i IN 0 TO c_registers-1 LOOP 
        i_reg_din(I) <= STD_LOGIC_VECTOR(TO_UNSIGNED(10+I, i_reg_din(0)'LENGTH));
      END LOOP;
      i_reg_wrreq <= (OTHERS => '1');
      WaitForClock(i_clock, 2);
      i_reg_wrreq <= (OTHERS => '0');
      WaitForClock(i_clock, 2);
      --
      --
      FOR I IN 0 TO c_registers-1 LOOP 
        v_val := STD_LOGIC_VECTOR(TO_UNSIGNED(10+I, v_val'LENGTH));
        AffirmIf(id, o_reg_dout(I)(g_register_width-1 DOWNTO 0) = v_val(g_register_width-1 DOWNTO 0), "regout check failed@" & TO_STRING(I) & "=" & TO_HSTRING(o_reg_dout(I)) );
        read_bus(net, bus_handle, I*4, v_tmp);
        AffirmIf(id, v_tmp(g_register_width-1 DOWNTO 0) = v_val(g_register_width-1 DOWNTO 0), TO_HSTRING(v_val) & " /= " & TO_HSTRING(v_tmp));
      END LOOP;

    END IF;

    ReportAlerts;
    check(GetAffirmCount > 0,  "not selfchecking");
    check_equal(GetAlertCount, 0, "error occured");
    test_runner_cleanup(runner);
  END PROCESS;
  test_runner_watchdog(runner, 20 us);


  --====================================================================
  --= verification COMPONENT
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
  --= device under test
  --====================================================================
  inst_dut : ENTITY WORK.avl_gen_reg_bank
    GENERIC MAP (
      g_registers       => c_registers,
      g_reg_width       => c_register_width,
      g_addr_upper_bit  => c_register_upper_bit,
      g_addr_lower_bit  => c_register_lower_bit
    )
    PORT MAP (
      i_clock           => i_clock,
      i_reset           => i_reset,
      --
      i_avalon_select   => '1',
      i_avalon_wr       => i_avalon_wr,
      o_avalon_rd       => o_avalon_rd,
      --
      i_reg_wrreq       => i_reg_wrreq,
      i_reg_din         => i_reg_din,
      o_reg_dout        => o_reg_dout,
      o_reg_valid       => o_reg_valid
    );
END ARCHITECTURE ;
