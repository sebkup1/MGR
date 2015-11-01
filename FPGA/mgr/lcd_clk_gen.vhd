
----------------------------------------------------------------------------------
-- University of Novi Sad
-- Faculty of Technical Sciences
--
-- Digital Systems Design
-- Lab 09
--
-- LCD clock generator
--
-- Author: Ivan Kastelan
-- ivan.kastelan@rt-rk.com
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lcd_clk_gen is
    Port ( iCLK : in  STD_LOGIC;
           inRST : in  STD_LOGIC;
           oCLK : out  STD_LOGIC;
           onRST : out  STD_LOGIC);
end lcd_clk_gen;

architecture Behavioral of lcd_clk_gen is

    signal sCLK_DIV : std_logic_vector(7 downto 0);
    signal snRST : std_logic;

begin

    process (iCLK, inRST) begin
        if (inRST = '0') then
            sCLK_DIV <= (others => '0');
        elsif (iCLK'event and iCLK = '1') then
            sCLK_DIV <= sCLK_DIV + 1;
        end if;
    end process;
    
    process (iCLK, inRST) begin
        if (inRST = '0') then
            snRST <= '0';
        elsif (iCLK'event and iCLK= '1') then
            if (sCLK_DIV(7) = '1') then
                snRST <= '1';
            end if;
        end if;
    end process;
    
    oCLK <= sCLK_DIV(7);   -- = iCLK/256 = 50000000/256 = 190937.5 Hz
    onRST <= snRST;

end Behavioral;
