library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_serial_7E2_fd is
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
end entity;

architecture rx_serial_7E2_fd_arch of rx_serial_7E2_fd is

    component deslocador_n
      generic (
          constant N : integer
      );
      port (
          clock          : in  std_logic;
          reset          : in  std_logic;
          carrega        : in  std_logic;
          desloca        : in  std_logic;
          entrada_serial : in  std_logic;
          dados          : in  std_logic_vector (N-1 downto 0);
          saida          : out std_logic_vector (N-1 downto 0)
      );
    end component;

    component contador_m
      generic (
          constant M : integer;
          constant N : integer
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

    component testador_paridade
      port (
              dado     : in  std_logic_vector (6 downto 0);
              paridade : in  std_logic;
              par_ok   : out std_logic;
              impar_ok : out std_logic
        );
    end component;

    signal s_dados: std_logic_vector (10 downto 0);
      signal s_dado_armazenado, s_dados_reg: std_logic_vector (8 downto 0);
      signal s_paridade_ok: std_logic;

begin

    U1: deslocador_n
      generic map (
          N => 11
      )
      port map (
          clock          => clock,
          reset          => reset,
          carrega        => carrega,
          desloca        => desloca,
          entrada_serial => dados_serial,
          dados          => (others => '1'),
          saida          => s_dados
      );

    U2: contador_m
      generic map (
          M => 12,
          N => 4
      )
      port map (
          clock => clock,
          zera  => zera,
          conta => conta,
          Q     => open,
          fim   => fim,
                  meio  => open
      );

    U3: registrador_n
      generic map (
          N => 9
      )
      port map (
          clock  => clock,
          clear  => limpa,
                  enable => registra,
                  D      => s_dados_reg,
          Q      => s_dado_armazenado
      );

    U4: testador_paridade
      port map (
          dado     => s_dados(7 downto 1),
                paridade => s_dados(8),
                par_ok   => s_paridade_ok,
                impar_ok => open
      );

    -- Entrada de dados do registrador N
    s_dados_reg <= s_paridade_ok & s_dados(8 downto 1);

    -- saidas
      dado_recebido     <= s_dado_armazenado(6 downto 0);
      paridade_recebida <= s_dado_armazenado(7);
      paridade_ok       <= s_dado_armazenado(8);

end architecture;
