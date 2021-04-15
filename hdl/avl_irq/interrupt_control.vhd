LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_MISC.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
USE WORK.avalon_pkg.ALL;
USE WORK.interrupt_pkg.ALL;

ENTITY avl_interrupt_control IS
  PORT (
    i_clock           : IN  STD_LOGIC;
    i_reset           : IN  STD_LOGIC;
    --
    i_avalon_select   : IN  STD_LOGIC;
    i_avalon_wr       : IN  t_avalonf_slave_in;
    o_avalon_rd       : OUT t_avalonf_slave_out;
    --
    i_input           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    o_interrupt       : OUT STD_LOGIC
  );
END ENTITY avl_interrupt_control;

ARCHITECTURE rtl OF avl_interrupt_control IS 
  -- avalon config
  SIGNAL r_cfg_mask        : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');   -- '0' active, '1' inactive
  SIGNAL r_cfg_type        : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');   -- '0' level, '1' edge
  SIGNAL r_cfg_level_edge  : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');   -- level: interrupt level, edge: '0' rising '1' falling
  -- self clearing interrupt register
  SIGNAL r_reg_int         : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

  SIGNAL r_input            : STD_LOGIC_VECTOR(31 DOWNTO 0);
  
  SIGNAL s_readdata         : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL r_readdata         : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL s_waitrequest      : STD_LOGIC := '0';
  SIGNAL r_waitrequest      : STD_LOGIC := '0';
  SIGNAL r_readdatavalid    : STD_LOGIC := '0';
  SIGNAL s_readdatavalid    : STD_LOGIC := '0';

  SIGNAL s_asel_mask        : STD_LOGIC;
  SIGNAL s_asel_config0     : STD_LOGIC;
  SIGNAL s_asel_config1     : STD_LOGIC;
  SIGNAL s_asel_int         : STD_LOGIC;
  SIGNAL r_asel_int         : STD_LOGIC;

  SUBTYPE t_interrupt_decoder IS STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

  proc_input: PROCESS(i_clock)
  BEGIN
    IF RISING_EDGE(i_clock) THEN
      r_input   <= i_input;
    END IF;
  END PROCESS;


    
  proc_addr_decoder : PROCESS(ALL) 
  BEGIN

    s_waitrequest                   <= '0';
    s_readdatavalid                 <= '0';
    s_readdata                      <= x"DEADBEEF";

    s_asel_mask       <= '0';
    s_asel_config0    <= '0';
    s_asel_config1    <= '0';
    s_asel_int        <= '0';

    IF i_avalon_select  = '1' AND r_waitrequest = '0' THEN
      --=====================================================================
      --= THRUST
      --=====================================================================
      IF i_avalon_wr.address(t_interrupt_decoder'RANGE) = p_addr_interrupt_reg_mask(t_interrupt_decoder'RANGE) THEN
        s_asel_mask                       <= '1';
        s_readdata                        <= r_cfg_mask;
        s_readdatavalid                   <= i_avalon_wr.read;
      END IF;

      IF i_avalon_wr.address(t_interrupt_decoder'RANGE) = p_addr_interrupt_reg_config0(t_interrupt_decoder'RANGE) THEN
        s_asel_config0                    <= '1';
        s_readdata                        <= r_cfg_type;
        s_readdatavalid                   <= i_avalon_wr.read;
      END IF;

      IF i_avalon_wr.address(t_interrupt_decoder'RANGE) = p_addr_interrupt_reg_config1(t_interrupt_decoder'RANGE) THEN
        s_asel_config1                    <= '1';
        s_readdata                        <= r_cfg_level_edge;
        s_readdatavalid                   <= i_avalon_wr.read;
      END IF;

      IF i_avalon_wr.address(t_interrupt_decoder'RANGE) = p_addr_interrupt_reg_int(t_interrupt_decoder'RANGE) THEN
        s_asel_int                        <= '1';
        s_readdata                        <= r_reg_int;
        s_readdatavalid                   <= i_avalon_wr.read;
      END IF;

    END IF;
  END PROCESS proc_addr_decoder;



  proc_reg: PROCESS(i_clock) 
  BEGIN
    IF RISING_EDGE(i_clock) THEN
	  r_asel_int <= s_asel_int AND i_avalon_wr.read; 
	  r_waitrequest <= '0';
      IF i_avalon_wr.read OR i_avalon_wr.write THEN
		r_waitrequest       <= s_waitrequest;
	  END IF; 
      IF i_avalon_wr.read = '1' THEN
        r_readdatavalid     <= s_readdatavalid;
      END IF;
      r_readdata          <= s_readdata;
    END IF;
  END PROCESS;

  o_avalon_rd.readdata      <= s_readdata;
  o_avalon_rd.readdatavalid <= s_readdatavalid;
  o_avalon_rd.waitrequest   <= s_waitrequest;




  proc_read_clear : PROCESS(i_clock) 
  BEGIN
    IF RISING_EDGE(i_clock) THEN
      IF r_asel_int THEN
        r_reg_int <= (OTHERS => '0');
      END IF;
      FOR I IN 0 TO r_reg_int'LENGTH-1 LOOP
        IF r_cfg_type(i) = p_type_level THEN
          IF (r_input(I) XNOR r_cfg_level_edge(I)) AND r_cfg_mask(I) THEN
            r_reg_int(I) <= '1';
          END IF;
        END IF;

        IF r_cfg_type(I) = p_type_edge THEN
          IF r_cfg_mask(I) = '1' 
            AND ( (r_cfg_level_edge(I) = '0' AND r_input(I) = '0' AND i_input(I) = '1' )
            OR    (r_cfg_level_edge(I) = '1' AND r_input(I) = '1' AND i_input(I) = '0' ) ) THEN 
            r_reg_int(I) <= '1';
          END IF;
            
        END IF;
      END LOOP;
    END IF;
  END PROCESS;



  proc_write : PROCESS(i_clock) 
  BEGIN
    IF RISING_EDGE(i_clock) THEN

      IF i_avalon_select AND i_avalon_wr.write THEN
        IF s_asel_mask THEN
          r_cfg_mask  <= i_avalon_wr.writedata;
        END IF;

        IF s_asel_config0 THEN
          r_cfg_type  <= i_avalon_wr.writedata;
        END IF;

        IF s_asel_config1 THEN
          r_cfg_level_edge <= i_avalon_wr.writedata;
        END IF;
      END IF;
    END IF;
  END PROCESS;



  o_interrupt <= OR_REDUCE( r_reg_int );

END ARCHITECTURE;
