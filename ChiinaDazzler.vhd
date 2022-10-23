--======================================================================
--======================================================================
--                          Chiina-Dazzler
--                  6502 Video Card @MarchXO2 FPGA
--======================================================================
-- This VHDL source is the top level module.
-- Copyright 2021, 2022 @ponzu840w GPLv3.0
--======================================================================
--======================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--======================================================================
-- I/O definition
--======================================================================
entity ChiinaDazzler is
  port
  (
    -- Board I/O
    clk_in :  in  std_logic;
    reset_in :  in  std_logic;
    hsync_out :  out  std_logic;
    vsync_out :  out  std_logic;
    r_out : out std_logic;
    g_out : out std_logic_vector(1 downto 0);
    b_out : out std_logic;

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

--======================================================================
-- Video timing counter compornent
--======================================================================
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

--======================================================================
-- Registers and signals
--======================================================================
--+-----------------------------------------------------------
-- Video timing signals
  signal  hblank, vblank, hsync, vsync  :  std_logic;
  signal  haddr  : integer range 0 to 511;
  signal  vaddr  : integer range 0 to 1023;

--+-----------------------------------------------------------
-- Video timing signals
  signal haddr_vec  : std_logic_vector(8 downto 0);
  signal vaddr_vec  : std_logic_vector(9 downto 0);
  signal hvblank    : std_logic_vector(1 downto 0);

--+-----------------------------------------------------------
-- Convinient aliases of video timing signals
  signal  state           : std_logic_vector(1 downto 0);
  signal  exstate         : std_logic_vector(2 downto 0);
  signal  line_state_sig  : std_logic_vector(1 downto 0);

--+-----------------------------------------------------------
-- Input buffer registors
--    +---------+-------------------------------------+
--    |data flow| [6502] -> #regS -> #reg0 -> #reg1   |
--    +---------+--------------------------+----------+
--    |sensitive|          6502 strb       | CPLD clk |
--    +---------+--------------------------+----------+
  -- 3bit Address
  signal  addr_buff_regS : std_logic_vector(2 downto 0); -- MPU strb
  signal  addr_buff_reg0 : std_logic_vector(2 downto 0); -- MPU strb
  signal  addr_buff_reg1 : std_logic_vector(2 downto 0); -- CPLD clk
  -- 8bit Data
  signal  data_buff_regs : std_logic_vector(7 downto 0);
  signal  data_buff_reg0 : std_logic_vector(7 downto 0);
  signal  data_buff_reg1 : std_logic_vector(7 downto 0);
  -- 1bit Command Flag
  signal  cmd_flag_regS : std_logic;  -- Value change (0->1, 1->0) is the signal,
  signal  cmd_flag_reg0 : std_logic;  --        means the existence of a command.
  signal  cmd_flag_reg1 : std_logic;
  signal  cmd_flag_reg2 : std_logic;  -- (reg1 != reg2) => cmd!

--+-----------------------------------------------------------
-- VRAM to VGA pipe
--    +------+----------------------------------------------------+-----+
--    | VRAM | -> lut_que -> [color_pallet_regfile] -> rgb_reg -> | VGA |
--    +------+----------------------------------------------------+-----+
  signal  lut_que_reg0  : std_logic_vector(3 downto 0);
  signal  lut_que_reg1  : std_logic_vector(3 downto 0);
  signal  lut_que_reg2  : std_logic_vector(3 downto 0);
  signal  rgb_reg       : std_logic_vector(3 downto 0);

--+-----------------------------------------------------------
-- VRAM reading address
  signal  vram_scan_addr_sig  : std_logic_vector(16 downto 0);
  signal  disp_frame_bf_reg   : std_logic_vector(7 downto 0); -- to suppress flicker
  type disp_frame_for_lines_type is array (0 to 3) of std_logic_vector(1 downto 0);
  signal  disp_frame_by_lines_reg   : disp_frame_for_lines_type; -- return frame by line

--+-----------------------------------------------------------
-- Frame-specific data
  signal charbox_width_reg   : integer range 0 to 127;
  signal charbox_height_reg  : integer range 0 to 255;
  signal frame_ttmode_flag_reg        : std_logic_vector(3 downto 0);

--+-----------------------------------------------------------
-- VRAM writing
  -- Sequencing control
  signal  write_flag_reg        : std_logic;
  signal  repeat_flag_regP        : std_logic;
  signal  repeat_flag_regS        : std_logic;
  signal  nedge_write_flag_reg  : std_logic;
  signal  we_vram_reg           : std_logic;
  -- Address
  signal  vram_writecursor_reg  : std_logic_vector(14 downto 0);
  signal  write_frame_reg       : std_logic_vector(1 downto 0);
  signal  write_frame_intc      : integer range 0 to 3;
  -- Data
  signal  WDBF_vreg             : std_logic_vector(7 downto 0);
  -- Countup control
  signal  charbox_disable_reg    : std_logic;
  signal  charbox_width_counter : integer range 0 to 255;
  signal  charbox_height_counter: integer range 0 to 255;
  signal  charbox_top_y    : std_logic_vector(7 downto 0);
  signal  charbox_next_x        : integer range 0 to 255;
  signal  charbox_base_x        : std_logic_vector(6 downto 0);

--+-----------------------------------------------------------
-- 16 or 2 colors
  signal  mode_sig            : std_logic;                    -- current mode
--+-----------------------------------------------------------
-- 2 colors
  signal  tt_shift_reg    : std_logic_vector(6 downto 0); -- shift register
  signal  tt_color_0_reg  : std_logic_vector(3 downto 0);
  signal  tt_color_1_reg  : std_logic_vector(3 downto 0);

--+-----------------------------------------------------------
-- 4bit data -> RGB121 color pallet
  signal cp_outaddr_reg         : integer range 0 to 15;  -- index

  signal findaddr : std_logic;

begin
--======================================================================
--                        Signal definition
--======================================================================
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

--+-----------------------------------------------------------
-- Video timings -> state
  -- Count by integer and separate by vector
  haddr_vec <= std_logic_vector(to_unsigned(haddr, haddr_vec'length));
  vaddr_vec <= std_logic_vector(to_unsigned(vaddr, vaddr_vec'length));
  -- State
  state           <= haddr_vec(1 downto 0); -- state for 16 colors mode
  exstate         <= haddr_vec(2 downto 0); -- state for 2 colors mode
  line_state_sig  <= vaddr_vec(1 downto 0);

  with addr_mpu_in select
    findaddr <= '1' when "001",
                '0' when others;

--+-----------------------------------------------------------
-- Cast signals
  write_frame_intc <= to_integer(unsigned(write_frame_reg));

--+-----------------------------------------------------------
-- Color mode of current line
  mode_sig <= frame_ttmode_flag_reg(to_integer(unsigned(disp_frame_by_lines_reg(to_integer(unsigned(line_state_sig))))));

--+-----------------------------------------------------------
-- VRAM scan address
  -- Which frame buffer?
  vram_scan_addr_sig(16 downto 15) <= disp_frame_by_lines_reg(to_integer(unsigned(line_state_sig)));

  -- Where in the buffer?
  with mode_sig select
    vram_scan_addr_sig(14 downto 0) <=
      vaddr_vec(9 downto 2)&haddr_vec(7 downto 2)&haddr_vec(0)  when '0',
      vaddr_vec(9 downto 2)&"00"&haddr_vec(7 downto 3)          when others;

--+-----------------------------------------------------------
-- Charbox signals
  -- next-x
  charbox_next_x <= to_integer(unsigned(vram_writecursor_reg(6 downto 0)))+1;

--======================================================================
--                         Receive MPU data
--======================================================================
  process(strb_mpu_in,reset_in,cs_mpu_in) -- MPU timing!
  begin
    if(reset_in = '0')then -- async reset
      cmd_flag_regS <= '0';
    elsif(strb_mpu_in'event and strb_mpu_in = '1' and cs_mpu_in = '0')then -- strb edge and cs
      data_buff_regS <= data_mpu_in;
      addr_buff_regS <= addr_mpu_in;
      cmd_flag_regS <= not cmd_flag_reg0;
    end if; -- end strb edge
  end process;

  process(findaddr,reset_in) -- MPU timing!
  begin
    if(reset_in = '0')then -- async reset
        repeat_flag_regP <= '0';
    elsif(cs_mpu_in = '0')then
      if(findaddr'event and findaddr = '1')then
        repeat_flag_regP <= not repeat_flag_regP;
      end if; -- end strb edge
    end if;
  end process;

  process(clk_in)
  begin

--======================================================================
--                    Negative edge VRAM writing
--======================================================================
    if(clk_in'event and clk_in = '0')then
      if(nedge_write_flag_reg = '1')then
        data_vram_io <= WDBF_vreg;    -- Write
        we_vram_reg <= '0';
      else
        data_vram_io <= "ZZZZZZZZ";   -- Don't write anything
        we_vram_reg <= '1';
      end if;
    end if;

    -- positive edge
    if(clk_in'event and clk_in = '1')then
--======================================================================
--                              Reset
--======================================================================
      if(reset_in = '0')then
        write_flag_reg <= '0';
        repeat_flag_regS <= '0';
        cmd_flag_reg1 <= '0';
        cmd_flag_reg2 <= '0';
        nedge_write_flag_reg <= '0';
--======================================================================
--                           Every clock
--======================================================================
      else -- not reset
        -- every clock jobs
        data_buff_reg0 <= data_buff_regS;
        addr_buff_reg0 <= addr_buff_regS;
        cmd_flag_reg0 <= cmd_flag_regS;
        data_buff_reg1 <= data_buff_reg0;
        addr_buff_reg1 <= addr_buff_reg0;
        cmd_flag_reg1 <= cmd_flag_reg0;
        if(cmd_flag_reg0 = not cmd_flag_reg1)then
          cmd_flag_reg2 <= '1';
        end if;

--======================================================================
--                      MPU Command Processing
--======================================================================
        if(cmd_flag_reg2 = '1')then
          cmd_flag_reg2 <= '0';
          case addr_buff_reg1 is
--+-----------------------------------------------------------
-- CONF: ConFiG
            when "000" =>
              --   +-----------------+
              --   |  Command  Data  |
              -- +-+--------+--------+-+
              -- |7|  addr  |  data  |0|
              -- +-+--------+--------+-+
              case data_buff_reg1(7 downto 4) is
                when "0000" =>  -- WF write-frame 2bit
                  write_frame_reg <= data_buff_reg1(1 downto 0);
                when "0001" =>  -- TT frame-ttmode 1bit
                  frame_ttmode_flag_reg(write_frame_intc) <= data_buff_reg1(0); -- 105%
                  --frame_ttmode_flag_reg <= data_buff_reg1(3 downto 0);        -- 109%
                when "0010" =>  -- T0
                  tt_color_0_reg <= data_buff_reg1(3 downto 0);
                when "0011" =>  -- T1
                  tt_color_1_reg <= data_buff_reg1(3 downto 0);
                when others =>
              end case;
--+-----------------------------------------------------------
-- REPT: REPeat
            when "001" =>
--+-----------------------------------------------------------
-- PTRX: VraM Adress Horizonal
            when "010" =>
              -- reset counter
              charbox_width_counter <= 0;
              charbox_base_x <= std_logic_vector(to_unsigned(charbox_next_x,7));
              vram_writecursor_reg(6 downto 0) <= data_buff_reg1(6 downto 0);
--+-----------------------------------------------------------
-- PTRY: VraM Adress Vertical
            when "011" =>
              -- reset counter
              charbox_height_counter <= 0;
              charbox_top_y    <= data_buff_reg1(7 downto 0);
              vram_writecursor_reg(14 downto 7) <= data_buff_reg1;
--+-----------------------------------------------------------
-- WDAT: Write Data BuFfer
            when "100" =>
              WDBF_vreg <= data_buff_reg1;
              write_flag_reg <= '1';
--+-----------------------------------------------------------
-- DISP: DISPlay frame
            when "101" =>
              disp_frame_bf_reg <= data_buff_reg1;
--+-----------------------------------------------------------
-- CHRW: CHARbox Width
            when "110" =>
              charbox_disable_reg <= data_buff_reg1(7);
              charbox_width_reg <= to_integer(unsigned(data_buff_reg1(6 downto 0)));
--+-----------------------------------------------------------
-- CHRH: CHARbox Height
            when "111" =>
              charbox_height_reg <= to_integer(unsigned(data_buff_reg1));
            when others =>
          end case;
        end if;

--======================================================================
--                        Data flow by state
--======================================================================
--+-----------------------------------------------------------
-- 4 cycle states independent of color mode
        case state is
          when "00" | "01" =>
              -- read
            addr_vram_out <= std_logic_vector(unsigned(vram_scan_addr_sig));
            oe_vram_out <= '0'; -- out enable
          when "10" =>
              -- write 1
            addr_vram_out <= write_frame_reg & vram_writecursor_reg;

            if(write_flag_reg = '1' or repeat_flag_regP = not repeat_flag_regS)then
              nedge_write_flag_reg <= '1';
              write_flag_reg <= '0';
              repeat_flag_regS <= repeat_flag_regP;
            end if;

            oe_vram_out <= '1'; -- out disable
          when "11" =>
              --write 2
            nedge_write_flag_reg <= '0';

--+-----------------------------------------------------------
-- Count-Up
            if(nedge_write_flag_reg = '1')then
              --+-----------------------------------------------------------
              -- Over Right
              if(charbox_width_counter = charbox_width_reg and charbox_disable_reg = '1')then
                charbox_width_counter <= 0;        -- width counter reset
                  --+-----------------------------------------------------------
                  -- Over Bottom-Right
                if(charbox_height_counter = charbox_height_reg)then  -- over bottom-right
                  vram_writecursor_reg(14 downto 7) <= charbox_top_y;
                  vram_writecursor_reg(6 downto 0) <= std_logic_vector(to_unsigned(charbox_next_x,7));
                  charbox_base_x <= std_logic_vector(to_unsigned(charbox_next_x,7));
                  charbox_height_counter <= 0;
                  --+-----------------------------------------------------------
                  -- Over Right but Bottom
                else                                -- over rignt but bottom
                  vram_writecursor_reg(14 downto 7) <= std_logic_vector(unsigned(vram_writecursor_reg(14 downto 7))+1);
                  vram_writecursor_reg(6 downto 0) <= charbox_base_x;
                  charbox_height_counter <= charbox_height_counter+1;
                end if; -- /bottom right
              --+-----------------------------------------------------------
              -- No Over
              else
                -- right next
                vram_writecursor_reg <= std_logic_vector(unsigned(vram_writecursor_reg)+1);
                charbox_width_counter <= charbox_width_counter+1;
              end if;   -- /right
           end if;
          when others =>
        end case;

--+-----------------------------------------------------------
-- 4 cycle states of 16 color mode
        -- read and output
        if( mode_sig = '0' )then  -- 16 colors mode
          case state is
            when "01" =>
              lut_que_reg0 <= data_vram_io(3 downto 0);
              -- load 2
              cp_outaddr_reg <=
                   to_integer(unsigned(data_vram_io(7 downto 4)));
            when "10" =>
              lut_que_reg1 <= data_vram_io(7 downto 4);
              lut_que_reg2 <= data_vram_io(3 downto 0);

              cp_outaddr_reg <= to_integer(unsigned(lut_que_reg0));
            when "11" =>
              cp_outaddr_reg <= to_integer(unsigned(lut_que_reg1));
            when "00" =>
              -- load 1
              cp_outaddr_reg <= to_integer(unsigned(lut_que_reg2));
            when others =>
          end case;
--+-----------------------------------------------------------
-- 8 cycle states of 2 color mode
        else  -- 2 colors mode
          case exstate is
            when "001" =>
              tt_shift_reg <= data_vram_io(6 downto 0);
              case data_vram_io(7) is
                when '0'|'L' =>
                  cp_outaddr_reg <= to_integer(unsigned(tt_color_0_reg));
                when others =>
                  cp_outaddr_reg <= to_integer(unsigned(tt_color_1_reg));
              end case;
            when others =>
              tt_shift_reg <= tt_shift_reg(5 downto 0) & 'X';
              case tt_shift_reg(6) is
                when '0'|'L' =>
                  cp_outaddr_reg <= to_integer(unsigned(tt_color_0_reg));
                when others =>
                  cp_outaddr_reg <= to_integer(unsigned(tt_color_1_reg));
              end case;
          end case;
        end if;

--+-----------------------------------------------------------
-- Switch display frame in vblank
--  While suppressing flicker
        case vblank is
          when '0' =>
            disp_frame_by_lines_reg(0) <= disp_frame_bf_reg(7 downto 6);
            disp_frame_by_lines_reg(1) <= disp_frame_bf_reg(5 downto 4);
            disp_frame_by_lines_reg(2) <= disp_frame_bf_reg(3 downto 2);
            disp_frame_by_lines_reg(3) <= disp_frame_bf_reg(1 downto 0);
          when others =>
        end case;

--+-----------------------------------------------------------
-- Reflect in the output except for the blank
        if( hvblank = "11" )then
          case cp_outaddr_reg is
            when 0  => rgb_reg <= "0000";
            when 1  => rgb_reg <= "0010";
            when 2  => rgb_reg <= "0100";
            when 3  => rgb_reg <= "0110";
            when 4  => rgb_reg <= "0001";
            when 5  => rgb_reg <= "0011";
            when 6  => rgb_reg <= "0101";
            when 7  => rgb_reg <= "0111";
            when 8  => rgb_reg <= "1000";
            when 9  => rgb_reg <= "1010";
            when 10 => rgb_reg <= "1100";
            when 11 => rgb_reg <= "1110";
            when 12 => rgb_reg <= "1001";
            when 13 => rgb_reg <= "1011";
            when 14 => rgb_reg <= "1101";
            when 15 => rgb_reg <= "1111";
            when others =>
          end case;
        else
          rgb_reg <= "0000";
        end if;

      end if;
    end if;
  end process;

  hsync_out <= hsync;
  vsync_out <= vsync;

  hvblank <= hblank & vblank;

  r_out <= rgb_reg(3);
  g_out <= rgb_reg(2 downto 1);
  b_out <= rgb_reg(0);

  we_vram_out <= we_vram_reg or clk_in;

end RTL;

