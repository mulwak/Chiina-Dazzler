-- Copyright 2021, 2022 @ponzu840w GPLv3.0
-- Generate 1024*768 (XGA) H,V Sync.
-- But address out is 256*768, because real dotclock is 16MHz.
-- includes
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entity declaration
entity VideoTimingGen is
  port(
  clk_in, reset_in  : in std_logic;
  h_blank_out, v_blank_out, h_sync_out, v_sync_out  : out std_logic; -- negative logic
  h_earlyblank_out, v_earlyblank_out  : out std_logic;
  h_addr_out  : out integer range 0 to 511;
  v_addr_out  : out integer range 0 to 1023
);
end VideoTimingGen;

architecture RTL of VideoTimingGen is
  -- constants
  -- clock length
  -- H
  constant H_VALID : integer := 256;
  constant H_FRONT : integer := 6;
  constant H_SYNC : integer := 34;
  constant H_BACK : integer := 40;
  -- V
  constant V_VALID : integer := 768;
  constant V_FRONT : integer := 3;
  constant V_SYNC : integer := 6;
  constant V_BACK : integer := 28;

  signal h_cnt_reg  : integer range 0 to (H_VALID+H_FRONT+H_SYNC+H_BACK-1); -- 0~331 9bit counter
  signal v_cnt_reg  : integer range 0 to (V_VALID+V_FRONT+V_SYNC+V_BACK-1); -- 0~806 10bit counter
  signal h_blank_delayreg0, v_blank_delayreg0 : std_logic;
  signal h_blank_delayreg1, v_blank_delayreg1 : std_logic;
  signal h_eblank_reg, v_eblank_reg : std_logic;
begin
  h_addr_out <= h_cnt_reg;
  v_addr_out <= v_cnt_reg;
  h_blank_out <= h_blank_delayreg0;
  v_blank_out <= v_blank_delayreg0;
  h_earlyblank_out <= h_eblank_reg;
  v_earlyblank_out <= v_eblank_reg;
  h_eblank_reg <= '0' when
                  H_VALID-1 < h_cnt_reg  else
                  '1';
  v_eblank_reg <= '0' when
                  V_VALID-1 < v_cnt_reg  else
                  '1';
  h_sync_out <= '0' when
                H_VALID+H_FRONT < h_cnt_reg and
                h_cnt_reg < H_VALID+H_FRONT+H_SYNC+1 else
                '1';
  v_sync_out <= '0' when
                V_VALID+V_FRONT-1 < v_cnt_reg and
                v_cnt_reg < V_VALID+V_FRONT+V_SYNC else
                '1';
  u1:process(clk_in)
  begin
    -- clk positive edge
    if(clk_in'event and clk_in = '1')then
      -- reset
      if(reset_in = '0')then
        h_cnt_reg <= 0;
        v_cnt_reg <= 0;
      else
        -- end of h back
        if(h_cnt_reg = H_VALID+H_FRONT+H_SYNC+H_BACK-1) then
          h_cnt_reg <= 0;
          -- end of v back
          if(v_cnt_reg = V_VALID+V_FRONT+V_SYNC+V_BACK-1) then
            v_cnt_reg <= 0;
          else
            v_cnt_reg <= v_cnt_reg+1;
          end if; -- end if(end of v)
        else -- not end of h back
          h_cnt_reg <= h_cnt_reg+1;
        end if; -- end if(end of h)
      end if; -- end reset
    h_blank_delayreg1 <= h_eblank_reg;
    h_blank_delayreg0 <= h_blank_delayreg1;
    v_blank_delayreg1 <= v_eblank_reg;
    v_blank_delayreg0 <= v_blank_delayreg1;
    end if; -- end clk positive edge
  end process;
end RTL;

