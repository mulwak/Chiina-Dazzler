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
    b_out :  out  std_logic;

    strb_mpu_in : in std_logic;
    cs_mpu_in : in std_logic;
    data_mpu_in : in std_logic_vector(7 downto 0);
    addr_mpu_in : in std_logic_vector(2 downto 0)
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

  component testram is
    port(
          address: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
          data    : IN STD_LOGIC_VECTOR (11 DOWNTO 0);
          we    : IN STD_LOGIC  := '1';
          q    : OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
        );
  end component;

  signal  hblank, vblank, hsync, vsync  :  std_logic;
  signal  haddr  : integer range 0 to 511;
  signal  vaddr  : integer range 0 to 1023;

  signal  data_buff_reg0 : std_logic_vector(7 downto 0); -- mpu strb
  signal  data_buff_reg1 : std_logic_vector(7 downto 0); -- CPLD clk
  signal  mpu_test_reg  : std_logic_vector(7 downto 0);

  signal  ram_address    : STD_LOGIC_VECTOR (3 DOWNTO 0);
  signal  ram_data    : STD_LOGIC_VECTOR (11 DOWNTO 0);
  signal  ram_we    : STD_LOGIC  ;
  signal  ram_q    : STD_LOGIC_VECTOR (11 DOWNTO 0);

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

  U02 : testram
  port map(
            address => ram_address,
            data => ram_data,
            we => ram_we,
            q => ram_q
          );

  -- input mpu data
  process(strb_mpu_in,cs_mpu_in,reset_in)
  begin
    if(reset_in = '0')then -- async reset
      data_buff_reg0 <= "00000000";
    elsif(strb_mpu_in'event and strb_mpu_in = '1' and cs_mpu_in = '0')then -- strb edge and cs
      if(reset_in = '1')then
        data_buff_reg0 <= data_mpu_in;
      end if;
    end if; -- end strb edge
  end process;

  -- edge test
  process(clk_in)
  begin
    if(clk_in'event and clk_in = '1')then
      if(reset_in = '0')then
        mpu_test_reg <= "00000000";
        --data_buff_reg0 <= "00000000";
        data_buff_reg1 <= "00000000";
      else -- not reset
        data_buff_reg1 <= data_buff_reg0;
        mpu_test_reg <= data_buff_reg1;
        hsync_out <= hsync;
        vsync_out <= vsync;
        if(hblank = '1' and vblank = '1')then -- valid
          g_out <= '1';
          b_out <= '1';

          case haddr is
            when 0 to 31 =>
              r_out <= mpu_test_reg(7);
            when 32 to 63 =>
              r_out <= mpu_test_reg(6);
            when 64 to 95 =>
              r_out <= mpu_test_reg(5);
            when 96 to 127 =>
              r_out <= mpu_test_reg(4);
            when 128 to 159 =>
              r_out <= mpu_test_reg(3);
            when 160 to 191 =>
              r_out <= mpu_test_reg(2);
            when 192 to 223 =>
              r_out <= mpu_test_reg(1);
            when 224 to 255 =>
              r_out <= mpu_test_reg(0);
            when others =>
              r_out <= '0';
          end case; -- end about haddr
        else -- not valid
          r_out <= '0';
          g_out <= '0';
          b_out <= '0';
        end if;
      end if;
    end if;
  end process;

end RTL;

