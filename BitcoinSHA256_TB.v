
module I2C_TB; 

    wire [255:0] first_hash;
    wire initial_hash_complete;
    wire final_hash_complete;
    wire [255:0] final_hash;
    wire [255:0] formatted_final_hash;

    clock_gen testclk1 (clk);

    Bitcoin_SHA256 initial_hashing  (
        .clk (clk),
        .second_hash(1'b0),
        .input_hash(256'd0),
        .hash_status(1'b0),
        .hash_complete(initial_hash_complete),
        .hash(first_hash)
    );

   Bitcoin_SHA256 final_hashing  (
        .clk (clk),
        .second_hash(1'b1),
        .input_hash(first_hash),
        .hash_status(initial_hash_complete),
        .hash_complete(final_hash_complete),
        .hash(final_hash)       
   );

    // always @(*) begin
    //     if (final_hash_complete) begin
    //         assign formatted_final_hash = {<<byte {final_hash}};
    //     end
    // end

endmodule

module clock_gen (output reg clk);
    initial begin
        clk = 0;
    end
    
    always begin
        #1 clk = ~clk;
        
    end
endmodule