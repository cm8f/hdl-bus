## Avalon UART

### Description

Avalon UART is a Avalon wrapper for a simple UART Implementation (8bit, No Parity, 1 stopbit).

### Register Map

| Register                       | address | bit(s) | Description            |
|--------------------------------|---------|--------|------------------------|
| p_addr_uart_divider            | 0x00    | 31:16  | UNUSED                 |
|                                |         | 15:0   | UART Clock divider     |
| p_addr_uart_tx_data            | 0x04    | 31:8   | UNUSED                 |
|                                |         | 7:0    | TX Data FIFO           |
| p_addr_uart_tx_stat            | 0x08    | 31:0   | TX FIFO State          |
| p_addr_uart_rx_data            | 0x0C    | 31:8   | UNUSED                 |
|                                |         | 7:0    | RX Data FIFO           |
| p_addr_uart_rx_stat            | 0x10    | 31:0   | RX FIFO State          |

### Generics 

| Generic    | type    | range | comment                                                                               |
|------------|---------|-------|---------------------------------------------------------------------------------------|
| g_parity   | Integer | 0-2   | Parity: 0: none, 1: odd parity, 2: even parity (dummy, curreently only 0 implemented) |
| g_stopbits | Integer | 1-2   | Number of Stop Bits                            (dummy, curreently only 1 implemented) |

### Ports 

| Port                    | direction   | type                    | comment                            |
| ----------------------- | ----------- | ----------------------- | --------------------------------   |
| i_clock                 | in          | std_logic               | Avalon clock                       |
| i_reset                 | in          | std_logic               | Avalon reset                       |
| i_avalon_select         | in          | std_logic               | Avalon select from master          |
| i_avalon_wr             | in          | t_avalonf_slave_in      | Avalon Write Port from master      |
| o_avalon_rd             | out         | t_avalonf_slave_out     | Avalon Read Port to master         |
| i_uart_rx               | in          | std_logic               | UART Serial In                     |
| o_uart_tx               | out         | std_logic               | UART Serial Out                    |
| o_irq_tx_empty          | out         | std_logic               | TX FIFO Empty Interrupt            |
| o_irq_rx_eop            | out         | std_logic               | RX Received EOP signal             |

### Usage

TODO
