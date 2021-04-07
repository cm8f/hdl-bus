## Avalon Interrut Controller

### Description

This is a simple reconfigurable interrupt controller. Each individual input can be cnfigured as Level or Edge Detect. 
The interrupt output stays high until the interrupt register is read (and thereby cleared). Interrupts can be enabled 
independent from each other. Before enabling a IRQ source, it must be configured. Otherwise bad things might happen.

### Register Map

| Register                     | address | bit(s) | Description                                                                                             |
|------------------------------|---------|--------|---------------------------------------------------------------------------------------------------------|
| p_addr_interrupt_reg_int     | 0x00    | 31:0   | Interrupt Register. If Bit N is set, an IRQ at source N occured. Clear on Read.                         |
| p_addr_interrupt_reg_mask    | 0x04    | 31:0   | '0': Interrupt source N is disabled, '1': Interrupt source N is enabled                                 |
| p_addr_interrupt_reg_config0 | 0x08    | 31:0   | '0': Source N is level interrupt, '1': Source N is edge Interrupt                                       |
| p_addr_interrupt_reg_config1 | 0x0C    | 31:0   | Level Interrupt: '0': Active Low, '1': Active High; Edge Interrupt: '0': Rising Edge, '1': Falling Edge |

### Generics 

| Generic             | type    | range | comment                            |
|---------------------|---------|-------|------------------------------------|

### Ports 

| Port                    | direction   | type                    | comment                            |
| ----------------------- | ----------- | ----------------------- | --------------------------------   |
| i_clock                 | in          | std_logic               | Avalon clock                       |
| i_reset                 | in          | std_logic               | Avalon reset                       |
| i_avalon_select         | in          | std_logic               | Avalon select from master          |
| i_avalon_wr             | in          | t_avalonf_slave_in      | Avalon Write Port from master      |
| o_avalon_rd             | out         | t_avalonf_slave_out     | Avalon Read Port to master         |
| i_input                 | in          | std_logic_vector        | Interrupt Source vector            |
| o_interrupt             | out         | std_logic               | Active High Interrupt to Processor |

### Usage

TODO
