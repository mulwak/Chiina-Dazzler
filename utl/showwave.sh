#! /bin/bash

echo "M4 macro"
m4 ChiinaDazzler_TB.vhd > tmptb.vhd

echo "Analyse"

ghdl -a -fsynopsys VideoTimingGen.vhd
ghdl -a -fsynopsys ChiinaDazzler.vhd
ghdl -a -fsynopsys tmptb.vhd

echo "Elaborate"

ghdl -e -fsynopsys VideoTimingGen
ghdl -e -fsynopsys ChiinaDazzler
ghdl -e -fsynopsys ChiinaDazzler_TB

echo "Run"

ghdl -r -fsynopsys ChiinaDazzler_TB --wave=tmpwave.ghw --ieee-asserts=disable

gtkwave ./tmpwave.ghw

