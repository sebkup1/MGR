--------------------------------------------------------------------------------
-- Title        : LCD Driver
-- Project      : FPGA-Board
--------------------------------------------------------------------------------
-- File         : LCD_DRIVER.vhd
-- Author       : Joseph Chung josephchunghk@yahoo.com base on Chao Chen's work (c.chen@gmx.de)
-- Supervisor   : Prof. Dr. B. Schwarz
-- Organization : Hochschule für Angewandte Wissenschaften Hamburg (HAW Hamburg)
-- Created      : 08.02.2005 (MM.DD.YYYY)
-- Last update  : 08.02.2005
-- Platform     : Windows XP
-- Editor       : ISE 6.2
-- Simulator    : ModelSim 5.7g SE
-- Synthesizer  : Xilinx ISE 6.2.03i
-- Targets      : XC3S400-4PQ208 [Memec Spartan-3 DS-BD-3SxLC-PQ208 Board]
-- Dependency   : None
--------------------------------------------------------------------------------
-- Description  : Modify from 8 bit to 4 bit operation
--				  		port from Samsung KS0066u to Sunplus SPLC780A1
--				  		Below orginal comment
--				  		LCD Driver Console : initialize the LCD and wait for the user
--                to input the characters.
--                FSM chart can be found in the master thesis documentation.
--
--                All signal abbreviations (i.e. signal name convention) can be
--                found in the root source folder \VHDL\Src\SIGNAL_ABBR_LIST.txt
--------------------------------------------------------------------------------
-- Modification history :
-- 05.01.2004 Created
-- 05.02.2004 Check WAITING, VERIFY state
-- 05.05.2004 Change CNT_SV = REG_SETUP_1T+1 to CNT_SV = REG_SETUP_1T in the
--            FUNCTION_SET state
-- 05.06.2004 Add RTR(Ready To Receive) handshaking signal
-- 05.07.2004 Add RESTART state
-- 09.05.2004 Delete RTR signal and RESTART state, everything depends on the
--            EN_IP_DB signal; Add POS32 counter for restarting case
-- 09.24.2004 Delete RESTART state and fix in VERIFY state for continuous two
--            line display.
--            Interpret "ESCAPE" as "clear screen" command
--
--            Future improvement : More commands can be interpreted;
--            German Umlaut ä,ö,ü,ß can be user-programmed into the CG RAM; 
--			  the BF(Busy Flag) can be used; initialization steps can be reprogrammed 
--            in-between so that there are different display effect.

-- 07.02.2005 (DD.MM.YYYY) add debouncer to Enable signal
-- 14.02.2005 add width_display generic
-- 22.02.2005 add ready signal for handshaking
-- 23.02.2005 extract comparator from FSM 
-- 23.02.2005 extract multiplexer from FSM
-- 28.08.2005 Modifizierung auf ein File, Reset-Anpassung
-- 08.11.2005 Übernahmeanforderung auf WATING-Zustand synchronisiert 
--------------------------------------------------------------------------------

-- 30.01.2007 Modified by Mihajlo Jovanovic to work with Hitachi HD44780U LCD controller

--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
--library Joseph_LIB;
--use work.joseph_PACK.all;

entity LCD_DRIVER is
generic (WIDTH : NATURAL := 4;
		   WIDTH_DISPLAY	 : integer := 16;
		   WIDTH_OUTSIDE: integer:= 8;
		   SIMULATION : boolean:= FALSE
		); 

port
(
   	CLR_IP		: in  STD_LOGIC;
   	CLK_IP_DR	: in  STD_LOGIC; -- Running at 187500 kHz
   	EN_IP			: in  STD_LOGIC; -- Detect if there is any incoming message
   	MSG_IPV		: in  STD_LOGIC_VECTOR(WIDTH_OUTSIDE-1 downto 0); -- Message from outside
   	LCD_DAT_OPV	: out STD_LOGIC_VECTOR(WIDTH-1 downto 0); -- LCD Data Bus Line
   	LCD_EN_OP	: out STD_LOGIC; -- LCD Enable
   	LCD_SEL_OP	: out STD_LOGIC; -- LCD Regiser Select
   	LCD_RW_OP	: out STD_LOGIC;  -- LCD Data Read/Write
		READY 		: out std_logic 
);
end entity LCD_DRIVER;

architecture BEHAVIORAL of LCD_DRIVER is



-----------------
-- Start up 0011 
-----------------
constant STU : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := x"3";

------------------------------------------------------------
-- Function Set for 4-bit data transfer and 2-line display
------------------------------------------------------------
constant SET : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := x"2";
constant SET2 : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := x"8";	-- N F is 1

---------------------------------------------------------------------------------------
-- Entry Mode Set to increment cursor automatically after each character is displayed. 
-- If the last digit is set to 1, then the whole display is shifted to the left.
---------------------------------------------------------------------------------------
constant ESM : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := x"0";
constant ESM2 : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := x"6";

---------------------------------------------------------
-- Display ON, with cursor.
-- If the last digit is set to 1 then the cursor blinks.
---------------------------------------------------------
constant DON : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := x"0";
constant DON2 : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := x"E";	 -- Display "on", cursor "on", no blinking

----------------
-- Clear Screen
----------------
constant CLR : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := x"0";
constant CLR2 : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := x"1";

------------------------------
-- DD RAM Address Set, Line 1
------------------------------
constant DDRAS_HOME1 : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := x"8";
constant DDRAS_HOME12 : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := x"0";

-----------------------
-- Home Cursor, Line 2
-----------------------
constant DDRAS_HOME2 : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := x"c";
constant DDRAS_HOME22 : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := x"0";

-------------------------
-- Register Setup Period
-------------------------
--constant REG_SETUP_1T : NATURAL := 16; -- 60 µs
-- the lines commented out by MJovanovic
--constant REG_SETUP_1T: NATURAL := 12; -- 60 us, in accordance with 187500Hz clock, the value 3 is used for simulation
	
--constant REG_SETUP_2T : NATURAL := 32; -- 120 µs,
-- the lines commented out by MJovanovic
--constant REG_SETUP_2T : NATURAL := 47; -- 250 us, to have a delay in accordance with Pjevalica's LCD test routine
													-- there is a delay of 250us after sending a character to LCD
													-- the value 6 should be used for simulation
------------------------
-- Clear Screen Period
------------------------
--constant CLR_T : NATURAL := 469; -- 1.8 ms, constant CLR_T : NATURAL := 10; 38 us for simulation		  469 normal
-- the lines commented out by MJovanovic
--constant CLR_T : NATURAL := 938; -- 5 ms, to have a delay in accordance with Pjevalica's LCD test routine
													-- there is a delay of 250us after sending a character to LCD
													-- the value 10 should be used for simulation
------------------------
-- Function Set Period
------------------------
--constant SET_T : NATURAL := 6250; -- 24 ms
-- the line above commented out by MJovanovic
--constant SET_T : NATURAL := 4500; -- 24ms on 187500Hz clock
												-- the value 15 should be used for simulation

-----------------------------------------------
--constants for Timer output to control the FSM
-----------------------------------------------
constant REG_SETUP_1T_CTRL: STD_LOGIC_VECTOR(2 downto 0) := "001"; --    60 µs
constant REG_SETUP_2T_CTRL: STD_LOGIC_VECTOR(2 downto 0) := "010"; --   250 µs
constant CLR_T_CTRL: STD_LOGIC_VECTOR(2 downto 0) 		 := "011"; --  5000 µs
constant SET_T_CTRL: STD_LOGIC_VECTOR(2 downto 0) 		 := "100"; -- 24000 µs
constant NON_CNT_CTRL: STD_LOGIC_VECTOR(2 downto 0) 	 := "000";

-------------------------------------------------
--contants from FSM to control the datapath Mux--
-------------------------------------------------
constant SET_CTRL: STD_LOGIC_VECTOR(3 downto 0)  		:= "0000";
constant SET2_CTRL: STD_LOGIC_VECTOR(3 downto 0) 		:= "0001";
constant DON_CTRL: STD_LOGIC_VECTOR(3 downto 0)  		:= "0010";
constant DON2_CTRL: STD_LOGIC_VECTOR(3 downto 0) 		:= "0011";
constant CLR_CTRL: STD_LOGIC_VECTOR(3 downto 0)  		:= "0100";
constant CLR2_CTRL: STD_LOGIC_VECTOR(3 downto 0) 		:= "0101";
constant ESM_CTRL: STD_LOGIC_VECTOR(3 downto 0)  		:= "0110";
constant ESM2_CTRL: STD_LOGIC_VECTOR(3 downto 0) 		:= "0111";
constant DDRAS_HOME1_CTRL: STD_LOGIC_VECTOR(3 downto 0)  := "1000";
constant DDRAS_HOME12_CTRL: STD_LOGIC_VECTOR(3 downto 0) := "1001";
constant NON_MUX_CTRL: STD_LOGIC_VECTOR(3 downto 0)      := "1010";
constant MSG7_4_CTRL: STD_LOGIC_VECTOR(3 downto 0)       := "1011";
constant MSG3_0_CTRL: STD_LOGIC_VECTOR(3 downto 0)       := "1100";
constant DDRAS_HOME2_CTRL: STD_LOGIC_VECTOR(3 downto 0)  := "1101";
constant DDRAS_HOME22_CTRL: STD_LOGIC_VECTOR(3 downto 0) := "1110";
constant STU_CTRL: STD_LOGIC_VECTOR(3 downto 0) 		 := "1111";

---------------------------------------------------------
--contants for Cursor-Counter output to control the FSM--
---------------------------------------------------------
constant POS16_CTRL : STD_LOGIC_VECTOR(1 downto 0)   := "01";
constant POS32_CTRL : STD_LOGIC_VECTOR(1 downto 0)   := "10";
constant POS0_CTRL : STD_LOGIC_VECTOR(1 downto 0)    := "11";
constant POS_NON_CTRL : STD_LOGIC_VECTOR(1 downto 0) := "00";

--******************************************************************
--******************************************************************

-- State definition

type STATE_TYPE is (START_UP1,START_UP2,START_UP3,START_UP4, FUNCTION_SET, DISPLAY, ENTRY_MODE, CLEAR, 
					ADDRESS_SET, WAITING, VERIFY, PUT_CHAR, HOME_CURSOR,FUNCTION_SET2, DISPLAY2, 
					ENTRY_MODE2, CLEAR2, ADDRESS_SET2, PUT_CHAR2, HOME_CURSOR2);
                       
signal STATE, N_STATE : STATE_TYPE; -- Present & Next States

signal REG_SETUP_1T : NATURAL;
signal REG_SETUP_2T : NATURAL;
signal CLR_T 		  : NATURAL;
signal SET_T		  : NATURAL;
---------------------------
-- General Period Counter--
---------------------------
signal CNT_SV : NATURAL range 0 to 4500;-- previously SET_T, but SET_T is not a constant any more;
signal CLR_CNT_S : STD_LOGIC;

------------------------------
-- Cursor Position (16*2=32) -
------------------------------
signal CLR_POS32_S, EN_POS32_S : STD_LOGIC;
signal POS32_SV : NATURAL range 0 to 32;
signal POS16_32:  STD_LOGIC_VECTOR(1 downto 0) ;
---------------------------------------------
-- debounce signal, A first FF, B second FF--
---------------------------------------------		
signal EN_IP_DB: STD_LOGIC;  --, B,C, A 
signal SEL_LCD_DAT:  STD_LOGIC_VECTOR(3 downto 0) ;
signal CNT_MSG :  STD_LOGIC_VECTOR(2 downto 0) ;
signal CLR_IP_S: std_logic;
signal Q1: std_logic;
signal READY_INT: std_logic;
signal MSG_IPV_INT: std_logic_vector (7 downto 0);
signal VERIFY_STATE: std_logic;
signal WAITING_STATE: std_logic;
--*******************************************************************

begin


   REG_SETUP_1T <= 12 when SIMULATION = FALSE else
					    3; 
   
	REG_SETUP_2T <= 47 when SIMULATION = FALSE else
						 6;

   CLR_T <= 938 when SIMULATION = FALSE else
				10;
				
	SET_T <= 4500 when SIMULATION = FALSE else
			   15;
						 
						 
GATED_RESET:      -- optional label
process(CLK_IP_DR)
begin

if (CLK_IP_DR'event and CLK_IP_DR = '1') then
	Q1 <= CLR_IP ;
	CLR_IP_S <= not(Q1);	  -- Invertierung wegen CLR_IP low aktiv
end if;
end process;



LCD_RW_OP <= '0'; -- Always Data Write


SYNCHRON:  											-- Synchronisieren von EN_IP
process (CLK_IP_DR, EN_IP, CLR_IP_S)
begin

	if (CLR_IP_S = '1') then

	elsif (CLK_IP_DR = '1' and CLK_IP_DR'event) then
			if READY_INT = '1' then

       		MSG_IPV_INT <= MSG_IPV;		-- Zeichen zwischenspeichern	
       	else
       	end if;
       	if (EN_IP and WAITING_STATE) = '1' then		-- Übernahmeanforderung auf WATING synchronisiert
       	
       		EN_IP_DB <= '1';
       	elsif VERIFY_STATE = '1' then 
       		EN_IP_DB <= '0';
 
       	end if;     	
	end if;

end process SYNCHRON;
	



dp_mux: process (SEL_LCD_DAT, MSG_IPV_INT)	--
begin
   case SEL_LCD_DAT is
	when SET_CTRL 			=> LCD_DAT_OPV <= SET;
	when SET2_CTRL 			=> LCD_DAT_OPV <= SET2;
	when DON_CTRL 			=> LCD_DAT_OPV <= DON;
	when DON2_CTRL 			=> LCD_DAT_OPV <= DON2;
	when CLR_CTRL 			=> LCD_DAT_OPV <= CLR;
	when CLR2_CTRL 			=> LCD_DAT_OPV <= CLR2;
	when ESM_CTRL 			=> LCD_DAT_OPV <= ESM;
	when ESM2_CTRL 			=> LCD_DAT_OPV <= ESM2;
	when DDRAS_HOME1_CTRL 	=> LCD_DAT_OPV <= DDRAS_HOME1;
	when DDRAS_HOME12_CTRL 	=> LCD_DAT_OPV <= DDRAS_HOME12;
	when NON_MUX_CTRL 		=> LCD_DAT_OPV <= "0000";
	when MSG7_4_CTRL 		=> LCD_DAT_OPV <= MSG_IPV_INT(7 downto 4);
	when MSG3_0_CTRL 		=> LCD_DAT_OPV <= MSG_IPV_INT(3 downto 0);
	when DDRAS_HOME2_CTRL 	=> LCD_DAT_OPV <= DDRAS_HOME2;
	when DDRAS_HOME22_CTRL 	=> LCD_DAT_OPV <= DDRAS_HOME22;
	when STU_CTRL 			=> LCD_DAT_OPV <= STU;
	when others 			=> NULL;
   end case;
end process;


CNT : process (CLR_IP, CLK_IP_DR)
begin
	if (CLK_IP_DR = '1' and CLK_IP_DR'event) then

		if (CLR_CNT_S = '1') then
            CNT_SV <= 0; 			--after 5 ns;
		else
            CNT_SV <= CNT_SV + 1; 	--after 5 ns;
		end if;
	end if;
end process CNT;

CNT_COMPARE:process(CNT_SV)
begin
   	if (CNT_SV = REG_SETUP_1T) then 	 	-- =16, corresponds to 60 µs
		CNT_MSG <= "001";
    elsif ( CNT_SV = REG_SETUP_2T  ) then 	-- =47, corresponds to 250 µs
		CNT_MSG <= "010";
    elsif ( CNT_SV = CLR_T  ) then  		-- =938, corresponds to 5000 µs
		CNT_MSG <= "011";
	elsif ( CNT_SV = SET_T  ) then 			-- =6250, corresponds to 24000 µs
		CNT_MSG <= "100";
	else 
		CNT_MSG <= "000";
	end if;
end process;


POS_COMPARE:process(POS32_SV)
begin
   	if (POS32_SV = 16 ) then 
		POS16_32 <= POS16_CTRL;
    elsif (POS32_SV = 32) then 
		POS16_32 <= POS32_CTRL;
    elsif (POS32_SV = 0) then 
		POS16_32 <= POS0_CTRL;
	else 
		POS16_32 <= POS_NON_CTRL;
	end if;
end process;

POS32 : process (CLR_IP, CLK_IP_DR)
begin
	if (CLK_IP_DR = '1' and CLK_IP_DR'event) then

		if (CLR_POS32_S = '1') then
			POS32_SV <= 0;
		elsif (EN_POS32_S = '1') then		  --after a character put
			POS32_SV <= POS32_SV + 1;
		end if;
	end if;
end process POS32;



   --/*------------------------------------*\
   --| Present State Register               |
   --| Synchronous process of state machine |
   --\*------------------------------------*/
FSM_SYNC : process (CLR_IP, CLK_IP_DR)
begin

	if (CLK_IP_DR = '1' and CLK_IP_DR'event) then
		STATE <= N_STATE;
	end if;
end process FSM_SYNC;

   --/*--------------------------------------*\
   --| Next State Forming Logic               |
   --| Combinational process of state machine |
   --\*--------------------------------------*/
FSM_COMB : process (STATE, EN_IP_DB, MSG_IPV_INT, CNT_SV, POS32_SV, CNT_MSG, POS16_32, CLR_IP_S)
begin
-- Default assignments, to avoid latches
	N_STATE <= START_UP1 ;
	SEL_LCD_DAT <= "0000";
	VERIFY_STATE <= '0';
	WAITING_STATE <= '0';
	LCD_EN_OP <= '0';
	LCD_SEL_OP <= '0';
	READY_INT <= '0';
	CLR_CNT_S <= '0';
	CLR_POS32_S <= '0';
	EN_POS32_S <= '0';

	case STATE is

		when START_UP1 =>

			SEL_LCD_DAT <=STU_CTRL;					-- LCD_DAT_OPV = 3
            if (CNT_MSG = SET_T_CTRL) then	-- 24 ms
               	LCD_EN_OP <= '1';
				N_STATE <= START_UP2;
               	CLR_CNT_S <= '1';
            else
               	LCD_EN_OP <= '0';
				   N_STATE <= START_UP1;
               	CLR_CNT_S <= '0';
            end if;
            
		when START_UP2 =>
			SEL_LCD_DAT <=STU_CTRL;
            if (CNT_MSG = CLR_T_CTRL) then	-- 5 ms -- 24 ms
				LCD_EN_OP <= '1';
				N_STATE <= START_UP3;
				CLR_CNT_S <= '1';
            else
				LCD_EN_OP <= '0';
				N_STATE <= START_UP2;
				CLR_CNT_S <= '0';
            end if;
            
		when START_UP3 =>
			SEL_LCD_DAT <= STU_CTRL;
            if (CNT_MSG = CLR_T_CTRL) then	-- 5 ms -- 24 ms
				LCD_EN_OP <= '1';
				N_STATE <= START_UP4;
				CLR_CNT_S <= '1';
            else
				LCD_EN_OP <= '0';
				N_STATE <= START_UP3;
				CLR_CNT_S <= '0';
            end if;
            
		when START_UP4 =>
			SEL_LCD_DAT <= SET_CTRL;
			if (CNT_MSG = CLR_T_CTRL) then	-- 5 ms -- 24 ms
				LCD_EN_OP <= '1';
				N_STATE <= FUNCTION_SET;
				CLR_CNT_S <= '1';
            else
				LCD_EN_OP <= '0';
				N_STATE <= START_UP4;
				CLR_CNT_S <= '0';
            end if;
            
		when FUNCTION_SET =>
			SEL_LCD_DAT <=SET_CTRL;
            if (CNT_MSG = REG_SETUP_1T_CTRL) then  -- 60us
				LCD_EN_OP <= '1';
				N_STATE <= FUNCTION_SET2;
				CLR_CNT_S <= '1';
            else
				LCD_EN_OP <= '0';
				N_STATE <= FUNCTION_SET;
				CLR_CNT_S <= '0';
            end if;

		when FUNCTION_SET2 =>
			SEL_LCD_DAT <=SET2_CTRL;
            if (CNT_MSG = REG_SETUP_1T_CTRL) then   -- 60us
				LCD_EN_OP <= '1';
            else
				LCD_EN_OP <= '0';
            end if;
            if (CNT_MSG = CLR_T_CTRL) then  -- after 5 ms
				N_STATE <= DISPLAY;
				CLR_CNT_S <= '1';
            else
				N_STATE <= FUNCTION_SET2;
				CLR_CNT_S <= '0';
            end if;

		when DISPLAY => 			-- Set display on
			SEL_LCD_DAT <=DON_CTRL;
            if (CNT_MSG = REG_SETUP_1T_CTRL) then  -- 60 us
				N_STATE <= DISPLAY2;
				LCD_EN_OP <= '1';
				CLR_CNT_S <= '1';
            else
				N_STATE <= DISPLAY;
				LCD_EN_OP <= '0';
				CLR_CNT_S <= '0';
            end if;


		when DISPLAY2 => 				-- Set display on
			SEL_LCD_DAT <=DON2_CTRL;  -- display on, cursor on, no blinking
			if (CNT_MSG = REG_SETUP_1T_CTRL) then    -- 60 us
				LCD_EN_OP <= '1';
			else 
				LCD_EN_OP <='0';
			end if;
			if (CNT_MSG = CLR_T_CTRL) then				-- 5 ms
				N_STATE <= CLEAR;
				CLR_CNT_S <= '1';
         else
				N_STATE <= DISPLAY2;
				CLR_CNT_S <= '0';
         end if;

		when CLEAR => 					-- Clear the screen
			SEL_LCD_DAT <= CLR_CTRL;
			if (CNT_MSG = REG_SETUP_1T_CTRL) then -- wenn 60 us vergangen
				LCD_EN_OP <= '1';
				N_STATE <= CLEAR2;
				CLR_CNT_S <= '1';
         else
				LCD_EN_OP <= '0';
				N_STATE <= CLEAR;
				CLR_CNT_S <= '0';
         end if;

		when CLEAR2 => 					-- Clear the screen
			SEL_LCD_DAT <= CLR2_CTRL;
			if (CNT_MSG = REG_SETUP_1T_CTRL) then
				LCD_EN_OP <= '1';
            else
				LCD_EN_OP <= '0';
            end if;
			if (CNT_MSG = CLR_T_CTRL) then   -- after 5 ms
				N_STATE <= ENTRY_MODE;
				CLR_CNT_S <= '1';
            else
				N_STATE <= CLEAR2;
				CLR_CNT_S <= '0';
            end if;

		when ENTRY_MODE => 					-- Increment after each character is displayed
			SEL_LCD_DAT <= ESM_CTRL;
            if (CNT_MSG = REG_SETUP_1T_CTRL) then   -- 60us
				N_STATE <= ENTRY_MODE2;
				LCD_EN_OP <= '1';
				CLR_CNT_S <= '1';
			else
				N_STATE <= ENTRY_MODE;
				LCD_EN_OP <= '0';
				CLR_CNT_S <= '0';
            end if;

		when ENTRY_MODE2 => 	-- Increment after each character is displayed, display shift doesn't accompany the cursor shift
			SEL_LCD_DAT <= ESM2_CTRL;
			if (CNT_MSG = REG_SETUP_1T_CTRL) then
				LCD_EN_OP <= '1';
			else
				LCD_EN_OP <= '0';
			end if;
			if (CNT_MSG = CLR_T_CTRL) then	
				N_STATE <= ADDRESS_SET;
				CLR_CNT_S <= '1';
         else
				N_STATE <= ENTRY_MODE2;
				CLR_CNT_S <= '0';
         end if;

		when ADDRESS_SET => 				-- DD RAM address set
			SEL_LCD_DAT <= DDRAS_HOME1_CTRL;
			if (CNT_MSG = REG_SETUP_1T_CTRL) then  -- 60us
				N_STATE <= ADDRESS_SET2;
				LCD_EN_OP <= '1';
				CLR_CNT_S <= '1';
         else
				N_STATE <= ADDRESS_SET;
				LCD_EN_OP <= '0';
				CLR_CNT_S <= '0';
         end if;

		when ADDRESS_SET2 => 				-- DD RAM address set
			SEL_LCD_DAT <= DDRAS_HOME12_CTRL	;
			if (CNT_MSG = REG_SETUP_1T_CTRL) then  -- 60 us   
				LCD_EN_OP <= '1';
			else
				LCD_EN_OP <= '0';
			end if;	
			if (CNT_MSG = CLR_T_CTRL) then       -- after 5ms
				N_STATE <= WAITING;
				CLR_CNT_S <= '1';
         else
				N_STATE <= ADDRESS_SET2;
				CLR_CNT_S <= '0';
         end if;
				
		when WAITING =>
			WAITING_STATE <= '1';								-- when fails, one solution -> prolong ADDRESS_SET to REG_SETUP_2T)
			VERIFY_STATE <= '0';
			SEL_LCD_DAT <= NON_MUX_CTRL;
			LCD_EN_OP <= '0';							-- enable = 0
			CLR_CNT_S <= '1';							-- clear counter
			READY_INT <= '1';							-- ready for a new character
			
			if (EN_IP_DB = '1' or CLR_IP_S = '1') then  -- start writing
				N_STATE <= VERIFY;
				LCD_SEL_OP <= '1';  		-- data register in the LCD controller selected
         else
				N_STATE <= WAITING;	   -- still waiting
				LCD_SEL_OP <= '0';
         end if;

		when VERIFY =>						-- Verify curson position
			WAITING_STATE <= '0';
			READY_INT <= '0'; 				-- character writing in process
			VERIFY_STATE <= '1';				-- verify state indicator set
			SEL_LCD_DAT <= NON_MUX_CTRL;	-- LCD_DAT_OPV = "0000"
			LCD_EN_OP <= '0'; 				-- keine Aktion
			LCD_SEL_OP <= '1';				-- data register is selected
			CLR_CNT_S <= '1';					-- clear counter
			
			if (MSG_IPV_INT = X"1B" or CLR_IP_S = '1') then	 -- "1B" = Clear display. Cursor on the 1st position in the 1st row
				N_STATE <= CLEAR;
				CLR_POS32_S <= '1';
				
			elsif (POS16_32 = POS16_CTRL) then
				N_STATE <= HOME_CURSOR;
				CLR_POS32_S <= '0';

			elsif (POS16_32 = POS32_CTRL) then
				N_STATE <= HOME_CURSOR;
				CLR_POS32_S <= '1';

			else
				N_STATE <= PUT_CHAR;
				CLR_POS32_S <= '0';
			end if;

		when PUT_CHAR => 							-- Display the character
			SEL_LCD_DAT <=MSG7_4_CTRL;				-- data higher nibble
			LCD_SEL_OP <= '1';						-- data register selected
			READY_INT <= '0';

			if (CNT_MSG = REG_SETUP_1T_CTRL) then 	-- after 60 us
				LCD_EN_OP <= '1';					-- write
				N_STATE <= PUT_CHAR2;
				CLR_CNT_S <= '1';
				READY_INT <= '0';
			else
				LCD_EN_OP <= '0';
				N_STATE <= PUT_CHAR;
				CLR_CNT_S <= '0';
			end if;

		when PUT_CHAR2=> 							-- Display the character
			SEL_LCD_DAT <=MSG3_0_CTRL;
			LCD_SEL_OP <= '1';
			READY_INT <= '0';	
			if (CNT_MSG = REG_SETUP_1T_CTRL) then   -- 60 us
				LCD_EN_OP <= '1';
       	else
				LCD_EN_OP <= '0';
         end if;
			if (CNT_MSG = REG_SETUP_2T_CTRL) then    -- 250 us
				N_STATE <= WAITING;
				CLR_CNT_S <= '1';
				EN_POS32_S <= '1';
            else
				N_STATE <= PUT_CHAR2;
				CLR_CNT_S <= '0';
				EN_POS32_S <= '0';
            end if;

		when HOME_CURSOR => 						-- Home curson position
			if (POS16_32 = POS16_CTRL) then			-- "01"        (width of display)?
            	SEL_LCD_DAT <=DDRAS_HOME2_CTRL;		-- LCD_DAT_OPV = "C"H
			elsif (POS16_32 = POS0_CTRL) then  		-- "11"
            	SEL_LCD_DAT <=DDRAS_HOME1_CTRL;		-- LCD_DAT_OPV = "8"H
			end if;
			if (CNT_MSG = REG_SETUP_1T_CTRL) then
				N_STATE <= HOME_CURSOR2;
				LCD_EN_OP <= '1';
				CLR_CNT_S <= '1';
            else
				N_STATE <= HOME_CURSOR;
				LCD_EN_OP <= '0';
				CLR_CNT_S <= '0';
            end if;

	 	when HOME_CURSOR2 => 						-- Home curson position
			if (POS16_32 = POS16_CTRL) then			-- "01"
            	SEL_LCD_DAT <=DDRAS_HOME22_CTRL;	-- LCD_DAT_OPV = "0"H
			elsif (POS16_32 =  POS0_CTRL) then		-- "11"
				SEL_LCD_DAT <=DDRAS_HOME12_CTRL;	-- LCD_DAT_OPV = "0"H
            end if;
			if (CNT_MSG = CLR_T_CTRL) then     -- 5 ms
				N_STATE <= PUT_CHAR;
				LCD_EN_OP <= '1';
				CLR_CNT_S <= '1';
            else
				N_STATE <= HOME_CURSOR2;
				LCD_EN_OP <= '0';
				CLR_CNT_S <= '0';
            end if;
		when others =>
			N_STATE <= START_UP1 ;
	end case;
end process FSM_COMB;

READY <= READY_INT;							-- actualisation

end architecture BEHAVIORAL;
