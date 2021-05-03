LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY nios_test_system;

USE WORK.avalon_pkg.ALL;
USE WORK.project_pkg.ALL;

ENTITY de10nano IS 
  PORT (
    FPGA_CLK1_50  : IN STD_LOGIC;
    KEY           : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    SW            : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    UART_RX       : IN STD_LOGIC;
    UART_TX       : OUT STD_LOGIC
  );
END ENTITY;

ARCHITECTURE rtl OF de10nano IS 

  SIGNAL s_clock     : STD_LOGIC; 
  SIGNAL s_reset     : STD_LOGIC; 
  SIGNAL s_avalon_wr : t_avalonf_slave_in;
  SIGNAL s_avalon_rd : t_avalonf_slave_out;

  SIGNAL s_avalon_splitter_select   : STD_LOGIC_VECTOR(c_address_map'length-1 DOWNTO 0);
  SIGNAL s_avalon_splitter_wr       : t_avalonf_master_out_matrix(c_address_map'length-1 DOWNTO 0);
  SIGNAL s_avalon_splitter_rd       : t_avalonf_master_in_matrix (c_address_map'length-1 DOWNTO 0);
  SIGNAL s_irq_vector               : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL s_irq_soc                  : STD_LOGIC;
  SIGNAL s_uart_rx                  : STD_LOGIC;
  SIGNAL s_uart_tx                  : STD_LOGIC;

BEGIN 

  --====================================================================
  --= clocking/reset sync
  --====================================================================
  s_clock             <= FPGA_CLK1_50;


  inst_reset: ENTITY WORK.reset_control 
    GENERIC MAP(
      g_pipeline_stages     => 5
    )
    PORT MAP(
      i_clock               => s_clock,
      i_reset               => (NOT KEY(0)),
      o_reset               => s_reset
    );



  --====================================================================
  --= nios test controller 
  --====================================================================
  inst_nios: ENTITY nios_test_system.nios_test_system 
    PORT MAP(
      clk_clk                           => s_clock,
      reset_reset_n                     => s_reset,
			mm_bridge_0_m0_waitrequest        => s_avalon_rd.waitrequest,   -- mm_bridge_0_m0.waitrequest
			mm_bridge_0_m0_readdata           => s_avalon_rd.readdata,      --               .readdata
			mm_bridge_0_m0_readdatavalid      => s_avalon_rd.readdatavalid, --               .readdatavalid
			mm_bridge_0_m0_burstcount         => OPEN,                      --               .burstcount
			mm_bridge_0_m0_writedata          => s_avalon_wr.writedata,     --               .writedata
			mm_bridge_0_m0_address            => s_avalon_wr.address(15 downto 0),       --               .address
			mm_bridge_0_m0_write              => s_avalon_wr.write,         --               .write
			mm_bridge_0_m0_read               => s_avalon_wr.read,          --               .read
			mm_bridge_0_m0_byteenable         => OPEN,                      --               .byteenable
			mm_bridge_0_m0_debugaccess        => OPEN,                      --               .debugaccess
			irq_bridge_0_receiver_irq_irq(0)  => s_irq_soc  -- irq
		);



  --====================================================================
  --= avalon bus splitter
  --====================================================================
  inst_bus_splitter: ENTITY WORK.avl_bus_splitter
    GENERIC MAP(
      g_number_ports        => c_address_map'LENGTH,
      g_compare_bit_upper   => 15,
      g_compare_bit_lower   => 12,
      g_address_map         => c_address_map
    )
    PORT MAP(
      i_clock               => s_clock,
      i_reset               => s_reset,
      --
      i_slave_avalon_select   => '1',
      i_slave_avalon_wr       => s_avalon_wr,
      o_slave_avalon_rd       => s_avalon_rd,
      --
      o_master_avalon_select  => s_avalon_splitter_select,
      o_master_avalon_wr      => s_avalon_splitter_wr,
      i_master_avalon_rd      => s_avalon_splitter_rd
    );



  --====================================================================
  --= version register 
  --====================================================================
  inst_version: ENTITY WORK.version_reg_bus_interface 
  GENERIC MAP(
    g_features        => x"abcdabcd",
    g_system_version  => x"00000001"
  ) 
  PORT MAP(
    i_clock       => s_clock,
    i_reset       => s_reset,
    --
    i_avalon_select   => s_avalon_splitter_select (c_index_version),
    i_avalon_wr       => s_avalon_splitter_wr     (c_index_version),
    o_avalon_rd       => s_avalon_splitter_rd     (c_index_version)
  );



  --====================================================================
  --= generic register bank
  --====================================================================
  inst_reg_bank: ENTITY WORK.avl_gen_reg_bank 
    GENERIC MAP(
      g_registers     => 64, 
      g_reg_width     => 32,
      g_addr_upper_bit  => 7,
      g_addr_lower_bit  => 2
    )
    PORT MAP(
      i_clock           => s_clock,
      i_reset           => s_reset,
      --
      i_avalon_select   => s_avalon_splitter_select (c_index_regbank),
      i_avalon_wr             => s_avalon_splitter_wr     (c_index_regbank),
      o_avalon_rd             => s_avalon_splitter_rd     (c_index_regbank)
    );



  --====================================================================
  --= interrupt controller 
  --====================================================================
  inst_irq: ENTITY WORK.avl_interrupt_control 
    PORT MAP(
      i_clock                 => s_clock,
      i_reset                 => s_reset,
      --
      i_avalon_select         => s_avalon_splitter_select (c_index_irq),
      i_avalon_wr             => s_avalon_splitter_wr     (c_index_irq),
      o_avalon_rd             => s_avalon_splitter_rd     (c_index_irq),
      --
      i_input                 => s_irq_vector,
      o_interrupt             => s_irq_soc
    );



  --====================================================================
  --= ram 
  --====================================================================
  --inst_ram : ENTITY WORK.avl_ram 
  --  GENERIC MAP(
  --    g_addr_width          => 8,
  --    g_data_width          => 32
  --  )
  --  PORT MAP(
  --    i_clock               => s_clock,
  --    i_reset               => s_reset, 
  --    --
  --    i_avalon_select       => s_avalon_splitter_select (c_index_ram),
  --    i_avalon_wr           => s_avalon_splitter_wr     (c_index_ram),
  --    o_avalon_rd           => s_avalon_splitter_rd     (c_index_ram)
  --  );



  --====================================================================
  --= uart
  --====================================================================
  inst_uart: ENTITY WORK.uart_avalon_slave 
    PORT MAP(
      i_clock               => s_clock,
      i_reset               => s_reset, 
      --
      i_avalon_select       => s_avalon_splitter_select (c_index_uart),
      i_avalon_wr           => s_avalon_splitter_wr     (c_index_uart),
      o_avalon_rd           => s_avalon_splitter_rd     (c_index_uart),
      --
      i_uart_rx             => s_uart_rx,
      o_uart_tx             => s_uart_tx,
      --
      o_irq_tx_empty        => s_irq_vector(0),
      o_irq_rx_eop          => s_irq_vector(1) 
    );

    s_uart_rx <= UART_RX;
    UART_TX   <= s_uart_tx;

END ARCHITECTURE;
