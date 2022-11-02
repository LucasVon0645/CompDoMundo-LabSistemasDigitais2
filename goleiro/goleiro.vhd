library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity goleiro is
    port (
        clock          : in  std_logic;
        reset          : in  std_logic;
        entrada_serial : in  std_logic;
        posicionar     : in  std_logic;
        pwm            : out std_logic;
		db_posicao     : out std_logic_vector (2 downto 0)
    );
end entity;

architecture arch_goleiro of goleiro is
	 
	component rx_serial_7E2 is
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
    end component;

    component controle_servo is
        port (
            clock      : in  std_logic;
            reset      : in  std_logic;
            posicao    : in  std_logic_vector(2 downto 0);  
            pwm        : out std_logic;
            db_reset   : out std_logic;
            db_pwm     : out std_logic;
            db_posicao : out std_logic_vector(2 downto 0)  
        );
    end component;

	component definidor_posicao is
		port (
			clock    : in  std_logic;
			reset    : in  std_logic;
			dado     : in  std_logic_vector (6 downto 0);
			tem_dado : in  std_logic;
			posicao  : out std_logic_vector (2 downto 0)
		);
	end component;
	 
	signal s_dado_recebido : std_logic_vector (6 downto 0);
	signal s_tem_dado, s_pwm : std_logic;
    signal s_posicao : std_logic_vector (2 downto 0);

begin
		
	RX: rx_serial_7E2
	port map (
		clock          => clock,
		reset          => reset,
		dado_serial    => entrada_serial,
		recebe_dado    => '1',
		dado_recebido  => s_dado_recebido,
		tem_dado       => s_tem_dado,
		paridade_ok    => open,
		pronto         => open,
		db_dado_serial => open,
		db_estado      => open
	);

    servomotor_goleiro: controle_servo
	port map (
        clock      => clock,
        reset      => reset,
        posicao    => s_posicao,
        pwm        => s_pwm,
        db_reset   => open,
        db_pwm     => open,
        db_posicao => open
	);

    posicao: definidor_posicao
	port map (
        clock      => clock,
        reset      => reset,
		dado       => s_dado_recebido,
		tem_dado   => s_tem_dado,
		posicao    => s_posicao
	);

	db_posicao <= s_posicao;
	pwm <= posicionar and s_pwm;
    
end architecture;