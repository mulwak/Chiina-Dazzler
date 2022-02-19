-- Copyright 2021, 2022 @ponzu840w GPLv3.0
-- 6502 Graphics Board @MAX-V CPLD
-- This VHDL source is the top level module.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ChiinaDazzler is
  port
  (
    -- Board I/O
    clk_in :  in  std_logic;
    reset_in :  in  std_logic;
    hsync_out :  out  std_logic;
    vsync_out :  out  std_logic;
    r_out :  out  std_logic;
    g_out :  out  std_logic;
    b_out :  out  std_logic;

    -- MPU interface
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
end ChiinaDazzler;

architecture RTL of ChiinaDazzler is

  component VideoTimingGen
    port(
          clk_in : in std_logic;
          reset_in : in std_logic;
          h_blank_out : out std_logic;
          v_blank_out : out std_logic;
          h_earlyblank_out, v_earlyblank_out  : out std_logic;
          h_sync_out : out std_logic;
          v_sync_out : out std_logic;
          h_addr_out  : out integer range 0 to 511;
          v_addr_out  : out integer range 0 to 1023
        );
  end component;

  component testram is
    port(
          address : in std_logic_vector(3 downto 0);
          data  : in std_logic_vector(11 downto 0);
          we  : in std_logic := '1';
          q : out std_logic_vector(11 downto 0)
    );
  end component;

  --crtc signals
  signal  heblank, hblank, veblank, vblank, hsync, vsync  :  std_logic;
  signal  haddr  : integer range 0 to 511;
  signal  vaddr  : integer range 0 to 1023;

  --tmp signals
  signal haddr_vec  : std_logic_vector(8 downto 0);
  signal vaddr_vec  : std_logic_vector(9 downto 0);

  signal  vram_scan_addr  : std_logic_vector(16 downto 0);
  signal  state : std_logic_vector(1 downto 0);

  --colorpallet signals
  signal  cp_addr : std_logic_vector(3 downto 0);
  signal  cp_data, cp_q : std_logic_vector(11 downto 0);
  signal  cp_we : std_logic;

  --regs
  signal  data_buff_reg0 : std_logic_vector(7 downto 0); -- mpu strb
  signal  data_buff_reg1 : std_logic_vector(7 downto 0); -- CPLD clk
  signal  addr_buff_reg0 : std_logic_vector(2 downto 0);
  signal  addr_buff_reg1 : std_logic_vector(2 downto 0);
  signal  cmd_flag_reg0 : std_logic;
  signal  cmd_flag_reg1 : std_logic;
  signal  cmd_flag_reg2 : std_logic;

  signal  write_data_reg  : std_logic_vector(7 downto 0);
  signal  write_flag_reg  : std_logic;

  signal  color_lut_test_reg : std_logic_vector(3 downto 0);
  signal  lut_que_reg0 : std_logic_vector(3 downto 0);
  signal  lut_que_reg1 : std_logic_vector(3 downto 0);
  signal  lut_que_reg2 : std_logic_vector(3 downto 0);
  signal  vram_writecursor_reg : std_logic_vector(16 downto 0);
  signal  read_frame_reg  : std_logic_vector(1 downto 0);

  signal  nedge_write_flag_reg  : std_logic;
  signal  nedge_data_reg  : std_logic_vector(7 downto 0);

begin
  U01 : VideoTimingGen
  port map(clk_in => clk_in,
           reset_in => reset_in,
           h_blank_out => hblank,
           v_blank_out => vblank,
           h_earlyblank_out => heblank,
           v_earlyblank_out => veblank,
           h_sync_out => hsync,
           v_sync_out => vsync,
           h_addr_out => haddr,
           v_addr_out => vaddr
         );

  U02 : testram
  port map( address => cp_addr,
            data => cp_data,
            we => cp_we,
            q => cp_q
          );

  haddr_vec <= std_logic_vector(to_unsigned(haddr, haddr_vec'length));
  vaddr_vec <= std_logic_vector(to_unsigned(vaddr, vaddr_vec'length));
  state <= haddr_vec(1 downto 0);

  vram_scan_addr(16 downto 15) <= read_frame_reg(1 downto 0);
  vram_scan_addr(14 downto 7) <= vaddr_vec(7 downto 0);
  vram_scan_addr(6 downto 1) <= haddr_vec(7 downto 2);
  vram_scan_addr(0) <= haddr_vec(0);

  -- input mpu data
  process(strb_mpu_in,cs_mpu_in,reset_in)
  begin
    if(reset_in = '0')then -- async reset
      data_buff_reg0 <= "00000000";
      addr_buff_reg0 <= "000";
      cmd_flag_reg0 <= '0';
    elsif(strb_mpu_in'event and strb_mpu_in = '1' and cs_mpu_in = '0')then -- strb edge and cs
      if(reset_in = '1')then
        data_buff_reg0 <= data_mpu_in;
        addr_buff_reg0 <= addr_mpu_in;
        cmd_flag_reg0 <= not cmd_flag_reg0;
      end if;
    end if; -- end strb edge
  end process;

  process(clk_in)
  begin

    if(clk_in'event and clk_in = '0')then -- banned negative edge!
      if(reset_in = '0')then
      else
        if(nedge_write_flag_reg = '1')then
          data_vram_io <= write_data_reg;
        else
          data_vram_io <= "ZZZZZZZZ";
        end if;
      end if;
    end if;

    if(clk_in'event and clk_in = '1')then
      if(reset_in = '0')then
        write_data_reg  <= "00000000";
        write_flag_reg <= '0';
        cmd_flag_reg1 <= '0';
        cmd_flag_reg2 <= '0';
        data_buff_reg1 <= "00000000";
        addr_buff_reg1 <= "000";
        color_lut_test_reg <= "0000";
        lut_que_reg0 <= "0000";
        lut_que_reg1 <= "0000";
        lut_que_reg2 <= "0000";
        vram_writecursor_reg <= "00000000000000000";
        read_frame_reg <= "00";
        nedge_write_flag_reg <= '0';
        cp_we <= '1';
      else -- not reset
        -- every clock jobs
        data_buff_reg1 <= data_buff_reg0;
        addr_buff_reg1 <= addr_buff_reg0;
        cmd_flag_reg1 <= cmd_flag_reg0;
        if(cmd_flag_reg0 = not cmd_flag_reg1)then
          cmd_flag_reg2 <= '1';
        end if;
        hsync_out <= hsync;
        vsync_out <= vsync;

        -- command processing
        if(cmd_flag_reg2 = '1')then
          cmd_flag_reg2 <= '0';
          case addr_buff_reg1 is
            when "000" =>
              write_data_reg <= data_buff_reg1;
              write_flag_reg <= '1';
              vram_writecursor_reg <= std_logic_vector(unsigned(vram_writecursor_reg)+1);
            when others =>
          end case;
        end if;


        if(heblank = '1' and veblank = '1')then -- valid address
          case state is
            when "00" =>
              --color_lut_test_reg <= data_vram_io(7 downto 4);
              cp_addr <= data_vram_io(7 downto 4);
              lut_que_reg0 <= data_vram_io(3 downto 0);

              addr_vram_out <= vram_scan_addr;
              --data_vram_io <= "ZZZZZZZZ";
            when "01" =>
              cp_addr <= lut_que_reg0;
              lut_que_reg1 <= data_vram_io(7 downto 4);
              lut_que_reg2 <= data_vram_io(3 downto 0);

              addr_vram_out <= vram_writecursor_reg;

              if(write_flag_reg = '1')then
                nedge_write_flag_reg <= '1';
                we_vram_out <= '0'; -- write enable
                write_flag_reg <= '0';
              end if;

              oe_vram_out <= '1'; -- out disable
            when "10" =>
              cp_addr <= lut_que_reg1;

              --data_vram_io <= write_data_reg;
              nedge_write_flag_reg <= '0';

              we_vram_out <= '1'; -- write disable == write trig
            when "11" =>
              --color_lut_test_reg <= lut_que_reg2;

              addr_vram_out <= vram_scan_addr;
              --data_vram_io <= "ZZZZZZZZ";
              oe_vram_out <= '0'; -- out enable
            when others =>
              -- ???
          end case;
        end if;

        if(hblank = '1' and vblank = '1')then -- valid timing
          case state is
            when "11" =>
              cp_addr <= lut_que_reg2;
            when others =>
              -- ???
          end case;
          r_out <= cp_q(2);
          g_out <= cp_q(1);
          b_out <= cp_q(0);
        else -- not valid
          r_out <= '0';
          g_out <= '0';
          b_out <= '0';
        end if;

      end if;
    end if;
  end process;

end RTL;

