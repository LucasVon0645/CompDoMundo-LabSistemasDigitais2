library ieee;
use ieee.std_logic_1164.all;

entity detector_gol_uc is
    port ( 
        clock               : in  std_logic;
        reset               : in  std_logic;
        verificar           : in  std_logic;
        distancia_menor     : in  std_logic;
        pronto_med          : in  std_logic;
        fim_timer_medicao   : in  std_logic;
        fim_timeout         : in  std_logic;
        mensurar            : out std_logic;
        zera_interface      : out std_logic;
        zera_timeout        : out std_logic;
        zera_timer_medicao  : out std_logic;
        pronto              : out std_logic;
        gol                 : out std_logic;
        db_estado           : out std_logic_vector(3 downto 0)
    );
end entity;

architecture fsm_arch of detector_gol_uc is
    type tipo_estado is (inicial,
                         inicializa_elementos,
                         aguarda_para_medir,
                         mede,
                         aguarda_medicao, 
                         compara,
                         nova_medicao,
                         final_com_gol,
                         final_sem_gol);

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
    process (verificar, pronto_med, distancia_menor, fim_timer_medicao, fim_timeout, Eatual) 
    begin
      case Eatual is
        when inicial =>           if verificar='1' then Eprox <= inicializa_elementos;
                                  else                  Eprox <= inicial;
                                  end if;

        when inicializa_elementos  => Eprox <= aguarda_para_medir;

        when aguarda_para_medir =>  if fim_timeout = '1' then Eprox <= final_sem_gol;
                                    elsif fim_timer_medicao = '1' then Eprox <= mede;
                                    else Eprox <= aguarda_para_medir;
                                    end if;

        when mede  =>               if fim_timeout = '1' then Eprox <= final_sem_gol;
                                      else Eprox <= aguarda_medicao;
                                                end if;

        when aguarda_medicao =>  if fim_timeout = '1' then Eprox <= final_sem_gol;
                                    elsif pronto_med = '1' then Eprox <= compara;
                                    else Eprox <= aguarda_medicao;
                                    end if;

        when compara  =>    if fim_timeout = '1' then Eprox <= final_sem_gol;
                            elsif distancia_menor = '1' then Eprox <= final_com_gol;
                            else Eprox <= nova_medicao;
                            end if;

        when nova_medicao =>      if fim_timeout = '1' then Eprox <= final_sem_gol;
                                             else Eprox <= aguarda_para_medir;
                                             end if;
        
        when final_sem_gol =>     Eprox <= inicial;

        when final_com_gol =>     Eprox <= inicial;

        when others =>            Eprox <= inicial;
      end case;
    end process;

    -- saidas de controle
    with Eatual select 
        mensurar <= '1' when mede,
                        '0' when others;
    
    

    with Eatual select
        zera_timeout <= '1' when inicializa_elementos,
                        '0' when others;
    
    with Eatual select
        zera_timer_medicao <= '1' when inicializa_elementos,
                              '1' when nova_medicao,
                              '0' when others;

    with Eatual select
        zera_interface <=     '1' when inicializa_elementos,
                              '1' when nova_medicao,
                              '0' when others;
    

    with Eatual select
        pronto <= '1' when final_com_gol, 
                  '1' when final_sem_gol,
                  '0' when others;

    with Eatual select
        gol <= '1' when final_com_gol, '0' when others;
    
    -- db_estado
    with Eatual select
        db_estado <= "0000" when inicial, 
                     "0001" when inicializa_elementos,
                     "0010" when aguarda_para_medir,
                     "0011" when mede, 
                     "0100" when aguarda_medicao,
                     "0101" when compara,
                     "0110" when nova_medicao,
                     "0111" when final_sem_gol,
                     "1000" when final_com_gol,
                     "1111" when others;

end architecture fsm_arch;