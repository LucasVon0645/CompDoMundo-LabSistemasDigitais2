library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity detector_gol is
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
end entity;

architecture arch of detector_gol is

    component detector_gol_fd is
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
    end component;

    component detector_gol_uc is
        port ( 
            clock               : in  std_logic;
            reset               : in  std_logic;
            verificar           : in  std_logic;
            distancia_menor     : in  std_logic;
            pronto_med          : in  std_logic;
            fim_timer_medicao   : in  std_logic;
            fim_timeout         : in  std_logic;
            mensurar            : out std_logic;
            zera_interface      : out std_logic;
            zera_timeout        : out std_logic;
            zera_timer_medicao  : out std_logic;
            pronto              : out std_logic;
            gol                 : out std_logic;
            db_estado           : out std_logic_vector(3 downto 0)
        );
    end component;

    signal s_mensurar, s_zera_interface, s_zera_timeout, s_zera_timer_medicao: std_logic;
    signal s_distancia_menor, s_pronto_med, s_fim_timer_medicao, s_fim_timeout: std_logic;
    
    begin

        FD_detector_gol: detector_gol_fd
        port map (
            clock               => clock,
            reset               => reset,
            mensurar            => s_mensurar,
            zera_interface      => s_zera_interface,
            zera_timeout        => s_zera_timeout,
            zera_timer_medicao  => s_zera_timer_medicao,
            echo                => echo,
            trigger             => trigger,
            distancia_menor     => s_distancia_menor,
            pronto_med          => s_pronto_med,
            fim_timer_medicao   => s_fim_timer_medicao,
            fim_timeout         => s_fim_timeout
        );

        UC_detector_gol: detector_gol_uc
        port map (
            clock               => clock,
            reset               => reset,
            verificar           => verificar,
            distancia_menor     => s_distancia_menor,
            pronto_med          => s_pronto_med,
            fim_timer_medicao   => s_fim_timer_medicao,
            fim_timeout         => s_fim_timeout,
            mensurar            => s_mensurar,
            zera_interface      => s_zera_interface,
            zera_timeout        => s_zera_timeout,
            zera_timer_medicao  => s_zera_timer_medicao,
            pronto              => pronto,
            gol                 => gol,
            db_estado           => db_estado
        );
    
end architecture arch;