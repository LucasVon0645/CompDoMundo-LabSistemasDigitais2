library ieee;
use ieee.std_logic_1164.all;

entity unidade_controle is
    port ( 
        clock             : in  std_logic;
        reset             : in  std_logic;
        iniciar           : in  std_logic;
        bater             : in  std_logic;
        fim_preparacao    : in  std_logic;
        fim_penalti       : in  std_logic;
        fim_jogo          : in  std_logic;
        fim_transmissao   : in  std_logic;
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
        transcode         : out std_logic_vector (1 downto 0);
        db_estado         : out std_logic_vector (3 downto 0)
    );
end entity;

architecture fsm_arch of unidade_controle is
    type tipo_estado is (inicial,
                         espera_partida,
                         reset_componentes,
                         transmite_preparacao,
                         preparacao,
                         transmite_batedor,
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
    process (Eatual, iniciar, fim_preparacao, bater, fim_penalti, fim_jogo, fim_transmissao) 
    begin
        case Eatual is
            when inicial => if fim_transmissao = '1' then Eprox <= espera_partida;
                            else Eprox <= inicial;
                            end if;

            when espera_partida => if iniciar = '1' then Eprox <= reset_componentes;
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

            when placar =>               Eprox <= transmissao;

            when transmissao =>          if fim_transmissao = '0' then Eprox <= transmissao;
                                         elsif fim_jogo = '1' then Eprox <= espera_partida;
                                         else Eprox <= transmite_preparacao;
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
        transmite <= '1' when inicial | transmite_preparacao | transmite_batedor | transmissao,
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

    with Eatual select
        transcode <= "00" when inicial, 
                     "01" when transmite_preparacao,
                     "10" when transmite_batedor,
                     "11" when transmissao,
                     "00" when others;

    -- db_estado
    with Eatual select
        db_estado <= "0000" when inicial,
                     "0001" when espera_partida,
                     "0010" when reset_componentes,
                     "0011" when transmite_preparacao,
                     "0100" when preparacao,
                     "0101" when transmite_batedor,
                     "0110" when batedor,
                     "0111" when chute,
                     "1000" when gol,
                     "1001" when placar,
                     "1010" when transmissao,
                     "1111" when others;

end architecture;