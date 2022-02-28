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
      r_out : out std_logic_vector(3 downto 0);
      g_out : out std_logic_vector(3 downto 0);
      b_out : out std_logic_vector(3 downto 0);

      strb_mpu_in : in std_logic;
      cs_mpu_in : in std_logic;
      data_mpu_in : in std_logic_vector(7 downto 0);
      addr_mpu_in : in std_logic_vector(2 downto 0);

    -- VRAM interface
      oe_vram_out : out std_logic;
      we_vram_out : out std_logic;
      data_vram_io : inout std_logic_vector(7 downto 0);
      addr_vram_out : out std_logic_vector(16 downto 0)
  );
  end component;

  signal T_CLK, T_RESET, T_HSync, T_VSync : std_logic;
  signal T_R, T_G, T_B : std_logic_vector(3 downto 0);
  signal T_STRB, T_CS : std_logic;
  signal T_DATA : std_logic_vector(7 downto 0);
  signal T_ADDR : std_logic_vector(2 downto 0);
  signal T_VRAMOE, T_VRAMWE : std_logic;
  signal T_VRAMDATA : std_logic_vector(7 downto 0);
  signal T_VRAMADDR : std_logic_vector(16 downto 0);

begin
  U02 : ChiinaDazzler
  port map(
            clk_in => T_CLK,
            reset_in => T_RESET,
            hsync_out => T_HSync,
            vsync_out => T_VSync,
            r_out => T_R,
            g_out => T_G,
            b_out => T_B,
            strb_mpu_in => T_STRB,
            cs_mpu_in => T_CS,
            data_mpu_in => T_DATA,
            addr_mpu_in => T_ADDR,
            oe_vram_out => T_VRAMOE,
            we_vram_out => T_VRAMWE,
            data_vram_io => T_VRAMDATA,
            addr_vram_out => T_VRAMADDR
          );
  process
  begin
    T_CLK <= '0'; wait for 31.25 ns; --16MHz clock
    T_CLK <= '1'; wait for 31.25 ns;
  end process;

  process(T_CLK)
  begin
    if(T_CLK'event and T_CLK = '1')then
      case T_VRAMDATA is
        when "LLLL"&"LLLH" =>
          T_VRAMDATA <= "LLHL"&"LLHH";
        when "LLHL"&"LLHH" =>
          T_VRAMDATA <= "LHLL"&"LHLH";
        when "LHLL"&"LHLH" =>
          T_VRAMDATA <= "LHHL"&"LHHH";
        when others =>
          T_VRAMDATA <= "LLLL"&"LLLH";
      end case;
    end if;
  end process;


  process
  begin
    T_CS <= '0';
    T_ADDR <= "000";
    wait for 10 ns;
    T_RESET <= '0'; wait for 200 ns;
    T_RESET <= '1'; wait for 25 ns;

    T_STRB <= '0'; wait for 500 ns;
    T_DATA <= "00000000"; wait for 250 ns;
    T_STRB <= '1'; wait for 500 ns;

    T_ADDR <= "001"; wait for 10 ns;
    T_STRB <= '0'; wait for 500 ns;
    T_DATA <= "00000001"; wait for 250 ns;
    T_STRB <= '1'; wait for 500 ns;

    T_ADDR <= "010"; wait for 10 ns;
    T_STRB <= '0'; wait for 500 ns;
    T_DATA <= "00000000"; wait for 250 ns;
    T_STRB <= '1'; wait for 500 ns;

    T_ADDR <= "011"; wait for 10 ns;
    T_STRB <= '0'; wait for 500 ns;
    T_DATA <= "00000000"; wait for 250 ns;
    T_STRB <= '1'; wait for 500 ns;

    T_ADDR <= "101"; wait for 10 ns;
    T_STRB <= '0'; wait for 500 ns;
    T_DATA <= "00011011"; wait for 250 ns;
    T_STRB <= '1'; wait for 500 ns;

    T_ADDR <= "110"; wait for 10 ns;
    T_STRB <= '0'; wait for 500 ns;
    T_DATA <= "00000011"; wait for 250 ns;
    T_STRB <= '1'; wait for 500 ns;

    T_ADDR <= "100";
    for T_I in 0 to 5000 loop
      wait for 100 ns;
      T_STRB <= '0'; wait for 500 ns;
      T_DATA <= "10101010"; wait for 250 ns;
      T_STRB <= '1'; wait for 500 ns;

      wait for 100 ns;
      T_STRB <= '0'; wait for 500 ns;
      T_DATA <= "10101011"; wait for 250 ns;
      T_STRB <= '1'; wait for 500 ns;

      wait for 100 ns;
      T_STRB <= '0'; wait for 500 ns;
      T_DATA <= "10101100"; wait for 250 ns;
      T_STRB <= '1'; wait for 500 ns;
    end loop;

    assert false
    report "Simulation Complete!"
    severity Failure;
  end process;
end SIM;

