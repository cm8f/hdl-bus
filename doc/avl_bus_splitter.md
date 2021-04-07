## Avalon Bus Splitter


### Generics 

| Generic             | type    | range | comment                            |
|---------------------|---------|-------|------------------------------------|
| g_number_ports      | Integer | 2-16  | Number of avalon slave ports       |
| g_compare_bit_upper | Integer |       | Upper bit for address comparission |
| g_compare_bit_lower | Integer |       | Lower bit for address comparission |

### Ports 

| Port                          | direction   | type                             | comment                          |
| ----------------------------- | ----------- | -------                          | -------------------------------- |
| i_clock                       | in          | std_logic                        | Avalon clock                     |
| i_reset                       | in          | std_logic                        | Avalon reset                     |
| i_slave_avalon_select         | in          | std_logic                        | Avalon select from master        |
| i_slave_avalon_wr             | in          | t_avalonf_slave_in               | Avalon Write Port from master    |
| o_slave_avalon_rd             | out         | t_avalonf_slave_out              | Avalon Read Port to master       |
| o_master_avalon_select[n:0]   | out         | std_logic_vector                 | Avalon select to Slave(s)        |
| o_master_avalon_wr[n:0]       | out         | t_avalonf_master_out_matrix[n:0] | Avalon Write Port to slave(s)    |
| i_master_avalon_rd[n:0]       | in          | t_avalonf_master_in_matrix[n:0]  | Avalon Read port from slave(s)   |

### Usage

```
  CONSTANT c_address_map      : t_slv_matrix(0 TO 3)(31 DOWNTO 0) := (
                                                        0  => x"00000000",
                                                        1  => x"00010000",
                                                        2  => x"00020000",
                                                        3  => x"00030000");
  SIGNAL i_avalon_select  : STD_LOGIC;
  SIGNAL i_avalon_wr      : t_avalonf_slave_in;
  SIGNAL o_avalon_rd      : t_avalonf_slave_out;
  --
  SIGNAL s_select         : STD_LOGIC_VECTOR(0 TO g_number_ports-1);
  SIGNAL s_avalon_wr      : t_avalonf_master_out_matrix(0 TO g_number_ports-1);
  SIGNAL s_avalon_rd      : t_avalonf_master_in_matrix(0 TO g_number_ports-1);
begin 
...
  inst_dut : ENTITY WORK.avl_bus_splitter
    GENERIC MAP (
      g_number_ports          => 2,
      g_compare_bit_upper     => 17,
      g_compare_bit_lower     => 16,
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
...
``` 
