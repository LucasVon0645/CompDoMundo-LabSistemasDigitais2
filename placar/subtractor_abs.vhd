library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity subtractor_abs_n is
  generic (
    constant N : integer := 4
  );
  port (
    A      : in  std_logic_vector (N-1 downto 0);
	 B      : in  std_logic_vector (N-1 downto 0);
    res    : out std_logic_vector (N-1 downto 0)
  );
end entity subtractor_abs_n;

architecture dataflow of subtractor_abs_n is
	signal abs_diff : signed(N downto 0);

begin

	abs_diff <=  abs(signed('0' & A) - signed('0' & B));
	res      <=  std_logic_vector(abs_diff(N-1 downto 0));
  
end architecture dataflow;