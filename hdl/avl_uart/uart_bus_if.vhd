LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
USE WORK.avalon_pkg.ALL;
USE WORK.uart_pkg.ALL;

ENTITY uart_bus_if IS 
  PORT (
    i_clock         : IN  STD_LOGIC;
    i_reset         : IN  STD_LOGIC;
    i_avalon_select : IN  STD_LOGIC;
    i_avalon_wr     : IN  t_avalonf_slave_in;
    o_avalon_rd     : OUT t_avalonf_slave_out;
    -- 
    o_divider       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    --
    o_txfifo_wrreq  : OUT STD_LOGIC;
    o_txfifo_data   : OUT STD_LOGIC_VECTOR( 7 DOWNTO 0);
    i_txfifo_status : IN  STD_LOGIC_VECTOR(17 DOWNTO 0);
    --
    o_rxfifo_rdreq  : OUT STD_LOGIC;
    i_rxfifo_data   : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
    i_rxfifo_status : IN  STD_LOGIC_VECTOR(17 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE rtl OF uart_bus_if IS


  SIGNAL s_asel_rxstatus        : STD_LOGIC;
  SIGNAL s_asel_rxdata          : STD_LOGIC;
  SIGNAL s_asel_txstatus        : STD_LOGIC;
  SIGNAL s_asel_txdata          : STD_LOGIC;
  SIGNAL s_asel_divider         : STD_LOGIC;
  SIGNAL r_divider              : STD_LOGIC_VECTOR(15 DOWNTO 0);
  
  SIGNAL r_waitrequest          : STD_LOGIC := '0';
  SIGNAL s_waitrequest          : STD_LOGIC;
  SIGNAL s_readdatavalid        : STD_LOGIC;
  SIGNAL s_readdata             : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

  proc_addr_decoder : PROCESS(ALL)
  BEGIN
    
    s_waitrequest   <= '0';
    s_readdatavalid <= '0';
    s_readdata      <= x"DEADBEEF";

    s_asel_divider  <= '0';
    s_asel_txdata   <= '0';
    s_asel_txstatus <= '0';
    s_asel_rxdata   <= '0';
    s_asel_rxstatus <= '0';

    IF i_avalon_select = '1' AND r_waitrequest = '0' THEN 
      IF i_avalon_wr.address(t_uart_decoder'RANGE) = p_addr_uart_divider(t_uart_decoder'RANGE) THEN
        s_asel_divider      <= '1';
        s_readdata          <= STD_LOGIC_vECTOR(RESIZE(UNSIGNED(r_divider), 32));
        s_readdatavalid     <= i_avalon_wr.read;
      END IF;

      IF i_avalon_wr.address(t_uart_decoder'RANGE) = p_addr_uart_tx_data(t_uart_decoder'RANGE) THEN
        s_asel_txdata       <= '1';
        s_readdatavalid     <= i_avalon_wr.read;
      END IF;

      IF i_avalon_wr.address(t_uart_decoder'RANGE) = p_addr_uart_tx_stat(t_uart_decoder'RANGE) THEN
        s_asel_txstatus     <= '1';
        s_readdata          <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(i_txfifo_status), 32));
        s_readdatavalid     <= i_avalon_wr.read;
      END IF;

      IF i_avalon_wr.address(t_uart_decoder'RANGE) = p_addr_uart_rx_data(t_uart_decoder'RANGE) THEN
        s_asel_rxdata       <= '1';
        s_readdata          <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(i_rxfifo_data), 32));
        s_readdatavalid     <= i_avalon_wr.read;
      END IF;

      IF i_avalon_wr.address(t_uart_decoder'RANGE) = p_addr_uart_rx_stat(t_uart_decoder'RANGE) THEN
        s_asel_rxstatus     <= '1';
        s_readdata          <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(i_rxfifo_status), 32));
        s_readdatavalid     <= i_avalon_wr.read;
      END IF;

    END IF;

  END PROCESS;



  o_avalon_rd.readdata      <= s_readdata;
  o_avalon_rd.readdatavalid <= s_readdatavalid;
  o_avalon_rd.waitrequest   <= s_waitrequest;

  proc_write: PROCESS(i_clock) 
  BEGIN
    IF RISING_EDGE(i_clock) THEN
		  r_waitrequest       <= s_waitrequest;
      --
      IF i_avalon_wr.write = '1' THEN
        IF s_asel_divider = '1' THEN
          r_divider     <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(i_avalon_wr.writedata), r_divider'LENGTH));
        END IF;
      END IF;
    END IF;
  END PROCESS;

  o_rxfifo_rdreq  <= s_asel_rxdata AND i_avalon_wr.read;
  o_txfifo_wrreq  <= s_asel_txdata AND i_avalon_wr.write;
  o_txfifo_data   <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(i_avalon_wr.writedata), o_txfifo_data'LENGTH));
  o_divider       <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(r_divider), o_divider'LENGTH));

END ARCHITECTURE rtl;
