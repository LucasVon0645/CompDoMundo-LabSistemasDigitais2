library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity super_transmissor is
    port (
        -- entradas
        clock              : in std_logic;
        reset              : in std_logic;
        transmite          : in std_logic;
        -- dados
        transcode          : in  std_logic_vector(2 downto 0);
        gols_A             : in  std_logic_vector(3 downto 0);
        gols_B             : in  std_logic_vector(3 downto 0);
        rodada             : in  std_logic_vector(3 downto 0);
        jogador            : in  std_logic;
        direcao_batedor    : in  std_logic;
        -- saidas
        saida_serial       : out std_logic;
        fim_transmissao    : out std_logic
    );
end entity;

architecture super_arch of super_transmissor is

    component tx_serial_7E2 is
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
    end component;

    component construtor_mensagem is
        port (
            clock              : in std_logic;
            reset              : in std_logic;
            fim_caracter       : in std_logic;
            header             : in  std_logic_vector(2 downto 0);
            gols_A             : in  std_logic_vector(3 downto 0);
            gols_B             : in  std_logic_vector(3 downto 0);
            rodada             : in  std_logic_vector(3 downto 0);
            jogador            : in  std_logic;
            direcao_batedor    : in  std_logic;
            caracter_trans     : out std_logic_vector(6 downto 0);
            fim_mensagem       : out std_logic
        );
    end component;

    signal s_transmite       : std_logic;
    signal s_fim_caracter    : std_logic;
    signal s_fim_transmissao : std_logic;
    signal s_dado_trans      : std_logic_vector(6 downto 0);

begin

    construtor: construtor_mensagem
        port map (
            clock            => clock,
            reset            => reset,
            fim_caracter     => s_fim_caracter,
            header           => transcode,
            gols_A           => gols_A,
            gols_B           => gols_B,
            rodada           => rodada,
            jogador          => jogador,
            direcao_batedor  => direcao_batedor,
            caracter_trans   => s_dado_trans,
            fim_mensagem     => s_fim_transmissao
        );

    s_transmite <= transmite and not s_fim_transmissao;

    transmissor: tx_serial_7E2
        port map (
            clock            => clock,
            reset            => reset,
            partida          => s_transmite,
            dados_ascii      => s_dado_trans,
            saida_serial     => saida_serial,
            pronto           => s_fim_caracter,
            db_partida       => open,
            db_saida_serial  => open,
            db_estado        => open
        );

    -- Saidas
    fim_transmissao <= s_fim_transmissao;

end architecture;
