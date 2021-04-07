## Avalon RAM

### Description

This is a simple system identification IP, containing Buildtime, GIT Revision, Buildnumber, and global system Features and version.
It is expected, that your build scripts handle the patching of dynamic (per build) fields like git revision, timestamp and build 
number. 

Example comming soon.

### Register Map

| Register                          | address | bit(s) | Description            |
|-----------------------------------|---------|--------|------------------------|

### Generics 

| Generic      | type    | range | comment                                        |
|--------------|---------|-------|------------------------------------------------|
| g_addr_width | Integer |       | RAM Address Width. Ram Depth = 2**g_addr_width |
| g_data_width | Integer | 32    | RAM Write Width                                |

### Ports 

| Port                    | direction   | type                    | comment                            |
| ----------------------- | ----------- | ----------------------- | --------------------------------   |
| i_clock                 | in          | std_logic               | Avalon clock                       |
| i_reset                 | in          | std_logic               | Avalon reset                       |
| i_avalon_select         | in          | std_logic               | Avalon select from master          |
| i_avalon_wr             | in          | t_avalonf_slave_in      | Avalon Write Port from master      |
| o_avalon_rd             | out         | t_avalonf_slave_out     | Avalon Read Port to master         |
| i_addr                  | in          | std_logic_vetor         | read/write address from user logic |
| i_wrreq                 | in          | std_logic               | Write Enable from user logic       |
| i_din                   | in          | std_logic_vetor         | Write Data from user logic         |
| i_rdreq                 | in          | std_logic               | Read Enable from user logic        |
| o_dout                  | out         | std_logic_vetor         | Read Data to user logic            |

### Usage

TODO
