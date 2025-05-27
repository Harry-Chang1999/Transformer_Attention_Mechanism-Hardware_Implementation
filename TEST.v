`timescale 1ns/1ps

`define CYCLE     0.55
`define EXPECT    "./dat/goal.dat"
`define QUERY     "./dat/Q1.dat"
`define KEY       "./dat/K1.dat"
`define VALUE     "./dat/V1.dat"

`include "TRANSFORMER_ATTENTION.v"

module TEST;

parameter t_reset = `CYCLE*2;

reg clk;
reg reset;
reg MATRIX_rd;
reg en;
reg [17:0] expect_M[0:63];
reg [6:0] index;
reg [6:0] ans_index;
reg [6:0] err;
reg over;
reg [8:0] latency_clk;
reg latency;

wire [3:0] MATRIX_Q;
wire [3:0] MATRIX_K;
wire [3:0] MATRIX_V;
wire done;
wire [17:0] answer;

TRANSFORMER_ATTENTION TRANSFORMER_ATTENTION(.clk(clk), .reset(reset), .MATRIX_Q(MATRIX_Q), .MATRIX_K(MATRIX_K), .MATRIX_V(MATRIX_V), .en(en), .done(done), .answer(answer));

MATRIXQ  MATRIXQ1(.MATRIX_rd(MATRIX_rd), .MATRIX_Q(MATRIX_Q), .index(index), .clk(clk), .reset(reset));

MATRIXK  MATRIXK1(.MATRIX_rd(MATRIX_rd), .MATRIX_K(MATRIX_K), .index(index), .clk(clk), .reset(reset));

MATRIXV  MATRIXV1(.MATRIX_rd(MATRIX_rd), .MATRIX_V(MATRIX_V), .index(index), .clk(clk), .reset(reset));

initial begin
    clk         = 1'b0;
    reset       = 1'b1;
    index       = 7'b0;
    MATRIX_rd   = 1'b0;
    err         = 1'b0;
    over        = 1'b0;
    ans_index   = 1'b0;
    latency_clk = 9'b0;
    latency     = 1'b0;
    en          = 1'b0;
end

always begin #(`CYCLE/2.0) clk = ~clk; end

initial begin@(negedge clk)
    reset = 1'b1;
    #t_reset reset = 1'b0;
end

initial begin
    $toggle_count("TEST.TRANSFORMER_ATTENTION");
    $toggle_count_mode(1);

    $fsdbDumpfile("TRANSFORMER_ATTENTION.fsdb");
    $fsdbDumpvars;
    $fsdbDumpMDA;
    
    #1000 $display("--------------------ERROR--------------------\n");
    $finish;
end

initial @(negedge MATRIX_rd)
begin
    latency = 1'b1;
end

always@(negedge clk)begin
    if(latency) begin
        latency_clk <= latency_clk + 1;
    end
end

always@(negedge clk)begin
    if(MATRIX_rd && index == 7'd0) begin
        en <= 1'b1;
    end
    else if (index == 7'd64)begin
        en <= 1'b0;
    end
end

always@(negedge clk)begin
    if(!reset) begin
        if(index == 7'd64)
            MATRIX_rd <= 1'b0;
        else
            MATRIX_rd <= 1'b1;
    end
end

always@(negedge clk)begin
    if(!reset)begin
        if(MATRIX_rd == 1'b1 && index <= 7'd63)begin
            index <= index + 7'd1;
        end
    end
end

initial begin
    @ (negedge reset) $readmemb (`EXPECT , expect_M);
end

always@(negedge clk)begin
    if(done)begin
        if(ans_index == 63)begin
            over <= 1'b1;
        end
    end
end

always@(negedge clk)begin
    if(done)begin
        ans_index <= ans_index + 1;
    end
end

// 213
always@(negedge clk)begin
    if(latency_clk == 250 && done == 1'b0) begin
        $display ("\n //// Error: Your first output must smaller than 250 clock cycles. //// \n " );
        #10 $finish;
    end
end

always@(negedge clk)begin
    if(done)begin
        if(ans_index <= 63)begin
            if(answer !== expect_M[ans_index])begin
                $display("ERROR at %d:output %d !=expect %d ",ans_index, answer, expect_M[ans_index]);
                err = err + 1;
            end
            else if(answer === 8'dx)begin
                $display("ERROR at %d:output %d !=expect %d ",ans_index, answer, expect_M[ans_index]);
                err = err + 1;
            end
        end
    end
end

always@(negedge clk)begin
    if(done)begin
        if(err == 0 && over == 1'b1)begin
            $display("------------- All data have been generated successfully!-------------\n");
            $display("--------------------------------- ALL PASS ---------------------------------\n");
            
            $toggle_count_report_flat("TRANSFORMER_ATTENTION.tcf", "TEST.TRANSFORMER_ATTENTION");
            #10 $finish;
        end
        else if(over == 1'b1)begin
            $display("There are %d errors!\n",err);
            
            $toggle_count_report_flat("TRANSFORMER_ATTENTION.tcf", "TEST.TRANSFORMER_ATTENTION");
            #10 $finish;
        end
    end
end

endmodule

module MATRIXQ (MATRIX_rd, MATRIX_Q, index, clk, reset);
input          MATRIX_rd;
input [6:0]    index;
output [3:0]   MATRIX_Q;
input          clk, reset;

reg [3:0] sti_Q [0:63];
integer i;

reg    [3:0]    MATRIX_Q;

initial begin
    @ (negedge reset) $readmemb (`QUERY , sti_Q);
end

always@(negedge clk)
    if (MATRIX_rd && index <= 63) MATRIX_Q <= sti_Q[index];
    else MATRIX_Q <= 4'b0;

endmodule

module MATRIXK (MATRIX_rd, MATRIX_K, index, clk, reset);
input          MATRIX_rd;
input [6:0]    index;
output [3:0]   MATRIX_K;
input          clk, reset;

reg [3:0] sti_K [0:63];
integer i;

reg    [3:0]    MATRIX_K;

initial begin
    @ (negedge reset) $readmemb (`KEY , sti_K);
end

always@(negedge clk)
    if (MATRIX_rd && index <= 63) MATRIX_K <= sti_K[index];
    else MATRIX_K <= 4'b0;

endmodule

module MATRIXV (MATRIX_rd, MATRIX_V, index, clk, reset);
input          MATRIX_rd;
input [6:0]    index;
output [3:0]   MATRIX_V;
input          clk, reset;

reg [3:0] sti_V [0:63];

reg    [3:0]    MATRIX_V;

initial begin
    @ (negedge reset) $readmemb (`VALUE , sti_V);
end

always@(negedge clk)
    if (MATRIX_rd && index <= 63) MATRIX_V <= sti_V[index];
    else MATRIX_V <= 4'b0;

endmodule