library ieee;
use ieee.std_logic_1164.all;

entity comparador_n is
    generic (
        constant N : integer := 4
    );
    port (
        A      : in  std_logic_vector (N-1 downto 0);
        B      : in  std_logic_vector (N-1 downto 0);
        A_gt_B : out std_logic;
        A_lt_B : out std_logic;
        A_eq_B : out std_logic
    );
end entity comparador_n;

architecture dataflow of comparador_n is
begin
   process(A, B)
   begin
        if A > B then
            A_gt_B <= '1';
            A_lt_B <= '0';
            A_eq_B <= '0';
        elsif A = B then
            A_gt_B <= '0';
            A_lt_B <= '1';
            A_eq_B <= '0';
        else
            A_gt_B <= '0';
            A_lt_B <= '0';
            A_eq_B <= '1';
        end if;
   end process;
  
end architecture dataflow;