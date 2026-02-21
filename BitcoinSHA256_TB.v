
module I2C_TB; 

    wire [255:0] first_hash;
    wire initial_hash_complete;
    wire final_hash_complete;
    wire [255:0] final_hash;
    reg [255:0] formatted_final_hash;
    wire [255:0] hash_target;

    reg rst = 0;
    reg hash_complete_flag = 0;
    reg valid_hash_found = 0;

    reg [255:0] hash_reset = 0; //this needs to be renamed in a bit, its the input hash for the initial_hashing, i think that its jumping the gun because its a non-zero value one the 2nd pass 
    //above is not true, the first hash that gets passed from .hash from initial hashing is causing final hasing to go right after the rst

    reg [31:0] nonce = 32'd396525939; //396525940 is the correct nonce to get the hash

    clock_gen testclk1 (clk);

    Pipelined_Bitcoin_SHA256 initial_hashing  (
        .clk (clk),
        .second_hash(1'b0),
        .input_hash1(hash_reset),
        .input_hash2(hash_reset),
        .input_hash3(hash_reset),
        .hash_status(1'b0),
        .hash_complete(initial_hash_complete),
        .hash1(first_hash),
        .hash2(first_hash),
        .hash3(first_hash),

        .nonce(nonce),

        .rst(rst),
        .hash_target(255'd0) //isnt used for the first hash
    );

    Pipelined_Bitcoin_SHA256 final_hashing  (
        .clk (clk),
        .second_hash(1'b1),

        .input_hash1(first_hash),
        .input_hash2(first_hash),
        .input_hash3(first_hash),
        
        .hash_status(initial_hash_complete),
        .hash_complete(final_hash_complete),
        .hash1(final_hash),
        .hash2(final_hash),
        .hash3(final_hash),

        .nonce(nonce),
        
        .rst(rst),
        .hash_target(hash_target)
   );

    Bitcoin_SHA256 initial_hashing_test  (
        .clk (clk),
        .second_hash(1'b0),
        .input_hash(hash_reset),
        .hash_status(1'b0),
        .hash_complete(initial_hash_complete),
        .hash(first_hash),

        .nonce(nonce),

        .rst(rst),
        .hash_target(255'd0) //isnt used for the first hash
    );

   Bitcoin_SHA256 final_hashing_test  (
        .clk (clk),
        .second_hash(1'b1),
        .input_hash(first_hash),
        .hash_status(initial_hash_complete),
        .hash_complete(final_hash_complete),
        .hash(final_hash),

        .nonce(nonce),
        
        .rst(rst),
        .hash_target(hash_target)
   );

    targetchecker target_checker (
        .clk(clk),
        .difficulty(32'h1701d936), //will probably need to create a module here later on to grab difficulty from bitcoin API
        .hash_target(hash_target)
    
    );

    //do something here to choose when to reset the program
    always @(posedge clk) begin
        if (formatted_final_hash < hash_target && final_hash_complete) begin
            valid_hash_found <= 1;
        end

        else begin
            if (final_hash_complete && !hash_complete_flag) begin //first hash should take double the amount of time as the 2nd hash therefore. i should see a wide pulse after initial hash goes high, then final hash small pulse and both pulses go low after 
                rst <= 1;
                nonce <= nonce + 1;
                hash_complete_flag <= 1;
                hash_reset <= 0;
            end

            if (!final_hash_complete && hash_complete_flag) begin
                rst <= 0;
                hash_complete_flag <= 0;
            end
        end
    end

    always @(*) begin
        assign formatted_final_hash = {<<8 {final_hash}};
    end

endmodule

module clock_gen (output reg clk);
    initial begin
        clk = 0;
    end
    
    always begin
        #1 clk = ~clk;
        
    end
endmodule

//sounds like i need to have a reset signal so that every time a nonce fails i reset the values of the hashing algorithm