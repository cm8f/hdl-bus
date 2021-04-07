## Avalon Package 

### Avalon Stream Type Definition 

#### t_avalonst_slave_in/t_avalonf_master_out 
| signal                        | type             | description  |
| ---------                     | ----             | ------------ |
| t_avalonst_slave_in.data[n:0] | std_logic_vector |              |
| t_avalonst_slave_in.valid     | std_logic        |              |
| t_avalonst_slave_in.sop       | std_logic        |              |
| t_avalonst_slave_in.eop       | std_logic        |              |

#### t_avalonst_slave_out/t_avalonst_master_in
| signal                          | type           | description  |
| ---------                       | ----           | ------------ |
| t_avalonst_slave_out.ready      | std_logic      |              |


### Avalon Memory Mapped Type Definitino

#### t_avalonf_slave_in/t_avalon_master_out 
| signal                             | type             | description         |
| ---------                          | ----             | ------------        |
| t_avalonf_slave_in.address[31:0]   | std_logic_vector | Avalon Byte Address |
| t_avalonf_slave_in.writedata[31:0] | std_logic_vector | Avalon Write Data   |
| t_avalonf_slave_in.byteenable[3:0] | std_logic_vector | Avalon Byte Enable  |
| t_avalonf_slave_in.burstcount[7:0] | std_logic_vector | Avalon Burst count  |
| t_avalonf_slave_in.read            | std_logic        | Avalon Read Strobe  |
| t_avalonf_slave_in.write           | std_logic        | Avalon Write Strobe |

#### t_avalonf_slave_in/t_avalon_master_out 
| signal                             | type             | description                |
| ---------                          | ----             | ------------               |
| t_avalonf_slave_out.readdata[31:0] | std_logic_vector | Avalon Read data           |
| t_avalonf_slave_out.readdatavalid  | std_logic        | Avalon Read Data Valid     |
| t_avalonf_slave_out.waitrequest    | std_logic        | Avalon Wait request        |
