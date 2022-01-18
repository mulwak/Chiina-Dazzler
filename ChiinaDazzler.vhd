-- Copyright 2021, 2022 @ponzu840w GPLv3.0
-- 6502 Graphics Board @MAX-V CPLD
-- This VHDL source is the top level module.
library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

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
  signal flame_cnt_reg  : integer range 0 to 3;

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

  -- color mix test
  process(clk_in)
  begin
    if(clk_in'event and clk_in = '1')then

      -- reset
      if(reset_in = '0')then
        flame_cnt_reg <= 0;
      else

        hsync_out <= hsync;
        vsync_out <= vsync;

        if(vaddr = 767 and haddr = 255)then

          -- count up
          if(flame_cnt_reg = 3)then
            flame_cnt_reg <= 0;
          else
            flame_cnt_reg <= flame_cnt_reg+1;
          end if;
        end if;

        if(hblank = '1' and vblank = '1')then -- valid

          case vaddr is

            when 0 to 255 => -- line mix
              if(std_logic_vector(to_unsigned(vaddr,2)) = "00")then
                r_out <= '1';
                g_out <= '0';
                b_out <= '0';
              elsif(std_logic_vector(to_unsigned(vaddr,2)) = "01")then
                r_out <= '0';
                g_out <= '1';
                b_out <= '0';
              elsif(std_logic_vector(to_unsigned(vaddr,2)) = "10")then
                r_out <= '0';
                g_out <= '0';
                b_out <= '1';
              else
                r_out <= '1';
                g_out <= '1';
                b_out <= '1';
              end if;

            when 256 to 511 => -- time mix
              case flame_cnt_reg is
                when 0 =>
                  r_out <= '1';
                  g_out <= '0';
                  b_out <= '0';
                when 1 =>
                  r_out <= '0';
                  g_out <= '1';
                  b_out <= '0';
                when 2 =>
                  r_out <= '0';
                  g_out <= '0';
                  b_out <= '1';
                when 3 =>
                  r_out <= '1';
                  g_out <= '1';
                  b_out <= '1';
                when others =>
              end case;

            when others => -- double mix
              if(std_logic_vector(to_unsigned(vaddr+flame_cnt_reg,2)) = "00")then
                r_out <= '1';
                g_out <= '0';
                b_out <= '0';
              elsif(std_logic_vector(to_unsigned(vaddr+flame_cnt_reg,2)) = "01")then
                r_out <= '0';
                g_out <= '1';
                b_out <= '0';
              elsif(std_logic_vector(to_unsigned(vaddr+flame_cnt_reg,2)) = "10")then
                r_out <= '0';
                g_out <= '0';
                b_out <= '1';
              else
                r_out <= '1';
                g_out <= '1';
                b_out <= '1';
              end if;

          end case;

        else -- not valid
          r_out <= '0';
          g_out <= '0';
          b_out <= '0';
        end if;
      end if;
    end if;
  end process;

end RTL;

