library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity batedor is
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
end batedor;


architecture arch_batedor of batedor is

    component batedor_fd is
        port (
            clock            : in  std_logic;
            reset            : in  std_logic;
            bater_direita    : in  std_logic;
            bater_esquerda   : in  std_logic;
            posicao_direita  : in  std_logic_vector (2 downto 0);
            posicao_esquerda : in  std_logic_vector (2 downto 0);
            zera_timer       : in  std_logic;
            conta_timer      : in  std_logic;
            bateu            : out std_logic;
            direcao          : out std_logic;
            pwm_direita      : out std_logic;
            pwm_esquerda     : out std_logic;
            fim_timer        : out std_logic
        );
    end component;

    component batedor_uc is
        port ( 
            clock            : in  std_logic;
            reset            : in  std_logic;
            direcao          : in  std_logic;
            habilitar        : in  std_logic;
            fim_timer        : in  std_logic;
            posicao_direita  : out  std_logic_vector (2 downto 0);
            posicao_esquerda : out  std_logic_vector (2 downto 0);
            zera_timer       : out std_logic;
            conta_timer      : out std_logic;
            db_estado        : out std_logic_vector (1 downto 0)
        );
    end component;

    signal s_direcao                                : std_logic;
    signal s_zera_timer, s_conta_timer, s_fim_timer : std_logic;
    signal s_posicao_direita, s_posicao_esquerda    : std_logic_vector (2 downto 0);
  
begin

    FD: batedor_fd
    port map (
        clock            => clock,
        reset            => reset,
        bater_direita    => bater_direita,
        bater_esquerda   => bater_esquerda,
        posicao_direita  => s_posicao_direita,
        posicao_esquerda => s_posicao_esquerda,
        zera_timer       => s_zera_timer,
        conta_timer      => s_conta_timer,
        bateu            => bateu,
        direcao          => s_direcao,
        pwm_direita      => pwm_direita,
        pwm_esquerda     => pwm_esquerda,
        fim_timer        => s_fim_timer
    );

    UC: batedor_uc
    port map (
        clock            => clock,
        reset            => reset,
        direcao          => s_direcao,
        habilitar        => habilitar,
        fim_timer        => s_fim_timer,
        posicao_direita  => s_posicao_direita,
        posicao_esquerda => s_posicao_esquerda,
        zera_timer       => s_zera_timer,
        conta_timer      => s_conta_timer,
        db_estado        => db_estado
    );

    -- Saidas
    direcao <= s_direcao;
  
end architecture;