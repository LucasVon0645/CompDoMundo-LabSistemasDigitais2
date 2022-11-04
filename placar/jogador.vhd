library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity jogador is
    port (
        -- entradas
        clock               : in  std_logic;
        reset               : in  std_logic;
		atualiza_jogada     : in  std_logic;
		novo_gol            : in  std_logic;
        -- saidas
		jogada_atual        : out std_logic_vector (3 downto 0);
        gols                : out std_logic_vector (3 downto 0)
    );
end entity;

architecture jogador_arch of jogador is

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


    contador_jogadas: contador_m
		  generic map (
				M => 16,
				N => 4
		  )
        port map (
            clock   => clock,
            zera    => reset,
            conta   => atualiza_jogada,
            Q       => jogada_atual,
            fim     => open,
            meio    => open
        );
		  
	 contador_gols: contador_m
		  generic map (
				M => 16,
				N => 4
		  )
        port map (
            clock   => clock,
            zera    => reset,
            conta   => novo_gol,
            Q       => gols,
            fim     => open,
            meio    => open
        );

end architecture;
