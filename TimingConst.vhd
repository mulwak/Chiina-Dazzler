-- Copyright 2021, 2022 @ponzu840w GPLv3.0
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity timingconst is
  port (
  HOLTotal,VARTotal,HOLValid,VARValid,HOLFront,VARFront,HOLSync,VARSync,VARSyncStart,VARSyncEnd : out std_logic_vector(11 downto 0)
);
end timingconst;

architecture RTL of timingconst is
begin
  HOLTotal <= conv_std_logic_vector(336,12);
  VARTotal <= conv_std_logic_vector(806,12);
  HOLValid <= conv_std_logic_vector(256,12);
  VARValid <= conv_std_logic_vector(768,12);
  HOLFront <= conv_std_logic_vector(6,12);
  VARFront <= conv_std_logic_vector(3,12);
  HOLSync  <= conv_std_logic_vector(34,12);
  VARSync <= conv_std_logic_vector(6,12);
  VARSyncStart <= conv_std_logic_vector(0,12);
  VARSyncEnd <= conv_std_logic_vector(0,12);
end RTL;

