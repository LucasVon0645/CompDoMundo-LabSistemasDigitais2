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
        db_traco           : out std_logic;
        db_gols_A          : out std_logic_vector (6 downto 0);
        db_gols_B          : out std_logic_vector (6 downto 0);
        db_rodada          : out std_logic_vector (6 downto 0);
        db_ganhador        : out std_logic_vector (6 downto 0);
        db_estado          : out std_logic_vector (6 downto 0)
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
            db_estado          : out std_logic_vector (3 downto 0)
        );
    end component;

    component construtor_displays is
        port (
            -- entradas
            gols_A             : in  std_logic_vector(3 downto 0);
            gols_B             : in  std_logic_vector(3 downto 0);
            rodada             : in  std_logic_vector(3 downto 0);
            estado_uc          : in  std_logic_vector(3 downto 0);
            fim_jogo           : in  std_logic;
            ganhador           : in  std_logic;
            -- saidas
            gols_A_display     : out std_logic_vector(6 downto 0);
            gols_B_display     : out std_logic_vector(6 downto 0);
            rodada_display     : out std_logic_vector(6 downto 0);
            estado_uc_display  : out std_logic_vector(6 downto 0);
            ganhador_display   : out std_logic_vector(6 downto 0);
            traco              : out std_logic
        );
    end component;
    
    component edge_detector is
        port (  
            clock     : in  std_logic;
            signal_in : in  std_logic;
            output    : out std_logic
        );
    end component;

    signal s_iniciar, s_bater_direita, s_bater_esquerda                : std_logic;
    signal s_trigger, s_echo                                           : std_logic;
    signal s_fim_jogo, s_jogador, s_ganhador                           : std_logic;
    signal s_gols_A, s_gols_B, s_rodada, s_estado_uc : std_logic_vector (3 downto 0);
  
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
            db_estado          => s_estado_uc
        );

    iniciar_detector: edge_detector
        port map (  
            clock     => clock,
            signal_in => iniciar,
            output    => s_iniciar
        );
    
    direita_detector: edge_detector
        port map (  
            clock     => clock,
            signal_in => bater_direita,
            output    => s_bater_direita
        );

    esquerda_detector: edge_detector
        port map (  
            clock     => clock,
            signal_in => bater_esquerda,
            output    => s_bater_esquerda
        );

    construtor_7seg: construtor_displays
        port map (
            -- entradas
            gols_A             => s_gols_A,
            gols_B             => s_gols_B,
            rodada             => s_rodada,
            estado_uc          => s_estado_uc,
            fim_jogo           => s_fim_jogo,
            ganhador           => s_ganhador,
            -- saidas
            gols_A_display     => db_gols_A,
            gols_B_display     => db_gols_B,
            rodada_display     => db_rodada,
            estado_uc_display  => db_estado,
            ganhador_display   => db_ganhador,
            traco              => db_traco -- puramente estetico
        );


    -- Sinais internos
    trigger <= s_trigger;
    s_echo  <= echo;

    -- Sinais de depuracao
    db_echo    <= s_echo;
    db_trigger <= s_trigger;

end architecture;