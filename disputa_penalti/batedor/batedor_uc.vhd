library ieee;
use ieee.std_logic_1164.all;

entity batedor_uc is
    port ( 
        clock            : in  std_logic;
        reset            : in  std_logic;
        direcao          : in  std_logic;
        habilitar        : in  std_logic;
        fim_timer        : in  std_logic;
        posicao_direita  : out  std_logic_vector (2 downto 0);
        posicao_esquerda : out  std_logic_vector (2 downto 0);
        zera_timer       : out std_logic;
        conta_timer      : out std_logic;
        db_estado        : out std_logic_vector (1 downto 0)
    );
end entity;

architecture fsm_arch of batedor_uc is
    type tipo_estado is (repouso, movimento_direita, movimento_esquerda);
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
    process (Eatual, habilitar, direcao, fim_timer) 
    begin
        case Eatual is
            when repouso =>             if habilitar = '0' then Eprox <= repouso;
                                        elsif direcao = '0' then Eprox <= movimento_direita;
                                        else Eprox <= movimento_esquerda;
                                        end if;

            when movimento_direita =>   if fim_timer = '1' then Eprox <= repouso;
                                        else Eprox <= movimento_direita;
                                        end if;

            when movimento_esquerda =>  if fim_timer = '1' then Eprox <= repouso;
                                        else Eprox <= movimento_esquerda;
                                        end if;

            when others =>              Eprox <= repouso;
        end case;
    end process;

    -- saidas de controle
    with Eatual select 
        zera_timer <= '1' when repouso,
                      '0' when others;

    with Eatual select
        conta_timer <= '1' when movimento_direita | movimento_esquerda,
                       '0' when others;

    with Eatual select
        posicao_direita <= "000" when movimento_direita,
                           "100" when others;

    with Eatual select
        posicao_esquerda <= "100" when movimento_esquerda,
                            "000" when others;

    -- db_estado
    with Eatual select
        db_estado <= "00" when repouso, 
                     "01" when movimento_direita,
                     "10" when movimento_esquerda,
                     "11" when others;

end architecture;