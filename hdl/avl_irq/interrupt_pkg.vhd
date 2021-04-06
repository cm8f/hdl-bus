LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;

PACKAGE interrupt_pkg IS
  
  CONSTANT p_addr_interrupt_reg_int     : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
  CONSTANT p_addr_interrupt_reg_mask    : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000004";
  CONSTANT p_addr_interrupt_reg_config0 : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000008";
  CONSTANT p_addr_interrupt_reg_config1 : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"0000000c";

  CONSTANT p_type_edge                  : STD_LOGIC := '1';
  CONSTANT p_type_level                 : STD_LOGIC := '0';

  CONSTANT p_btpos_irq_mpu              : INTEGER   := 0;
  CONSTANT p_btpos_irq_adc              : INTEGER   := 1;
  CONSTANT p_btpos_irq_adxl             : INTEGER   := 2;
  CONSTANT p_btpos_irq_comp             : INTEGER   := 3;
  CONSTANT p_btpos_irq_mma              : INTEGER   := 4;
  CONSTANT p_btpos_irq_gps_eop          : INTEGER   := 5;
  CONSTANT p_btpos_irq_esp_tx_empty     : INTEGER   := 6;
  CONSTANT p_btpos_irq_esp_eop          : INTEGER   := 7;
  CONSTANT p_btpos_irq_uart_tx_empty    : INTEGER   := 8;
  CONSTANT p_btpos_irq_uart_eop         : INTEGER   := 9;


END PACKAGE;
