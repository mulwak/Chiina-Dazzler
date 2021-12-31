-- Generate 1024*768 (XGA) H,V Sync.
-- But address out is 256*768, because real dotclock is 16MHz.
-- includes
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- entity declaration
entity VideoTimingGen is
  -- constants
  generic(
  -- clock length
  -- H
     H_VALID : integer range 0 to 256 := 256;
     H_FRONT : integer range 0 to 6 := 6;
     H_SYNC : integer range 0 to 34 := 34;
     H_BACK : integer range 0 to 35 := 35;
  -- V
     V_VALID : integer range 0 to 768 := 768;
     V_FRONT : integer range 0 to 3 := 3;
     V_SYNC : integer range 0 to 6 := 6;
     V_BACK : integer range 0 to 29 := 29;
  -- Counter Width
     H_CNT_WIDTH  : integer range 0 to 9 := 9;
     V_CNT_WIDTH  : integer range 0 to 10 := 10;
     H_OUT_WIDTH  : integer range 0 to 8 := 8;
     V_OUT_WIDTH  : integer range 0 to 10 := 10
   );

  port(
    clk_in, reset_in  : in std_logic;
    h_blank_out, v_blank_out, h_sync_out, v_sync_out  : out std_logic;
    h_addr_out  : out std_logic_vector(H_OUT_WIDTH-1 downto 0);
    v_addr_out  : out std_logic_vector(V_OUT_WIDTH-1 downto 0)
  );
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
      end if;
    end if;
  end process;
end RTL;

