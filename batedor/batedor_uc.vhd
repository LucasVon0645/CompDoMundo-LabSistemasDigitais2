library ieee;
use ieee.std_logic_1164.all;

entity batedor_uc is
    port ( 
        clock       : in  std_logic;
        reset       : in  std_logic;
        bater       : in  std_logic;
        fim_timer   : in  std_logic;
        zera_timer  : out std_logic;
        conta_timer : out std_logic;
        posicao     : out std_logic_vector (2 downto 0);
        db_estado   : out std_logic
    );
end entity;

architecture fsm_arch of batedor_uc is
    type tipo_estado is (repouso, movimento);
    signal Eatual, Eprox: tipo_estado;
begin

    -- estado
    process (reset, clock)
    begin
        if reset = '1' then
            Eatual <= repouso;
        elsif clock'event and clock = '1' then
            Eatual <= Eprox; 
        end if;
    end process;

    -- logica de proximo estado
    process (Eatual, bater, fim_timer) 
    begin
        case Eatual is
            when repouso =>     if bater = '1' then Eprox <= movimento;
                                else Eprox <= repouso;
                                end if;

            when movimento =>   if fim_timer = '1' then Eprox <= repouso;
                                else Eprox <= movimento;
                                end if;

            when others =>      Eprox <= repouso;
        end case;
    end process;

    -- saidas de controle
    with Eatual select 
        zera_timer <= '1' when repouso,
                      '0' when others;

    with Eatual select
        conta_timer <= '1' when movimento,
                       '0' when others;

    with Eatual select
        posicao <= "000" when repouso,
                   "100" when movimento,
                   "000" when others;

    -- db_estado
    with Eatual select
        db_estado <= '0' when repouso, 
                     '1' when movimento,
                     '0' when others;

end architecture;