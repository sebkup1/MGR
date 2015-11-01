library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rmii_port is
port (
--  rmii_rxdata   : in  std_logic_vector(1 downto 0);
--  rmii_crs_rxdv : in  std_logic;
--  rmii_txdata   : out std_logic_vector(1 downto 0) := "00";
--  rmii_txen     : out std_logic := '0';
--  rmii_clk		 : in  std_logic;
--
--  mii_rxdata    : out std_logic_vector(3 downto 0) := x"0";
--  mii_rxdv      : out std_logic := '0';
--  mii_txdata    : in  std_logic_vector(3 downto 0);
--  mii_txen      : in  std_logic;
--  mii_clk		 : out std_logic := '0'

  rmii_rxdata   : out  	std_logic_vector(1 downto 0);
  rmii_crs_rxdv : out  	std_logic;
  rmii_txdata   : in 	std_logic_vector(1 downto 0) := "00";
  rmii_txen     : in 	std_logic := '0';
  rmii_clk		 : in  	std_logic;

  mii_rxdata    : in 	std_logic_vector(3 downto 0) := x"0";
  mii_rxdv      : in 	std_logic := '0';
  mii_txdata    : out  	std_logic_vector(3 downto 0);
  mii_txen      : out  	std_logic

);
end rmii_port;

architecture beh of rmii_port is

--type rx_state_type is (IDLE, RX0, RX1);
--signal rx_state : rx_state_type := IDLE;
--
--signal rx0_data : std_logic_vector(1 downto 0);
--signal tx_sel   : std_logic := '0';
--signal clk2     : std_logic := '0';

type tx_state_type is (IDLE, TX0, TX1);
signal tx_state : tx_state_type := IDLE;

signal tx0_data : std_logic_vector(1 downto 0):= "00";
signal tx1_data : std_logic_vector(1 downto 0):= "00";
signal rx_sel   : std_logic := '0';

begin

	process(rmii_clk)--RX
	begin
--		wait until rising_edge(rmii_clk);

	if rising_edge(rmii_clk)then
		if rx_sel = '0' then
			rmii_crs_rxdv <= mii_rxdv;
			if mii_rxdv = '1' then
				rmii_rxdata <= mii_rxdata(1 downto 0);
				rx_sel      <= '1';
			end if;
		else
			rmii_rxdata    <= mii_rxdata(3 downto 2);
			rx_sel         <= '0';
		end if;
	end if;
	end process;
	
	

	process(rmii_clk)--TX
	begin
--		wait until rising_edge(rmii_clk);
	if rising_edge(rmii_clk) then
		case tx_state is
		when IDLE =>
			if rmii_txen = '1' then
--			if rmii_txen = '1' and  rmii_txdata /= "00" then
				tx0_data <= rmii_txdata;
				tx_state <= TX1;
			end if;
		
		when TX0 =>
			tx0_data <= rmii_txdata;
			tx_state <= TX1;
		
		when TX1 =>
			mii_txdata <= rmii_txdata & tx0_data;
			mii_txen <= rmii_txen;
			tx_state <= TX0;
			if rmii_txen = '0' then
				tx_state <= IDLE;
			end if;
		end case;
		end if;
	end process;



-- pierwotny =======================================
--	process--RX
--	begin
--		wait until rising_edge(rmii_clk);
--
--		case rx_state is
--		when IDLE =>
--			if rmii_crs_rxdv = '1' and rmii_rxdata /= "00" then
--				rx0_data <= rmii_rxdata;
--				rx_state <= RX1;
--			end if;
--		
--		when RX0 =>
--			rx0_data <= rmii_rxdata;
--			rx_state <= RX1;
--		
--		when RX1 =>
--			mii_rxdata <= rmii_rxdata & rx0_data;
--			mii_rxdv   <= rmii_crs_rxdv;
--
--			rx_state <= RX0;
--			if rmii_crs_rxdv = '0' then
--				rx_state <= IDLE;
--			end if;
--		end case;
--	end process;
--

	--	process--TX
--	begin
--		wait until rising_edge(rmii_clk);
--
--		if tx_sel = '0' then
--			rmii_txen <= mii_txen;
--			if mii_txen = '1' then
--				rmii_txdata <= mii_txdata(1 downto 0);
--				tx_sel      <= '1';
--			end if;
--		else
--			rmii_txdata    <= mii_txdata(3 downto 2);
--			tx_sel         <= '0';
--		end if;
--	end process;

--	process
--	begin
--		wait until rising_edge(rmii_clk);
--		mii_clk <= clk2;
--		clk2    <= not clk2;
--	end process;
end beh;