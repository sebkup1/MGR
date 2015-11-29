----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:47:02 07/22/2015 
-- Design Name: 
-- Module Name:    main - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity main is
					Port ( 
							 clk : in  STD_LOGIC;
						  reset : in  STD_LOGIC;
						  
							 led : out std_logic_vector(7 downto 0):=x"00";
							 
	 FPGA_LPC_EMAC_synch_1 : out STD_LOGIC;
	 FPGA_LPC_EMAC_synch_2 : out STD_LOGIC;
	 
						LPCreq9 : in std_logic :='1'; --P0.9
					  LPCreq10 : in std_logic :='1'; --P0.10
						  
					dip_switch : in std_logic_vector(5 downto 0);
					
							  IR : in STD_LOGIC;
						  
--				LPC_Pico_Data : inout STD_LOGIC_VECTOR(7 DOWNTO 0);
		  LPC_Pico_Data_OUT : out STD_LOGIC_VECTOR(7 DOWNTO 0);
		   LPC_Pico_Data_IN : in std_logic_vector(3 downto 0);
 LPC_to_LCD_Pico_Ready_Receive  : in STD_LOGIC;
	  LPC_to_LCD_Pico_D_V  : in STD_LOGIC:='0';
	  LCD_Pico_to_LPC_D_V  : OUT STD_LOGIC:='0';
LCD_Pico_to_LPC_Ready_Receive : OUT STD_LOGIC:='0';
			
		  --Ethernet PHY connectors by MII
		  Ethernet_Lite_COL : in  STD_LOGIC;
		  Ethernet_Lite_CRS : in  STD_LOGIC;
	     Ethernet_Lite_RXD : in  STD_LOGIC_VECTOR(3 downto 0);--
	     Ethernet_Lite_TXD : out  STD_LOGIC_VECTOR(3 downto 0);--
	   Ethernet_Lite_TX_EN : out  STD_LOGIC; --
	  Ethernet_Lite_RX_CLK : in  STD_LOGIC;
	   Ethernet_Lite_RX_DV : in  STD_LOGIC;  --
		Ethernet_Lite_RX_ER : in  STD_LOGIC;  --
	  Ethernet_Lite_TX_CLK : in  STD_LOGIC;
  Ethernet_Lite_PHY_RST_N : out  STD_LOGIC :='1';
		  Ethernet_Lite_MDC : out  STD_LOGIC; --
		 Ethernet_Lite_MDIO : inout STD_LOGIC;

		--LPC2368 connectors by RMII
					  ENET_TXD : in  STD_LOGIC_VECTOR(1 downto 0);--P1.0--
					ENET_TX_EN : in  STD_LOGIC;--P1.4 --
					  ENET_CRS : out  STD_LOGIC;--P1.8 -- 
					  ENET_RXD : out  STD_LOGIC_VECTOR(1 downto 0);--P1.9--
				   ENET_RX_ER : out  STD_LOGIC;--P1.14 --
				 ENET_REF_CLK : out  STD_LOGIC;--P1.15 --
					  ENET_MDC : in  STD_LOGIC;--P1.16 --
					 ENET_MDIO : inout STD_LOGIC;--P1.17 
					 
--			  iSEL : in  STD_LOGIC;
--			  inRST : in  STD_LOGIC;
            oLCD_DAT_OPV : out  STD_LOGIC_VECTOR (3 downto 0);
             oLCD_EN_OPV : out  STD_LOGIC;
            oLCD_SEL_OPV : out  STD_LOGIC;
             oLCD_RW_OPV : out  STD_LOGIC;
			        uart_rx : in STD_LOGIC;
			        uart_tx : out STD_LOGIC
			  );

end main;

architecture Behavioral of main is

 component kcpsm6 
    generic(                 hwbuild : std_logic_vector(7 downto 0) := X"00";
                    interrupt_vector : std_logic_vector(11 downto 0) := X"3FF";
             scratch_pad_memory_size : integer := 256);
    port (                   address : out std_logic_vector(11 downto 0);
                         instruction : in std_logic_vector(17 downto 0);
                         bram_enable : out std_logic;
                             in_port : in std_logic_vector(7 downto 0);
                            out_port : out std_logic_vector(7 downto 0);
                             port_id : out std_logic_vector(7 downto 0);
                        write_strobe : out std_logic;
                      k_write_strobe : out std_logic;
                         read_strobe : out std_logic;
                           interrupt : in std_logic;
                       interrupt_ack : out std_logic;
                               sleep : in std_logic;
                               reset : in std_logic;
                                 clk : in std_logic
														  );
 end component;


   component program                            
    generic(            C_FAMILY : string := "S6"; 
               C_RAM_SIZE_KWORDS : integer := 1;
            C_JTAG_LOADER_ENABLE : integer := 1);
				 Port (      address : in std_logic_vector(11 downto 0);
							instruction : out std_logic_vector(17 downto 0);
								  enable : in std_logic;
									  rdl : out std_logic;
									  clk : in std_logic);
  end component;
 
 
  	signal address : std_logic_vector(11 downto 0);
	signal instruction : std_logic_vector(17 downto 0);
	signal bram_enable : std_logic;
	signal in_port : std_logic_vector(7 downto 0);
	signal out_port : std_logic_vector(7 downto 0);
	Signal port_id : std_logic_vector(7 downto 0);
	Signal write_strobe : std_logic;
	Signal k_write_strobe : std_logic;
	Signal read_strobe : std_logic;
	Signal interrupt : std_logic;
	Signal interrupt_ack : std_logic;
	Signal kcpsm6_sleep : std_logic;
	Signal kcpsm6_reset : std_logic;
--	signal rdl : std_logic;
	
-- Signals used to connect UART_TX6
--
	signal      uart_tx_data_in 	: std_logic_vector(7 downto 0);
	signal     write_to_uart_tx 	: std_logic;
	signal        pipe_port_id0 	: std_logic := '0';
	signal uart_tx_data_present 	: std_logic;
	signal    uart_tx_half_full 	: std_logic;
	signal         uart_tx_full 	: std_logic;
	signal         uart_tx_reset 	: std_logic;
	--
	-- Signals used to connect UART_RX6
	--
	signal     uart_rx_data_out : std_logic_vector(7 downto 0);
	signal    read_from_uart_rx : std_logic := '0';
	signal uart_rx_data_present : std_logic;
	signal    uart_rx_half_full : std_logic;
	signal         uart_rx_full : std_logic;
	signal        uart_rx_reset : std_logic;
	

	-- Signals used to define baud rate
	signal           baud_count : integer range 0 to 26 := 0; 
	signal         en_16_x_baud : std_logic := '0';

	signal 			 uart_status : std_logic_vector (7 downto 0);
	
	-- LCD sygna³y 
	signal sCLK : std_logic;
	signal snRST : std_logic;
	signal sDATA : std_logic_vector(7 downto 0);
	signal sEN : std_logic;
	signal sREADY : std_logic;


	component uart_tx6
		Port ( data_in : in std_logic_vector(7 downto 0);
				en_16_x_baud : in std_logic;
				serial_out : out std_logic;
				buffer_write : in std_logic;
				buffer_data_present : out std_logic;
				buffer_half_full : out std_logic;
				buffer_full : out std_logic;
				buffer_reset : in std_logic;
				clk : in std_logic);
	end component;

	component uart_rx6
		Port ( serial_in : in std_logic;
				en_16_x_baud : in std_logic;
				data_out : out std_logic_vector(7 downto 0);
				buffer_read : in std_logic;
				buffer_data_present : out std_logic;
				buffer_half_full : out std_logic;
				buffer_full : out std_logic;
				buffer_reset : in std_logic;
				clk : in std_logic);
	end component;


    component lcd_clk_gen is
    Port ( iCLK 	: in  STD_LOGIC;
           inRST 	: in  STD_LOGIC;
           oCLK 	: out  STD_LOGIC;
           onRST 	: out  STD_LOGIC);
    end component;


	component LCD_DRIVER is
    generic (WIDTH : NATURAL := 4;
            WIDTH_DISPLAY	 : integer := 16;
            WIDTH_OUTSIDE: integer:= 8;
            SIMULATION : boolean:= FALSE
            ); 
    port
    (
        CLR_IP			: in  STD_LOGIC;
        CLK_IP_DR		: in  STD_LOGIC; -- Running at 187500 kHz
        EN_IP			: in  STD_LOGIC; -- Detect if there is any incoming message
        MSG_IPV		: in  STD_LOGIC_VECTOR(WIDTH_OUTSIDE-1 downto 0); -- Message from outside
        LCD_DAT_OPV	: out STD_LOGIC_VECTOR(WIDTH-1 downto 0); -- LCD Data Bus Line
        LCD_EN_OP		: out STD_LOGIC; -- LCD Enable
        LCD_SEL_OP	: out STD_LOGIC; -- LCD Regiser Select
        LCD_RW_OP		: out STD_LOGIC;  -- LCD Data Read/Write
        READY 			: out std_logic 
    );
    end component;

	-- Help signals
	signal COUNTER: std_logic_vector(7 downto 0) :=x"00";
	signal PRESCALER: std_logic_vector(25 downto 0);
	signal FRAME: std_logic_vector(31 downto 0);
	signal RXTX_STAT: std_logic_vector(7 downto 0) :=x"00";
	signal INSPECTOR: std_logic_vector(9 downto 0) :="00" & x"00";

	-- MDIO State Machine
   type tipo_stato is ( WaitStart, Preamble, StartOpcode, MdioAddress, DeviceAddress, TurnAroundDataRead, TurnAroundDataWrite, TurnAround, DataRead, DataWrite );

   signal stato       	: tipo_stato := Preamble;
	
	signal serial_trigger : std_logic := '0';

	signal mdio1 : std_logic;
	signal mdio2 : std_logic;
	
	signal test : std_logic :='0';
	
	type tx_state_type is (IDLE, TX0, TX1);
	signal tx_state : tx_state_type := IDLE;

	signal tx0_data : std_logic_vector(1 downto 0):= "00";
	signal tx1_data : std_logic_vector(1 downto 0):= "00";
	signal rx_sel   : std_logic := '0';
	
	
	
	
	
	
----------------------------------------------------------------------
--Begin of behavioral
----------------------------------------------------------------------
begin

processor: kcpsm6
    generic map (  hwbuild => X"00", 
          interrupt_vector => X"3FF",
   scratch_pad_memory_size => 256)
    port map(      address => address,
               instruction => instruction,
               bram_enable => bram_enable,
                   port_id => port_id,
              write_strobe => write_strobe,
            k_write_strobe => k_write_strobe,
                  out_port => out_port,
               read_strobe => read_strobe,
                   in_port => in_port,
                 interrupt => interrupt,
--						interrupt => '0',
             interrupt_ack => interrupt_ack,
                     sleep => kcpsm6_sleep,
--							sleep => '0',
                     reset => kcpsm6_reset,
                       clk => clk
							  );

  
--   kcpsm6_reset <= rdl;

  --
  -- Unused signals tied off until required.
  -- Tying to other signals used to minimise warning messages.
  --

  kcpsm6_sleep <= write_strobe and k_write_strobe;  -- Always '0'
  interrupt <= interrupt_ack;
  
  
  
  
    program_rom: program                    --Name to match your PSM file
    generic map(             C_FAMILY => "S6",   --Family 'S6', 'V6' or '7S'
                    C_RAM_SIZE_KWORDS => 1,      --Program size '1', '2' or '4'
                 C_JTAG_LOADER_ENABLE => 1)      --Include JTAG Loader when set to '1' 
    port map(      address => address,      
               instruction => instruction,
                    enable => bram_enable,
                       rdl => kcpsm6_reset,
                       clk => clk);
							  
							  
	tx: uart_tx6
	port map ( data_in => uart_tx_data_in,
		en_16_x_baud => en_16_x_baud,
		serial_out => uart_tx,
		buffer_write => write_to_uart_tx,
		buffer_data_present => uart_tx_data_present,
		buffer_half_full => uart_tx_half_full,
		buffer_full => uart_tx_full,
		buffer_reset => uart_tx_reset,
		clk => clk);

	rx: uart_rx6
	port map ( serial_in => uart_rx,
		en_16_x_baud => en_16_x_baud,
		data_out => uart_rx_data_out ,
		buffer_read => read_from_uart_rx,
		buffer_data_present => uart_rx_data_present,
		buffer_half_full => uart_rx_half_full,
		buffer_full => uart_rx_full,
		buffer_reset => uart_rx_reset,
		clk => clk);
		
		
  i_lcd_clk_gen : lcd_clk_gen port map (
	  iCLK => clk,
	  inRST => reset,
	  oCLK => sCLK,
	  onRST => snRST
 );


    i_lcd_driver : lcd_driver port map (
        CLR_IP => snRST,
        CLK_IP_DR => sCLK,
        MSG_IPV => sDATA,
        EN_IP => sEN,
        READY => sREADY,
        LCD_DAT_OPV => oLCD_DAT_OPV,
        LCD_EN_OP => oLCD_EN_OPV,
        LCD_SEL_OP => oLCD_SEL_OPV,
        LCD_RW_OP => oLCD_RW_OPV
    );


  
    baud_rate: process(clk)
  begin
    if clk'event and clk = '1' then
      if baud_count = 26 then                    -- counts 27 states including zero
        baud_count <= 0;
        en_16_x_baud <= '1';                     -- single cycle enable pulse
       else
        baud_count <= baud_count + 1;
        en_16_x_baud <= '0';
      end if;
    end if;
  end process baud_rate;
  
  
  
  input_ports: process(clk)
  begin
  
    if clk'event and clk = '1' then
      case port_id(3 downto 0) is

        -- Read UART status at port address 00 hex
        when "0000" => in_port(0) <= uart_tx_data_present;
                      in_port(1) <= uart_tx_half_full;
                      in_port(2) <= uart_tx_full; 
                      in_port(3) <= uart_rx_data_present;
                      in_port(4) <= uart_rx_half_full;
                      in_port(5) <= uart_rx_full;

        -- Read UART_RX6 data at port address 01 hex
        -- (see 'buffer_read' pulse generation below) 
        when "0001" =>  in_port <= uart_rx_data_out;
		  
		  -- ready syg z lcd drivera
		  when "0100" =>  in_port <= "0000000" & sREADY;
		  
		  -- LPC to LCD Pico synchronization
		  when "0111" =>  in_port <= "0000000" & LPC_to_LCD_Pico_Ready_Receive;
		  
		  when "1001" =>  in_port <= "0000000" & LPC_to_LCD_Pico_D_V;
--								led(1)<=LPC_to_LCD_Pico_D_V;
								
		  -- input data to LCD Pico from LPC
		  when "1000" =>  in_port <= "0000" & LPC_Pico_Data_IN;
		  
		  when "1011" =>  in_port <= "0000000" & IR;
--								in_port <= uart_rx_data_out;
								
        when others =>  in_port <= "XXXXXXXX"; 
								

      end case;

      -- Generate 'buffer_read' pulse following read from port address 01

      if (read_strobe = '1') and (port_id(0) = '1') and (port_id(1) = '0') and (port_id(2) = '0') then
        read_from_uart_rx <= '1';
       else
        read_from_uart_rx <= '0';
      end if;
 
    end if;
  end process input_ports;

 
	uart_tx_data_in <= out_port when (write_strobe = '1') and (port_id(0) = '1') and (port_id(1) = '0') and (port_id(2) = '0');


	write_to_uart_tx  <= '1' when (write_strobe = '1') and (port_id(0) = '1') and (port_id(1) = '0') and (port_id(2) = '0') 
								else '0'; 
			  
	sDATA <= out_port when (write_strobe = '1')  and (port_id(0) = '0') and (port_id(1) = '1') and (port_id(2) = '0');
--	led <= out_port when (write_strobe = '1') and (port_id(0) = '0') and (port_id(1) = '1');
--led <= sDATA;
--LPC_Pico_Data <= sDATA;
--	sEN <= '1'  when (port_id(0) = '1') and (port_id(1) = '1') 
--		else '0'; 
  
	
  constant_output_ports: process(clk)
  begin
    if clk'event and clk = '1' then
      if k_write_strobe = '1' then
			--UART flags
        if port_id(0) = '1' and (port_id(1) = '0') and (port_id(2) = '0') and (port_id(3) = '0') then
				uart_tx_reset <= out_port(0);
				uart_rx_reset <= out_port(1);
			--LCD en
		  elsif (port_id(0) = '1') and (port_id(1) = '1') and (port_id(2) = '0') and (port_id(3) = '0') then 
				sEN <= out_port(0);
			--LPC confirm port
		  elsif (port_id(2) = '1') and (port_id(1) = '1') and (port_id(0) = '0') and (port_id(3) = '0') then 
				LCD_Pico_to_LPC_D_V <= out_port(0);
			--Pico(lcd) ready port
		  elsif (port_id(3) = '1') and (port_id(2) = '0') and (port_id(1) = '1') and (port_id(0) = '0') then 
				LCD_Pico_to_LPC_Ready_Receive <= out_port(0);
        end if;
		 end if;
		
			if write_strobe = '1' then
				--Pico to LPC data
				if (port_id(3) = '0') and (port_id(2) = '1') and (port_id(1) = '0') and (port_id(0) = '1') then
					LPC_Pico_Data_OUT <= out_port;
				end if;
		 end if; 
	 end if;
  end process constant_output_ports;









--------------------------------------------------------------------------
-- RMII to MII Converter
	process(clk)--RX
	begin
--		wait until rising_edge(rmii_clk);

		if falling_edge(clk)then
			if rx_sel = '0' then
				ENET_CRS <= Ethernet_Lite_RX_DV;
				INSPECTOR(0) <= '1';
				INSPECTOR(1) <= '0';
				if Ethernet_Lite_RX_DV = '1' then
					INSPECTOR(1) <= '1';
					INSPECTOR(0) <= '0';
					ENET_RXD <= Ethernet_Lite_RXD(1 downto 0);
					rx_sel      <= '1';
				end if;
			else
				ENET_RXD    <= Ethernet_Lite_RXD(3 downto 2);
				INSPECTOR(1) <= '1';
				INSPECTOR(0) <= '0';
				INSPECTOR(7) <= '1';
				rx_sel       <= '0';
			end if;
		end if;
	end process;
	
		process(clk)--TX
	begin
	--		wait until rising_edge(rmii_clk);
		if falling_edge(clk) then
			case tx_state is
			when IDLE =>
				INSPECTOR(2) <= '1';
				INSPECTOR(3) <= '0';
				if ENET_TX_EN = '1' and ENET_TXD /= "00" then
	--			if rmii_txen = '1' and rmii_txdata /= "00" then
					tx0_data <= ENET_TXD;
					tx_state <= TX1;
				end if;
			
			when TX0 =>
				tx0_data <= ENET_TXD;
				tx_state <= TX1;
				INSPECTOR(6) <= '1';
			
			when TX1 =>
				INSPECTOR(2) <= '0';
				INSPECTOR(3) <= '1';
				Ethernet_Lite_TXD <= ENET_TXD & tx0_data;
				RXTX_STAT(7 downto 4) <= ENET_TXD & tx0_data;
				Ethernet_Lite_TX_EN <= ENET_TX_EN;
				tx_state <= TX0;
				if ENET_TX_EN = '0' then
					tx_state <= IDLE;
				end if;
			end case;
		end if;
	end process;
	
	



RXTX_STAT(3 downto 0) <= Ethernet_Lite_RXD;
INSPECTOR(4) <= ENET_TX_EN;
INSPECTOR(5) <= Ethernet_Lite_RX_DV;
INSPECTOR(8) <= Ethernet_Lite_RX_CLK;
INSPECTOR(9) <= Ethernet_Lite_TX_CLK;

ENET_RX_ER 			<=	Ethernet_Lite_RX_ER;
--ENET_REF_CLK		<=	Ethernet_Lite_RX_CLK;
ENET_REF_CLK		<=	clk;
Ethernet_Lite_MDC <=	ENET_MDC;
--ENET_CRS 		<= Ethernet_Lite_CRS;



--Ethernet_Lite_PHY_RST_N <= dip_switch(2);
--led(0)	<=	Ethernet_Lite_RXD(0);
--led(1)	<=	Ethernet_Lite_RXD(1);
--led(2)	<= Ethernet_Lite_RXD(2);
--led(3)	<= Ethernet_Lite_RXD(3);
--led(4)	<= ENET_MDIO;
--led(5)	<= ENET_MDC;
--led(5)	<=	Ethernet_Lite_CRS;
--led(6) 	<= Ethernet_Lite_RX_DV;
--ENET_MDIO <=dip_switch(2);

--led(7) <= LPCreq9;
--led(6) <= LPCreq10;
--led(5)	<= ENET_MDIO;
--led(4)	<= ENET_MDC;




process(clk)
	begin
	
	FPGA_LPC_EMAC_synch_1 <= '0';
	FPGA_LPC_EMAC_synch_2 <= '0';
	
----	if dip_switch(5) = '0' then
----		if dip_switch(3) = '0' and dip_switch(4) = '0' then
----			led <= FRAME(7 downto 0);
----		end if;
----		if dip_switch(3) = '1' and dip_switch(4) = '0' then
----			led <= FRAME(15 downto 8);
----		end if;
----		if dip_switch(3) = '0' and dip_switch(4) = '1' then
----			led <= FRAME(23 downto 16);
----		end if;
----		if dip_switch(3) = '1' and dip_switch(4) = '1' then
----			led <= FRAME(31 downto 24);
----		end if;
----	else
----		if dip_switch(3) = '0' and dip_switch(4) = '0' THEN
----			led <= RXTX_STAT;
----		end if;
----		if dip_switch(3) = '1' and dip_switch(4) = '0' THEN
----			led <= INSPECTOR(7 downto 0);
----		end if;
----		if dip_switch(3) = '0' and dip_switch(4) = '1' THEN
----			led <= "000000" & INSPECTOR(9 downto 8);
----		end if;
----		if dip_switch(3) = '1' and dip_switch(4) = '1' THEN
----			led <= "000000" & INSPECTOR(9 downto 8);
----		end if;
----	end if;
end process;



--------------------------------------------------------------------
-- MDIO Interface (State Machine)
	process(ENET_MDC)
      variable bit_counter : natural range 0 to 31 := 31;
		variable dir : std_logic;
		variable start : std_logic :='0';
		variable frame_counter : natural range 0 to 3323 :=0;
		variable g_counter : natural range 0 to 3323 :=0;
	begin
		
      if falling_edge(ENET_MDC) then

			if ((LPCreq9 = '0')AND (LPCreq10 = '1')) then
			
						if ENET_MDIO = '0' and start = '0' then
								start := '1';
						end if;

						if start = '1' then
							if g_counter < 16 then
								FRAME(g_counter) <= ENET_MDIO;
							end if;
							g_counter := g_counter +1;
							
						end if;			
						
						if g_counter > 31 then
							g_counter := 0;
							start := '0';
						end if;
				
	    case stato is

	       when WaitStart =>

		  if ENET_MDIO = '0' then
				stato <= StartOpcode;
		      bit_counter := 3;
		  end if;
		  

			when Preamble =>

				Ethernet_Lite_MDIO <='1';
				if bit_counter > 0 then
					bit_counter := bit_counter - 1;
				else
					stato <= StartOpcode;
					bit_counter := 3;
				end if;


	       when StartOpcode =>
		if ENET_MDIO = '0' and start = '0' then
			start := '1';
		end if;

		if start = '1' then
			Ethernet_Lite_MDIO <= ENET_MDIO;
		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
		     stato <= MdioAddress;
		     bit_counter := 4;
			  start := '0';
			  dir := ENET_MDIO;
		  end if;
		end if;

	       when MdioAddress =>
			Ethernet_Lite_MDIO <= ENET_MDIO;

		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
		     stato <= DeviceAddress;
		     bit_counter := 4;
		  end if;

	       when DeviceAddress =>
			Ethernet_Lite_MDIO <= ENET_MDIO;

		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
		     if dir = '1' then
			stato <= TurnAroundDataWrite;
		     else
			stato <= TurnAroundDataRead;
		     end if;
		  end if;

			
	       when TurnAroundDataWrite =>

		  if bit_counter = 0 then
		     Ethernet_Lite_MDIO <= '1';
		     bit_counter := 15;
		  else 
		     Ethernet_Lite_MDIO <= '0';
		     stato <= DataWrite;
		  end if;

	       when DataWrite =>
		  Ethernet_Lite_MDIO <= ENET_MDIO;
		  FRAME(bit_counter+16) <=  ENET_MDIO;

		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
		     stato <= Preamble;
		  end if;

			 when TurnAroundDataRead =>

		  Ethernet_Lite_MDIO <= 'Z';
		  if bit_counter = 0 then
  	         bit_counter := 15;
				
		  else 
			  if Ethernet_Lite_MDIO = '0' then
				  stato <= DataRead;
	--			  
			  else
				  stato <= Preamble; -- ERRORE!

			  end if;
		  end if;

		 when DataRead =>
--		  ENET_MDIO <=  Ethernet_Lite_MDIO;
--			if bit_counter <8 then
--			ENET_MDIO <= '1';
--			else
--			ENET_MDIO <= '0';
--			end if;

			FRAME(bit_counter+16) <=  Ethernet_Lite_MDIO;

		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
		     stato <= Preamble;
		  end if;
		  
	       when others =>
			
		  stato <= WaitStart;
 		  Ethernet_Lite_MDIO <= 'Z';
--		  error_code <= "111";
--		  hexint <= x"3";

	    end case;
				end if;
			end if; 
   end process;

end Behavioral;