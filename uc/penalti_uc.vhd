library ieee;
use ieee.std_logic_1164.all;

entity penalti_uc is
    port ( 
        clock             : in  std_logic;
        reset             : in  std_logic;
        iniciar           : in  std_logic;
        fim_preparacao    : in  std_logic;
        bateu             : in  std_logic;
        fim_penalti       : in  std_logic;
        fim_jogo          : in  std_logic;
        reset_preparacao  : out std_logic;
        reset_goleiro     : out std_logic;
        reset_batedor     : out std_logic;
        reset_gol         : out std_logic;
        reset_placar      : out std_logic;
        reset_transmissor : out std_logic;
        conta_preparacao  : out std_logic;
        transmite         : out std_logic;
        habilita_batedor  : out std_logic;
        posiciona_goleiro : out std_logic;
        verifica_gol      : out std_logic;
        atualiza_placar   : out std_logic;
        atualiza_jogada   : out std_logic;
        db_estado         : out std_logic_vector (2 downto 0)
    );
end entity;

architecture fsm_arch of penalti_uc is
    type tipo_estado is (inicial,
                         reset_componentes,
                         preparacao,
                         batedor,
                         chute,
                         gol,
                         placar,
                         transmissao);
    signal Eatual, Eprox: tipo_estado;
begin

    -- estado
    process (reset, clock)
    begin
        if reset = '1' then
            Eatual <= inicial;
        elsif clock'event and clock = '1' then
            Eatual <= Eprox; 
        end if;
    end process;

    -- logica de proximo estado
    process (Eatual, iniciar, fim_preparacao, bateu, fim_penalti, fim_jogo) 
    begin
        case Eatual is
            when inicial =>             if iniciar = '1' then Eprox <= reset_componentes;
                                        else Eprox <= inicial;
                                        end if;

            when reset_componentes =>   Eprox <= preparacao;

            when preparacao =>          if fim_preparacao = '1' then Eprox <= batedor;
                                        else Eprox <= preparacao;
                                        end if;

            when batedor =>             if bateu = '1' then Eprox <= chute;
                                        else Eprox <= batedor;
                                        end if;
        
            when chute =>               Eprox <= gol;

            when gol =>                 if fim_penalti = '1' then Eprox <= placar;
                                        else Eprox <= gol;
                                        end if;

            when placar =>              Eprox <= transmissao;

            when transmissao =>         if fim_jogo = '1' then Eprox <= inicial;
                                        else Eprox <= preparacao;
                                        end if;

            when others =>              Eprox <= inicial;
        end case;
    end process;

    -- saidas de controle
    with Eatual select 
        reset_preparacao <= '1' when reset_componentes, '0' when others;

    with Eatual select 
        reset_goleiro <= '1' when reset_componentes, '0' when others;

    with Eatual select 
        reset_batedor <= '1' when reset_componentes, '0' when others;

    with Eatual select 
        reset_gol <= '1' when reset_componentes, '0' when others;

    with Eatual select 
        reset_placar <= '1' when reset_componentes, '0' when others;

    with Eatual select 
        reset_transmissor <= '1' when reset_componentes, '0' when others;
    
    with Eatual select 
        conta_preparacao <= '1' when preparacao, '0' when others;
    
    with Eatual select 
        transmite <= '1' when inicial, 
                     '1' when preparacao,
                     '1' when batedor,
                     '1' when transmissao, 
                     '0' when others;

    with Eatual select 
        habilita_batedor <= '1' when chute, '0' when others;
    
    with Eatual select 
        posiciona_goleiro <= '1' when chute, '0' when others;

    with Eatual select 
        verifica_gol <= '1' when chute, '0' when others;
    
    with Eatual select 
        atualiza_placar <= '1' when placar, '0' when others;

    with Eatual select 
        atualiza_jogada <= '1' when placar, '0' when others;

    -- db_estado
    with Eatual select
        db_estado <= "000" when inicial, 
                     "001" when reset_componentes,
                     "010" when preparacao,
                     "011" when batedor,
                     "100" when chute,
                     "101" when gol,
                     "110" when placar,
                     "111" when transmissao,
                     "000" when others;

end architecture;