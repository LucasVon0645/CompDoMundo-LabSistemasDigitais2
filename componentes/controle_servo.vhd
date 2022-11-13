library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controle_servo is
    port (
        clock      : in  std_logic;
        reset      : in  std_logic;
        posicao    : in  std_logic_vector(2 downto 0);  
        pwm        : out std_logic;
        db_reset   : out std_logic;
        db_pwm     : out std_logic;
        db_posicao : out std_logic_vector(2 downto 0)  
    );
end controle_servo;

architecture controle_servo_arch of controle_servo is

  constant CONTAGEM_MAXIMA : integer := 1000000;  -- valor para frequencia da saida de 50Hz 
                                                  -- ou periodo de 20ms
  signal contagem    : integer range 0 to CONTAGEM_MAXIMA-1;
  signal largura_pwm : integer range 0 to CONTAGEM_MAXIMA-1;
  signal s_largura   : integer range 0 to CONTAGEM_MAXIMA-1;
  signal s_controle  : std_logic;
  
begin

    process(clock, reset, s_largura)
    begin
        -- inicia contagem e largura
        if(reset = '1') then
            contagem    <= 0;
            s_controle  <= '0';
            largura_pwm <= s_largura;
        elsif(rising_edge(clock)) then
            -- saida
            if(contagem < largura_pwm) then
                s_controle <= '1';
            else
                s_controle <= '0';
            end if;
            -- atualiza contagem e largura
            if(contagem = CONTAGEM_MAXIMA-1) then
                contagem   <= 0;
                largura_pwm <= s_largura;
            else
                contagem <= contagem + 1;
            end if;
        end if;
    end process;

    process(posicao)
    begin
        case posicao is
            when "000"  => s_largura <= 35000;
            when "001"  => s_largura <= 53750;
            when "010"  => s_largura <= 72500;
            when "011"  => s_largura <= 91250;
            when "100"  => s_largura <= 110000;
            when others => s_largura <= 72500;
        end case;
    end process;
  
    pwm        <= s_controle;
    db_pwm     <= s_controle;
    db_reset   <= reset;
    db_posicao <= posicao;
  
end architecture;