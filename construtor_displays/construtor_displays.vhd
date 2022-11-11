library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity construtor_displays is
    port (
        -- entradas
        gols_A             : in  std_logic_vector(3 downto 0);
        gols_B             : in  std_logic_vector(3 downto 0);
        rodada             : in  std_logic_vector(3 downto 0);
        estado_uc          : in  std_logic_vector(3 downto 0);
        fim_jogo           : in  std_logic;
        ganhador           : in  std_logic;
        -- saidas
        gols_A_display     : out std_logic_vector(6 downto 0);
        gols_B_display     : out std_logic_vector(6 downto 0);
        rodada_display     : out std_logic_vector(6 downto 0);
        estado_uc_display  : out std_logic_vector(6 downto 0);
        ganhador_display   : out std_logic_vector(6 downto 0);
        traco              : out std_logic
    );
end entity;

architecture construtor_dis_arch of construtor_displays is

    component hex7seg is
        port (
            enable : in  std_logic;
            hexa   : in  std_logic_vector(3 downto 0);
            sseg   : out std_logic_vector(6 downto 0)
        );
    end component;

    signal s_ganhador_hex : std_logic_vector(3 downto 0);

begin

    hex_rodadas: hex7seg
        port map (
            enable => '1',
            hexa   => rodada,
            sseg   => rodada_display
        );
        
    hex_gols_A: hex7seg
        port map (
            enable => '1',
            hexa   => gols_A,
            sseg   => gols_A_display
        );

    hex_gols_B: hex7seg
        port map (
            enable => '1',
            hexa   => gols_B,
            sseg   => gols_B_display
        );

    hex_estado: hex7seg
        port map (
            enable => '1',
            hexa   => estado_uc,
            sseg   => estado_uc_display
        );

    hex_ganhador: hex7seg
        port map (
            enable => fim_jogo,
            hexa   => s_ganhador_hex,
            sseg   => ganhador_display
        );
    s_ganhador_hex <= "101" & ganhador;

    traco <= '0';

end architecture;
