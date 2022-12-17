library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comp_do_mundo is
    port (
        -- entradas
        clock              : in  std_logic;
        reset              : in  std_logic;
        iniciar            : in  std_logic;
        bater_direita      : in  std_logic;
        bater_esquerda     : in  std_logic;
        echo               : in  std_logic;
        entrada_serial     : in  std_logic;
		config_displays    : in  std_logic;
        -- saidas
        pwm_goleiro        : out std_logic;
        pwm_batedor_dir    : out std_logic;
        pwm_batedor_esq    : out std_logic;
        trigger            : out std_logic;
        saida_serial       : out std_logic;
        -- depuracao
        db_fim_preparacao  : out std_logic;
        db_fim_transmissao : out std_logic;
        db_trigger         : out std_logic;
        db_echo            : out std_logic;
        hex0               : out std_logic_vector (6 downto 0);
        hex1               : out std_logic_vector (6 downto 0);
        hex2               : out std_logic_vector (6 downto 0);
        hex3               : out std_logic_vector (6 downto 0);
        hex4               : out std_logic_vector (6 downto 0);
		hex5               : out std_logic_vector (6 downto 0)
    );
end entity;


architecture arch_comp_do_mundo of comp_do_mundo is

    component disputa_penalti is
        port (
            -- entradas
            clock              : in  std_logic;
            reset              : in  std_logic;
            iniciar            : in  std_logic;
            bater_direita      : in  std_logic;
            bater_esquerda     : in  std_logic;
            echo               : in  std_logic;
            entrada_serial     : in  std_logic;
            -- saidas
            pwm_goleiro        : out std_logic;
            pwm_batedor_dir    : out std_logic;
            pwm_batedor_esq    : out std_logic;
            trigger            : out std_logic;
            saida_serial       : out std_logic;
            -- depuracao
            db_fim_preparacao  : out std_logic;
            db_fim_transmissao : out std_logic;
            db_fim_jogo        : out std_logic;
            db_ganhador        : out std_logic;
            db_gols_A          : out std_logic_vector (3 downto 0);
            db_gols_B          : out std_logic_vector (3 downto 0);
            db_rodada          : out std_logic_vector (3 downto 0);
            db_estado_uc       : out std_logic_vector (3 downto 0);
			db_distancia       : out std_logic_vector (11 downto 0);
			db_estado_detector : out std_logic_vector (3 downto 0)
        );
    end component;
	 
	 component construtor_displays is
        port (
		    -- selecao
			config_displays    : in  std_logic;
			-- entradas de debug (config = 0)
			gols_A             : in  std_logic_vector(3 downto 0);
			gols_B             : in  std_logic_vector(3 downto 0);
			rodada             : in  std_logic_vector(3 downto 0);
			estado_uc          : in  std_logic_vector(3 downto 0);
			fim_jogo           : in  std_logic;
			ganhador           : in  std_logic;
			-- entradas de debug (config = 1)
			distancia          : in  std_logic_vector (11 downto 0);
			detector_gol_uc    : in  std_logic_vector (3 downto 0);
			-- displays
			hex0               : out std_logic_vector (6 downto 0);
			hex1               : out std_logic_vector (6 downto 0);
			hex2               : out std_logic_vector (6 downto 0);
			hex3               : out std_logic_vector (6 downto 0);
			hex4               : out std_logic_vector (6 downto 0);
			hex5               : out std_logic_vector (6 downto 0)
	     );
	 end component;
    
    component edge_detector is
        port (  
            clock     : in  std_logic;
            signal_in : in  std_logic;
            output    : out std_logic
        );
    end component;

    signal s_not_iniciar, s_not_bater_direita, s_not_bater_esquerda    : std_logic;
    signal s_iniciar, s_bater_direita, s_bater_esquerda                : std_logic;
    signal s_trigger, s_echo                                           : std_logic;
    signal s_fim_jogo, s_jogador, s_ganhador                           : std_logic;
    signal s_gols_A, s_gols_B, s_rodada, s_estado_uc : std_logic_vector (3 downto 0);
	signal s_db_estado_detector                      : std_logic_vector (3 downto 0);
	signal s_db_distancia                            : std_logic_vector (11 downto 0);
  
begin

    disputa: disputa_penalti
        port map (
            -- entradas
            clock              => clock,
            reset              => reset,
            iniciar            => s_iniciar,
            bater_direita      => s_bater_direita,
            bater_esquerda     => s_bater_esquerda,
            echo               => s_echo,
            entrada_serial     => entrada_serial,
            -- saidas
            pwm_goleiro        => pwm_goleiro,
            pwm_batedor_dir    => pwm_batedor_dir,
            pwm_batedor_esq    => pwm_batedor_esq,
            trigger            => s_trigger,
            saida_serial       => saida_serial,
            -- depuracao
            db_fim_preparacao  => db_fim_preparacao,
            db_fim_transmissao => db_fim_transmissao,
            db_fim_jogo        => s_fim_jogo,
            db_ganhador        => s_ganhador,
            db_gols_A          => s_gols_A,
            db_gols_B          => s_gols_B,
            db_rodada          => s_rodada,
            db_estado_uc       => s_estado_uc,
			db_distancia       => s_db_distancia,
			db_estado_detector => s_db_estado_detector
        );

    iniciar_detector: edge_detector
        port map (  
            clock     => clock,
            signal_in => s_not_iniciar,
            output    => s_iniciar
        );
    
    direita_detector: edge_detector
        port map (  
            clock     => clock,
            signal_in => s_not_bater_direita,
            output    => s_bater_direita
        );

    esquerda_detector: edge_detector
        port map (  
            clock     => clock,
            signal_in => s_not_bater_esquerda,
            output    => s_bater_esquerda
        );

	 construtor_7seg: construtor_displays
        port map (
		    -- selecao
			config_displays => config_displays,
			-- entradas de debug (config = 0)
			gols_A             => s_gols_A,
			gols_B             => s_gols_B,
			rodada             => s_rodada,
			estado_uc          => s_estado_uc,
			fim_jogo           => s_fim_jogo,
			ganhador           => s_ganhador,
			-- entradas de debug (config = 1)
			distancia          => s_db_distancia,
			detector_gol_uc    => s_db_estado_detector,
			-- displays
			hex0                => hex0,
			hex1                => hex1,
			hex2                => hex2,
			hex3                => hex3,
			hex4                => hex4,
			hex5                => hex5
	     );

    -- Pull up
    s_not_iniciar        <= not iniciar;
    s_not_bater_direita  <= not bater_direita;
    s_not_bater_esquerda <= not bater_esquerda;

    -- Sinais internos
    trigger <= s_trigger;
    s_echo  <= echo;

    -- Sinais de depuracao
    db_echo    <= s_echo;
    db_trigger <= s_trigger;

end architecture;