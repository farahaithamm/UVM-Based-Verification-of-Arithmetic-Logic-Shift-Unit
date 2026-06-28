package alsu_seq_item_pkg;
import uvm_pkg::*;
import shared_pkg::*;
`include "uvm_macros.svh"

class alsu_seq_item extends uvm_sequence_item;
    `uvm_object_utils(alsu_seq_item);
    rand logic cin, rst, red_op_A, red_op_B, bypass_A, bypass_B, direction, serial_in;
    rand opcode_e opcode;
    rand logic signed [2:0] A, B;
    logic [15:0] leds;
    logic signed [5:0] out;
    
    function new(string name = "alsu_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("%s rst=%0b, cin=%0b, red_op_A=%0b, red_op_B=%0b, bypass_A=%0b, bypass_B=%0b, direction=%0b, serial_in=%0b, opcode=%0d, A=%0d, B=%0d, out=%0d, leds=0x%0h",
            super.convert2string(),
            rst, cin, red_op_A, red_op_B, bypass_A, bypass_B,
            direction, serial_in, opcode, A, B, out, leds);
    endfunction

    function string convert2string_stimulus();
        return $sformatf("rst=%0b, cin=%0b, red_op_A=%0b, red_op_B=%0b, bypass_A=%0b, bypass_B=%0b, direction=%0b, serial_in=%0b, opcode=%0d, A=%0d, B=%0d",
            rst, cin, red_op_A, red_op_B, bypass_A, bypass_B,
            direction, serial_in, opcode, A, B);
    endfunction

    constraint rst_const{
        rst dist {1'b0 :/ 95 , 1'b1 :/ 5};
    }

    constraint A_B_const{
        if(opcode == ADD || opcode == MULT){
            A dist {0 :/ 30, 3 :/ 30, -4 :/ 30, [1:2] :/ 5, [-3:-1] :/ 5};
            B dist {0 :/ 30, 3 :/ 30, -4 :/ 30, [1:2] :/ 5, [-3:-1] :/ 5};
        }

        if (opcode inside {OR, XOR} && red_op_A && !red_op_B) {
            A dist {1 :/ 30, 2 :/ 30, -4 :/ 30, [-3:0] :/ 10};
            B == 3'b000;
        }

        else if (opcode inside {OR, XOR} && red_op_B && !red_op_A) {
            B dist {1 :/ 30, 2 :/ 30, -4 :/ 30, [-3:0] :/ 10};
            A == 3'b000;
        }

        else if (opcode inside {OR, XOR} && red_op_B && red_op_A) {
            B dist {1 :/ 30, 2 :/ 30, -4 :/ 30, [-3:0] :/ 10};
            A dist {1 :/ 30, 2 :/ 30, -4 :/ 30, [-3:0] :/ 10};
        }
    }

    constraint opcode_const{
        opcode dist {[0:5] :/ 90 , [6:7] :/ 10};
    }

    constraint bypass_const{
        bypass_A dist {1'b0 :/ 90, 1'b1 :/ 10};
        bypass_B dist {1'b0 :/ 90, 1'b1 :/ 10};
    }


endclass
endpackage