library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comparador_dist_bcd is
    port (
        dist_1 : in  std_logic_vector(11 downto 0);
		dist_2 : in  std_logic_vector(11 downto 0);
		menor  : out std_logic;
		igual  : out std_logic
    );
end entity comparador_dist_bcd;

architecture arch of comparador_dist_bcd is
    signal s_d1_dig2, s_d1_dig1, s_d1_dig0 : unsigned(3 downto 0);
    signal s_d2_dig2, s_d2_dig1, s_d2_dig0 : unsigned(3 downto 0);
begin
    s_d1_dig2 <= unsigned(dist_1(11 downto 8));
    s_d1_dig1 <= unsigned(dist_1(7 downto 4));
    s_d1_dig0 <= unsigned(dist_1(3 downto 0));

    s_d2_dig2 <= unsigned(dist_2(11 downto 8));
    s_d2_dig1 <= unsigned(dist_2(7 downto 4));
    s_d2_dig0 <= unsigned(dist_2(3 downto 0));

    menor <= '1' when s_d1_dig2 < s_d2_dig2 else
             '1' when (s_d1_dig2 = s_d2_dig2 and s_d1_dig1 < s_d2_dig1) else
             '1' when (s_d1_dig2 = s_d2_dig2 and s_d1_dig1 = s_d2_dig1 and s_d1_dig0 < s_d2_dig0) else
             '0';
    
    igual <= '1' when (s_d1_dig2 = s_d2_dig2 and s_d1_dig1 = s_d2_dig1 and s_d1_dig0 = s_d2_dig0) else
             '0';
            
end arch ; -- arch