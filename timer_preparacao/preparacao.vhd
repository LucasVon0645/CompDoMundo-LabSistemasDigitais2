library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity preparacao is
    port (
        clock : in  std_logic;
        reset : in  std_logic;
        conta : in  std_logic;
        fim   : out std_logic
    );
end entity preparacao;

architecture preparacao_arch of preparacao is

	component contador_m is
		generic (
			constant M : integer := 50;  
			constant N : integer := 6 
		);
		port (
			clock : in  std_logic;
			zera  : in  std_logic;
			conta : in  std_logic;
			Q     : out std_logic_vector (N-1 downto 0);
			fim   : out std_logic;
			meio  : out std_logic
		);
	end component;

begin
  
	timer: contador_m generic map (
        -- M => 100000000, -- 2 seg (experimento pratico)
        M => 1000, -- 20 usegs (simulacao testbench)
		N => 27
	) port map (
		clock => clock,
		zera  => reset,
		conta => conta,
		Q     => open,
		fim   => fim,
		meio  => open
	);
	
    
end architecture;