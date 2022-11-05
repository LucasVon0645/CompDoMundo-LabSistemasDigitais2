library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CompDoMundo is
    port (
        -- Entradas
        clock             : in  std_logic;
        restart           : in  std_logic;
        start             : in  std_logic;
        posicao_batedor   : in  std_logic;
		bater             : in  std_logic;
        echo              : in  std_logic;
		entrada_serial    : in  std_logic;
        -- Saidas
		pwm_goleiro       : out std_logic;
        pwm_batedor_esq   : out std_logic;
        pwm_batedor_dir   : out std_logic;
        trigger           : out std_logic;
        saida_serial      : out std_logic;
        -- Depuracao
		  db_ganhador       : out std_logic;
        db_estado         : out std_logic_vector(2 downto 0)
    );
end CompDoMundo;


architecture arch_comp_do_mundo of CompDoMundo is

    component placar is
        port (
            -- entradas
            clock               : in  std_logic;
            reset               : in  std_logic;
            atualiza_jogada     : in  std_logic;
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

    component batedor is
        port (
            clock        : in  std_logic;
            reset        : in  std_logic;
            habilitar    : in  std_logic;
            bater        : in  std_logic;
            direcao      : in  std_logic; -- 0: direita; 1: esquerda
            pwm_direita  : out std_logic;
            pwm_esquerda : out std_logic;
            bateu        : out std_logic;
            db_estado    : out std_logic
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
            db_estado : out std_logic_vector (3 downto 0)
        );
    end component;

    component goleiro is
        port (
            clock          : in  std_logic;
            reset          : in  std_logic;
            entrada_serial : in  std_logic;
            posicionar     : in  std_logic;
            pwm            : out std_logic;
            db_posicao     : out std_logic_vector (2 downto 0)
        );
    end component;

    component preparacao is
        port (
            clock : in  std_logic;
            reset : in  std_logic;
            conta : in  std_logic;
            fim   : out std_logic
        );
    end component;


    component super_transmissor is
        port (
            clock              : in std_logic;
            reset              : in std_logic;
            transmite          : in std_logic;
            transcode          : in  std_logic_vector(1 downto 0);
            gols_A             : in  std_logic_vector(3 downto 0);
            gols_B             : in  std_logic_vector(3 downto 0);
            rodada             : in  std_logic_vector(3 downto 0);
            jogador            : in  std_logic;
            direcao_batedor    : in  std_logic;
            saida_serial       : out std_logic;
            fim_transmissao    : out std_logic
        );
    end component;


    component penalti_uc is
        port ( 
            clock             : in  std_logic;
            reset             : in  std_logic;
            iniciar           : in  std_logic;
            fim_preparacao    : in  std_logic;
            bateu             : in  std_logic;
            fim_penalti       : in  std_logic;
            fim_jogo          : in  std_logic;
            fim_transmissao   : in  std_logic;
            reset_preparacao  : out std_logic;
            reset_goleiro     : out std_logic;
            reset_batedor     : out std_logic;
            reset_gol         : out std_logic;
            reset_placar      : out std_logic;
            reset_transmissor : out std_logic;
            conta_preparacao  : out std_logic;
            transmite         : out std_logic;
            habilita_batedor  : out std_logic;
            posiciona_goleiro : out std_logic;
            verifica_gol      : out std_logic;
            atualiza_placar   : out std_logic;
            atualiza_jogada   : out std_logic;
            transcode         : out std_logic_vector (1 downto 0);
            db_estado         : out std_logic_vector (2 downto 0)
        );
    end component;

    signal s_reset_preparacao, s_conta_preparacao, s_fim_preparacao : std_logic;
    signal s_reset_batedor, s_habilita_batedor, s_bateu             : std_logic;
    signal s_reset_placar, s_atualiza_jogada, s_atualiza_placar     : std_logic;
    signal s_reset_gol, s_gol, s_fim_jogo                           : std_logic;
    signal s_fim_penalti, s_verifica_gol                            : std_logic;
    signal s_reset_goleiro, s_posiciona_goleiro                     : std_logic;
    signal s_jogador                                                : std_logic;
    signal s_transmite, s_reset_transmissor, s_fim_transmissao      : std_logic;
    signal s_transcode                          : std_logic_vector (1 downto 0);
    signal s_gols_A, s_gols_B, s_rodada         : std_logic_vector (3 downto 0);
  
begin

    UC: penalti_uc
    port map (
        clock             => clock,
        reset             => restart,
        iniciar           => start,
        fim_preparacao    => s_fim_preparacao,
        bateu             => s_bateu,
        fim_penalti       => s_fim_penalti,
        fim_jogo          => s_fim_jogo,
        fim_transmissao   => s_fim_transmissao,
        reset_preparacao  => s_reset_preparacao,
        reset_goleiro     => s_reset_goleiro,
        reset_batedor     => s_reset_batedor,
        reset_gol         => s_reset_gol,
        reset_placar      => s_reset_placar,
        reset_transmissor => s_reset_transmissor,
        conta_preparacao  => s_conta_preparacao,
        transmite         => s_transmite,
        habilita_batedor  => s_habilita_batedor,
        posiciona_goleiro => s_posiciona_goleiro,
        verifica_gol      => s_verifica_gol,
        atualiza_placar   => s_atualiza_placar,
        atualiza_jogada   => s_atualiza_jogada,
        transcode         => s_transcode,
        db_estado         => db_estado
    );

    timer_preparacao: preparacao
    port map (
        clock => clock,
        reset => s_reset_preparacao,
        conta => s_conta_preparacao,
        fim   => s_fim_preparacao
    );

    cobrador: batedor port map (
        clock        => clock,
        reset        => s_reset_batedor,
        habilitar    => s_habilita_batedor,
        bater        => bater,
        direcao      => posicao_batedor, -- 0: direita; 1: esquerda
        pwm_direita  => pwm_batedor_dir,
        pwm_esquerda => pwm_batedor_esq,
        bateu        => s_bateu,
        db_estado    => open
    );

    placar_info: placar port map (
        clock             => clock,
        reset             => s_reset_placar,
        atualiza_jogada   => s_atualiza_jogada,
        atualiza_placar   => s_atualiza_placar,
        gol               => s_gol,
        gols_A            => s_gols_A,
        gols_B            => s_gols_B,
        rodada            => s_rodada,
        jogador           => s_jogador,
        ganhador          => db_ganhador,
        fim_jogo          => s_fim_jogo
    );

    gol: detector_gol port map (
        clock      => clock,
        reset      => s_reset_gol,
        echo       => echo,
        verificar  => s_verifica_gol,
        gol        => s_gol,
        pronto     => s_fim_penalti,
        trigger    => trigger,
        db_estado  => open
    );

    defensor: goleiro port map (
        clock           => clock,
        reset           => s_reset_goleiro,
        entrada_serial  => entrada_serial,
        posicionar      => s_posiciona_goleiro,
        pwm             => pwm_goleiro,
        db_posicao      => open
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
            direcao_batedor  => posicao_batedor,
            saida_serial     => saida_serial,
            fim_transmissao  => s_fim_transmissao
        );
  
end architecture;