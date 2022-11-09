library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_serial_7E2 is
    port (
        clock             : in  std_logic;
        reset             : in  std_logic;
        dado_serial       : in  std_logic;
        recebe_dado       : in  std_logic;
        dado_recebido     : out std_logic_vector (6 downto 0);
        tem_dado          : out std_logic;
        paridade_ok       : out std_logic;
        pronto            : out std_logic;
        db_dado_serial    : out std_logic;
        db_estado         : out std_logic_vector (3 downto 0)
    );
end entity;

architecture rx_serial_7E2_arch of rx_serial_7E2 is

    component rx_serial_uc
      port (
          clock       : in  std_logic;
          reset       : in  std_logic;
          dado_serial : in  std_logic;
             recebe_dado : in  std_logic;
          tick        : in  std_logic;
          fim         : in  std_logic;
          limpa       : out std_logic;
          carrega     : out std_logic;
          zera        : out std_logic;
          desloca     : out std_logic;
          conta       : out std_logic;
          registra    : out std_logic;
          pronto      : out std_logic;
          tem_dado    : out std_logic;
          db_estado   : out std_logic_vector (3 downto 0)
      );
    end component;

    component rx_serial_7E2_fd
        port (
            clock             : in  std_logic;
            reset             : in  std_logic;
            zera              : in  std_logic;
            limpa             : in  std_logic;
            conta             : in  std_logic;
            carrega           : in  std_logic;
            desloca           : in  std_logic;
            registra          : in  std_logic;
            dados_serial      : in  std_logic;
            dado_recebido     : out std_logic_vector (6 downto 0);
            paridade_recebida : out std_logic;
            paridade_ok       : out std_logic;
            fim               : out std_logic
        );
    end component;

    component contador_m
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

    signal s_tick_meio, s_fim: std_logic;
    signal s_limpa, s_carrega, s_zera, s_desloca, s_conta, s_registra: std_logic;
    signal s_dado_recebido: std_logic_vector(6 downto 0);


begin

    U1_UC: rx_serial_uc
        port map (
            clock       => clock,
            reset       => reset,
            dado_serial => dado_serial,
            recebe_dado => recebe_dado,
            tick        => s_tick_meio,
            fim         => s_fim,
            limpa       => s_limpa,
            carrega     => s_carrega,
            zera        => s_zera,
            desloca     => s_desloca,
            conta       => s_conta,
            registra    => s_registra,
            pronto      => pronto,
            tem_dado    => tem_dado,
            db_estado   => db_estado
        );

    U2_FD: rx_serial_7E2_fd
        port map (
            clock             => clock,
            reset             => reset,
            zera              => s_zera,
            limpa             => s_limpa,
            conta             => s_conta,
            carrega           => s_carrega,
            desloca           => s_desloca,
            registra          => s_registra,
            dados_serial      => dado_serial,
            dado_recebido     => dado_recebido,
            paridade_recebida => open,
            paridade_ok       => paridade_ok,
            fim               => s_fim
        );

    -- gerador de tick
    U3_TICK: contador_m
        generic map (
            M => 434, -- 115.200 bauds
            N => 9
        )
        port map (
            clock => clock,
            zera  => s_zera,
            conta => '1',
            Q     => open,
            fim   => open,
            meio  => s_tick_meio
        );
        
        db_dado_serial <= dado_serial;

end architecture;
