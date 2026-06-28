package alsu_scoreboard_pkg;
import alsu_seq_item_pkg::*;
import uvm_pkg::*;
import shared_pkg::*;
`include "uvm_macros.svh"

class alsu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(alsu_scoreboard);

    uvm_analysis_export #(alsu_seq_item) sb_export;
    uvm_tlm_analysis_fifo #(alsu_seq_item) sb_fifo;
    alsu_seq_item seq_item_sb;
    logic [15:0] leds_ref, leds_old;
    logic signed [5:0] out_ref, out_old;
    logic invalid;

    int error_count = 0;
    int correct_count = 0;

    function new(string name = "alsu_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sb_export = new("sb_export", this);
        sb_fifo = new("sb_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        sb_export.connect(sb_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            sb_fifo.get(seq_item_sb);
            ref_model(seq_item_sb);
            if(seq_item_sb.out != out_old) begin
                `uvm_error("run_phase", $sformatf("out_expected = %h, out = %h", seq_item_sb.out, out_old));
                error_count++;
            end
            else correct_count++;
            if(seq_item_sb.leds != leds_old) begin
                `uvm_error("run_phase", $sformatf("leds_expected = %h, leds = %h", seq_item_sb.leds, leds_old));
                error_count++;
            end
            else correct_count++;
        end
    endtask 

    task ref_model(alsu_seq_item seq_item_chk);
        out_old = (seq_item_chk.rst) ? 0 : out_ref;
        leds_old = (seq_item_chk.rst) ? 0 : leds_ref;
        invalid = ((seq_item_chk.red_op_A || seq_item_chk.red_op_B) && !(seq_item_chk.opcode == 0 || seq_item_chk.opcode == 1))
         || (seq_item_chk.opcode == 6 || seq_item_chk.opcode== 7);
        if (seq_item_chk.rst) begin
            out_ref = 0;
            leds_ref = 0;
        end
        else begin
            if(invalid) leds_ref = ~leds_ref;
            else leds_ref = 0;
            if (seq_item_chk.bypass_A) out_ref = { {3{seq_item_chk.A[2]}}, (seq_item_chk.A)};
            else if(seq_item_chk.bypass_B) out_ref = { {3{seq_item_chk.B[2]}}, (seq_item_chk.B)};
            else begin
                if (invalid) begin
                    out_ref = 0;
                end
                else begin
                    case(seq_item_chk.opcode)
                    OR: begin
                        if (seq_item_chk.red_op_A)  out_ref = |seq_item_chk.A;
                        else if(seq_item_chk.red_op_B) out_ref = |seq_item_chk.B;
                        else out_ref = { {3{seq_item_chk.A[2] | seq_item_chk.B[2]}}, (seq_item_chk.A | seq_item_chk.B) };
                    end
                    XOR: begin
                        if (seq_item_chk.red_op_A) out_ref = ^seq_item_chk.A;
                        else if(seq_item_chk.red_op_B) out_ref = ^seq_item_chk.B;
                        else out_ref = { {3{seq_item_chk.A[2] ^ seq_item_chk.B[2]}}, (seq_item_chk.A ^ seq_item_chk.B) };
                    end
                    ADD: out_ref = { {3{seq_item_chk.A[2]}} , seq_item_chk.A} + { {3{seq_item_chk.B[2]}} , seq_item_chk.B} + { {5{seq_item_chk.cin}} , seq_item_chk.cin};
                    MULT: out_ref = seq_item_chk.A * seq_item_chk.B;
                    SHIFT: out_ref = (seq_item_chk.direction) ?  {out_ref[4:0], seq_item_chk.serial_in} : {seq_item_chk.serial_in, out_ref[5:1]};
                    ROTATE: out_ref = (seq_item_chk.direction) ? {out_ref[4:0], out_ref[5]} : {out_ref[0], out_ref[5:1]};
                    default: out_ref = 0;
                    endcase
                end
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("report_phase", $sformatf("correct_count = %d, error_count = %d", correct_count, error_count), UVM_MEDIUM);
    endfunction

endclass

endpackage