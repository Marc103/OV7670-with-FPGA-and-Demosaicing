## This file is a general .xdc for the Basys3 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
 
# Switches
set_property PACKAGE_PIN V17 [get_ports {switches_PIN[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[0]}]
set_property PACKAGE_PIN V16 [get_ports {switches_PIN[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[1]}]
set_property PACKAGE_PIN W16 [get_ports {switches_PIN[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[2]}]
set_property PACKAGE_PIN W17 [get_ports {switches_PIN[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[3]}]
set_property PACKAGE_PIN W15 [get_ports {switches_PIN[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[4]}]
set_property PACKAGE_PIN V15 [get_ports {switches_PIN[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[5]}]
set_property PACKAGE_PIN W14 [get_ports {switches_PIN[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[6]}]
set_property PACKAGE_PIN W13 [get_ports {switches_PIN[7]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[7]}]
#set_property PACKAGE_PIN V2 [get_ports {switches_PIN[8]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[8]}]
#set_property PACKAGE_PIN T3 [get_ports {switches_PIN[9]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[9]}]
#set_property PACKAGE_PIN T2 [get_ports {switches_PIN[10]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[10]}]
#set_property PACKAGE_PIN R3 [get_ports {switches_PIN[11]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[11]}]
#set_property PACKAGE_PIN W2 [get_ports {switches_PIN[12]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[12]}]
#set_property PACKAGE_PIN U1 [get_ports {switches_PIN[13]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[13]}]
#set_property PACKAGE_PIN T1 [get_ports {switches_PIN[14]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[14]}]
#set_property PACKAGE_PIN R2 [get_ports {switches_PIN[15]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {switches_PIN[15]}]
 

# LEDs
set_property PACKAGE_PIN U16 [get_ports {LED[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
set_property PACKAGE_PIN E19 [get_ports {LED[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]
set_property PACKAGE_PIN U19 [get_ports {LED[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]
set_property PACKAGE_PIN V19 [get_ports {LED[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]
set_property PACKAGE_PIN W18 [get_ports {LED[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]
set_property PACKAGE_PIN U15 [get_ports {LED[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]
set_property PACKAGE_PIN U14 [get_ports {LED[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]
set_property PACKAGE_PIN V14 [get_ports {LED[7]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]
set_property PACKAGE_PIN V13 [get_ports {LED[8]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[8]}]
set_property PACKAGE_PIN V3 [get_ports {LED[9]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[9]}]
set_property PACKAGE_PIN W3 [get_ports {LED[10]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[10]}]
set_property PACKAGE_PIN U3 [get_ports {LED[11]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[11]}]
set_property PACKAGE_PIN P3 [get_ports {LED[12]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[12]}]
set_property PACKAGE_PIN N3 [get_ports {LED[13]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[13]}]
set_property PACKAGE_PIN P1 [get_ports {LED[14]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[14]}]
set_property PACKAGE_PIN L1 [get_ports {LED[15]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {LED[15]}]
	
	
#7 segment display
set_property PACKAGE_PIN W7 [get_ports CA_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports CA_PIN]
set_property PACKAGE_PIN W6 [get_ports CB_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports CB_PIN]
set_property PACKAGE_PIN U8 [get_ports CC_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports CC_PIN]
set_property PACKAGE_PIN V8 [get_ports CD_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports CD_PIN]
set_property PACKAGE_PIN U5 [get_ports CE_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports CE_PIN]
set_property PACKAGE_PIN V5 [get_ports CF_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports CF_PIN]
set_property PACKAGE_PIN U7 [get_ports CG_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports CG_PIN]

set_property PACKAGE_PIN V7 [get_ports DP_PIN]							
	set_property IOSTANDARD LVCMOS33 [get_ports DP_PIN]

set_property PACKAGE_PIN U2 [get_ports AN0_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports AN0_PIN]
set_property PACKAGE_PIN U4 [get_ports AN1_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports AN1_PIN]
set_property PACKAGE_PIN V4 [get_ports AN2_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports AN2_PIN]
set_property PACKAGE_PIN W4 [get_ports AN3_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports AN3_PIN]


##Buttons
set_property PACKAGE_PIN U18 [get_ports c_btn_PIN]						
	set_property IOSTANDARD LVCMOS33 [get_ports c_btn_PIN]
set_property PACKAGE_PIN T18 [get_ports u_btn_PIN]						
	set_property IOSTANDARD LVCMOS33 [get_ports u_btn_PIN]
set_property PACKAGE_PIN W19 [get_ports l_btn_PIN]						
	set_property IOSTANDARD LVCMOS33 [get_ports l_btn_PIN]
set_property PACKAGE_PIN T17 [get_ports r_btn_PIN]						
	set_property IOSTANDARD LVCMOS33 [get_ports r_btn_PIN]
set_property PACKAGE_PIN U17 [get_ports d_btn_PIN]						
	set_property IOSTANDARD LVCMOS33 [get_ports d_btn_PIN]
 


##Pmod Header JA
##Sch name = JA1
#set_property PACKAGE_PIN J1 [get_ports {JA[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[0]}]
##Sch name = JA2
#set_property PACKAGE_PIN L2 [get_ports {JA[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[1]}]
##Sch name = JA3
#set_property PACKAGE_PIN J2 [get_ports {JA[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[2]}]
##Sch name = JA4
#set_property PACKAGE_PIN G2 [get_ports {JA[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[3]}]
##Sch name = JA7
#set_property PACKAGE_PIN H1 [get_ports {JA[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[4]}]
##Sch name = JA8
#set_property PACKAGE_PIN K2 [get_ports {JA[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[5]}]
##Sch name = JA9
#set_property PACKAGE_PIN H2 [get_ports {JA[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[6]}]
##Sch name = JA10
#set_property PACKAGE_PIN G3 [get_ports {JA[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[7]}]



##Pmod Header JB
##Sch name = JB1
set_property PACKAGE_PIN A14 [get_ports SCL_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports SCL_PIN]
##Sch name = JB2
set_property PACKAGE_PIN A16 [get_ports VSYNC_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports VSYNC_PIN]
##Sch name = JB3
set_property PACKAGE_PIN B15 [get_ports PCLK_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports PCLK_PIN]
	set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {PCLK_PIN_IBUF}]
##Sch name = JB4
set_property PACKAGE_PIN B16 [get_ports {D_PIN[7]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {D_PIN[7]}]
##Sch name = JB7
set_property PACKAGE_PIN A15 [get_ports SDA_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports SDA_PIN]
##Sch name = JB8
set_property PACKAGE_PIN A17 [get_ports HREF_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports HREF_PIN]
##Sch name = JB9
set_property PACKAGE_PIN C15 [get_ports MCLK]					
	set_property IOSTANDARD LVCMOS33 [get_ports MCLK]
##Sch name = JB10 
set_property PACKAGE_PIN C16 [get_ports {D_PIN[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {D_PIN[6]}]
 


##Pmod Header JC
##Sch name = JC1
set_property PACKAGE_PIN K17 [get_ports {D_PIN[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {D_PIN[5]}]
##Sch name = JC2
set_property PACKAGE_PIN M18 [get_ports {D_PIN[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {D_PIN[3]}]
##Sch name = JC3
set_property PACKAGE_PIN N17 [get_ports {D_PIN[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {D_PIN[1]}]
##Sch name = JC4
set_property PACKAGE_PIN P18 [get_ports RST_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports RST_PIN]
##Sch name = JC7
set_property PACKAGE_PIN L17 [get_ports {D_PIN[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {D_PIN[4]}]
##Sch name = JC8
set_property PACKAGE_PIN M19 [get_ports {D_PIN[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {D_PIN[2]}]
##Sch name = JC9
set_property PACKAGE_PIN P17 [get_ports {D_PIN[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {D_PIN[0]}]
##Sch name = JC10
set_property PACKAGE_PIN R18 [get_ports PWDN_PIN]					
	set_property IOSTANDARD LVCMOS33 [get_ports PWDN_PIN]


#Pmod Header JXADC
#Sch name = XA1_P
#set_property PACKAGE_PIN J3 [get_ports {vauxp6}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxp6}]
#Sch name = XA2_P
#set_property PACKAGE_PIN L3 [get_ports {vauxp14}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxp14}]
#Sch name = XA3_P
#set_property PACKAGE_PIN M2 [get_ports {vauxp7}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxp7}]
#Sch name = XA4_P
#set_property PACKAGE_PIN N2 [get_ports {vauxp15}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxp15}]
#Sch name = XA1_N
#set_property PACKAGE_PIN K3 [get_ports {vauxn6}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxn6}]
#Sch name = XA2_N
#set_property PACKAGE_PIN M3 [get_ports {vauxn14}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxn14}]
#Sch name = XA3_N
#set_property PACKAGE_PIN M1 [get_ports {vauxn7}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxn7}]
#Sch name = XA4_N
#set_property PACKAGE_PIN N1 [get_ports {vauxn15}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxn15}]



##VGA Connector
set_property PACKAGE_PIN G19 [get_ports {VGA_R_PIN[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R_PIN[0]}]
set_property PACKAGE_PIN H19 [get_ports {VGA_R_PIN[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R_PIN[1]}]
set_property PACKAGE_PIN J19 [get_ports {VGA_R_PIN[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R_PIN[2]}]
set_property PACKAGE_PIN N19 [get_ports {VGA_R_PIN[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R_PIN[3]}]
set_property PACKAGE_PIN N18 [get_ports {VGA_B_PIN[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B_PIN[0]}]
set_property PACKAGE_PIN L18 [get_ports {VGA_B_PIN[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B_PIN[1]}]
set_property PACKAGE_PIN K18 [get_ports {VGA_B_PIN[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B_PIN[2]}]
set_property PACKAGE_PIN J18 [get_ports {VGA_B_PIN[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B_PIN[3]}]
set_property PACKAGE_PIN J17 [get_ports {VGA_G_PIN[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G_PIN[0]}]
set_property PACKAGE_PIN H17 [get_ports {VGA_G_PIN[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G_PIN[1]}]
set_property PACKAGE_PIN G17 [get_ports {VGA_G_PIN[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G_PIN[2]}]
set_property PACKAGE_PIN D17 [get_ports {VGA_G_PIN[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G_PIN[3]}]
set_property PACKAGE_PIN P19 [get_ports VGA_HS_PIN]						
	set_property IOSTANDARD LVCMOS33 [get_ports VGA_HS_PIN]
set_property PACKAGE_PIN R19 [get_ports VGA_VS_PIN]						
	set_property IOSTANDARD LVCMOS33 [get_ports VGA_VS_PIN]


##USB-RS232 Interface
#set_property PACKAGE_PIN B18 [get_ports RsRx]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsRx]
#set_property PACKAGE_PIN A18 [get_ports RsTx]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsTx]


##USB HID (PS/2)
#set_property PACKAGE_PIN C17 [get_ports PS2Clk]						
	#set_property IOSTANDARD LVCMOS33 [get_ports PS2Clk]
	#set_property PULLUP true [get_ports PS2Clk]
#set_property PACKAGE_PIN B17 [get_ports PS2Data]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PS2Data]	
	#set_property PULLUP true [get_ports PS2Data]


##Quad SPI Flash
##Note that CCLK_0 cannot be placed in 7 series devices. You can access it using the
##STARTUPE2 primitive.
#set_property PACKAGE_PIN D18 [get_ports {QspiDB[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[0]}]
#set_property PACKAGE_PIN D19 [get_ports {QspiDB[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[1]}]
#set_property PACKAGE_PIN G18 [get_ports {QspiDB[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[2]}]
#set_property PACKAGE_PIN F18 [get_ports {QspiDB[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[3]}]
#set_property PACKAGE_PIN K19 [get_ports QspiCSn]					
	#set_property IOSTANDARD LVCMOS33 [get_ports QspiCSn]

