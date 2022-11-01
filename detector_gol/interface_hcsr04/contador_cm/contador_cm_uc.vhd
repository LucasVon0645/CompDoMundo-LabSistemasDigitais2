library ieee;
use ieee.std_logic_1164.all;

entity contador_cm_uc is
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
end entity;

architecture contador_cm_uc_arch of contador_cm_uc is

    type tipo_estado is (
        inicial, conta, atualizaDist, arredondaDist, final
    );
    signal Eatual: tipo_estado;  -- estado atual
    signal Eprox:  tipo_estado;  -- proximo estado

begin

    -- memoria de estado
    process (reset, clock)
    begin
        if reset = '1' then
            Eatual <= inicial;
        elsif clock'event and clock = '1' then
            Eatual <= Eprox;
        end if;
    end process;

    -- logica de proximo estado
    process (pulso, tick, arredonda, Eatual)
    begin

        case Eatual is

            when inicial =>       if pulso='1' then Eprox <= conta;
                                  else              Eprox <= inicial;
                                  end if;
									 
	        when conta =>         if    pulso='1' and tick='1'      then Eprox <= atualizaDist;
			                      elsif pulso='0' and arredonda='1' then Eprox <= arredondaDist;
		                          elsif pulso='0' and arredonda='0' then Eprox <= final;
                                  else                                   Eprox <= conta;
                                  end if;
							 
	        when atualizaDist =>  if    pulso='1'                   then Eprox <= conta;
			                      elsif pulso='0' and arredonda='1' then Eprox <= arredondaDist;
		                          else                                   Eprox <= final;
                                  end if;				
									
	        when arredondaDist => Eprox <= final;

            when final =>         Eprox <= inicial;

            when others =>        Eprox <= inicial;

        end case;
    end process;

    -- logica de saida (Moore)
    with Eatual select
        zera_tick <= '1' when inicial, '0' when others;
		
    with Eatual select
        zera_bcd <= '1' when inicial, '0' when others;
		
    with Eatual select
        conta_tick <= '1' when conta | atualizaDist, '0' when others;

    with Eatual select
        conta_bcd <= '1' when atualizaDist | arredondaDist, '0' when others;

    with Eatual select
        pronto <= '1' when final, '0' when others;

    -- saida de depuracao (db_estado)
    with Eatual select
        db_estado <= "000" when inicial,       -- 0
                     "001" when conta,         -- 1
                     "010" when atualizaDist,  -- 2
                     "011" when arredondaDist, -- 3
                     "100" when final,         -- 4
                     "111" when others;        -- F

end architecture contador_cm_uc_arch;