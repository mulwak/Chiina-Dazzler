-- Generate 1024*768 (XGA) H,V Sync.
-- But address out is 256*768, because real dotclock is 16MHz.
-- includes
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- constants
-- clock length
-- H
generic(H_VALID : integer range 0 to 256 := 256;
       );
constant H_FRONT : integer := 6;
constant H_SYNC : integer := 34;
constant H_BACK : integer := 35;
-- V
constant V_VALID : integer := 768;
constant V_FRONT : integer := 3;
constant V_SYNC : integer := 6;
constant V_BACK : integer := 29;
-- bas width
constant H_CNT_WIDTH  : integer := 9;
constant V_CNT_WIDTH  : integer := 10;
constant H_OUT_WIDTH  : integer := 8;
constant V_OUT_WIDTH  : integer := 10;

-- entity declaration
entity VideoTimingGen is
  port(
    clk_in, reset_in  : in std_logic;
    h_blank_out, v_blank_out, h_sync_out, v_sync_out  : out std_logic;
    h_addr_out  : out std_logic_vector(H_OUT_WIDTH-1 downto 0);
    v_addr_out  : out std_logic_vector(V_OUT_WIDTH-1 downto 0)
  )
end VideoTimingGen;

architecture RTL of VideoTimingGen is
  signal h_cnt_reg  : std_logic_vector(H_CNT_WIDTH-1 downto 0); -- 0~331 9bit counter
  signal v_cnt_reg  : std_logic_vector(V_CNT_WIDTH-1 downto 0); -- 0~806 10bit counter
begin
  u1:process(clk)
  begin
    if(clk'event and clk = '1')then
      -- reset
      if(reset_in = '0')then
        h_cnt_reg <= conv_std_logic_vector(0, 9);
        v_cnt_reg <= conv_std_logic_vector(0, 10);
      end if
    end if
  end process;
end RTL;

