library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity contador_cm_fd is
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
end entity;

architecture contador_cm_FD_arch of contador_cm_fd is

    component contador_m is
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
	
    component analisa_m is
        generic (
            constant M : integer := 50;  
            constant N : integer := 6 
        );
        port (
            valor            : in  std_logic_vector(N-1 downto 0);
            zero             : out std_logic;
            meio             : out std_logic;
            fim              : out std_logic;
            metade_superior  : out std_logic
        );
    end component;
	
	
    component contador_bcd_3digitos is 
        port ( 
            clock   : in  std_logic;
            zera    : in  std_logic;
            conta   : in  std_logic;
            digito0 : out std_logic_vector(3 downto 0);
            digito1 : out std_logic_vector(3 downto 0);
            digito2 : out std_logic_vector(3 downto 0);
            fim     : out std_logic
        );
    end component;

    signal s_tick_restante: std_logic_vector(11 downto 0);

begin

    gerador_tick_cm: contador_m
        generic map (
            M => 2941,
            N => 12
        )
        port map (
            clock => clock,
            zera  => zera_tick,
            conta => conta_tick,
            Q     => s_tick_restante,
            fim   => tick,
			meio  => open
        );
	
    arredondador: analisa_m
	     generic map (
            M => 2941,
            N => 12
        )
        port map (
	        valor            => s_tick_restante,
		    zero             => open,
		    meio             => open,
		    metade_superior  => arredonda,
		    fim              => open
        );
		  
		  
    contador_bcd: contador_bcd_3digitos
        port map (
	        clock   => clock,
		    zera    => zera_bcd,
		    conta   => conta_bcd,
		    digito0 => digito0,
		    digito1 => digito1,
		    digito2 => digito2,
		    fim     => fim
        );

end architecture;