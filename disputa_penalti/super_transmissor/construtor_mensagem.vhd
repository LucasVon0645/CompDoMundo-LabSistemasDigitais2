library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity construtor_mensagem is
    port (
        -- entradas
        clock              : in std_logic;
        reset              : in std_logic;
        fim_caracter       : in std_logic;
        -- dados
        header             : in  std_logic_vector(2 downto 0);
        gols_A             : in  std_logic_vector(3 downto 0);
        gols_B             : in  std_logic_vector(3 downto 0);
        rodada             : in  std_logic_vector(3 downto 0);
        jogador            : in  std_logic;
        direcao_batedor    : in  std_logic;
        -- saidas
        caracter_trans     : out std_logic_vector(6 downto 0);
        fim_mensagem       : out std_logic
    );
end entity;

architecture construtor_arch of construtor_mensagem is

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

    component hex2ascii is
        port(
            hex    : in  std_logic_vector (3 downto 0);
            ascii  : out std_logic_vector (6 downto 0)
        );
    end component;

    signal s_fim_mensagem, s_conta            : std_logic;
    signal sel_caracter                       : std_logic_vector(2 downto 0);
    signal corpo_mensagem                     : std_logic_vector(8 downto 0);
    signal caracter_0_ascii, caracter_1_ascii : std_logic_vector(6 downto 0);
    signal caracter_2_ascii, caracter_3_ascii : std_logic_vector(6 downto 0);
    signal s_hex_header, s_hex_c1             : std_logic_vector(3 downto 0);

begin

    with header select
        corpo_mensagem <= (jogador & rodada & "0000")         when "001",
                          (direcao_batedor & gols_A & gols_B) when "011" | "100",
                          (others => '0')                     when others;

    s_hex_header <= '0' & header;

    conv_header: hex2ascii
        port map(
            hex    => s_hex_header,
            ascii  => caracter_0_ascii
        );

    s_hex_c1 <= "000" & corpo_mensagem(8);

    conv_caracter_1: hex2ascii
        port map(
            hex    => s_hex_c1,
            ascii  => caracter_1_ascii
        );

    conv_caracter_2: hex2ascii
        port map(
            hex    => corpo_mensagem(7 downto 4),
            ascii  => caracter_2_ascii
        );

    conv_caracter_3: hex2ascii
        port map(
            hex    => corpo_mensagem(3 downto 0),
            ascii  => caracter_3_ascii
        );

    with sel_caracter select
        caracter_trans <= caracter_0_ascii when "000",
                          caracter_1_ascii when "001",
                          caracter_2_ascii when "010",
                          caracter_3_ascii when "011",
                          caracter_0_ascii when others;

    s_conta <= fim_caracter or s_fim_mensagem;

    conta_mensagem: contador_m
        generic map (
            M => 5,
            N => 3 
        )
        port map (
            clock  => clock,
            zera   => reset,
            conta  => s_conta,
            Q      => sel_caracter,
            fim    => s_fim_mensagem,
            meio   => open
        );

    fim_mensagem <= s_fim_mensagem;

end architecture;
