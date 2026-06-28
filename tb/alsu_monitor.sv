package alsu_monitor_pkg;
import uvm_pkg::*;
import shared_pkg::*;
import alsu_seq_item_pkg::*;
`include "uvm_macros.svh"

class alsu_monitor extends uvm_monitor;
    `uvm_component_utils(alsu_monitor);

    virtual alsu_if aif;
    alsu_seq_item rsp_seq_item;
    uvm_analysis_port #(alsu_seq_item) mon_ap;

    function new(string name = "alsu_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_ap = new("mon_ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            rsp_seq_item = alsu_seq_item::type_id::create("rsp_seq_item");
            @(negedge aif.clk);
            rsp_seq_item.rst = aif.rst;
            rsp_seq_item.cin = aif.cin;
            rsp_seq_item.red_op_A = aif.red_op_A;
            rsp_seq_item.red_op_B = aif.red_op_B;
            rsp_seq_item.bypass_A = aif.bypass_A;
            rsp_seq_item.bypass_B = aif.bypass_B;
            rsp_seq_item.direction = aif.direction;
            rsp_seq_item.serial_in = aif.serial_in;
            rsp_seq_item.opcode = opcode_e'(aif.opcode);
            rsp_seq_item.A = aif.A;
            rsp_seq_item.B = aif.B;
            rsp_seq_item.out = aif.out;
            rsp_seq_item.leds = aif.leds;
            mon_ap.write(rsp_seq_item);
            `uvm_info("run_phase", rsp_seq_item.convert2string(), UVM_HIGH);
        end
    endtask
endclass
endpackage