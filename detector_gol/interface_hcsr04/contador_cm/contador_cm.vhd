library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity contador_cm is
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
end entity;

architecture contador_cm_arch of contador_cm is

    component contador_cm_uc is
        port (
            clock       : in  std_logic;
            reset       : in  std_logic;
            pulso       : in  std_logic;
            tick        : in  std_logic;
            arredonda   : in  std_logic;
            zera_bcd    : out std_logic;
            conta_bcd   : out std_logic;
                zera_tick   : out std_logic;
                conta_tick  : out std_logic;
                pronto      : out std_logic;
            db_estado   : out std_logic_vector (2 downto 0)
        );
    end component;

    component contador_cm_fd is
        port (
            clock             : in  std_logic;
            zera_bcd          : in  std_logic;
            conta_bcd         : in  std_logic;
            zera_tick         : in  std_logic;
            conta_tick        : in  std_logic;
            arredonda         : out std_logic;
            tick              : out std_logic;
            fim               : out std_logic;
            digito0           : out std_logic_vector(3 downto 0);
            digito1           : out std_logic_vector(3 downto 0);
            digito2           : out std_logic_vector(3 downto 0)
        );
    end component;

    signal s_zera_bcd, s_conta_bcd   : std_logic;
    signal s_zera_tick, s_conta_tick : std_logic;
    signal s_tick, s_arredonda       : std_logic;

begin

    UC: contador_cm_uc
        port map (
            clock      => clock,
            reset      => reset,
            pulso      => pulso,
            tick       => s_tick,
            arredonda  => s_arredonda,
            zera_bcd   => s_zera_bcd,
            conta_bcd  => s_conta_bcd,
            zera_tick  => s_zera_tick,
            conta_tick => s_conta_tick,
            pronto     => pronto,
            db_estado  => db_estado_cm
        );

    FD: contador_cm_fd
        port map (
            clock      => clock,
            zera_bcd   => s_zera_bcd,
            conta_bcd  => s_conta_bcd,
            zera_tick  => s_zera_tick,
            conta_tick => s_conta_tick,
            arredonda  => s_arredonda,
            tick       => s_tick,
            fim        => fim,
            digito0    => digito0,
            digito1    => digito1,
            digito2    => digito2
        );

end architecture;