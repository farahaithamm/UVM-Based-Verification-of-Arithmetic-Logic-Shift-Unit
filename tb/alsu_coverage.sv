package alsu_coverage_pkg;
import alsu_seq_item_pkg::*;
import uvm_pkg::*;
import shared_pkg::*;
`include "uvm_macros.svh"

class alsu_coverage extends uvm_component;
    `uvm_component_utils(alsu_coverage);

    uvm_analysis_export #(alsu_seq_item) cov_export;
    uvm_tlm_analysis_fifo #(alsu_seq_item) cov_fifo;
    alsu_seq_item seq_item_cov;

    covergroup Cov;
        A_cp: coverpoint seq_item_cov.A{
            bins A_data_0 = {0};
            bins A_data_max = {3};
            bins A_data_min = {-4};
            bins A_data_default = default;
        }

        A_cp1: coverpoint seq_item_cov.A iff (seq_item_cov.red_op_A){
            bins A_data_walkingones[] = {3'b001, 3'b010, 3'b100};
        }

        B_cp: coverpoint seq_item_cov.B{
            bins B_data_0 = {0};
            bins B_data_max = {3};
            bins B_data_min = {-4};
            bins B_data_default = default;
        }

        B_cp1: coverpoint seq_item_cov.B  iff (seq_item_cov.red_op_B && !seq_item_cov.red_op_A){
            bins B_data_walkingones[] = {3'b001, 3'b010, 3'b100};
        }

        cin_cp: coverpoint seq_item_cov.cin;

        direction_cp: coverpoint seq_item_cov.direction;

        serial_in_cp: coverpoint seq_item_cov.serial_in;

        red_op_A_cp: coverpoint seq_item_cov.red_op_A;

        ALU_cp: coverpoint seq_item_cov.opcode{
            bins Bins_shift[] = {SHIFT, ROTATE};
            bins Bins_arith[] = {ADD, MULT};
            bins Bins_bitwise[] = {OR, XOR};
            illegal_bins Bins_invalid[] = {INVALID_6, INVALID_7};
        }

        AB_addmul: cross A_cp, B_cp iff (seq_item_cov.opcode inside {ADD, MULT});

        cin_add: cross ALU_cp, cin_cp{
            bins cin0_crp = binsof(ALU_cp) intersect {ADD} && binsof(cin_cp) intersect {0};
            bins cin1_crp = binsof(ALU_cp) intersect {ADD} && binsof(cin_cp) intersect {1};
            option.cross_auto_bin_max = 0;
        }

        direction_rotshift: cross ALU_cp, direction_cp{
            bins dir0_crp = binsof(ALU_cp.Bins_shift) && binsof(direction_cp) intersect {0};
            bins dir1_crp = binsof(ALU_cp.Bins_shift) && binsof(direction_cp) intersect {1};
            option.cross_auto_bin_max = 0;
        }
        serial_in_shift: cross ALU_cp, serial_in_cp{
            bins cin0_crp = binsof(ALU_cp) intersect {SHIFT} && binsof(serial_in_cp) intersect {0};
            bins cin1_crp = binsof(ALU_cp) intersect {SHIFT} && binsof(serial_in_cp) intersect {1};
            option.cross_auto_bin_max = 0;
        }
        AB_orxorA: cross A_cp1, B_cp iff(seq_item_cov.red_op_A && seq_item_cov.opcode inside {OR, XOR}){
            bins AB1_crp = binsof(A_cp1) intersect {1} && binsof(B_cp) intersect {0};
            bins AB2_crp = binsof(A_cp1) intersect {2} && binsof(B_cp) intersect {0};
            bins AB3_crp = binsof(A_cp1) intersect {-4} && binsof(B_cp) intersect {0};
            option.cross_auto_bin_max = 0;
        }
        AB_orxorB: cross A_cp, B_cp1 iff(seq_item_cov.red_op_B && seq_item_cov.opcode inside {OR, XOR}){
            bins AB4_crp = binsof(B_cp1) intersect {1} && binsof(A_cp) intersect {0};
            bins AB5_crp = binsof(B_cp1) intersect {2} && binsof(A_cp) intersect {0};
            bins AB6_crp = binsof(B_cp1) intersect {-4} && binsof(A_cp) intersect {0};
            option.cross_auto_bin_max = 0;
        }
        red_orxor: cross ALU_cp, red_op_A_cp{
            bins red1_cp = binsof(ALU_cp.Bins_shift) && binsof(red_op_A_cp) intersect {1};
            bins red2_cp = binsof(ALU_cp.Bins_arith) && binsof(red_op_A_cp) intersect {1};
            option.cross_auto_bin_max = 0;
        }

    endgroup

    function new(string name = "alsu_coverage", uvm_component parent = null);
        super.new(name, parent);
        Cov = new();
    endfunction

    function void build_phase(uvm_phase phase);
       super.build_phase(phase); 
       cov_export = new("cov_export", this);
       cov_fifo = new("cov_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        cov_export.connect(cov_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            cov_fifo.get(seq_item_cov);
            Cov.sample();
        end
    endtask
endclass

endpackage