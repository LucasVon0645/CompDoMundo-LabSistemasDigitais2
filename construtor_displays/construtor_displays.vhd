library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity construtor_displays is
    port (
	     -- selecao
		  config_displays       : in  std_logic;
        -- entradas de debug (config = 0)
        gols_A             : in  std_logic_vector(3 downto 0);
        gols_B             : in  std_logic_vector(3 downto 0);
        rodada             : in  std_logic_vector(3 downto 0);
        estado_uc          : in  std_logic_vector(3 downto 0);
        fim_jogo           : in  std_logic;
        ganhador           : in  std_logic;
		  -- entradas de debug (config = 1)
        distancia             : in  std_logic_vector (11 downto 0);
        detector_gol_uc       : in  std_logic_vector (3 downto 0);
        -- displays
        hex0                  : out std_logic_vector (6 downto 0);
        hex1                  : out std_logic_vector (6 downto 0);
        hex2                  : out std_logic_vector (6 downto 0);
        hex3                  : out std_logic_vector (6 downto 0);
        hex4                  : out std_logic_vector (6 downto 0);
        hex5                  : out std_logic_vector (6 downto 0)
    );
end entity;

architecture construtor_dis_arch of construtor_displays is

     component mux_2x1_n is
        generic (
            constant BITS: integer := 4
        );
        port( 
            D1      : in  std_logic_vector (BITS-1 downto 0);
            D0      : in  std_logic_vector (BITS-1 downto 0);
            SEL     : in  std_logic;
            MUX_OUT : out std_logic_vector (BITS-1 downto 0)
        );
    end component;
	 
	 component hex7seg is
        port (
            enable : in  std_logic;
            hexa   : in  std_logic_vector(3 downto 0);
            sseg   : out std_logic_vector(6 downto 0)
        );
    end component;
	 
    signal s_ganhador_hex : std_logic_vector(3 downto 0);
	 signal sinais0, sinais1, sinais_finais : std_logic_vector(23 downto 0);
	 signal enables0, enables1, enables_finais : std_logic_vector(5 downto 0);
	 constant traco : std_logic_vector(3 downto 0) := "0000";
	 

begin

    mux_data: mux_2x1_n
			generic map (
            BITS => 24
         )
         port map (
             D1      => sinais1,
             D0      => sinais0,
             SEL     => config_displays,
             MUX_OUT => sinais_finais
         );
			
	  mux_enables: mux_2x1_n
			generic map (
				 BITS => 6
			)
			port map (
				 D1      => enables1,
				 D0      => enables0,
				 SEL     => config_displays,
				 MUX_OUT => enables_finais
			);
	 
	 
    display0: hex7seg
        port map (
	 	      enable => enables_finais(0),
            hexa   => sinais_finais(3 downto 0),
            sseg   => hex0
        );
		  
    display1: hex7seg
        port map (
	 	      enable => enables_finais(1),
            hexa   => sinais_finais(7 downto 4),
            sseg   => hex1
        );
		  
    display2: hex7seg
        port map (
	 	      enable => enables_finais(2),
            hexa   => sinais_finais(11 downto 8),
            sseg   => hex2
        );
		  
    display3: hex7seg
        port map (
	 	      enable => enables_finais(3),
            hexa   => sinais_finais(15 downto 12),
            sseg   => hex3
        );
		  
    display4: hex7seg
        port map (
	 	      enable => enables_finais(4),
            hexa   => sinais_finais(19 downto 16),
            sseg   => hex4
        );
		  
    display5: hex7seg
        port map (
	 	      enable => enables_finais(5),
            hexa   => sinais_finais(23 downto 20),
            sseg   => hex5
        );
		  
	 -- sinais intermediarios
	 s_ganhador_hex <= "101" & ganhador;
		  
	 -- depuracao (config = 0)
	 sinais0  <= rodada & traco & gols_A & gols_B & s_ganhador_hex & estado_uc;
	 enables0 <= "1011" & fim_jogo & '1';
	  
	 -- depuracao (config = 1)
	 sinais1  <= distancia & "0000" & detector_gol_uc & estado_uc;
	 enables1 <= "111011";
	 
end architecture;
