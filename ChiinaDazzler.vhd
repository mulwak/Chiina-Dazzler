-- Copyright (C) 2018  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details.

-- PROGRAM		"Quartus Prime"
-- VERSION		"Version 18.0.0 Build 614 04/24/2018 SJ Lite Edition"
-- CREATED		"Fri Dec 31 01:18:52 2021"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY ChiinaDazzler IS 
	PORT
	(
		CLK :  IN  STD_LOGIC;
		RESET :  IN  STD_LOGIC;
		HSync :  OUT  STD_LOGIC;
		VSync :  OUT  STD_LOGIC;
		G :  OUT  STD_LOGIC;
		R :  OUT  STD_LOGIC;
		B :  OUT  STD_LOGIC
	);
END ChiinaDazzler;

ARCHITECTURE bdf_type OF ChiinaDazzler IS 

COMPONENT videotiminggenerator
GENERIC (HWidth : INTEGER;
			VWidth : INTEGER
			);
	PORT(CLK : IN STD_LOGIC;
		 RESET : IN STD_LOGIC;
		 HOLFront : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		 HOLSync : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		 HOLTotal : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		 HOLValid : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		 VARFront : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		 VARSync : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		 VARSyncEnd : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		 VARSyncStart : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		 VARTotal : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		 VARValid : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		 HBlank : OUT STD_LOGIC;
		 VBlank : OUT STD_LOGIC;
		 HSync : OUT STD_LOGIC;
		 VSync : OUT STD_LOGIC;
		 H_Address_out : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		 V_Address_out : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
	);
END COMPONENT;

COMPONENT timingconst
	PORT(		 HOLFront : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		 HOLSync : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		 HOLTotal : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		 HOLValid : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		 VARFront : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		 VARSync : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		 VARSyncEnd : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		 VARSyncStart : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		 VARTotal : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		 VARValid : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
	);
END COMPONENT;

SIGNAL	SYNTHESIZED_WIRE_0 :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_1 :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_2 :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_3 :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_4 :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_5 :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_6 :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_7 :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_8 :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_9 :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_10 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_11 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_12 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_13 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_14 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_15 :  STD_LOGIC;


BEGIN 
R <= '0';
B <= '0';



b2v_inst : videotiminggenerator
GENERIC MAP(HWidth => 12,
			VWidth => 12
			)
PORT MAP(CLK => CLK,
		 RESET => RESET,
		 HOLFront => SYNTHESIZED_WIRE_0,
		 HOLSync => SYNTHESIZED_WIRE_1,
		 HOLTotal => SYNTHESIZED_WIRE_2,
		 HOLValid => SYNTHESIZED_WIRE_3,
		 VARFront => SYNTHESIZED_WIRE_4,
		 VARSync => SYNTHESIZED_WIRE_5,
		 VARSyncEnd => SYNTHESIZED_WIRE_6,
		 VARSyncStart => SYNTHESIZED_WIRE_7,
		 VARTotal => SYNTHESIZED_WIRE_8,
		 VARValid => SYNTHESIZED_WIRE_9,
		 HBlank => SYNTHESIZED_WIRE_10,
		 VBlank => SYNTHESIZED_WIRE_11,
		 HSync => SYNTHESIZED_WIRE_14,
		 VSync => SYNTHESIZED_WIRE_15);


b2v_inst1 : timingconst
PORT MAP(		 HOLFront => SYNTHESIZED_WIRE_0,
		 HOLSync => SYNTHESIZED_WIRE_1,
		 HOLTotal => SYNTHESIZED_WIRE_2,
		 HOLValid => SYNTHESIZED_WIRE_3,
		 VARFront => SYNTHESIZED_WIRE_4,
		 VARSync => SYNTHESIZED_WIRE_5,
		 VARSyncEnd => SYNTHESIZED_WIRE_6,
		 VARSyncStart => SYNTHESIZED_WIRE_7,
		 VARTotal => SYNTHESIZED_WIRE_8,
		 VARValid => SYNTHESIZED_WIRE_9);




SYNTHESIZED_WIRE_12 <= NOT(SYNTHESIZED_WIRE_10);



SYNTHESIZED_WIRE_13 <= NOT(SYNTHESIZED_WIRE_11);



G <= SYNTHESIZED_WIRE_12 AND SYNTHESIZED_WIRE_13;


HSync <= NOT(SYNTHESIZED_WIRE_14);



VSync <= NOT(SYNTHESIZED_WIRE_15);



END bdf_type;