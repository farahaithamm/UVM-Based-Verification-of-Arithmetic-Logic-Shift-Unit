vlib work
vlog -cover sbcef -f src_files.list
vsim -coverage -voptargs=+acc work.top -classdebug -uvmcontrol=all
add wave /top/aif/*
run -all
coverage report -details -output coverage.txt
coverage save coverage.ucdb