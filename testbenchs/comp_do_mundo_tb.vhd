library ieee;
use ieee.std_logic_1164.all;

entity comp_do_mundo_tb is
end entity;

architecture tb of comp_do_mundo_tb is
  
    -- Componente a ser testado (Device Under Test -- DUT)

    component comp_do_mundo is
        port (
            -- entradas
            clock              : in  std_logic;
            reset              : in  std_logic;
            iniciar            : in  std_logic;
            bater_direita      : in  std_logic;
            bater_esquerda     : in  std_logic;
            echo               : in  std_logic;
            entrada_serial     : in  std_logic;
            config_displays    : in  std_logic;
            -- saidas
            pwm_goleiro        : out std_logic;
            pwm_batedor_dir    : out std_logic;
            pwm_batedor_esq    : out std_logic;
            trigger            : out std_logic;
            saida_serial       : out std_logic;
            -- depuracao
            db_fim_preparacao  : out std_logic;
            db_fim_transmissao : out std_logic;
            db_trigger         : out std_logic;
            db_echo            : out std_logic;
            hex0               : out std_logic_vector (6 downto 0);
            hex1               : out std_logic_vector (6 downto 0);
            hex2               : out std_logic_vector (6 downto 0);
            hex3               : out std_logic_vector (6 downto 0);
            hex4               : out std_logic_vector (6 downto 0);
            hex5               : out std_logic_vector (6 downto 0)
        );
    end component;
    
    -- Declaracao de sinais para conectar o componente a ser testado (DUT)
    --   valores iniciais para fins de simulacao (GHDL ou ModelSim)
    signal clock_in               : std_logic := '0';
    signal reset_in               : std_logic := '0';
    signal iniciar_in             : std_logic := '0';
    signal bater_direita_in       : std_logic := '0';
    signal bater_esquerda_in      : std_logic := '0';
    signal echo_in                : std_logic := '0';

    signal entrada_serial_in      : std_logic := '1';
    signal serial_data            : std_logic_vector(7 downto 0) := "00000000";

    signal pwm_goleiro_out        : std_logic := '0';
    signal pwm_batedor_dir_out    : std_logic := '0';
    signal pwm_batedor_esq_out    : std_logic := '0';
    signal trigger_out            : std_logic := '0';
    signal saida_serial_out       : std_logic := '1';
    signal db_fim_preparacao_out  : std_logic := '0';
    signal db_fim_transmissao_out : std_logic := '0';


    -- Configuracoes do clock
    constant clockPeriod : time := 20 ns;           -- clock de 50MHz
    constant bitPeriod   : time := 434*clockPeriod; -- 434 clocks por bit (115.200 bauds)
    signal keep_simulating : std_logic := '0';    -- delimita o tempo de geracao do clock
    
    ---- UART_WRITE_BYTE()
    procedure UART_WRITE_BYTE (
        Data_In : in  std_logic_vector(7 downto 0);
        signal Serial_Out : out std_logic ) is
    begin

    -- envia Start Bit
    Serial_Out <= '0';
    wait for bitPeriod;

    -- envia 8 bits seriais (dados + paridade)
    for ii in 0 to 7 loop
      Serial_Out <= Data_In(ii);
      wait for bitPeriod;
    end loop;  -- loop ii

    -- envia 2 Stop Bits
    Serial_Out <= '1';
    wait for 2*bitPeriod;

    end UART_WRITE_BYTE;
    -- fim procedure

    -- Array de posicoes de teste
    type posicoes_teste_type is record
        jogo     : natural;
        rodada   : natural; 
        posicaoA : std_logic;
        dadoB    : std_logic_vector (7 downto 0);
        tempoA   : integer;  
        posicaoB : std_logic;
        dadoA    : std_logic_vector (7 downto 0);   
        tempoB   : integer;  
    end record;

    type posicoes_teste_array is array (natural range <>) of posicoes_teste_type;
    constant posicoes_teste : posicoes_teste_array := ( 
        -- 118us == 2cm de medicao ->  gooooooool
        -- 657us == 10cm de medicao -> nao ha gol

        ( 1, 1, '0', "01100011", 118, '1', "01100011", 647), -- A: 1, B: 0 - A faz gol
        ( 1, 2, '1', "01101001", 118, '0', "01101010", 647), -- A: 2, B: 0 - A faz gol
        ( 1, 3, '1', "01100110", 118, '1', "01100101", 647), -- A: 3, B: 0 - A faz gol = A vence

        ( 2, 1, '1', "01101010", 118, '0', "01101010", 647), -- A: 1, B: 0 - A faz gol
        ( 2, 2, '1', "01100101", 118, '1', "01101010", 118), -- A: 2, B: 1 - A e B fazem gol
        ( 2, 3, '0', "01100110", 118, '0', "01101001", 647), -- A: 3, B: 1 - A faz gol
        ( 2, 4, '0', "01100011", 118, '0', "00000000", 0),   -- A: 4, B: 1 - A faz gol = A vence

        ( 3, 1, '0', "01101001", 647, '1', "01100101", 647), -- A: 0, B: 0 - Ninguem faz gol
        ( 3, 2, '1', "01100101", 647, '0', "01101010", 647), -- A: 0, B: 0 - Ninguem faz gol
        ( 3, 3, '1', "01100011", 647, '1', "01101001", 118), -- A: 0, B: 1 - B faz gol
        ( 3, 4, '0', "01101011", 647, '0', "01100110", 118), -- A: 0, B: 2 - B faz gol = B vence

        ( 4, 1, '1', "01100101", 647, '0', "01100011", 118), -- A: 0, B: 1 - B faz gol
        ( 4, 2, '1', "01100011", 647, '1', "01100110", 118), -- A: 0, B: 2 - B faz gol
        ( 4, 3, '0', "01100110", 118, '1', "01101010", 118), -- A: 1, B: 3 - A e B fazem gol
        ( 4, 4, '0', "01101001", 118, '1', "01100101", 647), -- A: 2, B: 3 - A faz gol
        ( 4, 5, '1', "01100011", 647, '0', "00000000", 0),   -- A: 2, B: 3 - Ninguem faz gol = B vence

        ( 5, 1, '0', "01100101", 118, '1', "01100101", 647), -- A: 1, B: 0 - A faz gol
        ( 5, 2, '0', "01101010", 647, '0', "01100011", 118), -- A: 1, B: 1 - B faz gol
        ( 5, 3, '1', "01100110", 118, '1', "01100101", 647), -- A: 2, B: 1 - A faz gol
        ( 5, 4, '0', "01101010", 647, '1', "01101001", 118), -- A: 2, B: 2 - B faz gol
        ( 5, 5, '0', "01100011", 118, '0', "01100110", 118), -- A: 3, B: 3 - A e B fazem gol
        ( 5, 6, '1', "01100101", 647, '1', "01101010", 118), -- A: 3, B: 4 - B faz gol = B vence


        -- Testes adicionais: mata-mata
        ( 6, 1, '0', "01100101", 118, '1', "01100101", 647), -- A: 1, B: 0 - A faz gol
        ( 6, 2, '0', "01101010", 647, '0', "01100011", 118), -- A: 1, B: 1 - B faz gol
        ( 6, 3, '1', "01100110", 118, '1', "01100101", 647), -- A: 2, B: 1 - A faz gol
        ( 6, 4, '0', "01101010", 647, '1', "01101001", 118), -- A: 2, B: 2 - B faz gol
        ( 6, 5, '0', "01100011", 118, '0', "01100110", 118), -- A: 3, B: 3 - A e B fazem gol
        ( 6, 6, '1', "01100101", 647, '1', "01101010", 647), -- A: 3, B: 3 - Ninguem faz gol
        ( 6, 7, '1', "01100101", 647, '1', "01101010", 118), -- A: 3, B: 4 - B faz gol = B vence

        ( 7, 1, '0', "01100101", 118, '1', "01100101", 647), -- A: 1, B: 0 - A faz gol
        ( 7, 2, '0', "01101010", 647, '0', "01100011", 118), -- A: 1, B: 1 - B faz gol
        ( 7, 3, '1', "01100110", 118, '1', "01100101", 647), -- A: 2, B: 1 - A faz gol
        ( 7, 4, '0', "01101010", 647, '1', "01101001", 118), -- A: 2, B: 2 - B faz gol
        ( 7, 5, '0', "01100011", 118, '0', "01100110", 118), -- A: 3, B: 3 - A e B fazem gol
        ( 7, 6, '1', "01100101", 647, '1', "01101010", 647), -- A: 3, B: 3 - Ninguem faz gol
        ( 7, 7, '1', "01100101", 118, '1', "01101010", 647)  -- A: 4, B: 3 - A faz gol = A vence
    );

    signal larguraPulsoA, larguraPulsoB: time := 1 ns;

begin
    -- Gerador de clock: executa enquanto 'keep_simulating = 1', com o periodo
    -- especificado. Quando keep_simulating=0, clock eh interrompido, bem como a 
    -- simula????o de eventos
    clock_in <= (not clock_in) and keep_simulating after clockPeriod/2;

    -- Conecta DUT (Device Under Test)
    dut: comp_do_mundo
        port map ( 
            -- entradas
            clock              => clock_in,
            reset              => reset_in,
            iniciar            => iniciar_in,
            bater_direita      => bater_direita_in,
            bater_esquerda     => bater_esquerda_in,
            echo               => echo_in,
            entrada_serial     => entrada_serial_in,
            config_displays    => '0',
            -- saidas
            pwm_goleiro        => pwm_goleiro_out,
            pwm_batedor_dir    => pwm_batedor_dir_out,
            pwm_batedor_esq    => pwm_batedor_esq_out,
            trigger            => trigger_out,
            saida_serial       => saida_serial_out,
            -- depuracao
            db_fim_preparacao  => db_fim_preparacao_out,
            db_fim_transmissao => db_fim_transmissao_out,
            db_trigger         => open,
            db_echo            => open,
            hex0               => open,
            hex1               => open,
            hex2               => open,
            hex3               => open,
            hex4               => open,
            hex5               => open
        );

    -- geracao dos sinais de entrada (estimulos)
    stimulus: process is
    begin
    
        assert false report "Inicio das simulacoes" severity note;
        keep_simulating <= '1';
        
        ---- valores iniciais ----
        iniciar_in <= '0';
        echo_in  <= '0';

        ---- inicio: reset ----
        wait for 2*clockPeriod;
        reset_in <= '1'; 
        wait for 2 us;
        reset_in <= '0';
        wait until falling_edge(clock_in);

        wait until db_fim_transmissao_out = '1'; -- espera transmitir inicio

        ---- loop pelas posicoes de teste ----
        for i in posicoes_teste'range loop
            
            assert false report 
            "Jogo " & integer'image(posicoes_teste(i).jogo) & 
            " - Rodada " & integer'image(posicoes_teste(i).rodada) 
            severity note;

            if posicoes_teste(i).rodada = 1 then
                -- aciona iniciar
                wait for 1 us;
                iniciar_in <= '1';
                wait for 1 us;
                iniciar_in <= '0';
            end if;

            -- Jogada de A

            wait until db_fim_transmissao_out = '1'; -- espera transmitir preparacao

            -- envia dadoB
            serial_data <= posicoes_teste(i).dadoB;
            wait for 2*bitPeriod; -- aguarda 2 periodos de bit antes de enviar
            UART_WRITE_BYTE ( Data_In=>serial_data, Serial_Out=>entrada_serial_in );
            entrada_serial_in <= '1'; -- repouso
            wait for bitPeriod;

            -- wait until db_fim_preparacao_out = '1'; -- espera fim de preparacao

            wait until db_fim_transmissao_out = '1'; -- espera transmitir batedor
            
            if posicoes_teste(i).posicaoA = '0' then
                -- bater direita
                wait for 1 us;
                bater_direita_in <= '1';
                wait for 1 us;
                bater_direita_in <= '0';
            else
                -- bater esquerda
                wait for 1 us;
                bater_esquerda_in <= '1';
                wait for 1 us;
                bater_esquerda_in <= '0';
            end if;

            -- determina largura do pulso echo para A
            larguraPulsoA <= posicoes_teste(i).tempoA * 1 us;
            
            -- espera pelo pulso trigger
            wait until falling_edge(trigger_out);

            -- espera por 400us (simula tempo entre trigger e echo)
            wait for 400 us;
        
            -- gera pulso de echo (largura = larguraPulso)
            echo_in <= '1';
            wait for larguraPulsoA;
            echo_in <= '0';

            wait until db_fim_transmissao_out = '1'; -- espera transmitir informacoes
            
            -- Jogada de B
            
            if posicoes_teste(i).tempoB /= 0 then
                wait until db_fim_transmissao_out = '1'; -- espera transmitir preparacao

                -- envia dadoB
                serial_data <= posicoes_teste(i).dadoA;
                wait for 2*bitPeriod; -- aguarda 2 periodos de bit antes de enviar
                UART_WRITE_BYTE ( Data_In=>serial_data, Serial_Out=>entrada_serial_in );
                entrada_serial_in <= '1'; -- repouso
            wait for bitPeriod;

            wait until db_fim_transmissao_out = '1'; -- espera transmitir batedor

            if posicoes_teste(i).posicaoB = '0' then
                -- bater direita
                wait for 1 us;
                bater_direita_in <= '1';
                wait for 1 us;
                bater_direita_in <= '0';
            else
                -- bater esquerda
                wait for 1 us;
                bater_esquerda_in <= '1';
                wait for 1 us;
                bater_esquerda_in <= '0';
            end if;

            -- determina largura do pulso echo para A
            larguraPulsoB <= posicoes_teste(i).tempoB * 1 us;
            
            -- espera pelo pulso trigger
            wait until falling_edge(trigger_out);

            -- espera por 400us (simula tempo entre trigger e echo)
            wait for 400 us;
        
            -- gera pulso de echo (largura = larguraPulso)
            echo_in <= '1';
            wait for larguraPulsoB;
            echo_in <= '0';

            wait until db_fim_transmissao_out = '1'; -- espera transmitir informacoes
            end if;
        end loop;

        ---- final dos casos de teste da simulacao
        assert false report "Fim das simulacoes" severity note;
        keep_simulating <= '0';
        
        wait; -- fim da simulacao: aguarda indefinidamente
    end process;

end architecture;
