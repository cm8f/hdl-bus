LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE version_pkg IS
  
  SUBTYPE t_version_decoder IS STD_LOGIC_VECTOR(4 DOWNTO 2);
  
  CONSTANT p_addr_version_reg_system_version    : STD_LOGIC_VECTOR(31 DOWNTO 0)   := X"00000000";  
  CONSTANT p_addr_version_reg_gitversion        : STD_LOGIC_VECTOR(31 DOWNTO 0)   := x"00000004";
  CONSTANT p_addr_version_reg_timestamp         : STD_LOGIC_VECTOR(31 DOWNTO 0)   := x"00000008";
  CONSTANT p_addr_version_reg_buildnumber       : STD_LOGIC_VECTOR(31 DOWNTO 0)   := x"0000000C";
  CONSTANT p_addr_version_reg_features          : STD_LOGIC_VECTOR(31 DOWNTO 0)   := x"00000010";

  -- 0100 initial version
  CONSTANT p_version_reg_system_version         : STD_LOGIC_VECTOR(31 DOWNTO 0)   := X"0101C58f";  
  CONSTANT p_version_reg_timestamp              : STD_LOGIC_VECTOR(31 DOWNTO 0)   := STD_LOGIC_VECTOR(RESIZE(UNSIGNED'(x"513A2"), 32));
  CONSTANT p_version_reg_buildnumber            : STD_LOGIC_VECTOR(31 DOWNTO 0)   := x"00000000";
  CONSTANT p_version_reg_gitversion             : STD_LOGIC_VECTOR(31 DOWNTO 0)   := x"cc3e7368";

END PACKAGE;
