-- Copyright 2022 @ponzu840w GPLv3.0
-- 4bit pallet to select from RGB444
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ColorPallet is
  port(
        clk_in  : in std_logic;
        we_in   : in std_logic;
        addr_in : in std_logic_vector(3 downto 0);
        data_in : in std_logic_vector(11 downto 0);
        data_out  : out std_logic_vector(11 downto 0)
  );
end ColorPallet;

architecture RTL of ColorPallet is
  type regfile_type is array (15 downto 0) of std_logic_vector(11 downto 0);
  signal regfile  : regfile_type;
begin
  process(clk_in)
  begin
    if(clk_in'event and clk_in = '1')then
      if(we_in = '1')then
        regfile(to_integer(unsigned(addr_in))) <= data_in;
      end if;
      data_out <= regfile(to_integer(unsigned(addr_in)));
    end if;
  end process;
end RTL;

