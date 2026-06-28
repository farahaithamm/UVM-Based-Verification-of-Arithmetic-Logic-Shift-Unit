package alsu_agent_pkg;
import uvm_pkg::*;
import alsu_sequencer_pkg::*;
import alsu_seq_item_pkg::*;
import alsu_driver_pkg::*;
import alsu_monitor_pkg::*;
import alsu_config_pkg::*;
`include "uvm_macros.svh"

class alsu_agent extends uvm_agent;
    `uvm_component_utils(alsu_agent);

    alsu_sequencer sqr;
    alsu_driver drv;
    alsu_monitor mon;
    alsu_config alsu_cfg;
    uvm_analysis_port #(alsu_seq_item) agt_ap;

    function new(string name = "alsu_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(alsu_config)::get(this, "", "CFG", alsu_cfg))
            `uvm_fatal("build_phase", "Test - Unable to get configuration object");

        sqr = alsu_sequencer::type_id::create("sqr", this);
        drv = alsu_driver::type_id::create("drv", this);
        mon = alsu_monitor::type_id::create("mon", this);
        agt_ap = new("agt_ap", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.aif = alsu_cfg.aif;
        mon.aif = alsu_cfg.aif;
        drv.seq_item_port.connect(sqr.seq_item_export);
        mon.mon_ap.connect(agt_ap);
    endfunction

endclass
endpackage