library ieee;
use ieee.std_logic_1164.all;

entity mux_2x1_n is
    generic (
        constant BITS: integer := 4
    );
    port( 
        D1      : in  std_logic_vector (BITS-1 downto 0);
        D0      : in  std_logic_vector (BITS-1 downto 0);
        SEL     : in  std_logic;
        MUX_OUT : out std_logic_vector (BITS-1 downto 0)
    );
end entity mux_2x1_n;

architecture arch_mux_2x1_n of mux_2x1_n is
begin

    MUX_OUT <= D1 when (SEL = '1') else
               D0 when (SEL = '0') else
               (others => '1');

end architecture arch_mux_2x1_n;
