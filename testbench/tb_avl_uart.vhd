LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY OSVVM;
CONTEXT OSVVM.OSVVMContext;
LIBRARY VUNIT_LIB;
CONTEXT VUNIT_LIB.VUNIT_CONTEXT;
CONTEXT VUNIT_LIB.COM_CONTEXT;
CONTEXT VUNIT_LIB.VC_CONTEXT;

LIBRARY WORK;
USE WORK.avalon_pkg.ALL;
USE WORK.uart_pkg.ALL;

ENTITY tb_avl_uart IS
  GENERIC (
    runner_cfg  : STRING;
    g_baud      : INTEGER := 115200
  );
END ENTITY;

ARCHITECTURE tb OF tb_avl_uart IS 

  SIGNAL i_clock        : STD_LOGIC;
  SIGNAL i_reset        : STD_LOGIC := '1';
  SIGNAL i_avalon_wr    : t_avalon_slave_in;
  SIGNAL o_avalon_rd    : t_avalon_slave_out;

  SIGNAL o_uart_tx          : STD_LOGIC;
  SIGNAL i_uart_rx          : STD_LOGIC;
  SIGNAL o_irq_rx_eop       : STD_LOGIC;

  SIGNAL s_byteenable : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL s_burstcount : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL r_readdatavalid : STD_LOGIC;

  CONSTANT c_period         : TIME      := 20 ns;
  CONSTANT c_uart_divider : INTEGER := 50000000/g_baud;
  CONSTANT p_addr_base_uart   : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
  SUBTYPE t_address_decoder   IS STD_LOGIC_VECTOR(15 DOWNTO 14);

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
  CreateReset(i_reset, '1', i_clock, 10*c_period, 1 ns);


  --==========================================================================
  --= logging
  --==========================================================================
  proc_stim : PROCESS
    VARIABLE v_sumFail  : INTEGER := 0;
    VARIABLE v_sumErr   : INTEGER := 0;
    VARIABLE v_addr : STD_LOGIC_VECTOR(31 DOWNTO 0);
    VARIABLE v_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
  BEGIN
    test_runner_setup(runner, runner_cfg);
    id     <= GetAlertLogID(PathTail(tb_avl_uart'INSTANCE_NAME));
    SetGlobalAlertEnable(TRUE);
    SetLogEnable(INFO, TRUE);
    WaitForLevel(i_reset, '0');

    WHILE test_suite LOOP 
      IF run("test") THEN 
        Log(id, "Configure UART to divider" & TO_STRING(c_uart_divider));
        v_addr      := (OTHERS => '0');
        v_addr(t_address_decoder'RANGE)  := p_addr_base_uart(t_address_decoder'RANGE);
        v_data                           := STD_LOGIC_VECTOR(TO_UNSIGNED(c_uart_divider, 32));
        write_bus(net, bus_handle, v_addr, v_data);

        -- write data
        v_addr(7 DOWNTO 0)              := x"04";
        FOR I IN 32 TO 127 LOOP
          Log(id, "write data " & to_string(i));
          v_data                         := STD_LOGIC_VECTOR(TO_UNSIGNED(I, 32));
          write_bus(net, bus_handle, v_addr, v_data);
        END LOOP;

        Log(id, "write LF");
        -- lf
        v_data   := STD_LOGIC_VECTOR(TO_UNSIGNED(10, 32));
        write_bus(net, bus_handle, v_addr, v_data);
        Log(id, "write CR");
        -- cr
        v_data   := STD_LOGIC_VECTOR(TO_UNSIGNED(13, 32));
        write_bus(net, bus_handle, v_addr, v_data);

        Log(id, " wait for irq");
        WaitForLevel(o_irq_rx_eop, '1');
        Log(id, " irq received");

        -- READ 
        v_addr(7 DOWNTO 0) := x"0C";
        FOR I IN 32 TO 127 LOOP
          Log(id, " read from fifo");
          read_bus(net, bus_handle, v_addr, v_data);
          AffirmIfEqual(id, TO_INTEGER(UNSIGNED(v_data(7 DOWNTO 0))), I, "unexpected character " );
          WaitForClock(i_clock, 4);
        END LOOP;
      END IF;

    END LOOP;
    ReportAlerts;
    check(GetAffirmCount > 0, "not selfchecking");
    check_equal(GetAlertCount, 0, "errors occured");
    TranscriptClose;
    test_runner_cleanup(runner);
  END PROCESS;
  test_runner_watchdog(runner, 2000 ms);



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
      byteenable        => s_byteenable,
      burstcount        => s_burstcount,
      write             => i_avalon_wr.write,
      writedata         => i_avalon_wr.writedata,
      read              => i_avalon_wr.read,
      readdata          => o_avalon_rd.readdata,
      readdatavalid     => r_readdatavalid,
      waitrequest       => o_avalon_rd.waitrequest
    );



  PROCESS(i_clock)
  BEGIN
    IF RISING_EDGE(I_CLOCK) THEN 
      r_readdatavalid <= i_avalon_wr.read AND o_avalon_rd.waitrequest;
    END IF;
  END PROCESS;



  --===================================================================
  --= dut
  --===================================================================
  inst_uart_avalon: ENTITY WORK.uart_avalon_slave
  GENERIC MAP(
    0, 1
  )
  PORT MAP(
    i_clock     => i_clock,
    i_reset     => i_reset,
    --
    i_avalon_select => (i_avalon_wr.read OR i_avalon_wr.write),
    i_avalon_wr     => i_avalon_wr,
    o_avalon_rd     => o_avalon_rd,
    --
    i_uart_rx       => i_uart_rx,
    o_uart_tx       => o_uart_tx,
    --
    o_irq_rx_eop    => o_irq_rx_eop

  );

  i_uart_rx <= o_uart_tx;

END ARCHITECTURE;
