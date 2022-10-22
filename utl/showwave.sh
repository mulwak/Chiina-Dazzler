#! /bin/bash

echo "Analyse"

ghdl -a -fsynopsys VideoTimingGen.vhd
ghdl -a -fsynopsys ChiinaDazzler.vhd
ghdl -a -fsynopsys ChiinaDazzler_TB.vhd

echo "Elaborate"

ghdl -e -fsynopsys VideoTimingGen
ghdl -e -fsynopsys ChiinaDazzler
ghdl -e -fsynopsys ChiinaDazzler_TB

echo "Run"

ghdl -r -fsynopsys ChiinaDazzler_TB --vcd=tmpwave.vcd --ieee-asserts=disable

gtkwave ./tmpwave.vcd

