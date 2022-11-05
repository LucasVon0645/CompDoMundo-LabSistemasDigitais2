library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx_serial_7E2 is
    port (
        clock            : in  std_logic;
        reset            : in  std_logic;
        partida          : in  std_logic;
        dados_ascii      : in  std_logic_vector (6 downto 0);
        saida_serial     : out std_logic;
        pronto           : out std_logic;
        db_partida       : out std_logic;
        db_saida_serial  : out std_logic;
        db_estado        : out std_logic_vector (3 downto 0)
    );
end entity;

architecture tx_serial_7E2_arch of tx_serial_7E2 is
     
    component tx_serial_uc 
    port ( 
        clock     : in  std_logic;
        reset     : in  std_logic;
        partida   : in  std_logic;
        tick      : in  std_logic;
        fim       : in  std_logic;
        zera      : out std_logic;
        conta     : out std_logic;
        carrega   : out std_logic;
        desloca   : out std_logic;
        pronto    : out std_logic;
        db_estado : out std_logic_vector (3 downto 0)
    );
    end component;

    component tx_serial_7E2_fd 
    port (
        clock        : in  std_logic;
        reset        : in  std_logic;
        zera         : in  std_logic;
        conta        : in  std_logic;
        carrega      : in  std_logic;
        desloca      : in  std_logic;
        dados_ascii  : in  std_logic_vector (6 downto 0);
        saida_serial : out std_logic;
        fim          : out std_logic
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
    
    signal s_zera, s_conta, s_carrega, s_desloca, s_tick, s_fim, s_saida_serial: std_logic;

begin

    U1_UC: tx_serial_uc 
           port map (
               clock     => clock, 
               reset     => reset, 
               partida   => partida, 
               tick      => s_tick, 
               fim       => s_fim,
               zera      => s_zera, 
               conta     => s_conta, 
               carrega   => s_carrega, 
               desloca   => s_desloca, 
               pronto    => pronto,
               db_estado => db_estado
           );

    U2_FD: tx_serial_7E2_fd 
           port map (
               clock        => clock, 
               reset        => reset, 
               zera         => s_zera, 
               conta        => s_conta, 
               carrega      => s_carrega, 
               desloca      => s_desloca, 
               dados_ascii  => dados_ascii, 
               saida_serial => s_saida_serial, 
               fim          => s_fim
           );

    -- gerador de tick
    U3_TICK: contador_m 
             generic map (
                 M => 434, -- 115.200 bauds (434=50M/115200)
                 N => 9
             ) 
             port map (
                 clock => clock, 
                 zera  => s_zera, 
                 conta => '1', 
                 Q     => open,
                 fim   => s_tick,
                 meio  => open
             );

    -- saída serial
    saida_serial <= s_saida_serial;

    -- sinais de depuração de entrada/saída serial
    db_partida <= partida;
    db_saida_serial <= s_saida_serial;
    

end architecture;