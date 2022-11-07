library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity placar is
    port (
        -- entradas
        clock               : in  std_logic;
        reset               : in  std_logic;
		atualiza_placar     : in  std_logic;
		gol                 : in  std_logic;
        -- saidas
		gols_A              : out std_logic_vector(3 downto 0);
		gols_B              : out std_logic_vector(3 downto 0);
		rodada              : out std_logic_vector(3 downto 0);
		jogador             : out std_logic;
		ganhador            : out std_logic;
        fim_jogo            : out std_logic
    );
end entity;

architecture placar_arch of placar is

	component placar_jogador is
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
	end component;

	component comparador_n is
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
	end component;
	
	component subtractor_abs_n is
		generic (
			constant N : integer := 4
		);
		port (
			A      : in  std_logic_vector (N-1 downto 0);
			B      : in  std_logic_vector (N-1 downto 0);
			res    : out std_logic_vector (N-1 downto 0)
		);
	end component;
	
	component demux_1x2 is
		port (
			I : in std_logic;
			S : in std_logic;
			O : out std_logic_vector(1 downto 0)
		);
	end component;
	
	signal jogada_atual_A, jogada_atual_B       : std_logic_vector(3 downto 0);
	signal gols_atuais_A, gols_atuais_B         : std_logic_vector(3 downto 0);
	signal diferenca_entre_gols                 : std_logic_vector(3 downto 0);
	signal subtraendo_rodadas                   : std_logic_vector(3 downto 0);
	signal jogadas_restantes                    : std_logic_vector(3 downto 0);
	signal rodada_atual                         : std_logic_vector(3 downto 0);
	signal novos_gols                           : std_logic_vector(1 downto 0);
	signal atualiza_jogadas                     : std_logic_vector(1 downto 0);
	signal jogador_atual                        : std_logic;
	signal perdedor_atual                       : std_logic;
	signal empatado                             : std_logic;
	signal mata_a_mata                          : std_logic;
	signal fim_jogo_padrao, fim_jogo_mata_mata  : std_logic;

begin

    jogador_A: placar_jogador
			port map (
			clock           => clock,
            reset           => reset,
            atualiza_jogada => atualiza_jogadas(0),
            novo_gol        => novos_gols(0),
            jogada_atual    => jogada_atual_A,
            gols            => gols_atuais_A
		);
			
			
    jogador_B: placar_jogador
			port map (
			clock           => clock,
            reset           => reset,
            atualiza_jogada => atualiza_jogadas(1),
            novo_gol        => novos_gols(1),
            jogada_atual    => jogada_atual_B,
            gols            => gols_atuais_B
		);
	 
	subtractor_diff_gols: subtractor_abs_n
		generic map (
			N => 4
		) port map (
			A => gols_atuais_A,
			B => gols_atuais_B,
			res => diferenca_entre_gols
		);
	 
	 
	 subtractor_jogadas: subtractor_abs_n
		generic map (
			N => 4
		) port map (
			A => "0101",
			B => subtraendo_rodadas,
			res => jogadas_restantes
		);
		
	with perdedor_atual select
		subtraendo_rodadas <= jogada_atual_B when '1',
							  jogada_atual_A when others;
			
			
	comparador_perdedor_atual: comparador_n
		generic map (
			N => 4
		  )
        port map (
            A   => gols_atuais_A,
            B   => gols_atuais_B,
            A_gt_B   => perdedor_atual,
            A_lt_B   => ganhador,
            A_eq_B   => empatado
        );
		  
		  
	comparador_mata_a_mata: comparador_n
		generic map (
			N => 4
		)
        port map (
        	A   => jogada_atual_A,
            B   => "0101",
            A_gt_B   => mata_a_mata,
            A_lt_B   => open,
            A_eq_B   => open
        );
		  
		  
	comparador_fim_jogo_padrao: comparador_n
		generic map (
			N => 4
		)
        port map (
            A   => diferenca_entre_gols,
            B   => jogadas_restantes,
            A_gt_B   => fim_jogo_padrao,
            A_lt_B   => open,
            A_eq_B   => open
        );
		  
	demux_gol: demux_1x2
        port map (
            I   => gol,
            S   => jogador_atual,
            O   => novos_gols
        );
		  
	demux_rodada: demux_1x2
        port map (
            I   => atualiza_placar,
            S   => jogador_atual,
            O   => atualiza_jogadas
        );
		  
		  
	 -- sinais intermediarios
	jogador_atual <= jogada_atual_A(0) xor jogada_atual_B(0);
	fim_jogo_mata_mata <= not (empatado or jogador_atual);
	rodada_atual <= jogada_atual_A;
	 
	-- saidas
	gols_A  <= gols_atuais_A;
	gols_B  <= gols_atuais_B;
	rodada  <= rodada_atual;
	jogador <= jogador_atual;

	with mata_a_mata select
		fim_jogo <= fim_jogo_mata_mata when '1',
					fim_jogo_padrao when others;

end architecture;
