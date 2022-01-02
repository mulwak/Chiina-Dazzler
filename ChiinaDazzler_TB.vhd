-- Copyright 2021, 2022 @ponzu840w GPLv3.0
library ieee;
use ieee.std_logic_1164.all;

entity ChiinaDazzler_TB is
end ChiinaDazzler_TB;


architecture SIM of ChiinaDazzler_TB is

  component ChiinaDazzler is
    PORT
    (
      clk_in :  in  std_logic;
      reset_in :  in  std_logic;
      hsync_out :  out  std_logic;
      vsync_out :  out  std_logic;
      r_out :  out  std_logic;
      g_out :  out  std_logic;
      b_out :  out  std_logic
    );
  end component;

  signal T_CLK, T_RESET, T_HSync, T_VSync, T_R, T_G, T_B: std_logic;

begin
  U02 : ChiinaDazzler
  port map(
            clk_in => T_CLK,
            reset_in => T_RESET,
            hsync_out => T_HSync,
            vsync_out => T_VSync,
            r_out => T_R, g_out => T_G, b_out => T_B
          );
  process
  begin
    T_CLK <= '0'; wait for 31.25 ns; --16MHz clock
    T_CLK <= '1'; wait for 31.25 ns;
  end process;

  process
  begin
    T_RESET <= '0'; wait for 200 ns;
    T_RESET <= '1'; wait for 20 ms;
    assert false
    report "Simulation Complete!"
    severity Failure;
  end process;
end SIM;

