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

  process(vsync)
  begin
    if(vsync'event and vsync = '0')then
      if(ugoki_reg = 255)then
        ugoki_reg <= 0;
      else
        ugoki_reg <= ugoki_reg+1;
      end if;
    end if;
  end process;


  process(clk_in)
  begin
    if(clk_in'event and clk_in = '1')then
      hsync_out <= hsync;
      vsync_out <= vsync;
      if(conv_std_logic_vector(vaddr,10)(6) = '1')then
        r_out <= hblank and vblank and conv_std_logic_vector(haddr+ugoki_reg,9)(5);
        g_out <= hblank and vblank and conv_std_logic_vector(haddr+ugoki_reg,9)(2);
        b_out <= hblank and vblank and conv_std_logic_vector(haddr+ugoki_reg,9)(0);
      else
        r_out <= hblank and vblank and not(conv_std_logic_vector(haddr+ugoki_reg,9)(5));
        g_out <= hblank and vblank and not(conv_std_logic_vector(haddr+ugoki_reg,9)(2));
        b_out <= hblank and vblank and not(conv_std_logic_vector(haddr+ugoki_reg,9)(0));
      end if;
    end if;
  end process;

end RTL;

