LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE avalon_pkg IS

  TYPE t_slv_matrix IS ARRAY(NATURAL RANGE <>) OF STD_LOGIC_VECTOR;

  CONSTANT p_avl_st_data_width    : INTEGER := 32;
  CONSTANT p_avl_mm_addr_width    : INTEGER := 32;
  CONSTANT p_avl_mm_data_width    : INTEGER := 32;
  CONSTANT p_avl_mm_be_width      : INTEGER := p_avl_mm_data_width/8;
  CONSTANT p_avl_mm_burst_width   : INTEGER := 8;

  --! avalon stream type definition
  TYPE t_avalonst_slave_in IS RECORD
    data                              : STD_LOGIC_VECTOR(p_avl_st_data_width-1 DOWNTO 0);
    valid                             : STD_LOGIC;
    sop                               : STD_LOGIC;
    eop                               : STD_LOGIC;
  END RECORD;

  --! avalon stream type definition
  TYPE t_avalonst_slave_out IS RECORD
    ready                             : STD_LOGIC;
  END RECORD;

  --! avalon full type definition
  TYPE t_avalonf_slave_in IS RECORD
    address                   : STD_LOGIC_VECTOR(p_avl_mm_addr_width-1  DOWNTO 0);
    writedata                 : STD_LOGIC_VECTOR(p_avl_mm_data_width-1  DOWNTO 0);
    byteenable                : STD_LOGIC_VECTOR(p_avl_mm_be_width-1    DOWNTO 0);
    burstcount                : STD_LOGIC_VECTOR(p_avl_mm_burst_width-1 DOWNTO 0);
    read                      : STD_LOGIC;
    write                     : STD_LOGIC;
  END RECORD;

  TYPE t_avalonf_slave_out IS RECORD
    readdata                  : STD_LOGIC_VECTOR(p_avl_mm_data_width-1 DOWNTO 0);
    readdatavalid             : STD_LOGIC;
    waitrequest               : STD_LOGIC;
  END RECORD;

  ALIAS t_avalonst_master_in  IS t_avalonst_slave_out;
  ALIAS t_avalonst_master_out IS t_avalonst_slave_in;
  ALIAS t_avalonf_master_in   IS t_avalonf_slave_out;
  ALIAS t_avalonf_master_out  IS t_avalonf_slave_in;

  TYPE t_avalonst_slave_in_matrix   IS ARRAY(NATURAL RANGE <>) OF t_avalonst_slave_in;
  TYPE t_avalonst_slave_out_matrix  IS ARRAY(NATURAL RANGE <>) OF t_avalonst_slave_OUT;
  TYPE t_avalonf_slave_in_matrix    IS ARRAY(NATURAL RANGE <>) OF t_avalonf_slave_in;
  TYPE t_avalonf_slave_out_matrix   IS ARRAY(NATURAL RANGE <>) OF t_avalonf_slave_out;

  ALIAS t_avalonst_master_in_matrix   IS t_avalonst_slave_out_matrix;
  ALIAS t_avalonst_master_out_matrix  IS t_avalonst_slave_in_matrix;
  ALIAS t_avalonf_master_in_matrix    IS t_avalonf_slave_out_matrix;
  ALIAS t_avalonf_master_out_matrix   IS t_avalonf_slave_in_matrix;

  CONSTANT c_avalonf_slave_out_init : t_avalonf_slave_out := (
    readdata      => x"DEADDA7A",
    readdatavalid => '0',
    waitrequest   => '0'
  );

  CONSTANT c_avalonf_slave_in_init : t_avalonf_slave_in := (
    address       => (OTHERS => '0'),
    writedata     => (OTHERS => '0'),
    byteenable    => (OTHERS => '0'),
    burstcount    => (OTHERS => '0'),
    read          => '0',
    write         => '0'
  );

END PACKAGE;
