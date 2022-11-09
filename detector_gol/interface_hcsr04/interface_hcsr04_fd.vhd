library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity interface_hcsr04_fd is
    port (
        clock      : in  std_logic;
        reset      : in  std_logic;
        pulso      : in  std_logic;
        zera       : in  std_logic;
        registra   : in  std_logic;
        gera       : in  std_logic;
        distancia  : out std_logic_vector(11 downto 0);
        fim_medida : out std_logic;
        trigger    : out std_logic
    );
end entity;

architecture interface_hcsr04_fd_arch of interface_hcsr04_fd is

    component registrador_n is
        generic (
            constant N: integer := 8 
        );
        port (
            clock  : in  std_logic;
            clear  : in  std_logic;
            enable : in  std_logic;
            D      : in  std_logic_vector (N-1 downto 0);
            Q      : out std_logic_vector (N-1 downto 0) 
        );
    end component;
     
    component gerador_pulso is
        generic (
            largura: integer:= 25
        );
        port(
            clock  : in  std_logic;
            reset  : in  std_logic;
            gera   : in  std_logic;
            para   : in  std_logic;
            pulso  : out std_logic;
            pronto : out std_logic
        );
    end component;

    component contador_cm is
        port (
            clock        : in  std_logic;
            reset        : in  std_logic;
            pulso        : in  std_logic;
            digito0      : out std_logic_vector(3 downto 0);
            digito1      : out std_logic_vector(3 downto 0);
            digito2      : out std_logic_vector(3 downto 0);
            fim          : out std_logic;
            pronto       : out std_logic;
            db_estado_cm : out std_logic_vector (2 downto 0)
        );
    end component;

    signal s_fim, s_pronto, s_clear        : std_logic;
    signal s_digitos_concatenados        : std_logic_vector(11 downto 0);

begin

    contador_distancia: contador_cm
        port map (
            clock        => clock,
            reset        => zera,
            pulso        => pulso,
            digito0      => s_digitos_concatenados(3 downto 0),
            digito1      => s_digitos_concatenados(7 downto 4),
            digito2      => s_digitos_concatenados(11 downto 8),
            fim          => s_fim,
            pronto       => s_pronto,
            db_estado_cm => open
        );
        
    reg: registrador_n
            generic map (
                  N => 12
            )
        port map (
            clock  => clock,
            enable => registra,
            clear  => s_clear,
            D      => s_digitos_concatenados,
            Q      => distancia
        );

    gera_pulso: gerador_pulso
        generic map (
            largura => 500
        )
        port map (
            clock  => clock,
            reset  => zera,
            gera   => gera,
            para   => '0',
            pronto => open,
            pulso  => trigger
        );
        
     -- saida combinatoria
    fim_medida <= s_fim or s_pronto;
    s_clear <= zera or reset;

end architecture;