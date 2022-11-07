onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -color Coral -height 22 -label Clock /comp_do_mundo_tb/dut/clock
add wave -noupdate -divider Entradas
add wave -noupdate -color Cyan -height 22 -label Reset /comp_do_mundo_tb/dut/reset
add wave -noupdate -color Cyan -height 22 -label Iniciar /comp_do_mundo_tb/dut/iniciar
add wave -noupdate -color Cyan -height 22 -label {Posição do batedor} /comp_do_mundo_tb/dut/posicao_batedor
add wave -noupdate -color Cyan -height 22 -label Bater /comp_do_mundo_tb/dut/bater
add wave -noupdate -color Cyan -height 22 -label Echo /comp_do_mundo_tb/dut/echo
add wave -noupdate -color Cyan -height 22 -label {Entrada serial} /comp_do_mundo_tb/dut/entrada_serial
add wave -noupdate -divider Saidas
add wave -noupdate -height 22 -label Trigger /comp_do_mundo_tb/dut/trigger
add wave -noupdate -height 22 -label {Saida serial} /comp_do_mundo_tb/dut/saida_serial
add wave -noupdate -divider Depuração
add wave -noupdate -color Orchid -height 22 -label {Fim da transmissão} /comp_do_mundo_tb/dut/db_fim_transmissao
add wave -noupdate -color Orchid -height 22 -label Ganhador /comp_do_mundo_tb/dut/db_ganhador
add wave -noupdate -color Orchid -height 22 -label {Reposiciona goleiro} /comp_do_mundo_tb/dut/s_reposiciona_goleiro
add wave -noupdate -color Orchid -height 22 -label {Habilita batedor} /comp_do_mundo_tb/dut/s_habilita_batedor
add wave -noupdate -color Orchid -height 22 -label {Posiciona goleiro} /comp_do_mundo_tb/dut/s_posiciona_goleiro
add wave -noupdate -color Orchid -height 22 -label {Verifica gol} /comp_do_mundo_tb/dut/s_verifica_gol
add wave -noupdate -color Orchid -height 22 -label Gol /comp_do_mundo_tb/dut/s_gol
add wave -noupdate -color Orchid -height 22 -label {Fim do pênalti} /comp_do_mundo_tb/dut/s_fim_penalti
add wave -noupdate -divider Placar
add wave -noupdate -color Gold -height 22 -label {Header (decimal)} -radix unsigned /comp_do_mundo_tb/dut/s_transcode
add wave -noupdate -color Gold -height 22 -label {Gols de A (decimal)} -radix unsigned /comp_do_mundo_tb/dut/s_gols_A
add wave -noupdate -color Gold -height 22 -label {Gols de B (decimal)} -radix unsigned /comp_do_mundo_tb/dut/s_gols_B
add wave -noupdate -color Gold -height 22 -label {Rodada atual (decimal)} -radix unsigned /comp_do_mundo_tb/dut/s_rodada
add wave -noupdate -color Gold -height 22 -label {Caracter a ser transmitido (decimal)} -radix ascii /comp_do_mundo_tb/dut/transmissor/construtor/caracter_trans
add wave -noupdate -color Gold -height 22 -label {Estado atual da UC} /comp_do_mundo_tb/dut/UC/Eatual
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {304461190000 ps} 0} {{Cursor 2} {393476570000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 234
configure wave -valuecolwidth 118
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {304461190 ns} {344023590 ns}
