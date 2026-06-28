module alsu_sva(
    input logic clk, rst, cin, serial_in, red_op_A, red_op_B, bypass_A, bypass_B, direction,
    input logic [2:0] opcode,
    input logic signed [2:0] A, B,
    input logic [15:0] leds,
    input logic signed [5:0] out
);
    
always_comb begin
    if(rst) begin
        out_a: assert final(out == 6'b00_0000);
        leds_a: assert final(leds == 16'b0000_0000_0000_0000);
    end
end

assign invalid = ((red_op_A | red_op_B) & (opcode[1] | opcode[2])) | (opcode[1] & opcode[2]);

property p1;
    @(posedge clk) disable iff (rst) (invalid) |-> ##2 (leds == ~$past(leds));
endproperty

property p2;
    @(posedge clk) disable iff (rst) !(invalid) |-> ##2 (leds == 16'b0000_0000_0000_0000);
endproperty

property p3;
    @(posedge clk) disable iff (rst) (bypass_A) |-> ##2 (out == $past(A,2));
endproperty

property p4;
    @(posedge clk) disable iff (rst) (!bypass_A && bypass_B) |-> ##2 (out == $past(B,2));
endproperty

property p5;
    @(posedge clk) disable iff (rst) (!bypass_A && !bypass_B && invalid) |-> ##2 (out == 6'b00_0000);
endproperty

property p6;
    @(posedge clk) disable iff (rst) (!bypass_A && !bypass_B && !invalid && red_op_A && (opcode == 3'b000)) |-> ##2 (out == |$past(A,2));
endproperty

property p7;
    @(posedge clk) disable iff (rst) (!bypass_A && !bypass_B && !invalid && !red_op_A && red_op_B && (opcode == 3'b000)) |-> ##2 (out == |$past(B,2));
endproperty

property p8;
    @(posedge clk) disable iff (rst) (!bypass_A && !bypass_B && !invalid && !red_op_A && !red_op_B && (opcode == 3'b000)) |-> ##2 (out == $past(A,2) | $past(B,2));
endproperty

property p9;
    @(posedge clk) disable iff (rst) (!bypass_A && !bypass_B && !invalid && red_op_A && (opcode == 3'b001)) |-> ##2 (out == ^$past(A,2));
endproperty

property p10;
    @(posedge clk) disable iff (rst) (!bypass_A && !bypass_B && !invalid && !red_op_A && red_op_B && (opcode == 3'b001)) |-> ##2 (out == ^$past(B,2));
endproperty

property p11;
    @(posedge clk) disable iff (rst) (!bypass_A && !bypass_B && !invalid && !red_op_A && !red_op_B && (opcode == 3'b001)) |-> ##2 (out == $past(A,2) ^ $past(B,2));
endproperty

property p12;
    @(posedge clk) disable iff (rst) 
    (!bypass_A && !bypass_B && !invalid && (opcode == 3'b010)) |-> ##2 (out == {{3{$past(A[2],2)}}, $past(A,2)} + {{3{$past(B[2],2)}}, $past(B,2)} - $past(cin,2));
endproperty

property p13;
    @(posedge clk) disable iff (rst) (!bypass_A && !bypass_B && !invalid && (opcode == 3'b011)) |-> ##2 (out == $past(A,2) * $past(B,2));
endproperty

property p14;
    @(posedge clk) disable iff (rst) (!bypass_A && !bypass_B && !invalid && (opcode == 3'b100) && direction) |-> ##2 (out == {$past(out[4:0]), $past(serial_in,2)});
endproperty

property p15;
    @(posedge clk) disable iff (rst) (!bypass_A && !bypass_B && !invalid && (opcode == 3'b100) && !direction) |-> ##2 (out == {$past(serial_in,2), $past(out[5:1])});
endproperty

property p16;
    @(posedge clk) disable iff (rst) (!bypass_A && !bypass_B && !invalid && (opcode == 3'b101) && direction) |-> ##2 (out == {$past(out[4:0]), $past(out[5])});
endproperty

property p17;
    @(posedge clk) disable iff (rst) (!bypass_A && !bypass_B && !invalid && (opcode == 3'b101) && !direction) |-> ##2 (out == {$past(out[0]), $past(out[5:1])});
endproperty


p1_assert: assert property(p1);
p2_assert: assert property(p2);
p3_assert: assert property(p3);
p4_assert: assert property(p4);
p5_assert: assert property(p5);
p6_assert: assert property(p6);
p7_assert: assert property(p7);
p8_assert: assert property(p8);
p9_assert: assert property(p9);
p10_assert: assert property(p10);
p11_assert: assert property(p11);
p12_assert: assert property(p12);
p13_assert: assert property(p13);
p14_assert: assert property(p14);
p15_assert: assert property(p15);
p16_assert: assert property(p16);
p17_assert: assert property(p17);

p1_cover: cover property(p1);
p2_cover: cover property(p2);
p3_cover: cover property(p3);
p4_cover: cover property(p4);
p5_cover: cover property(p5);
p6_cover: cover property(p6);
p7_cover: cover property(p7);
p8_cover: cover property(p8);
p9_cover: cover property(p9);
p10_cover: cover property(p10);
p11_cover: cover property(p11);
p12_cover: cover property(p12);
p13_cover: cover property(p13);
p14_cover: cover property(p14);
p15_cover: cover property(p15);
p16_cover: cover property(p16);
p17_cover: cover property(p17);

endmodule