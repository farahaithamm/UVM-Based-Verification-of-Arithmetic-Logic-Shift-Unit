import uvm_pkg::*;
`include "uvm_macros.svh"
import alsu_test_pkg::*;

module top();
bit clk;

initial begin
    clk = 0;
    forever #1 clk = ~clk;
end

alsu_if aif (clk);
ALSU dut (
    .A(aif.A), .B(aif.B), .cin(aif.cin), .serial_in(aif.serial_in),
    .red_op_A(aif.red_op_A), .red_op_B(aif.red_op_B), .opcode(aif.opcode),
    .bypass_A(aif.bypass_A), .bypass_B(aif.bypass_B), .clk(aif.clk),
    .rst(aif.rst), .direction(aif.direction), .leds(aif.leds), .out(aif.out)
);

bind ALSU alsu_sva alsu_sva_inst(.A(aif.A), .B(aif.B), .cin(aif.cin), .serial_in(aif.serial_in),
    .red_op_A(aif.red_op_A), .red_op_B(aif.red_op_B), .opcode(aif.opcode),
    .bypass_A(aif.bypass_A), .bypass_B(aif.bypass_B), .clk(aif.clk),
    .rst(aif.rst), .direction(aif.direction), .leds(aif.leds), .out(aif.out));

initial begin
    uvm_config_db #(virtual alsu_if)::set(null, "uvm_test_top", "ALSU_IF", aif);
    run_test("alsu_test");
end

endmodule