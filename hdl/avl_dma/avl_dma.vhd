LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE WORK.avalon_pkg.ALL;

ENTITY avl_dma IS
  GENERIC(
    g_data_width              : INTEGER := 32;
    g_addr_width              : INTEGER := 32;
    g_burstlen_width          : INTEGER := 10;
    g_max_pending_transfers   : INTEGER := 1
  );
  PORT(
    i_clock               : IN  STD_LOGIC;
    i_reset               : IN  STD_LOGIC;
    -- descriptor
    i_descr_beats         : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
    i_descr_addr          : IN  STD_LOGIC_VECTOR(g_addr_width-1 DOWNTO 0);
    i_descr_wr_rdn        : IN  STD_LOGIC;
    i_descr_wrreq         : IN  STD_LOGIC;
    o_descr_ready         : OUT STD_LOGIC;
    -- avalon mm
    o_avl_mm_address      : OUT STD_LOGIC_VECTOR(g_addr_width-1 DOWNTO 0);
    o_avl_mm_write        : OUT STD_LOGIC;
    o_avl_mm_writedata    : OUT STD_LOGIC_VECTOR(g_data_width-1 DOWNTO 0);
    o_avl_mm_burstlen     : OUT STD_LOGIC_VECTOR(g_burstlen_width-1 DOWNTO 0);
    o_avl_mm_read         : OUT STD_LOGIC;
    i_avl_mm_readdata     : IN  STD_LOGIC_VECTOR(g_data_width-1 DOWNTO 0);
    i_avl_mm_readvalid    : IN  STD_LOGIC;
    i_avl_mm_waitrequest  : IN  STD_LOGIC;

    -- avlaon st
    i_avl_sts_data        : IN  STD_LOGIC_VECTOR(g_data_width-1 DOWNTO 0);
    i_avl_sts_valid       : IN  STD_LOGIC;
    o_avl_sts_ready       : OUT STD_LOGIC;
    --
    o_avl_stm_data        : OUT STD_LOGIC_VECTOR(g_data_width-1 DOWNTO 0);
    o_avl_stm_valid       : OUT STD_LOGIC;
    i_avl_stm_ready       : IN  STD_LOGIC
  );
END ENTITY avl_dma;
--
--ARCHITECTURE rtl OF avl_dma IS
--
--  SUBTYPE  t_descr_btt          IS STD_LOGIC_VECTOR(15 DOWNTO 0);
--  CONSTANT c_descr_wr_rdn       : NATURAL                           := 16;
--  SUBTYPE  t_descr_addr         IS STD_LOGIC_VECTOR(g_addr_width-1+17 DOWNTO 17);
--  TYPE     t_state              IS (idle, fetch_descr, issue_cmd, wait4wr_finish, wait4rd_finish);
--
--  SIGNAL r_descr_fifo_rdreq     : STD_LOGIC;
--  SIGNAL s_descr_fifo_dout      : STD_LOGIC_VECTOR(16 DOWNTO 0);
--  SIGNAL s_descr_fifo_empty     : STD_LOGIC;
--  SIGNAL s_descr_fifo_full      : STD_LOGIC;
--  --
--  SIGNAL s_din_fifo_rdata       : STD_LOGIC_VECTOR(g_data_width-1 DOWNTO 0);
--  SIGNAL s_din_fifo_rdreq       : STD_LOGIC;
--  SIGNAL r_din_fifo_rdreq_p1    : STD_LOGIC;
--  SIGNAL s_din_fifo_empty       : STD_LOGIC;
--  SIGNAL s_din_fifo_full        : STD_LOGIC;
--
--  SIGNAL r_fsm_rdreq            : STD_LOGIC;
--  SIGNAL r_state                : t_state := idle;
--  SIGNAL r_down_counter         : INTEGER := 0;
--
--BEGIN
--
--
--  inst_descr_fifo : ENTITY WORK.fifo_sc_mixed
--    GENERIC MAP(
--      g_wr_width          => 17+g_addr_width,
--      g_rd_width          => 17+g_addr_width,
--      g_wr_depth          => 128
--    )
--    PORT MAP(
--      i_clock             => i_clock,
--      i_reset             => i_reset,
--      i_din               => (i_descr_addr & i_descr_wr_rdn & i_descr_beats),
--      i_wrreq             => i_descr_wrreq,
--      i_rdreq             => r_descr_fifo_rdreq,
--      o_dout              => s_descr_fifo_dout,
--      o_empty             => s_descr_fifo_empty,
--      o_full              => s_descr_fifo_full
--    );
--  o_descr_ready           <= NOT s_descr_fifo_full;
--
--  proc_fsm: PROCESS(i_clock, i_reset)
--  BEGIN
--    IF i_reset = '1' THEN
--      r_state                 <= idle;
--    ELSIF RISING_EDGE(i_clock) THEN
--      r_descr_fifo_rdreq      <= '0';
--      CASE(r_state) IS
--      WHEN idle =>
--        r_state               <= idle;
--        IF NOT s_descr_fifo_empty THEN
--          r_state             <= fetch_descr;
--          r_descr_fifo_rdreq  <= '1';
--        END IF;
--      WHEN fetch_descr =>
--        r_state <= fetch_descr;
--        IF NOT r_descr_fifo_rdreq THEN
--          r_state <= issue_cmd;
--          r_down_counter <= TO_INTEGER(UNSIGNED(s_descr_fifo_dout(t_descr_btt'RANGE)));
--        END IF;
--      WHEN issue_cmd =>
--        r_state <= issue_cmd;
--      WHEN wait4rd_finish =>
--        r_state <= wait4rd_finish;
--      WHEN wait4wr_finish =>
--        r_state <= wait4wr_finish;
--      END CASE;
--    END IF;
--  END PROCESS;
--
--  o_avl_mm_address <= s_descr_fifo_dout(t_descr_addr'RANGE);
--  o_avl_mm_burstlen <= STD_LOGIC_VECTOR(UNSIGNED(s_descr_fifo_dout(t_descr_btt'RANGE))-1);
--
--
--  inst_din_fifo: ENTITY WORK.fifo_sc_mixed
--    GENERIC MAP(
--      g_wr_width          => g_data_width,
--      g_rd_width          => g_data_width,
--      g_wr_depth          => 1024
--    )
--    PORT MAP(
--      i_clock             => i_clock,
--      i_reset             => i_reset,
--      i_din               => i_avl_sts_data,
--      i_wrreq             => i_avl_sts_valid AND NOT s_din_fifo_full,
--      o_dout              => s_din_fifo_rdata,
--      i_rdreq             => s_din_fifo_rdreq,
--      o_empty             => s_din_fifo_empty,
--      o_full              => s_din_fifo_full
--    );
--
--  PROCESS(i_clock)
--  BEGIN
--    IF RISING_EDGE(i_clock) THEN
--      r_din_fifo_rdreq_p1 <= s_din_fifo_rdreq;
--    END IF;
--  END PROCESS;
--  s_din_fifo_rdreq        <= NOT i_avl_mm_waitrequest AND r_fsm_rdreq;
--  o_avl_mm_writedata      <= s_din_fifo_rdata;
--  o_avl_mm_write          <= r_din_fifo_rdreq_p1;
--
--
----  inst_dout_fifo: ENTITY WORK.fifo_sc_mixed
----    GENERIC MAP(
----      g_wr_width          => g_data_width,
----      g_rd_width          => g_data_width,
----      g_wr_depth          => 1024
----    )
----    PORT MAP(
----      i_clock             => i_clock,
----      i_reset             => i_reset,
----      i_din               => i_avl_mm_readdata,
----      i_wrreq             => i_avl_mm_readvalid,
----      o_dout              => s_dout_fifo_rdata,
----      i_rdreq             => s_dout_fifo_rdreq,
----      o_empty             => s_dout_fifo_empty,
----      o_full              => s_dout_fifo_full
----    );
--
--
--
--END ARCHITECTURE rtl;
