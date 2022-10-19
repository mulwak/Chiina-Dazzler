#! /bin/bash

echo "Analyse"

ghdl -a -fsynopsys VideoTimingGen.vhd
ghdl -a -fsynopsys VideoTimingGen_TB.vhd

echo "Elaborate"

ghdl -e -fsynopsys VideoTimingGen
ghdl -e -fsynopsys VideoTimingGen_TB

echo "Run"

ghdl -r -fsynopsys VideoTimingGen_TB --vcd=tmpwave.vcd

