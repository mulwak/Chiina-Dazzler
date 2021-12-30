-- Copyright 2021, 2022 @ponzu840w GPLv3.0
library ieee;
use ieee.std_logic_1164.all;

entity ChiinaDazzler_TB is
end ChiinaDazzler_TB;


architecture SIM of ChiinaDazzler_TB is

  component ChiinaDazzler is
    PORT
    (
      CLK :  IN  STD_LOGIC;
      RESET :  IN  STD_LOGIC;
      HSync :  OUT  STD_LOGIC;
      VSync :  OUT  STD_LOGIC;
      R : OUT STD_LOGIC;
      G : OUT STD_LOGIC;
      B : OUT STD_LOGIC
    );
  end component;

  signal T_CLK, T_RESET, T_HSync, T_VSync, T_R, T_G, T_B: std_logic;

begin
  U01:ChiinaDazzler port map(CLK => T_CLK, RESET => T_RESET, HSync => T_HSync, VSync => T_VSync,
                        R => T_R, G => T_G, B => T_B);
  process
  begin
    T_CLK <= '0'; wait for 31.25 ns; --16MHz clock
    T_CLK <= '1'; wait for 31.25 ns;
  end process;

  process
  begin
    T_RESET <= '0'; wait for 200 ns;
    T_RESET <= '1'; wait for 150 ms;
    assert false
    report "Simulation Complete!"
    severity Failure;
  end process;
end SIM;
