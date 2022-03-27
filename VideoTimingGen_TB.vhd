-- Copyright 2021, 2022 @ponzu840w GPLv3.0
library ieee;
use ieee.std_logic_1164.all;

entity VideoTimingGen_TB is
end VideoTimingGen_TB;


architecture SIM of VideoTimingGen_TB is

  component VideoTimingGen is
    port(
    clk_in, reset_in  : in std_logic;
    h_blank_out, v_blank_out, h_sync_out, v_sync_out  : out std_logic; -- negative logic
    h_earlyblank_out  : out std_logic;
    v_earlyblank_out  : out std_logic;
    h_addr_out  : out integer range 0 to 512;
    v_addr_out  : out integer range 0 to 1024
  );
  end component;

  signal t_clk, t_rst, t_h_blank, t_v_blank, t_h_sync, t_v_sync : std_logic;
  signal t_h_earlyblank, t_v_earlyblank : std_logic;
begin
  U01:VideoTimingGen port map(clk_in => t_clk, reset_in => t_rst,
                              h_blank_out => t_h_blank, v_blank_out => t_v_blank,
                              h_earlyblank_out => t_h_earlyblank,
                              v_earlyblank_out => t_v_earlyblank,
                              h_sync_out => t_h_sync, v_sync_out => t_v_sync);
  process
  begin
    t_clk <= '0'; wait for 31.25 ns; --16MHz clock
    t_clk <= '1'; wait for 31.25 ns;
  end process;

  process
  begin
    t_rst <= '0'; wait for 200 ns;
    t_rst <= '1'; wait for 20 ms;
    assert false
    report "Simulation Complete!"
    severity Failure;
  end process;
end SIM;

