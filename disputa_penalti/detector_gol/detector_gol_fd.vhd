library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity detector_gol_fd is
    port (
        clock               : in  std_logic;
        reset               : in  std_logic;
        mensurar            : in  std_logic;
        zera_interface      : in  std_logic;
        zera_timeout        : in  std_logic;
        zera_timer_medicao  : in  std_logic;
        echo                : in  std_logic;
        trigger             : out std_logic;
        distancia_menor     : out std_logic;
        pronto_med          : out std_logic;
        fim_timer_medicao   : out std_logic;
        fim_timeout         : out std_logic
    );
end entity;

architecture arch of detector_gol_fd is

    component interface_hcsr04 is
        port (
            clock     : in  std_logic;
            reset     : in  std_logic;
            echo      : in  std_logic;
            medir     : in  std_logic;
            medida    : out std_logic_vector(11 downto 0);
            pronto    : out std_logic;
            trigger   : out std_logic;
            db_reset  : out std_logic;
            db_medir  : out std_logic;
            db_estado : out std_logic_vector (3 downto 0)
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

    component comparador_dist_bcd is
        port (
            dist_1 : in  std_logic_vector(11 downto 0);
            dist_2 : in  std_logic_vector(11 downto 0);
            menor  : out std_logic;
            igual  : out std_logic
        );
    end component;
     
     signal s_zera_interface : std_logic;
     signal s_medida : std_logic_vector(11 downto 0);

begin

    interface: interface_hcsr04
    port map (
        clock     => clock,
        reset     => s_zera_interface,
        echo      => echo,
        medir     => mensurar,
        medida    => s_medida,
        pronto    => pronto_med,
        trigger   => trigger,
        db_reset  => open,
        db_medir  => open,
        db_estado => open
    );
    
    timer_medicao: contador_m
        generic map (
            M => 10000000, -- 200 mseg (experimento pratico)
            -- M => 200000, -- 400 useg (simulacao testbench)
            N => 27
        )
        port map (
            clock => clock,
            zera  => zera_timer_medicao,
            conta => '1',
            Q     => open,
            fim   => fim_timer_medicao,
            meio  => open
        );

    timeout: contador_m
    generic map (
        M => 100000000, -- 2 seg (experimento pratico)
        -- M => 600000, -- 1.2 mseg (simulacao testbench)
        N => 27
    )
    port map (
        clock => clock,
        zera  => zera_timeout,
        conta => '1',
        Q     => open,
        fim   => fim_timeout,
        meio  => open
    );

    comparador_gol: comparador_dist_bcd
    port map (
        dist_1 => s_medida,
        dist_2 => "000000001010", -- 10 cm 
        menor  => distancia_menor,
        igual  => open
    );

    s_zera_interface <= reset or zera_interface;
    
end architecture arch;