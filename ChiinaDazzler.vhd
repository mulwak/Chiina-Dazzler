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
    r_out : out std_logic_vector(3 downto 0);
    g_out : out std_logic_vector(3 downto 0);
    b_out : out std_logic_vector(3 downto 0);

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
          h_sync_out : out std_logic;
          v_sync_out : out std_logic;
          h_addr_out  : out integer range 0 to 511;
          v_addr_out  : out integer range 0 to 1023
        );
  end component;

  --crtc signals
  signal  hblank, vblank, hsync, vsync  :  std_logic;
  signal  haddr  : integer range 0 to 511;
  signal  vaddr  : integer range 0 to 1023;

  --tmp signals
  signal haddr_vec  : std_logic_vector(8 downto 0);
  signal vaddr_vec  : std_logic_vector(9 downto 0);
  signal hvblank : std_logic_vector(1 downto 0);

  signal  vram_scan_addr_sig  : std_logic_vector(16 downto 0);
  signal  state : std_logic_vector(1 downto 0);

  --config signals
  signal  UPDOWN_sig, RCSEC_sig : std_logic;
  signal  cursor_config : std_logic_vector(1 downto 0);

  --regs
  signal  data_buff_reg0 : std_logic_vector(7 downto 0); -- mpu strb
  signal  data_buff_reg1 : std_logic_vector(7 downto 0); -- CPLD clk
  signal  addr_buff_reg0 : std_logic_vector(2 downto 0);
  signal  addr_buff_reg1 : std_logic_vector(2 downto 0);
  signal  cmd_flag_reg0 : std_logic;
  signal  cmd_flag_reg1 : std_logic;
  signal  cmd_flag_reg2 : std_logic;

  signal  write_flag_reg  : std_logic;
  signal  nedge_write_flag_reg  : std_logic;

  signal  lut_que_reg0 : std_logic_vector(3 downto 0);
  signal  lut_que_reg1 : std_logic_vector(3 downto 0);
  signal  lut_que_reg2 : std_logic_vector(3 downto 0);
  signal  vram_writecursor_reg : std_logic_vector(16 downto 0);
  signal  read_frame_reg  : std_logic_vector(1 downto 0);
  signal  write_frame_reg  : std_logic_vector(1 downto 0);

  type regfile_type is array (0 to 15) of std_logic_vector(11 downto 0);
  signal color_pallet_regfile  : regfile_type;
  signal cp_outaddr_reg  : integer range 0 to 15;

  signal  we_vram_reg : std_logic;

  --regs (visible
  signal  WDBF_vreg : std_logic_vector(7 downto 0);

  signal rgb_sig  : std_logic_vector(11 downto 0);

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

  haddr_vec <= std_logic_vector(to_unsigned(haddr, haddr_vec'length));
  vaddr_vec <= std_logic_vector(to_unsigned(vaddr, vaddr_vec'length));
  state <= haddr_vec(1 downto 0);

  vram_scan_addr_sig(16 downto 15) <= read_frame_reg(1 downto 0);
  vram_scan_addr_sig(14 downto 7) <= vaddr_vec(9 downto 2);
  vram_scan_addr_sig(6 downto 1) <= haddr_vec(7 downto 2);
  vram_scan_addr_sig(0) <= haddr_vec(0);

  -- input mpu data
  process(strb_mpu_in,cs_mpu_in,reset_in)
  begin
    if(reset_in = '0')then -- async reset
      --data_buff_reg0 <= "00000000";
      --addr_buff_reg0 <= "000";
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

    -- negative edge
    if(clk_in'event and clk_in = '0')then
      if(reset_in = '0')then
      else
        if(nedge_write_flag_reg = '1')then
          data_vram_io <= WDBF_vreg;
          we_vram_reg <= '0';
        else
          data_vram_io <= "ZZZZZZZZ";
          we_vram_reg <= '1';
        end if;
      end if;
    end if;

    -- positive edge
    if(clk_in'event and clk_in = '1')then
      if(reset_in = '0')then
        --WDBF_vreg  <= "00000000";
        write_flag_reg <= '0';
        cmd_flag_reg1 <= '0';
        cmd_flag_reg2 <= '0';
        --data_buff_reg1 <= "00000000";
        --addr_buff_reg1 <= "000";
        --lut_que_reg0 <= "0000";
        --lut_que_reg1 <= "0000";
        --lut_que_reg2 <= "0000";
        --vram_writecursor_reg <= "00000000000000000";
        read_frame_reg <= "00";
        nedge_write_flag_reg <= '0';
        color_pallet_regfile(0) <= "000000000000";
        color_pallet_regfile(1) <= "111111111111";
        color_pallet_regfile(2) <= "111100000000";
        color_pallet_regfile(3) <= "000011110000";
        color_pallet_regfile(4) <= "000000001111";
        color_pallet_regfile(5) <= "111111110000";
        color_pallet_regfile(6) <= "000011111111";
        color_pallet_regfile(7) <= "111100001111";
        color_pallet_regfile(8) <= "000100010001";
        color_pallet_regfile(9) <= "100010001000";
        color_pallet_regfile(10) <= "100000000000";
        color_pallet_regfile(11) <= "000010000000";
        color_pallet_regfile(12) <= "000000001000";
        color_pallet_regfile(13) <= "100010000001";
        color_pallet_regfile(14) <= "000010001000";
        color_pallet_regfile(15) <= "100000001000";
      else -- not reset
        -- every clock jobs
        data_buff_reg1 <= data_buff_reg0;
        addr_buff_reg1 <= addr_buff_reg0;
        cmd_flag_reg1 <= cmd_flag_reg0;
        if(cmd_flag_reg0 = not cmd_flag_reg1)then
          cmd_flag_reg2 <= '1';
        end if;

        -- command processing
        if(cmd_flag_reg2 = '1')then
          cmd_flag_reg2 <= '0';
          case addr_buff_reg1 is
            -- CMD
            when "000" =>
              case data_buff_reg1 is
                -- cursor reset commandis
                when "00000000" =>
                  vram_writecursor_reg <= "00000000000000000";
                when "00000010" =>
                  vram_writecursor_reg <= std_logic_vector(unsigned(vram_writecursor_reg)+1);
                --when "00000011" =>
                  --vram_writecursor_reg <= std_logic_vector(unsigned(vram_writecursor_reg)+128);
                when others =>
              end case;
            -- CFG
            --when "001" =>
              --CFG_vreg <= data_buff_reg1;
            -- WDBF
            when "100" =>
              WDBF_vreg <= data_buff_reg1;
              write_flag_reg <= '1';
            when others =>
          end case;
        end if;

          case state is
            when "00" | "01" =>
              addr_vram_out <= std_logic_vector(unsigned(vram_scan_addr_sig));
              oe_vram_out <= '0'; -- out enable
            when others =>
              -- ???
          end case;

        case state is
          when "01" =>
            lut_que_reg0 <= data_vram_io(3 downto 0);
            -- load 2
            cp_outaddr_reg <= to_integer(unsigned(data_vram_io(7 downto 4)));
          when "10" =>
            lut_que_reg1 <= data_vram_io(7 downto 4);
            lut_que_reg2 <= data_vram_io(3 downto 0);

            cp_outaddr_reg <= to_integer(unsigned(lut_que_reg0));
              -- write 1
              addr_vram_out <= vram_writecursor_reg;

              if(write_flag_reg = '1')then
                nedge_write_flag_reg <= '1';
                --we_vram_out <= '0'; -- write enable
                write_flag_reg <= '0';
              end if;

              oe_vram_out <= '1'; -- out disable
          when "11" =>
            cp_outaddr_reg <= to_integer(unsigned(lut_que_reg1));
              --write 2
              nedge_write_flag_reg <= '0';

              --if(nedge_write_flag_reg = '1')then
                --vram_writecursor_reg <=
                 --std_logic_vector(unsigned(vram_writecursor_reg)+1);
               --end if;

              --we_vram_out <= '1'; -- write disable == write trig
          when "00" =>
            -- load 1
            cp_outaddr_reg <= to_integer(unsigned(lut_que_reg2));
          when others =>
        -- ???
        end case;

        case hvblank is
          when "11" =>
            rgb_sig <= color_pallet_regfile(cp_outaddr_reg);
          when others =>
            rgb_sig <= "000000000000";
        end case;

      end if;
    end if;
  end process;

  r_out <= rgb_sig(11 downto 8);
  g_out <= rgb_sig(7 downto 4);
  b_out <= rgb_sig(3 downto 0);

  hsync_out <= hsync;
  vsync_out <= vsync;

  hvblank <= hblank & vblank;

  we_vram_out <= we_vram_reg or clk_in;

end RTL;

