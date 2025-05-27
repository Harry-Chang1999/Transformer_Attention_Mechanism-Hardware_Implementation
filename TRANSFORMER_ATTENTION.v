//----------------------------------------------------------------//
//- Digital IC Design 2025                                      -//
//- Lab08: Low-Power Synthesis                                  -//
//----------------------------------------------------------------//

//cadence translate_off
`include "/chipware path/CW_mult.v"
`include "/chipware path/CW_mult_pipe.v"
//cadence translate_on

module TRANSFORMER_ATTENTION(clk,
                             reset,
                             MATRIX_Q,
                             MATRIX_K,
                             MATRIX_V,
                             en,
                             done,
                             answer);

input        clk;
input        reset;
input        en;
input [3:0]  MATRIX_Q;
input [3:0]  MATRIX_K;
input [3:0]  MATRIX_V;

output reg [17:0] answer;
output reg        done;

reg [4:0]  state, next_state;
reg [9:0]  cycle_count;

reg [4:0]  store_Q[0:63];
reg [4:0]  store_K[0:63];
reg [4:0]  store_V[0:63];
reg [14:0] store_W[0:63];
reg [17:0] store_O[0:63];
reg [14:0] temp1[0:5];
reg [17:0] temp2[0:5];
reg        delay3;
reg [2:0]  delay1, delay2;
reg [5:0]  idx;
reg [5:0]  rightm, leftm;
reg [5:0]  countw, counto;
reg [6:0]  s3_count;
reg        done1;
reg [17:0] answer1;

wire [9:0]  result[0:7];
wire [19:0] result2[0:7];

integer i, j;
parameter s0 = 5'd0, s1 = 5'd1, s2 = 5'd2, s3 = 5'd3, finish = 5'd4;

// Multiplication units for QK computation
CW_mult #(.wA(5), .wB(5)) mul1(.A(store_Q[leftm]), .B(store_K[rightm]), .TC(1'b0), .Z(result[0]));
CW_mult #(.wA(5), .wB(5)) mul2(.A(store_Q[leftm+6'd1]), .B(store_K[rightm+6'd1]), .TC(1'b0), .Z(result[1]));
CW_mult #(.wA(5), .wB(5)) mul3(.A(store_Q[leftm+6'd2]), .B(store_K[rightm+6'd2]), .TC(1'b0), .Z(result[2]));
CW_mult #(.wA(5), .wB(5)) mul4(.A(store_Q[leftm+6'd3]), .B(store_K[rightm+6'd3]), .TC(1'b0), .Z(result[3]));
CW_mult #(.wA(5), .wB(5)) mul5(.A(store_Q[leftm+6'd4]), .B(store_K[rightm+6'd4]), .TC(1'b0), .Z(result[4]));
CW_mult #(.wA(5), .wB(5)) mul6(.A(store_Q[leftm+6'd5]), .B(store_K[rightm+6'd5]), .TC(1'b0), .Z(result[5]));
CW_mult #(.wA(5), .wB(5)) mul7(.A(store_Q[leftm+6'd6]), .B(store_K[rightm+6'd6]), .TC(1'b0), .Z(result[6]));
CW_mult #(.wA(5), .wB(5)) mul8(.A(store_Q[leftm+6'd7]), .B(store_K[rightm+6'd7]), .TC(1'b0), .Z(result[7]));

// Multiplication units for attention computation
CW_mult #(.wA(15), .wB(5)) mul9(.A(store_W[leftm]), .B(store_V[rightm]), .TC(1'b0), .Z(result2[0]));
CW_mult #(.wA(15), .wB(5)) mul10(.A(store_W[leftm+6'd1]), .B(store_V[rightm+6'd8]), .TC(1'b0), .Z(result2[1]));
CW_mult #(.wA(15), .wB(5)) mul11(.A(store_W[leftm+6'd2]), .B(store_V[rightm+6'd16]), .TC(1'b0), .Z(result2[2]));
CW_mult #(.wA(15), .wB(5)) mul12(.A(store_W[leftm+6'd3]), .B(store_V[rightm+6'd24]), .TC(1'b0), .Z(result2[3]));
CW_mult #(.wA(15), .wB(5)) mul13(.A(store_W[leftm+6'd4]), .B(store_V[rightm+6'd32]), .TC(1'b0), .Z(result2[4]));
CW_mult #(.wA(15), .wB(5)) mul14(.A(store_W[leftm+6'd5]), .B(store_V[rightm+6'd40]), .TC(1'b0), .Z(result2[5]));
CW_mult #(.wA(15), .wB(5)) mul15(.A(store_W[leftm+6'd6]), .B(store_V[rightm+6'd48]), .TC(1'b0), .Z(result2[6]));
CW_mult #(.wA(15), .wB(5)) mul16(.A(store_W[leftm+6'd7]), .B(store_V[rightm+6'd56]), .TC(1'b0), .Z(result2[7]));

//state, next_state
always @(posedge clk or posedge reset) begin
    if(reset) state <= s0;
    else state <= next_state;
end

always @(*) begin
    case(state)
        s0: next_state = (idx == 6'd63) ? s1 : s0;
        s1: next_state = (countw == 6'd63) ? s2 : s1;
        s2: next_state = (counto == 6'd63) ? s3 : s2;
        s3: next_state = s3;
        default: next_state = s0;
    endcase
end

//done
always @(posedge clk or posedge reset) begin
    if(reset) begin
        done <= 1'b0;
    end
    else begin
        if(s3_count == 7'd64) done <= 1'b0;
        else begin
            if(state == s3) done <= 1'b1;
            else done <= 1'b0;
        end
    end
end

//answer
always @(posedge clk or posedge reset) begin
    if(reset) begin
        answer <= 18'd0;
    end
    else begin
        if(state == s3) answer <= store_O[s3_count];
    end
end

//s3_count
always @(posedge clk or posedge reset) begin
    if(reset) begin
        s3_count <= 7'd0;
    end
    else begin
        if(state == s3) s3_count <= s3_count + 7'd1;
        else s3_count <= 7'd0;
    end
end

//idx
always @(posedge clk or posedge reset) begin
    if(reset) begin
        idx <= 6'd0;
    end
    else begin
        if(en == 1'b1) begin
            if(idx < 6'd63) idx <= idx + 6'd1;
        end
    end
end

//delay1
always @(posedge clk or posedge reset) begin
    if(reset) begin
        delay1 <= 3'd0;
    end
    else begin
        if(state == s1) begin
            if(delay1 < 3'd2) delay1 <= delay1 + 3'd1;
        end
    end
end

//delay2
always @(posedge clk or posedge reset) begin
    if(reset) begin
        delay2 <= 3'd0;
    end
    else begin
        if(state == s2) begin
            if(delay2 < 3'd2) delay2 <= delay2 + 3'd1;
        end
    end
end

//temp1
always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(j = 0; j < 6; j = j + 1) temp1[j] <= 15'd0;
    end
    else begin
        if(state == s1) begin
            temp1[0] <= result[0] + result[1];
            temp1[1] <= result[2] + result[3];
            temp1[2] <= result[4] + result[5];
            temp1[3] <= result[6] + result[7];
            temp1[4] <= temp1[0] + temp1[1];
            temp1[5] <= temp1[2] + temp1[3];
        end
    end
end

//temp2
always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(j = 0; j < 6; j = j + 1) temp2[j] <= 18'd0;
    end
    else begin
        if(state == s2) begin
            temp2[0] <= result2[0] + result2[1];
            temp2[1] <= result2[2] + result2[3];
            temp2[2] <= result2[4] + result2[5];
            temp2[3] <= result2[6] + result2[7];
            temp2[4] <= temp2[0] + temp2[1];
            temp2[5] <= temp2[2] + temp2[3];
        end
    end
end

//countw
always @(posedge clk or posedge reset) begin
    if(reset) begin
        countw <= 6'd0;
    end
    else begin
        if(state == s1) begin
            if(delay1 == 3'd2) begin
                if(countw < 6'd63) countw <= countw + 6'd1;
            end
        end
    end
end

//counto
always @(posedge clk or posedge reset) begin
    if(reset) begin
        counto <= 6'd0;
    end
    else begin
        if(state == s2) begin
            if(delay2 == 3'd2) begin
                if(counto < 6'd63) counto <= counto + 6'd1;
            end
        end
    end
end

//store_W
always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i = 0; i < 64; i = i + 1) store_W[i] <= 5'd0;
    end
    else begin
        if(state == s1) begin
            store_W[countw] <= temp1[4] + temp1[5];
        end
    end
end

//store_O
always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i = 0; i < 64; i = i + 1) store_O[i] <= 18'd0;
    end
    else begin
        if(state == s2) begin
            store_O[counto] <= temp2[4] + temp2[5];
        end
    end
end

//store_Q
always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i = 0; i < 64; i = i + 1) store_Q[i] <= 5'd0;
    end
    else begin
        if(state == s0) begin
            if(en == 1'b1) store_Q[idx] <= MATRIX_Q;
        end
    end
end

//store_K
always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i = 0; i < 64; i = i + 1) store_K[i] <= 5'd0;
    end
    else begin
        if(state == s0) begin
            if(en == 1'b1) store_K[idx] <= MATRIX_K;
        end
    end
end

//store_V
always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i = 0; i < 64; i = i + 1) store_V[i] <= 5'd0;
    end
    else begin
        if(state == s0) begin
            if(en == 1'b1) store_V[idx] <= MATRIX_V;
        end
    end
end

//rightm
always @(posedge clk or posedge reset) begin
    if(reset) begin
        rightm <= 6'd0;
    end
    else begin
        if(state == s1) begin
            if(rightm == 6'd56) rightm <= 6'd0;
            else if(countw == 6'd63) rightm <= 6'd0;
            else rightm <= rightm + 6'd8;
        end
        else if(state == s2) begin
            if(rightm == 6'd7) rightm <= 6'd0;
            else rightm <= rightm + 6'd1;
        end
    end
end

//leftm
always @(posedge clk or posedge reset) begin
    if(reset) begin
        leftm <= 6'd0;
    end
    else begin
        if(state == s1) begin
            if(rightm == 6'd56) leftm <= leftm + 6'd8;
        end
        else if(state == s2) begin
            if(rightm == 6'd7) leftm <= leftm + 6'd8;
        end
    end
end

endmodule