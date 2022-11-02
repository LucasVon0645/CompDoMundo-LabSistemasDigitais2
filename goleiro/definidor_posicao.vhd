library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity definidor_posicao is
    port (
	    clock    : in  std_logic;
	    reset    : in  std_logic;
		dado     : in  std_logic_vector (6 downto 0);
		tem_dado : in  std_logic;
		posicao  : out std_logic_vector (2 downto 0)
    );
end entity definidor_posicao;

architecture definidor_posicao_arch of definidor_posicao is
	signal s_posicao, s_prox_posicao: std_logic_vector (2 downto 0);
begin

posicao_process:
    process (clock, reset)
    begin	 
	    if reset = '1' then
		    s_posicao <= "010";
		elsif clock'event and clock = '1'  then
		    s_posicao <= s_prox_posicao;
		end if;
    end process;

	 process (dado, tem_dado)
	 begin
		if tem_dado = '1' then
	     	case dado is
		        when "0110001" => s_prox_posicao <= "000";
				when "0110010" => s_prox_posicao <= "001";
				when "0110011" => s_prox_posicao <= "010";
				when "0110100" => s_prox_posicao <= "011";
				when "0110101" => s_prox_posicao <= "100";
				when others    => s_prox_posicao <= "010";
			end case;
		end if;
    end process;
	 
	posicao <= s_posicao;

end architecture;