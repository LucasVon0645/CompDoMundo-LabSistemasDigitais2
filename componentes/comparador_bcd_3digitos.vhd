library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comparador_bcd_3digitos is
    port (
        bcd_1 : in  std_logic_vector(11 downto 0);
        bcd_2 : in  std_logic_vector(11 downto 0);
        menor  : out std_logic;
        igual  : out std_logic;
        maior  : out std_logic
    );
end entity comparador_bcd_3digitos;

architecture arch of comparador_bcd_3digitos is

    signal s_d1_dig2, s_d1_dig1, s_d1_dig0 : unsigned(3 downto 0);
    signal s_d2_dig2, s_d2_dig1, s_d2_dig0 : unsigned(3 downto 0);
    signal s_menor, s_igual                : std_logic;

begin

    s_d1_dig2 <= unsigned(bcd_1(11 downto 8));
    s_d1_dig1 <= unsigned(bcd_1(7 downto 4));
    s_d1_dig0 <= unsigned(bcd_1(3 downto 0));

    s_d2_dig2 <= unsigned(bcd_2(11 downto 8));
    s_d2_dig1 <= unsigned(bcd_2(7 downto 4));
    s_d2_dig0 <= unsigned(bcd_2(3 downto 0));

    s_menor <= '1' when (s_d1_dig2 < s_d2_dig2) else
               '1' when (s_d1_dig2 = s_d2_dig2 and s_d1_dig1 < s_d2_dig1) else
               '1' when (s_d1_dig2 = s_d2_dig2 and s_d1_dig1 = s_d2_dig1 and s_d1_dig0 < s_d2_dig0) else
               '0';
    
    s_igual <= '1' when (s_d1_dig2 = s_d2_dig2 and s_d1_dig1 = s_d2_dig1 and s_d1_dig0 = s_d2_dig0) else
               '0';

    menor <= s_menor;
    igual <= s_igual;
    maior <= not (s_menor or s_igual);

end architecture;