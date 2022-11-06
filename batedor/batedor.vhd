library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity batedor is
    port (
        clock        : in  std_logic;
        reset        : in  std_logic;
        habilitar    : in  std_logic;
        bater        : in  std_logic;
        direcao      : in  std_logic; -- 0: direita; 1: esquerda
        pwm_direita  : out std_logic;
		pwm_esquerda : out std_logic;
        db_estado    : out std_logic
    );
end batedor;


architecture arch_batedor of batedor is

    component batedor_fd is
        port (
            clock        : in  std_logic;
            reset        : in  std_logic;
            habilitar    : in  std_logic;
            bater        : in  std_logic;
            direcao      : in  std_logic; -- 0: direita; 1: esquerda
            posicao      : in  std_logic_vector (2 downto 0);
            zera_timer   : in  std_logic;
            conta_timer  : in  std_logic;
            pwm_direita  : out std_logic;
            pwm_esquerda : out std_logic;
            fim_timer    : out std_logic
        );
    end component;

    component batedor_uc is
        port ( 
            clock       : in  std_logic;
            reset       : in  std_logic;
            bater       : in  std_logic;
            fim_timer   : in  std_logic;
            zera_timer  : out std_logic;
            conta_timer : out std_logic;
            posicao     : out std_logic_vector (2 downto 0);
            db_estado   : out std_logic
        );
    end component;

    signal s_zera_timer, s_conta_timer, s_fim_timer : std_logic;
    signal s_posicao : std_logic_vector (2 downto 0);
  
begin

    FD: batedor_fd
    port map (
        clock        => clock,
        reset        => reset,
        habilitar    => habilitar,
        bater        => bater,
        direcao      => direcao,
        posicao      => s_posicao,
        zera_timer   => s_zera_timer,
        conta_timer  => s_conta_timer,
        pwm_direita  => pwm_direita,
        pwm_esquerda => pwm_esquerda,
        fim_timer    => s_fim_timer
    );

    UC: batedor_uc
    port map (
        clock       => clock,
        reset       => reset,
        bater       => bater,
        fim_timer   => s_fim_timer,
        zera_timer  => s_zera_timer,
        conta_timer => s_conta_timer,
        posicao     => s_posicao,
        db_estado   => db_estado
    );
  
end architecture;