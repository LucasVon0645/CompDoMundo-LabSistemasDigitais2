library ieee;
use ieee.std_logic_1164.all;

entity hex2ascii is
    port(
        hex    : in  std_logic_vector (3 downto 0);
        ascii  : out std_logic_vector (6 downto 0)
    );
end entity;

architecture comportamental of hex2ascii is
begin
    with hex select 
        ascii <= "1000001"    when "1010",
                 "1000010"    when "1011",
                 "1000011"    when "1100",
                 "1000100"    when "1101",
                 "1000101"    when "1110",
                 "1000110"    when "1111",
                 "011" & hex  when others;
end architecture comportamental;