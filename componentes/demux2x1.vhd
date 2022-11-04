library ieee;
use ieee.std_logic_1164.all;
 
entity demux_1x2 is
	port(
		I : in std_logic;
		S : in std_logic;
		O : out std_logic_vector(1 downto 0)
	);
end demux_1x2;
 
architecture bhv of demux_1x2 is
begin
	process (I, S)
	begin
		O <= "00";
		
		case S is
			when '0' => O(0) <= I;
			when '1' => O(1) <= I;
		end case;
	end process;
end bhv;
