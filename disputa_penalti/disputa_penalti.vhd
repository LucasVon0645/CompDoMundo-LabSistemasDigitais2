library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity disputa_penalti is
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
end entity;


architecture arch_disputa_penalti of disputa_penalti is

    component preparacao is
        port (
            clock : in  std_logic;
            reset : in  std_logic;
            conta : in  std_logic;
            fim   : out std_logic
        );
    end component;

    component batedor is
        port (
            clock           : in  std_logic;
            reset           : in  std_logic;
            habilitar       : in  std_logic;
            bater_direita   : in  std_logic;
            bater_esquerda  : in  std_logic;
            bateu           : out std_logic;
            direcao         : out std_logic;
            pwm_direita     : out std_logic;
            pwm_esquerda    : out std_logic;
            db_estado       : out std_logic_vector (1 downto 0)
        );
    end component;

    component goleiro is
        port (
            clock          : in  std_logic;
            reset          : in  std_logic;
            entrada_serial : in  std_logic;
            posicionar     : in  std_logic;
            reposicionar   : in  std_logic;
            pwm            : out std_logic;
            db_posicao     : out std_logic_vector (2 downto 0)
        );
    end component;

    component detector_gol is
        port (
            clock     : in  std_logic;
            reset     : in  std_logic;
            echo      : in  std_logic;
            verificar : in  std_logic;
            gol       : out std_logic;
            pronto    : out std_logic;
            trigger   : out std_logic;
				db_medida : out std_logic_vector(11 downto 0);
            db_estado : out std_logic_vector (3 downto 0)
        );
    end component;

    component placar is
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
    end component;

    component super_transmissor is
        port (
            clock              : in std_logic;
            reset              : in std_logic;
            transmite          : in std_logic;
            transcode          : in  std_logic_vector(2 downto 0);
            gols_A             : in  std_logic_vector(3 downto 0);
            gols_B             : in  std_logic_vector(3 downto 0);
            rodada             : in  std_logic_vector(3 downto 0);
            jogador            : in  std_logic;
            direcao_batedor    : in  std_logic;
            saida_serial       : out std_logic;
            fim_transmissao    : out std_logic
        );
    end component;

    component unidade_controle is
        port ( 
            clock               : in  std_logic;
            reset               : in  std_logic;
            iniciar             : in  std_logic;
            bater               : in  std_logic;
            fim_preparacao      : in  std_logic;
            fim_penalti         : in  std_logic;
            fim_jogo            : in  std_logic;
            fim_transmissao     : in  std_logic;
            reset_preparacao    : out std_logic;
            reset_goleiro       : out std_logic;
            reset_batedor       : out std_logic;
            reset_gol           : out std_logic;
            reset_placar        : out std_logic;
            reset_transmissor   : out std_logic;
            conta_preparacao    : out std_logic;
            reposiciona_goleiro : out std_logic;
            transmite           : out std_logic;
            habilita_batedor    : out std_logic;
            posiciona_goleiro   : out std_logic;
            verifica_gol        : out std_logic;
            transcode           : out std_logic_vector (2 downto 0);
            db_estado           : out std_logic_vector (3 downto 0)
        );
    end component;

    signal s_reset_preparacao, s_conta_preparacao, s_fim_preparacao    : std_logic;
    signal s_reset_batedor, s_habilita_batedor, s_bateu, s_direcao     : std_logic;
    signal s_reset_placar, s_atualiza_jogada, s_atualiza_placar        : std_logic;
    signal s_reset_gol, s_gol, s_fim_jogo                              : std_logic;
    signal s_fim_penalti, s_verifica_gol                               : std_logic;
    signal s_reset_goleiro, s_posiciona_goleiro, s_reposiciona_goleiro : std_logic;
    signal s_jogador                                                   : std_logic;
    signal s_transmite, s_reset_transmissor, s_fim_transmissao         : std_logic;
    signal s_transcode                               : std_logic_vector (2 downto 0);
    signal s_gols_A, s_gols_B, s_rodada              : std_logic_vector (3 downto 0);
  
begin

    timer_preparacao: preparacao
        port map (
            clock => clock,
            reset => s_reset_preparacao,
            conta => s_conta_preparacao,
            fim   => s_fim_preparacao
        );

    cobrador: batedor
        port map (
            clock           => clock,
            reset           => s_reset_batedor,
            habilitar       => s_habilita_batedor,
            bater_direita   => bater_direita,
            bater_esquerda  => bater_esquerda,
            bateu           => s_bateu,
            direcao         => s_direcao,
            pwm_direita     => pwm_batedor_dir,
            pwm_esquerda    => pwm_batedor_esq,
            db_estado       => open
        );

    defensor: goleiro
        port map (
            clock           => clock,
            reset           => s_reset_goleiro,
            entrada_serial  => entrada_serial,
            posicionar      => s_posiciona_goleiro,
            reposicionar    => s_reposiciona_goleiro,
            pwm             => pwm_goleiro,
            db_posicao      => open
        );

    gol: detector_gol
        port map (
            clock      => clock,
            reset      => s_reset_gol,
            echo       => echo,
            verificar  => s_verifica_gol,
            gol        => s_gol,
            pronto     => s_fim_penalti,
            trigger    => trigger,
				db_medida  => db_distancia,
            db_estado  => db_estado_detector
        );

    placar_info: placar
        port map (
            clock             => clock,
            reset             => s_reset_placar,
            atualiza_placar   => s_fim_penalti,
            gol               => s_gol,
            gols_A            => s_gols_A,
            gols_B            => s_gols_B,
            rodada            => s_rodada,
            jogador           => s_jogador,
            ganhador          => db_ganhador,
            fim_jogo          => s_fim_jogo
        );

    transmissor: super_transmissor
        port map(
            clock            => clock,
            reset            => s_reset_transmissor,
            transmite        => s_transmite,
            transcode        => s_transcode,
            gols_A           => s_gols_A,
            gols_B           => s_gols_B,
            rodada           => s_rodada,
            jogador          => s_jogador,
            direcao_batedor  => s_direcao,
            saida_serial     => saida_serial,
            fim_transmissao  => s_fim_transmissao
        );

    UC: unidade_controle
        port map (
            clock               => clock,
            reset               => reset,
            iniciar             => iniciar,
            fim_preparacao      => s_fim_preparacao,
            bater               => s_bateu,
            fim_penalti         => s_fim_penalti,
            fim_jogo            => s_fim_jogo,
            fim_transmissao     => s_fim_transmissao,
            reset_preparacao    => s_reset_preparacao,
            reset_goleiro       => s_reset_goleiro,
            reset_batedor       => s_reset_batedor,
            reset_gol           => s_reset_gol,
            reset_placar        => s_reset_placar,
            reset_transmissor   => s_reset_transmissor,
            conta_preparacao    => s_conta_preparacao,
            reposiciona_goleiro => s_reposiciona_goleiro,
            transmite           => s_transmite,
            habilita_batedor    => s_habilita_batedor,
            posiciona_goleiro   => s_posiciona_goleiro,
            verifica_gol        => s_verifica_gol,
            transcode           => s_transcode,
            db_estado           => db_estado_uc
        );


    -- Sinais de depuracao
    db_fim_preparacao  <= s_fim_preparacao;
    db_fim_transmissao <= s_fim_transmissao;
    db_fim_jogo        <= s_fim_jogo;
    db_gols_A          <= s_gols_A;
    db_gols_B          <= s_gols_B;
    db_rodada          <= s_rodada;
  
end architecture;