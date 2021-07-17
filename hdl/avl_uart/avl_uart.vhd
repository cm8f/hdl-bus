LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
USE WORK.avalon_pkg.ALL;

ENTITY uart_avalon_slave IS 
  GENERIC(
    g_parity      : INTEGER RANGE 0 TO 2 := 0; -- 0 none, 1 odd, 2 even
    g_stopbits    : INTEGER RANGE 1 TO 2 := 1
  );
  PORT(
    i_clock       : IN    STD_LOGIC;
    i_reset       : IN    STD_LOGIC;
    -- avalon
    i_avalon_select   : IN  STD_LOGIC;
    i_avalon_wr       : IN  t_avalon_slave_in;
    o_avalon_rd       : OUT t_avalon_slave_out;
    -- interface
    i_uart_rx         : IN  STD_LOGIC;
    o_uart_tx         : OUT STD_LOGIC;
    -- interrupts
    o_irq_tx_empty    : OUT STD_LOGIC;
    o_irq_rx_eop      : OUT STD_LOGIC
  );
END ENTITY;

ARCHITECTURE rtl OF uart_avalon_slave IS

  CONSTANT c_ETX          : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"03";
  CONSTANT c_EOT          : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"04";
  CONSTANT c_LF           : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"0A";
  CONSTANT c_CR           : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"0D";
  CONSTANT c_SYN          : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"16";
  
  SIGNAL s_bus_tx_wrreq   : STD_LOGIC;
  SIGNAL s_bus_tx_data    : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL s_bus_rx_rdreq   : STD_LOGIC;
  SIGNAL s_bus_rx_rdata   : STD_LOGIC_VECTOR(7 DOWNTO 0);

  SIGNAL s_txfifo_rdreq   : STD_LOGIC;
  SIGNAL r_txfifo_rdreq   : STD_LOGIC;
  SIGNAL s_txfifo_data    : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL s_txfifo_usedw   : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL s_txfifo_empty   : STD_LOGIC;
  SIGNAL s_txfifo_full    : STD_LOGIC;

  SIGNAL s_rx_valid       : STD_LOGIC;
  SIGNAL s_rx_data        : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL s_rxfifo_full    : STD_LOGIC;
  SIGNAL s_rxfifo_empty   : STD_LOGIC;
  SIGNAL s_rxfifo_usedw   : STD_LOGIC_VECTOR(31 DOWNTO 0);

  SIGNAL s_tx_valid       : STD_LOGIC;
  SIGNAL s_tx_data        : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL s_tx_busy        : STD_LOGIC;
  SIGNAL s_tx_done        : STD_LOGIC;

  SIGNAL s_divider        : STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN

  inst_bus : ENTITY WORK.uart_bus_if
    PORT MAP(
      i_clock         => i_clock,
      i_reset         => i_reset,
      i_avalon_select => i_avalon_select,
      i_avalon_wr     => i_avalon_wr,
      o_avalon_rd     => o_avalon_rd,
      --
      o_divider       => s_divider,
      --
      o_txfifo_wrreq  => s_bus_tx_wrreq,
      o_txfifo_data   => s_bus_tx_data,
      i_txfifo_status => (s_txfifo_full & s_txfifo_empty & s_txfifo_usedw(15 DOWNTO 0)),
      --
      o_rxfifo_rdreq  => s_bus_rx_rdreq,
      i_rxfifo_data   => s_bus_rx_rdata,
      i_rxfifo_status => (s_rxfifo_full & s_rxfifo_empty & s_rxfifo_usedw(15 DOWNTO 0))
    );



  inst_tx_fifo : ENTITY WORK.fifo_sc_single
    GENERIC MAP(
      g_width       => 8,
      g_depth       => 512
    )
    PORT MAP(
      i_clock       => i_clock,
      i_reset       => i_reset,
      -- read
      i_wrreq       => s_bus_tx_wrreq,
      i_din         => s_bus_tx_data,
      -- read
      i_rdreq       => s_txfifo_rdreq,
      o_dout        => s_txfifo_data,
      -- status
      o_almost_empty  => OPEN,
      o_almost_full   => OPEN,
      o_empty         => s_txfifo_empty,
      o_full          => s_txfifo_full,
      o_usedw_wr      => s_txfifo_usedw,
      o_usedw_rd      => OPEN
    );


  PROCESS(i_clock)
  BEGIN
    IF RISING_EDGE(i_clock) THEN
      s_txfifo_rdreq  <= NOT s_txfifo_empty AND NOT s_tx_busy AND NOT s_txfifo_rdreq AND NOT r_txfifo_rdreq;
      r_txfifo_rdreq <= s_txfifo_rdreq;
    END IF;
  END PROCESS;
  s_tx_valid      <= s_txfifo_rdreq;
  s_tx_data       <= s_txfifo_data;


  inst_uart_trx: ENTITY WORK.uart_wrapper_top
    GENERIC MAP(
      g_parity    => g_parity,
      g_stopbits  => g_stopbits
    )
    PORT MAP(
      i_clock     => i_clock,
      i_cfg_divider => s_divider,
      --
      o_rx_valid    => s_rx_valid,
      o_rx_data     => s_rx_data,
      i_tx_valid    => s_tx_valid, 
      i_tx_data     => s_tx_data,
      o_tx_busy     => s_tx_busy,
      o_tx_done     => s_tx_done,
      i_uart_rx     => i_uart_rx,
      o_uart_tx     => o_uart_tx
    );



  inst_irq: PROCESS(i_clock)
  BEGIN
    IF RISING_EDGE(i_clock) THEN
      o_irq_rx_eop      <= '0';
      o_irq_tx_empty  <= s_txfifo_empty;
      --
      IF s_rx_valid = '1' THEN 
        IF (s_rx_data = c_LF  OR 
            s_rx_data = c_CR  OR 
            s_rx_data = c_EOT OR 
            s_rx_data = c_ETX) THEN

          o_irq_rx_eop  <= '1';
        END IF;
      END IF;
    END IF;
  END PROCESS;



  inst_rx_fifo : ENTITY WORK.fifo_sc_single
    GENERIC MAP(
      g_width       => 8,
      g_depth       => 512
    )
    PORT MAP(
      i_clock       => i_clock,
      i_reset       => i_reset,
      -- read
      i_wrreq       => s_rx_valid,
      i_din         => s_rx_data,
      -- read
      i_rdreq       => s_bus_rx_rdreq,
      o_dout        => s_bus_rx_rdata,
      -- status
      o_almost_empty  => OPEN,
      o_almost_full   => OPEN,
      o_empty         => s_rxfifo_empty,
      o_full          => s_rxfifo_full,
      o_usedw_wr      => OPEN,
      o_usedw_rd      => s_rxfifo_usedw
    );

END ARCHITECTURE;
