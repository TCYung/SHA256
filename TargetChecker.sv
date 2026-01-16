//this code is to convert the 32 bit difficulty value to allow easy comparison between the hash and the calculated difficulty
//wondering if it would be faster to check the number of zeros at the start instead of just a less than operator

module targetchecker
    (   input clk,
        input [31:0] difficulty,
        output reg [255:0] hash_target
);

reg [7:0] total_length;
reg [255:0] difficulty_target; 

always_comb begin
    total_length = difficulty[31:24];
end

always_ff @(posedge clk) begin 
    hash_target <= difficulty[23:0] * (1<<(8*(total_length - 3)));
end

endmodule