LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.avalon_pkg.ALL;

PACKAGE project_pkg IS 

  CONSTANT c_index_version      : NATURAL := 0;
  CONSTANT c_index_irq          : NATURAL := 1;
  CONSTANT c_index_ram          : NATURAL := 2;
  CONSTANT c_index_regbank      : NATURAL := 3;
  CONSTANT c_index_uart         : NATURAL := 4;
  CONSTANT c_index_timer        : NATURAL := 5;

  CONSTANT c_base_addr_version  : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
  CONSTANT c_base_addr_irq      : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00001000";
  CONSTANT c_base_addr_ram      : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00002000";
  CONSTANT c_base_addr_regbank  : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00003000";
  CONSTANT c_base_addr_uart     : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00004000";
  CONSTANT c_base_addr_timer    : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00005000";

  CONSTANT c_address_map        : t_slv32_matrix(0 TO 5) := (
    c_index_version       => c_base_addr_version,
    c_index_irq           => c_base_addr_irq,
    c_index_ram           => c_base_addr_ram,
    c_index_regbank       => c_base_addr_regbank,
    c_index_uart          => c_base_addr_uart,
    c_index_timer         => c_base_addr_timer);

END PACKAGE;
