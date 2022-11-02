library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity batedor_fd is
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
end batedor_fd;


architecture arch_batedor_fd of batedor_fd is

    component controle_servo is
        port (
            clock      : in  std_logic;
            reset      : in  std_logic;
            posicao    : in  std_logic_vector(2 downto 0);  
            pwm        : out std_logic;
            db_reset   : out std_logic;
            db_pwm     : out std_logic;
            db_posicao : out std_logic_vector(2 downto 0)  
        );
    end component;

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

    signal s_pwm_direita, s_pwm_esquerda : std_logic;
  
begin

    servomotor_direita: controle_servo
    port map (
        clock      => clock,
        reset      => reset,
        posicao    => posicao,
        pwm        => s_pwm_direita,
        db_reset   => open,
        db_pwm     => open,
        db_posicao => open
    );

    servomotor_esquerda: controle_servo
    port map (
        clock      => clock,
        reset      => reset,
        posicao    => posicao,
        pwm        => s_pwm_esquerda,
        db_reset   => open,
        db_pwm     => open,
        db_posicao => open
    );

    timer: contador_m
    generic map (
        M => 100000000,
        N => 27
    )
    port map (
        clock => clock,
        zera  => zera_timer,
        conta => conta_timer,
        Q     => open,
        fim   => fim_timer,
        meio  => open
    );

    pwm_direita  <= habilitar and not(direcao) and s_pwm_direita;
    pwm_esquerda <= habilitar and direcao      and s_pwm_esquerda;
  
end architecture;