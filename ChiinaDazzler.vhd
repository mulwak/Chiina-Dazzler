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
          h_addr_out  : out integer range 0 to 512;
          v_addr_out  : out integer range 0 to 1024
        );
  end component;

  signal  hblank, vblank  :  std_logic;
  signal haddr  : integer range 0 to 512;
  signal vaddr  : integer range 0 to 1024;

  -- "cannot associate individually with open"
  --signal haddr_float : std_logic_vector(1 downto 0);
  --signal vaddr_float : std_logic_vector(0 downto 0);

begin
  U01 : VideoTimingGen
  port map(clk_in => clk_in,
           reset_in => reset_in,
           h_blank_out => hblank,
           v_blank_out => vblank,
           h_sync_out => hsync_out,
           v_sync_out => vsync_out,
           h_addr_out => haddr,
           v_addr_out => vaddr
         );

  r_out <= hblank and vblank and conv_std_logic_vector(haddr,9)(5);
  g_out <= hblank and vblank and conv_std_logic_vector(haddr,9)(2);
  b_out <= hblank and vblank and conv_std_logic_vector(haddr,9)(0);

end RTL;

