library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity batedor_fd is
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
    
    component registrador_n
        generic (
            constant N: integer
        );
        port (
            clock  : in  std_logic;
            clear  : in  std_logic;
            enable : in  std_logic;
            D      : in  std_logic_vector (N-1 downto 0);
            Q      : out std_logic_vector (N-1 downto 0)
        );
    end component;


    signal s_pwm_direita, s_pwm_esquerda : std_logic;
    signal s_direcao_vector              : std_logic_vector(0 downto 0);
  
begin

    servomotor_direita: controle_servo
        port map (
            clock      => clock,
            reset      => reset,
            posicao    => posicao_direita,
            pwm        => pwm_direita,
            db_reset   => open,
            db_pwm     => open,
            db_posicao => open
        );

    servomotor_esquerda: controle_servo
        port map (
            clock      => clock,
            reset      => reset,
            posicao    => posicao_esquerda,
            pwm        => pwm_esquerda,
            db_reset   => open,
            db_pwm     => open,
            db_posicao => open
        );

    timer: contador_m
        generic map (
            M => 100000000, -- 2 seg (experimento pratico)
            -- M => 1000, -- 20 usegs (simulacao testbench)
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


    reg_direcao: registrador_n
        generic map (
            N => 1
        )
        port map (
            clock  => clock,
            clear  => bater_direita,
            enable => bater_esquerda,
            D      => "1",
            Q      => s_direcao_vector
        );

        -- Saidas
        bateu   <= bater_direita or bater_esquerda;
        direcao <= s_direcao_vector(0);
  
end architecture;