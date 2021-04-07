## Avalon Version/System ID Register

### Description

This is a simple system identification IP, containing Buildtime, GIT Revision, Buildnumber, and global system Features and version.
It is expected, that your build scripts handle the patching of dynamic (per build) fields like git revision, timestamp and build 
number. 

Example comming soon.

### Register Map

| Register                          | address | bit(s) | Description            |
|-----------------------------------|---------|--------|------------------------|
| p_addr_version_reg_system_version | 0x00    | 31:24  | System Major Version.  |
|                                   |         | 23:16  | System Minor Version.  |
|                                   |         | 15:0   | System Magic Number.   |
| p_addr_version_reg_gitversion     | 0x04    | 31:0   | Git Revision           |
| p_addr_version_reg_timestamp      | 0x08    | 31:0   | System Build Timestamp |
| p_addr_version_reg_buildnumber    | 0x0C    | 31:0   | Buildnumber            |
| p_addr_version_reg_features       | 0x10    | 31:0   | Feature Register       |

### Generics 

| Generic    | type             | range | comment                                    |
|------------|------------------|-------|--------------------------------------------|
| g_features | std_logic_vector |       | System Features (Implementation dependent) |

### Ports 

| Port                    | direction   | type                    | comment                            |
| ----------------------- | ----------- | ----------------------- | --------------------------------   |
| i_clock                 | in          | std_logic               | Avalon clock                       |
| i_reset                 | in          | std_logic               | Avalon reset                       |
| i_avalon_select         | in          | std_logic               | Avalon select from master          |
| i_avalon_wr             | in          | t_avalonf_slave_in      | Avalon Write Port from master      |
| o_avalon_rd             | out         | t_avalonf_slave_out     | Avalon Read Port to master         |

### Usage

TODO
