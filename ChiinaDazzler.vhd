-- Copyright 2021, 2022 @ponzu840w GPLv3.0
-- 6502 Graphics Board @MAX-V CPLD
-- This VHDL source is the top level module.
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity ChiinaDazzler is
  port
  (
    clk_in :  in  std_logic;
    reset_in :  in  std_logic;
    hsync_out :  out  std_logic;
    vsync_out :  out  std_logic;
    r_out :  out  std_logic;
    g_out :  out  std_logic;
    b_out :  out  std_logic
  );
end ChiinaDazzler;

architecture RTL of ChiinaDazzler is

  component VideoTimingGen
    port(
          clk_in : in std_logic;
          reset_in : in std_logic;
          h_blank_out : out std_logic;
          v_blank_out : out std_logic;
          h_sync_out : out std_logic;
          v_sync_out : out std_logic;
          h_addr_out  : out integer range 0 to 511;
          v_addr_out  : out integer range 0 to 1023
        );
  end component;

  signal  hblank, vblank, hsync, vsync  :  std_logic;
  signal haddr  : integer range 0 to 511;
  signal vaddr  : integer range 0 to 1023;
  signal ugoki_reg  : integer range 0 to 255;

begin
  U01 : VideoTimingGen
  port map(clk_in => clk_in,
           reset_in => reset_in,
           h_blank_out => hblank,
           v_blank_out => vblank,
           h_sync_out => hsync,
           v_sync_out => vsync,
           h_addr_out => haddr,
           v_addr_out => vaddr
         );

  -- edge test
  process(clk_in)
  begin
    if(clk_in'event and clk_in = '1')then
      hsync_out <= hsync;
      vsync_out <= vsync;
      if(hblank = '1' and vblank = '1')then -- valid
        g_out <= '1';

        case vaddr is
          when 0 to 15 | 767 downto 753 => -- top or bottom
            b_out <= '1';

            if vaddr=0 or vaddr=1 or vaddr=2 or vaddr=3 or
              vaddr=767 or vaddr=766 or vaddr=765 or vaddr=764 then
              r_out <= '1';
            else
              r_out <= '0';
            end if;

          when others=>

            case haddr is
              when 0 to 3 | 255 downto 252 => -- left or right
                b_out <= '1';

                if haddr=0 or haddr=255 then
                  r_out <= '1';
                else
                  r_out <= '0';
                end if;

              when others=>
                b_out <= '0';
            end case;

        end case;
      else -- not valid
        r_out <= '0';
        g_out <= '0';
        b_out <= '0';
      end if;
    end if;
  end process;

  end RTL;

