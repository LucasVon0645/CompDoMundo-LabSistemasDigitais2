library ieee;
use ieee.std_logic_1164.all;

entity unidade_controle is
    port ( 
        clock               : in  std_logic;
        reset               : in  std_logic;
        iniciar             : in  std_logic;
        bater               : in  std_logic;
        fim_preparacao      : in  std_logic;
        fim_penalti         : in  std_logic;
        fim_jogo            : in  std_logic;
        fim_transmissao     : in  std_logic;
        reset_preparacao    : out std_logic;
        reset_goleiro       : out std_logic;
        reset_batedor       : out std_logic;
        reset_gol           : out std_logic;
        reset_placar        : out std_logic;
        reset_transmissor   : out std_logic;
        conta_preparacao    : out std_logic;
        reposiciona_goleiro : out std_logic;
        transmite           : out std_logic;
        habilita_batedor    : out std_logic;
        posiciona_goleiro   : out std_logic;
        verifica_gol        : out std_logic;
        transcode           : out std_logic_vector (2 downto 0);
        db_estado           : out std_logic_vector (3 downto 0)
    );
end entity;

architecture fsm_arch of unidade_controle is
    type tipo_estado is (inicial,
                         transmite_inicio,
                         espera_partida,
                         reset_componentes,
                         transmite_preparacao,
                         preparacao,
                         transmite_batedor,
                         batedor,
                         chute,
                         gol,
                         placar,
                         transmite_rodada,
                         transmite_resultado);
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
    process (Eatual, iniciar, fim_preparacao, bater, fim_penalti, fim_jogo, fim_transmissao) 
    begin
        case Eatual is
            when inicial  =>  Eprox <= transmite_inicio;

            when transmite_inicio =>  if fim_transmissao = '1' then Eprox <= espera_partida;
                                      else Eprox <= transmite_inicio;
                                      end if;

            when espera_partida  =>  if iniciar = '1' then Eprox <= reset_componentes;
                                     else Eprox <= espera_partida;
                                     end if;

            when reset_componentes =>    Eprox <= transmite_preparacao;

            when transmite_preparacao => if fim_transmissao = '1' then Eprox <= preparacao;
                                         else Eprox <= transmite_preparacao;
                                         end if;

            when preparacao =>           if fim_preparacao = '1' then Eprox <= transmite_batedor;
                                         else Eprox <= preparacao;
                                         end if;

            when transmite_batedor =>    if fim_transmissao = '1' then Eprox <= batedor;
                                         else Eprox <= transmite_batedor;
                                         end if;

            when batedor =>              if bater = '1' then Eprox <= chute;
                                         else Eprox <= batedor;
                                         end if;
        
            when chute =>                Eprox <= gol;

            when gol =>                  if fim_penalti = '1' then Eprox <= placar;
                                         else Eprox <= gol;
                                         end if;

            when placar =>               if fim_jogo = '1' then Eprox <= transmite_resultado;
                                         else Eprox <= transmite_rodada;
                                         end if;

            when transmite_rodada    =>  if fim_transmissao = '1' then Eprox <= transmite_preparacao;
                                         else Eprox <= transmite_rodada;
                                         end if;

            when transmite_resultado =>  if fim_transmissao = '1' then Eprox <= espera_partida;
                                         else Eprox <= transmite_resultado;
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
        reposiciona_goleiro <= '1' when preparacao, '0' when others;
    
    with Eatual select 
        transmite <= '1' when transmite_inicio | transmite_preparacao |
                              transmite_batedor | transmite_rodada | transmite_resultado,
                     '0' when others;

    with Eatual select 
        habilita_batedor <= '1' when chute, '0' when others;
    
    with Eatual select 
        posiciona_goleiro <= '1' when chute, '0' when others;

    with Eatual select 
        verifica_gol <= '1' when chute, '0' when others;
    

    with Eatual select
        transcode <= "000" when transmite_inicio, 
                     "001" when transmite_preparacao,
                     "010" when transmite_batedor,
                     "011" when transmite_rodada,
                     "100" when transmite_resultado,
                     "111" when others;

    -- db_estado
    with Eatual select
        db_estado <= "0000" when inicial,
                     "0001" when transmite_inicio,
                     "0010" when espera_partida,
                     "0011" when reset_componentes,
                     "0100" when transmite_preparacao,
                     "0101" when preparacao,
                     "0110" when transmite_batedor,
                     "0111" when batedor,
                     "1000" when chute,
                     "1001" when gol,
                     "1010" when placar,
                     "1011" when transmite_rodada,
                     "1100" when transmite_resultado,
                     "1111" when others;

end architecture;