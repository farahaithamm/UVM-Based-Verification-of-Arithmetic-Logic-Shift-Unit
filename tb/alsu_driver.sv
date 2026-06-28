package alsu_driver_pkg;
import uvm_pkg::*;
import alsu_seq_item_pkg::*;
`include "uvm_macros.svh"

class alsu_driver extends uvm_driver #(alsu_seq_item);
    `uvm_component_utils(alsu_driver);

    virtual alsu_if aif;
    alsu_seq_item stim_seq_item;

    function new(string name = "alsu_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            stim_seq_item = alsu_seq_item::type_id::create("stim_seq_item");
            seq_item_port.get_next_item(stim_seq_item);
            aif.rst = stim_seq_item.rst;
            aif.cin = stim_seq_item.cin; 
            aif.red_op_A = stim_seq_item.red_op_A; 
            aif.red_op_B = stim_seq_item.red_op_B; 
            aif.bypass_A = stim_seq_item.bypass_A;
            aif.bypass_B = stim_seq_item.bypass_B; 
            aif.direction = stim_seq_item.direction; 
            aif.serial_in = stim_seq_item.serial_in; 
            aif.opcode = stim_seq_item.opcode;
            aif.A = stim_seq_item.A; 
            aif.B = stim_seq_item.B;
            @(negedge aif.clk);
            seq_item_port.item_done();
            `uvm_info("run_phase", stim_seq_item.convert2string_stimulus(), UVM_HIGH);
        end
    endtask
endclass
endpackage