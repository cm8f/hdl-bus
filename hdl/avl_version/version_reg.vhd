-- altera vhdl_input_version vhdl_2008
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE WORK.avalon_pkg.ALL;
USE WORK.version_pkg.ALL;

ENTITY version_reg_bus_interface IS
  GENERIC(
    g_features            : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0')
  );
  PORT (
    -- system
    i_clock               : IN  STD_LOGIC;
    i_reset               : IN  STD_LOGIC;
    -- avalon
    i_avalon_select       : IN  STD_LOGIC;
    i_avalon_wr           : IN  t_avalonf_slave_in;
    o_avalon_rd           : OUT t_avalonf_slave_out
    -- external bus pid tune
  );
END ENTITY;

ARCHITECTURE rtl OF version_reg_bus_interface IS

  SIGNAL   s_readdata                       : STD_LOGIC_VECTOR(p_avl_mm_data_width-1 DOWNTO 0);
  SIGNAL   r_readdata                       : STD_LOGIC_VECTOR(p_avl_mm_data_width-1 DOWNTO 0);
      
  SIGNAL   s_waitrequest                    : STD_LOGIC := '0';
  SIGNAL   r_waitrequest                    : STD_LOGIC := '0';
  SIGNAL   r_readdatavalid                  : STD_LOGIC := '0';
  SIGNAL   s_readdatavalid                  : STD_LOGIC := '0';

  SIGNAL   s_gitversion                     : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL   s_timestamp                      : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL   s_buildnumber                    : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL   s_features                       : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

BEGIN

  s_buildnumber <= p_version_reg_buildnumber;
  s_timestamp   <= p_version_reg_timestamp;
  s_gitversion  <= p_version_reg_gitversion;

  proc_addr_decoder : PROCESS(ALL) 
  BEGIN

    s_waitrequest                   <= '0';
    s_readdatavalid                 <= '0';
    s_readdata                      <= x"DEADBEEF";

    IF i_avalon_select  = '1' AND r_waitrequest = '0' THEN
      IF i_avalon_wr.address(t_version_decoder'RANGE) = p_addr_version_reg_system_version(t_version_decoder'RANGE) THEN
        s_readdata                        <= p_version_reg_system_version;
        s_readdatavalid                   <= i_avalon_wr.read;
      END IF; 

      IF i_avalon_wr.address(t_version_decoder'RANGE) = p_addr_version_reg_gitversion(t_version_decoder'RANGE) THEN
        s_readdata                        <= s_gitversion;
        s_readdatavalid                   <= i_avalon_wr.read;
      END IF; 

      IF i_avalon_wr.address(t_version_decoder'RANGE) = p_addr_version_reg_timestamp(t_version_decoder'RANGE) THEN
        s_readdata                        <= s_timestamp;
        s_readdatavalid                   <= i_avalon_wr.read;
      END IF; 

      IF i_avalon_wr.address(t_version_decoder'RANGE) = p_addr_version_reg_buildnumber(t_version_decoder'RANGE) THEN
        s_readdata                        <= s_buildnumber;
        s_readdatavalid                   <= i_avalon_wr.read;
      END IF; 

      IF i_avalon_wr.address(t_version_decoder'RANGE) = p_addr_version_reg_features(t_version_decoder'RANGE) THEN
        s_readdata                        <= s_features;
        s_readdatavalid                   <= i_avalon_wr.read;
      END IF; 
    END IF;
  END PROCESS proc_addr_decoder;



  proc_reg: PROCESS(i_clock) 
  BEGIN
    IF RISING_EDGE(i_clock) THEN
      r_readdatavalid       <= '0';
      IF i_avalon_wr.read = '1' THEN
        r_waitrequest       <= s_waitrequest;
        r_readdatavalid     <= s_readdatavalid;
      END IF;
      r_readdata          <= s_readdata;
      --
    END IF;
  END PROCESS;

  o_avalon_rd.readdata            <= s_readdata;
  o_avalon_rd.readdatavalid       <= s_readdatavalid;
  o_avalon_rd.waitrequest         <= s_waitrequest;

  s_features <= g_features;

END ARCHITECTURE rtl;

