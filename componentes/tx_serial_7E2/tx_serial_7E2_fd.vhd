library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity tx_serial_7E2_fd is
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
end entity;

architecture tx_serial_7E2_fd_arch of tx_serial_7E2_fd is
     
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
    
    signal s_dados, s_saida: std_logic_vector (11 downto 0);
    signal parity_bit: std_logic;

begin

    -- vetor de dados a ser carregado
    s_dados(0)            <= '1';         -- repouso
    s_dados(1)            <= '0';         -- start bit
    s_dados(8 downto 2)   <= dados_ascii; -- 8 bits
    s_dados(9)            <= parity_bit;  -- parity bit = xor dos bits de dados_ascii
    s_dados(11 downto 10) <= "11";        -- stop bits

    parity_bit <= dados_ascii(0) xor dados_ascii(1) xor dados_ascii(2) xor
                  dados_ascii(3) xor dados_ascii(4) xor dados_ascii(5) xor
                  dados_ascii(6);

    U1: deslocador_n 
        generic map (
            N => 12
        )  
        port map (
            clock          => clock, 
            reset          => reset, 
            carrega        => carrega, 
            desloca        => desloca, 
            entrada_serial => '1', 
            dados          => s_dados, 
            saida          => s_saida
        );

    U2: contador_m 
        generic map (
            M => 13, 
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

    -- saida
    saida_serial <= s_saida(0);
    
end architecture;

