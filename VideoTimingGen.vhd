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
  h_addr_out  : out integer range 0 to 511;
  v_addr_out  : out integer range 0 to 1023;
  cpload_out :  out std_logic
);
end VideoTimingGen;

architecture RTL of VideoTimingGen is
  -- constants
  -- clock length
  -- H
  constant H_VALID : integer := 256;
  constant H_FRONT : integer := 7;
  constant H_SYNC : integer := 35;
  constant H_BACK : integer := 40;
  -- V
  constant V_VALID : integer := 768;
  constant V_FRONT : integer := 3;
  constant V_SYNC : integer := 6;
  constant V_BACK : integer := 28;

  constant CPLOAD_END : integer := H_VALID+24+24-4;

  signal h_cnt_reg  : integer range 0 to (H_VALID+H_FRONT+H_SYNC+H_BACK-1); -- 0~331 9bit counter
  signal v_cnt_reg  : integer range 0 to (V_VALID+V_FRONT+V_SYNC+V_BACK-1); -- 0~806 10bit counter
begin
  h_addr_out <= h_cnt_reg;
  v_addr_out <= v_cnt_reg;
  u1:process(clk_in)
  begin
    -- clk positive edge
    if(clk_in'event and clk_in = '1')then
      -- reset
      if(reset_in = '0')then
        h_cnt_reg <= 0;
        v_cnt_reg <= 0;
        --h_sync_out <= '1';
        --v_sync_out <= '1';
        --v_blank_out <= '1';
      else
        -- count
        case h_cnt_reg is
          when H_VALID+H_FRONT+H_SYNC+H_BACK-1 =>
            h_cnt_reg <= 0;
          when others =>
            h_cnt_reg <= h_cnt_reg+1;
        end case;

        case h_cnt_reg is
          when 1 =>
          --when H_VALID+H_FRONT+H_SYNC+H_BACK-1 =>

            case v_cnt_reg is
              when V_VALID+V_FRONT+V_SYNC+V_BACK-1 =>
                v_cnt_reg <= 0;
              when others =>
                v_cnt_reg <= v_cnt_reg+1;
            end case;

            case v_cnt_reg is
              when V_VALID+V_FRONT+V_SYNC+V_BACK-1 =>
                v_blank_out <= '1';
              -- end of v valid
              when V_VALID-1 =>
                v_blank_out <= '0';

              -- end of v front
              when V_VALID+V_FRONT-1 =>
                v_sync_out <= '0';

              -- end of v sync
              when V_VALID+V_FRONT+V_SYNC-1 =>
                v_sync_out <= '1';

              when others =>
            -- ??
            end case; -- end case about v

          -- end of h valid
            h_blank_out <= '1';

          when 257 =>
            h_blank_out <= '0';

          when H_VALID-1 =>
            cpload_out <= '1';

            -- end of h front
          when H_VALID+H_FRONT =>
            h_sync_out <= '0';

            -- end of h sync
          when H_VALID+H_FRONT+H_SYNC =>
            h_sync_out <= '1';

          when CPLOAD_END =>
            cpload_out <= '0';

          when others =>
        end case;
      end if; -- end reset
    end if; -- end clk positive edge
  end process;
end RTL;

