//based off IEEE paper on parallelizing the sha256 algorithm
//inserting registers between the crtical paths (between areas that need to have modulo 232 addition)
//testing 3 nonce values at the same time 

module Pipelined_Bitcoin_SHA256
(   input clk,
    input rst,

    input second_hash, //0 means that its a 640 bit input, 1 means 256 bit input
    input [255:0] input_hash1, input_hash2, input_hash3, //isnt used on the 640 bit input, used on the 256 bit input (hash1 is the input_hash)

    input [255:0] hash_target, //the resultant hash needs to be less than this value

    input [31:0] nonce, //from top module this value gets changed every time the end hash is not correct

    input hash_status,
    output reg hash_complete,
    output reg [255:0] hash1, hash2, hash3
    
);

//for hash 1
reg [31:0] h0_hash1 = 32'h6a09e667;
reg [31:0] h1_hash1 = 32'hbb67ae85;
reg [31:0] h2_hash1 = 32'h3c6ef372;
reg [31:0] h3_hash1 = 32'ha54ff53a;
reg [31:0] h4_hash1 = 32'h510e527f;
reg [31:0] h5_hash1 = 32'h9b05688c;
reg [31:0] h6_hash1 = 32'h1f83d9ab;
reg [31:0] h7_hash1 = 32'h5be0cd19;

//for hash2
reg [31:0] h0_hash2 = 32'h6a09e667;
reg [31:0] h1_hash2 = 32'hbb67ae85;
reg [31:0] h2_hash2 = 32'h3c6ef372;
reg [31:0] h3_hash2 = 32'ha54ff53a;
reg [31:0] h4_hash2 = 32'h510e527f;
reg [31:0] h5_hash2 = 32'h9b05688c;
reg [31:0] h6_hash2 = 32'h1f83d9ab;
reg [31:0] h7_hash2 = 32'h5be0cd19;

//for hash3
reg [31:0] h0_hash3 = 32'h6a09e667;
reg [31:0] h1_hash3 = 32'hbb67ae85;
reg [31:0] h2_hash3 = 32'h3c6ef372;
reg [31:0] h3_hash3 = 32'ha54ff53a;
reg [31:0] h4_hash3 = 32'h510e527f;
reg [31:0] h5_hash3 = 32'h9b05688c;
reg [31:0] h6_hash3 = 32'h1f83d9ab;
reg [31:0] h7_hash3 = 32'h5be0cd19;

reg [31:0] k [0:63];

//for this test scenario we are going to be using bitcoin block 923948
//target hash = 000000000000000000001f276a92e92679e23e610e3392d7d15b1684089af45c

reg [31:0] bitcoin_version =  {<<byte {32'h3fff0000}};
reg [255:0] previous_hash = {<<byte {256'h00000000000000000000a94278b1c645a52dfc46bf6f985010f5626093b0eb9f}}; //this is the hash of block 923947
reg [255:0] merkle_root = {<<byte {256'h8d6f9f82908f4e916af2eb57010de762f46ea5923374898033b0599acf6c8bc0}};
reg [31:0] timestamp = {<<byte {32'h691A4FD1}}; 
reg [31:0] difficulty = {<<byte {32'd385997110}};

//reg [31:0] nonce = {<<byte {32'h7481a217}}; // 1954652695 in decimal

// block 937852 (for testing)
// reg [31:0] bitcoin_version =  {<<byte {32'h22c9a000}};
// reg [255:0] previous_hash = {<<byte {256'h00000000000000000000bfe45a95a7e7b0c955de787fc8d2026bdb91a0fc2915}}; //this is the hash of block 937851
// reg [255:0] merkle_root = {<<byte {256'h707af9794c1786fc5ff15cf1919eb6a9123626da869975d8eb3df960a0eb22c1}};
// reg [31:0] timestamp = {<<byte {32'd1771783753}}; //feb 22 26 1:09:13pm
// reg [31:0] difficulty = {<<byte {32'd386003715}};


reg [63:0] length_bits = 64'd640; //640 is the length of the bitcoin block header

reg [511:0] chunk1_hash1, chunk1_hash2, chunk1_hash3;
reg [511:0] chunk2_hash1, chunk2_hash2, chunk2_hash3;

reg [31:0] a_temp_hash1, b_temp_hash1, c_temp_hash1, d_temp_hash1, e_temp_hash1, f_temp_hash1, g_temp_hash1, h_temp_hash1;
reg [31:0] a_temp_hash2, b_temp_hash2, c_temp_hash2, d_temp_hash2, e_temp_hash2, f_temp_hash2, g_temp_hash2, h_temp_hash2;
reg [31:0] a_temp_hash3, b_temp_hash3, c_temp_hash3, d_temp_hash3, e_temp_hash3, f_temp_hash3, g_temp_hash3, h_temp_hash3;

initial begin
   k[0] = 32'h428a2f98;
   k[1] = 32'h71374491;
   k[2] = 32'hb5c0fbcf;
   k[3] = 32'he9b5dba5;
   k[4] = 32'h3956c25b;
   k[5] = 32'h59f111f1;
   k[6] = 32'h923f82a4;
   k[7] = 32'hab1c5ed5;
   k[8] = 32'hd807aa98;
   k[9] = 32'h12835b01;
   k[10] = 32'h243185be;
   k[11] = 32'h550c7dc3;
   k[12] = 32'h72be5d74;
   k[13] = 32'h80deb1fe;
   k[14] = 32'h9bdc06a7;
   k[15] = 32'hc19bf174;
   k[16] = 32'he49b69c1;
   k[17] = 32'hefbe4786;
   k[18] = 32'h0fc19dc6;
   k[19] = 32'h240ca1cc;
   k[20] = 32'h2de92c6f;
   k[21] = 32'h4a7484aa;
   k[22] = 32'h5cb0a9dc;
   k[23] = 32'h76f988da;
   k[24] = 32'h983e5152;
   k[25] = 32'ha831c66d;
   k[26] = 32'hb00327c8;
   k[27] = 32'hbf597fc7;
   k[28] = 32'hc6e00bf3;
   k[29] = 32'hd5a79147;
   k[30] = 32'h06ca6351;
   k[31] = 32'h14292967;
   k[32] = 32'h27b70a85;
   k[33] = 32'h2e1b2138;
   k[34] = 32'h4d2c6dfc;
   k[35] = 32'h53380d13;
   k[36] = 32'h650a7354;
   k[37] = 32'h766a0abb;
   k[38] = 32'h81c2c92e;
   k[39] = 32'h92722c85;
   k[40] = 32'ha2bfe8a1;
   k[41] = 32'ha81a664b;
   k[42] = 32'hc24b8b70;
   k[43] = 32'hc76c51a3;
   k[44] = 32'hd192e819;
   k[45] = 32'hd6990624;
   k[46] = 32'hf40e3585;
   k[47] = 32'h106aa070;
   k[48] = 32'h19a4c116;
   k[49] = 32'h1e376c08;
   k[50] = 32'h2748774c;
   k[51] = 32'h34b0bcb5;
   k[52] = 32'h391c0cb3;
   k[53] = 32'h4ed8aa4a;
   k[54] = 32'h5b9cca4f;
   k[55] = 32'h682e6ff3;
   k[56] = 32'h748f82ee;
   k[57] = 32'h78a5636f;
   k[58] = 32'h84c87814;
   k[59] = 32'h8cc70208;
   k[60] = 32'h90befffa;
   k[61] = 32'ha4506ceb;
   k[62] = 32'hbef9a3f7;
   k[63] = 32'hc67178f2;
   
end
reg chunk_flag = 0; //if 0 we are on chunk 1, if 1 we are on chunk 2

reg [31:0] w_chunk1_hash1 [0:63];
reg [31:0] w_chunk1_hash2 [0:63];
reg [31:0] w_chunk1_hash3 [0:63];

reg [31:0] w_chunk2_hash1 [0:63];
reg [31:0] w_chunk2_hash2 [0:63];
reg [31:0] w_chunk2_hash3 [0:63];

//unsure if the two below need separate variables for different hashes (should be fine)
reg [8:0] main_loop_counter = 0;
reg [8:0] extend_counter = 16;
reg main_loop_flag = 0;

//for chunk 1
reg [31:0] s0_1_hash1, s0_1_hash2, s0_1_hash3; 
reg [31:0] s1_1_hash1, s1_1_hash2, s1_1_hash3;

//for chunk 2
reg [31:0] s0_2_hash1, s0_2_hash2, s0_2_hash3;
reg [31:0] s1_2_hash1, s1_2_hash2, s1_2_hash3;

//below not needed anymore as different registers store the intermediate values
//reg [31:0] s1, ch, temp1, s0, maj, temp2; //temporary variables named according to sha2 wiki main loop 

reg [31:0] t11, t12, t1, t2, c_d; //parallelization variables (unsure if all of these variables can be shared between the 3 different hashes)
reg [255:0] p_hash1, p_hash2, p_hash3; //store the 3 output hashes from the 3x parallelization 

reg [7:0] state;
parameter idle_state = 8'b0000001; 
parameter w_chunk_initial = 8'b0000010; 
parameter w_chunk_extend = 8'b0000011;
parameter main_loop_chunks = 8'b0000100;
parameter main_loop_complete = 8'b0000110;

reg [7:0] main_loop_state;

parameter pipeline1 = 8'b0000111;
parameter pipeline2 = 8'b0001000;
parameter pipeline3 = 8'b0001001;
parameter pipeline4 = 8'b0001010;
parameter pipeline5 = 8'b0001011;
parameter pipeline6 = 8'b0001100;

parameter pipeline7 = 8'b0001101; //hash1 output
parameter pipeline8 = 8'b0001110; //2
parameter pipeline9 = 8'b0001111; //3


always_comb begin
    //w_chunk_extend chunk 1 and chunk 2
    s0_1_hash1 = ({w_chunk1_hash1[extend_counter-15][6:0], w_chunk1_hash1[extend_counter-15][31:7]}) ^ ({w_chunk1_hash1[extend_counter-15][17:0], w_chunk1_hash1[extend_counter-15][31:18]}) ^ (w_chunk1_hash1[extend_counter-15] >> 3); //right rotate 7, right rotate 18, right shift 3
    s1_1_hash1 = ({w_chunk1_hash1[extend_counter-2][16:0], w_chunk1_hash1[extend_counter-2][31:17]}) ^ ({w_chunk1_hash1[extend_counter-2][18:0], w_chunk1_hash1[extend_counter-2][31:19]}) ^ (w_chunk1_hash1[extend_counter-2] >> 10); //right rotate 17, right rotate 19, right shift 10

    s0_1_hash2 = ({w_chunk1_hash2[extend_counter-15][6:0], w_chunk1_hash2[extend_counter-15][31:7]}) ^ ({w_chunk1_hash2[extend_counter-15][17:0], w_chunk1_hash2[extend_counter-15][31:18]}) ^ (w_chunk1_hash2[extend_counter-15] >> 3); //right rotate 7, right rotate 18, right shift 3
    s1_1_hash2 = ({w_chunk1_hash2[extend_counter-2][16:0], w_chunk1_hash2[extend_counter-2][31:17]}) ^ ({w_chunk1_hash2[extend_counter-2][18:0], w_chunk1_hash2[extend_counter-2][31:19]}) ^ (w_chunk1_hash2[extend_counter-2] >> 10); //right rotate 17, right rotate 19, right shift 10

    s0_1_hash3 = ({w_chunk1_hash3[extend_counter-15][6:0], w_chunk1_hash3[extend_counter-15][31:7]}) ^ ({w_chunk1_hash3[extend_counter-15][17:0], w_chunk1_hash3[extend_counter-15][31:18]}) ^ (w_chunk1_hash3[extend_counter-15] >> 3); //right rotate 7, right rotate 18, right shift 3
    s1_1_hash3 = ({w_chunk1_hash3[extend_counter-2][16:0], w_chunk1_hash3[extend_counter-2][31:17]}) ^ ({w_chunk1_hash3[extend_counter-2][18:0], w_chunk1_hash3[extend_counter-2][31:19]}) ^ (w_chunk1_hash3[extend_counter-2] >> 10); //right rotate 17, right rotate 19, right shift 10

    //second pass only has 256 bits which only needs 1 chunk which means the below code doesnt need to be executed 
    if (!second_hash) begin
        s0_2_hash1 = ({w_chunk2_hash1[extend_counter-15][6:0], w_chunk2_hash1[extend_counter-15][31:7]}) ^ ({w_chunk2_hash1[extend_counter-15][17:0], w_chunk2_hash1[extend_counter-15][31:18]}) ^ (w_chunk2_hash1[extend_counter-15] >> 3); //right rotate 7, right rotate 18, right shift 3
        s1_2_hash1 = ({w_chunk2_hash1[extend_counter-2][16:0], w_chunk2_hash1[extend_counter-2][31:17]}) ^ ({w_chunk2_hash1[extend_counter-2][18:0], w_chunk2_hash1[extend_counter-2][31:19]}) ^ (w_chunk2_hash1[extend_counter-2] >> 10); //right rotate 17, right rotate 19, right shift 10
    
        s0_2_hash2 = ({w_chunk2_hash2[extend_counter-15][6:0], w_chunk2_hash2[extend_counter-15][31:7]}) ^ ({w_chunk2_hash2[extend_counter-15][17:0], w_chunk2_hash2[extend_counter-15][31:18]}) ^ (w_chunk2_hash2[extend_counter-15] >> 3); //right rotate 7, right rotate 18, right shift 3
        s1_2_hash2 = ({w_chunk2_hash2[extend_counter-2][16:0], w_chunk2_hash2[extend_counter-2][31:17]}) ^ ({w_chunk2_hash2[extend_counter-2][18:0], w_chunk2_hash2[extend_counter-2][31:19]}) ^ (w_chunk2_hash2[extend_counter-2] >> 10); //right rotate 17, right rotate 19, right shift 10
        
        s0_2_hash3 = ({w_chunk2_hash3[extend_counter-15][6:0], w_chunk2_hash3[extend_counter-15][31:7]}) ^ ({w_chunk2_hash3[extend_counter-15][17:0], w_chunk2_hash3[extend_counter-15][31:18]}) ^ (w_chunk2_hash3[extend_counter-15] >> 3); //right rotate 7, right rotate 18, right shift 3
        s1_2_hash3 = ({w_chunk2_hash3[extend_counter-2][16:0], w_chunk2_hash3[extend_counter-2][31:17]}) ^ ({w_chunk2_hash3[extend_counter-2][18:0], w_chunk2_hash3[extend_counter-2][31:19]}) ^ (w_chunk2_hash3[extend_counter-2] >> 10); //right rotate 17, right rotate 19, right shift 10
   
    end

    else begin
        s0_2_hash1 = 1'bX;
        s1_2_hash1 = 1'bX;

        s0_2_hash2 = 1'bX;
        s1_2_hash2 = 1'bX;

        s0_2_hash3 = 1'bX;
        s1_2_hash3 = 1'bX;
    end

end

always_ff @(posedge clk) begin 

    //reset for when the nonce is being incremented 
    if (rst) begin
        //for hash 1
        h0_hash1 = 32'h6a09e667;
        h1_hash1 = 32'hbb67ae85;
        h2_hash1 = 32'h3c6ef372;
        h3_hash1 = 32'ha54ff53a;
        h4_hash1 = 32'h510e527f;
        h5_hash1 = 32'h9b05688c;
        h6_hash1 = 32'h1f83d9ab;
        h7_hash1 = 32'h5be0cd19;

        //for hash2
        h0_hash2 = 32'h6a09e667;
        h1_hash2 = 32'hbb67ae85;
        h2_hash2 = 32'h3c6ef372;
        h3_hash2 = 32'ha54ff53a;
        h4_hash2 = 32'h510e527f;
        h5_hash2 = 32'h9b05688c;
        h6_hash2 = 32'h1f83d9ab;
        h7_hash2 = 32'h5be0cd19;

        //for hash3
        h0_hash3 = 32'h6a09e667;
        h1_hash3 = 32'hbb67ae85;
        h2_hash3 = 32'h3c6ef372;
        h3_hash3 = 32'ha54ff53a;
        h4_hash3 = 32'h510e527f;
        h5_hash3 = 32'h9b05688c;
        h6_hash3 = 32'h1f83d9ab;
        h7_hash3 = 32'h5be0cd19;
        
        hash_complete <= 0;
        state <= idle_state;
    end

    else begin
        case(state)	
            default: begin
            state <= idle_state;
            end
            
            idle_state: begin
                if (!second_hash) begin
                    chunk1_hash1 <= {bitcoin_version, previous_hash, merkle_root[255:32]};
                    chunk2_hash1 <= {merkle_root[31:0], timestamp, difficulty, nonce, 1'b1, 319'b0, length_bits};

                    chunk1_hash2 <= {bitcoin_version, previous_hash, merkle_root[255:32]};
                    chunk2_hash2 <= {merkle_root[31:0], timestamp, difficulty, nonce + 1, 1'b1, 319'b0, length_bits};

                    chunk1_hash3 <= {bitcoin_version, previous_hash, merkle_root[255:32]};
                    chunk2_hash3 <= {merkle_root[31:0], timestamp, difficulty, nonce + 2, 1'b1, 319'b0, length_bits};
                    state <= w_chunk_initial;
                end
                
                //not too sure if hash1 checking is necessary here or if i need to check all three
                
                if (second_hash && hash_status == 1 && input_hash1 !== 0) begin //hash status means that the first hash has finished (dont want the second hash to begin without output from 1st hash)
                    chunk1_hash1 <= {input_hash1, 1'b1, 191'b0, 64'd256};
                    chunk1_hash2 <= {input_hash2, 1'b1, 191'b0, 64'd256};
                    chunk1_hash3 <= {input_hash3, 1'b1, 191'b0, 64'd256};

                    state <= w_chunk_initial;
                end            
            end
                
            w_chunk_initial: begin
                w_chunk1_hash1[0] <= chunk1_hash1[511 - 0*32 : 480 - 0*32];		//[512 : 480]
                w_chunk1_hash1[1] <= chunk1_hash1[511 - 1*32 : 480 - 1*32];		//[479 : 448]
                w_chunk1_hash1[2] <= chunk1_hash1[511 - 2*32 : 480 - 2*32];		//[447 : 416]
                w_chunk1_hash1[3]  <= chunk1_hash1[511 - 3*32 : 480 - 3*32];	//[415 : 384]
                w_chunk1_hash1[4]  <= chunk1_hash1[511 - 4*32 : 480 - 4*32];	//[383 : 352]
                w_chunk1_hash1[5]  <= chunk1_hash1[511 - 5*32 : 480 - 5*32];	//[351 : 320]
                w_chunk1_hash1[6]  <= chunk1_hash1[511 - 6*32 : 480 - 6*32];	//[319 : 288]
                w_chunk1_hash1[7]  <= chunk1_hash1[511 - 7*32 : 480 - 7*32];	//[287 : 256]
                w_chunk1_hash1[8]  <= chunk1_hash1[511 - 8*32 : 480 - 8*32];	//[255 : 224]
                w_chunk1_hash1[9]  <= chunk1_hash1[511 - 9*32 : 480 - 9*32];	//[223 : 192]
                w_chunk1_hash1[10] <= chunk1_hash1[511 - 10*32: 480 - 10*32];	//[191 : 160]
                w_chunk1_hash1[11] <= chunk1_hash1[511 - 11*32: 480 - 11*32];	//[159 : 128]
                w_chunk1_hash1[12] <= chunk1_hash1[511 - 12*32: 480 - 12*32];	//[127 : 96]
                w_chunk1_hash1[13] <= chunk1_hash1[511 - 13*32: 480 - 13*32];	//[95  : 64]
                w_chunk1_hash1[14] <= chunk1_hash1[511 - 14*32: 480 - 14*32];	//[63  : 32]
                w_chunk1_hash1[15] <= chunk1_hash1[511 - 15*32: 480 - 15*32];	//[31  : 0]

                w_chunk1_hash2[0] <= chunk1_hash2[511 - 0*32 : 480 - 0*32];		//[512 : 480]
                w_chunk1_hash2[1] <= chunk1_hash2[511 - 1*32 : 480 - 1*32];		//[479 : 448]
                w_chunk1_hash2[2] <= chunk1_hash2[511 - 2*32 : 480 - 2*32];		//[447 : 416]
                w_chunk1_hash2[3]  <= chunk1_hash2[511 - 3*32 : 480 - 3*32];	//[415 : 384]
                w_chunk1_hash2[4]  <= chunk1_hash2[511 - 4*32 : 480 - 4*32];	//[383 : 352]
                w_chunk1_hash2[5]  <= chunk1_hash2[511 - 5*32 : 480 - 5*32];	//[351 : 320]
                w_chunk1_hash2[6]  <= chunk1_hash2[511 - 6*32 : 480 - 6*32];	//[319 : 288]
                w_chunk1_hash2[7]  <= chunk1_hash2[511 - 7*32 : 480 - 7*32];	//[287 : 256]
                w_chunk1_hash2[8]  <= chunk1_hash2[511 - 8*32 : 480 - 8*32];	//[255 : 224]
                w_chunk1_hash2[9]  <= chunk1_hash2[511 - 9*32 : 480 - 9*32];	//[223 : 192]
                w_chunk1_hash2[10] <= chunk1_hash2[511 - 10*32: 480 - 10*32];	//[191 : 160]
                w_chunk1_hash2[11] <= chunk1_hash2[511 - 11*32: 480 - 11*32];	//[159 : 128]
                w_chunk1_hash2[12] <= chunk1_hash2[511 - 12*32: 480 - 12*32];	//[127 : 96]
                w_chunk1_hash2[13] <= chunk1_hash2[511 - 13*32: 480 - 13*32];	//[95  : 64]
                w_chunk1_hash2[14] <= chunk1_hash2[511 - 14*32: 480 - 14*32];	//[63  : 32]
                w_chunk1_hash2[15] <= chunk1_hash2[511 - 15*32: 480 - 15*32];	//[31  : 0

                w_chunk1_hash3[0] <= chunk1_hash3[511 - 0*32 : 480 - 0*32];		//[512 : 480]
                w_chunk1_hash3[1] <= chunk1_hash3[511 - 1*32 : 480 - 1*32];		//[479 : 448]
                w_chunk1_hash3[2] <= chunk1_hash3[511 - 2*32 : 480 - 2*32];		//[447 : 416]
                w_chunk1_hash3[3]  <= chunk1_hash3[511 - 3*32 : 480 - 3*32];	//[415 : 384]
                w_chunk1_hash3[4]  <= chunk1_hash3[511 - 4*32 : 480 - 4*32];	//[383 : 352]
                w_chunk1_hash3[5]  <= chunk1_hash3[511 - 5*32 : 480 - 5*32];	//[351 : 320]
                w_chunk1_hash3[6]  <= chunk1_hash3[511 - 6*32 : 480 - 6*32];	//[319 : 288]
                w_chunk1_hash3[7]  <= chunk1_hash3[511 - 7*32 : 480 - 7*32];	//[287 : 256]
                w_chunk1_hash3[8]  <= chunk1_hash3[511 - 8*32 : 480 - 8*32];	//[255 : 224]
                w_chunk1_hash3[9]  <= chunk1_hash3[511 - 9*32 : 480 - 9*32];	//[223 : 192]
                w_chunk1_hash3[10] <= chunk1_hash3[511 - 10*32: 480 - 10*32];	//[191 : 160]
                w_chunk1_hash3[11] <= chunk1_hash3[511 - 11*32: 480 - 11*32];	//[159 : 128]
                w_chunk1_hash3[12] <= chunk1_hash3[511 - 12*32: 480 - 12*32];	//[127 : 96]
                w_chunk1_hash3[13] <= chunk1_hash3[511 - 13*32: 480 - 13*32];	//[95  : 64]
                w_chunk1_hash3[14] <= chunk1_hash3[511 - 14*32: 480 - 14*32];	//[63  : 32]
                w_chunk1_hash3[15] <= chunk1_hash3[511 - 15*32: 480 - 15*32];	//[31  : 0]

                if (!second_hash) begin
                    w_chunk2_hash1[0] <= chunk2_hash1[511 - 0*32 : 480 - 0*32];		//[512 : 480]
                    w_chunk2_hash1[1]  <= chunk2_hash1[511 - 1*32 : 480 - 1*32];	//[479 : 448]
                    w_chunk2_hash1[2]  <= chunk2_hash1[511 - 2*32 : 480 - 2*32];	//[447 : 416]
                    w_chunk2_hash1[3]  <= chunk2_hash1[511 - 3*32 : 480 - 3*32];	//[415 : 384]
                    w_chunk2_hash1[4]  <= chunk2_hash1[511 - 4*32 : 480 - 4*32];	//[383 : 352]
                    w_chunk2_hash1[5]  <= chunk2_hash1[511 - 5*32 : 480 - 5*32];	//[351 : 320]
                    w_chunk2_hash1[6]  <= chunk2_hash1[511 - 6*32 : 480 - 6*32];	//[319 : 288]
                    w_chunk2_hash1[7]  <= chunk2_hash1[511 - 7*32 : 480 - 7*32];	//[287 : 256]
                    w_chunk2_hash1[8]  <= chunk2_hash1[511 - 8*32 : 480 - 8*32];	//[255 : 224]
                    w_chunk2_hash1[9]  <= chunk2_hash1[511 - 9*32 : 480 - 9*32];	//[223 : 192]
                    w_chunk2_hash1[10] <= chunk2_hash1[511 - 10*32: 480 - 10*32];	//[191 : 160]
                    w_chunk2_hash1[11] <= chunk2_hash1[511 - 11*32: 480 - 11*32];	//[159 : 128]
                    w_chunk2_hash1[12] <= chunk2_hash1[511 - 12*32: 480 - 12*32];	//[127 : 96]
                    w_chunk2_hash1[13] <= chunk2_hash1[511 - 13*32: 480 - 13*32];	//[95  : 64]
                    w_chunk2_hash1[14] <= chunk2_hash1[511 - 14*32: 480 - 14*32];	//[63  : 32]
                    w_chunk2_hash1[15] <= chunk2_hash1[511 - 15*32: 480 - 15*32];	//[31  : 0]

                    w_chunk2_hash2[0] <= chunk2_hash2[511 - 0*32 : 480 - 0*32];		//[512 : 480]
                    w_chunk2_hash2[1]  <= chunk2_hash2[511 - 1*32 : 480 - 1*32];	//[479 : 448]
                    w_chunk2_hash2[2]  <= chunk2_hash2[511 - 2*32 : 480 - 2*32];	//[447 : 416]
                    w_chunk2_hash2[3]  <= chunk2_hash2[511 - 3*32 : 480 - 3*32];	//[415 : 384]
                    w_chunk2_hash2[4]  <= chunk2_hash2[511 - 4*32 : 480 - 4*32];	//[383 : 352]
                    w_chunk2_hash2[5]  <= chunk2_hash2[511 - 5*32 : 480 - 5*32];	//[351 : 320]
                    w_chunk2_hash2[6]  <= chunk2_hash2[511 - 6*32 : 480 - 6*32];	//[319 : 288]
                    w_chunk2_hash2[7]  <= chunk2_hash2[511 - 7*32 : 480 - 7*32];	//[287 : 256]
                    w_chunk2_hash2[8]  <= chunk2_hash2[511 - 8*32 : 480 - 8*32];	//[255 : 224]
                    w_chunk2_hash2[9]  <= chunk2_hash2[511 - 9*32 : 480 - 9*32];	//[223 : 192]
                    w_chunk2_hash2[10] <= chunk2_hash2[511 - 10*32: 480 - 10*32];	//[191 : 160]
                    w_chunk2_hash2[11] <= chunk2_hash2[511 - 11*32: 480 - 11*32];	//[159 : 128]
                    w_chunk2_hash2[12] <= chunk2_hash2[511 - 12*32: 480 - 12*32];	//[127 : 96]
                    w_chunk2_hash2[13] <= chunk2_hash2[511 - 13*32: 480 - 13*32];	//[95  : 64]
                    w_chunk2_hash2[14] <= chunk2_hash2[511 - 14*32: 480 - 14*32];	//[63  : 32]
                    w_chunk2_hash2[15] <= chunk2_hash2[511 - 15*32: 480 - 15*32];	//[31  : 0]

                    w_chunk2_hash3[0] <= chunk2_hash3[511 - 0*32 : 480 - 0*32];		//[512 : 480]
                    w_chunk2_hash3[1]  <= chunk2_hash3[511 - 1*32 : 480 - 1*32];	//[479 : 448]
                    w_chunk2_hash3[2]  <= chunk2_hash3[511 - 2*32 : 480 - 2*32];	//[447 : 416]
                    w_chunk2_hash3[3]  <= chunk2_hash3[511 - 3*32 : 480 - 3*32];	//[415 : 384]
                    w_chunk2_hash3[4]  <= chunk2_hash3[511 - 4*32 : 480 - 4*32];	//[383 : 352]
                    w_chunk2_hash3[5]  <= chunk2_hash3[511 - 5*32 : 480 - 5*32];	//[351 : 320]
                    w_chunk2_hash3[6]  <= chunk2_hash3[511 - 6*32 : 480 - 6*32];	//[319 : 288]
                    w_chunk2_hash3[7]  <= chunk2_hash3[511 - 7*32 : 480 - 7*32];	//[287 : 256]
                    w_chunk2_hash3[8]  <= chunk2_hash3[511 - 8*32 : 480 - 8*32];	//[255 : 224]
                    w_chunk2_hash3[9]  <= chunk2_hash3[511 - 9*32 : 480 - 9*32];	//[223 : 192]
                    w_chunk2_hash3[10] <= chunk2_hash3[511 - 10*32: 480 - 10*32];	//[191 : 160]
                    w_chunk2_hash3[11] <= chunk2_hash3[511 - 11*32: 480 - 11*32];	//[159 : 128]
                    w_chunk2_hash3[12] <= chunk2_hash3[511 - 12*32: 480 - 12*32];	//[127 : 96]
                    w_chunk2_hash3[13] <= chunk2_hash3[511 - 13*32: 480 - 13*32];	//[95  : 64]
                    w_chunk2_hash3[14] <= chunk2_hash3[511 - 14*32: 480 - 14*32];	//[63  : 32]
                    w_chunk2_hash3[15] <= chunk2_hash3[511 - 15*32: 480 - 15*32];	//[31  : 0]
                end
                
                state <= w_chunk_extend;
            end

            w_chunk_extend: begin            	               
                if (extend_counter !== 64) begin 
                    extend_counter <= extend_counter + 1;
                    
                    //chunk 1                
                    w_chunk1_hash1[extend_counter] <= w_chunk1_hash1[extend_counter-16] + s0_1_hash1 + w_chunk1_hash1[extend_counter-7] + s1_1_hash1; 
                    w_chunk1_hash2[extend_counter] <= w_chunk1_hash2[extend_counter-16] + s0_1_hash2 + w_chunk1_hash2[extend_counter-7] + s1_1_hash2; 
                    w_chunk1_hash3[extend_counter] <= w_chunk1_hash3[extend_counter-16] + s0_1_hash3 + w_chunk1_hash3[extend_counter-7] + s1_1_hash3; 
                    
                    //chunk 2
                    if (!second_hash) begin
                        w_chunk2_hash1[extend_counter] <= w_chunk2_hash1[extend_counter-16] + s0_2_hash1 + w_chunk2_hash1[extend_counter-7] + s1_2_hash1;
                        w_chunk2_hash2[extend_counter] <= w_chunk2_hash2[extend_counter-16] + s0_2_hash2 + w_chunk2_hash2[extend_counter-7] + s1_2_hash2;
                        w_chunk2_hash3[extend_counter] <= w_chunk2_hash3[extend_counter-16] + s0_2_hash3 + w_chunk2_hash3[extend_counter-7] + s1_2_hash3;

                    end

                    state <= w_chunk_extend;                    
                end

                //this would save a clock cycle since putting it in the main_loop_counter section would mean you need to wait a cycle
                if (extend_counter == 64) begin 
                    a_temp_hash1 <= h0_hash1;
                    b_temp_hash1 <= h1_hash1;
                    c_temp_hash1 <= h2_hash1;
                    d_temp_hash1 <= h3_hash1;
                    e_temp_hash1 <= h4_hash1;
                    f_temp_hash1 <= h5_hash1;
                    g_temp_hash1 <= h6_hash1;
                    h_temp_hash1 <= h7_hash1;

                    a_temp_hash2 <= h0_hash2;
                    b_temp_hash2 <= h1_hash2;
                    c_temp_hash2 <= h2_hash2;
                    d_temp_hash2 <= h3_hash2;
                    e_temp_hash2 <= h4_hash2;
                    f_temp_hash2 <= h5_hash2;
                    g_temp_hash2 <= h6_hash2;
                    h_temp_hash2 <= h7_hash2;

                    a_temp_hash3 <= h0_hash3;
                    b_temp_hash3 <= h1_hash3;
                    c_temp_hash3 <= h2_hash3;
                    d_temp_hash3 <= h3_hash3;
                    e_temp_hash3 <= h4_hash3;
                    f_temp_hash3 <= h5_hash3;
                    g_temp_hash3 <= h6_hash3;
                    h_temp_hash3 <= h7_hash3;
                    
                    extend_counter <= 16;
                    state <= main_loop_chunks;
                end
            end

            //pipeline 3-5 is the main pipeline that continuously runs, pipeline 1-2 is for the initial startup, and pipeline 6-8 are for the final 
            //kind of like ramp up and ramp down 
            //you cant assign variables for hash 2&3 at the start because hash 1 is using those variable and you dont need to assign variables for hash 1&2 when you are ramping down
            
            main_loop_chunks: begin
                case (main_loop_state)
                    default: begin
                        main_loop_state <= pipeline1;
                    end
                    
                    pipeline1: begin //7 in sim
                        if (!main_loop_flag) begin
                            //hash 1
                            t11 <= (({e_temp_hash1[5:0], e_temp_hash1[31:6]}) ^ ({e_temp_hash1[10:0], e_temp_hash1[31:11]}) ^ ({e_temp_hash1[24:0], e_temp_hash1[31:25]})) + ((e_temp_hash1 & f_temp_hash1) ^ (~e_temp_hash1 & g_temp_hash1)); //s1 + ch

                            if (chunk_flag) begin
                                t12 <= k[main_loop_counter] + w_chunk2_hash1[main_loop_counter] + h_temp_hash1; //k + w(t) + h(t)
                            end
                            else begin
                                t12 <= k[main_loop_counter] + w_chunk1_hash1[main_loop_counter] + h_temp_hash1; //k + w(t) + h(t)
                            end
                             
                            //variable assignments
                            //updating fgh for hash1
                            f_temp_hash1 <= e_temp_hash1;
                            g_temp_hash1 <= f_temp_hash1;
                            h_temp_hash1 <= g_temp_hash1;

                            main_loop_state <= pipeline2;
                        end

                        else begin
                            main_loop_state <= pipeline1;    
                        end
                    end

                    pipeline2: begin //8 in sim
                        //hash 1
                        t1 <= t11 + t12; 
                        t2 <= (({a_temp_hash1[1:0], a_temp_hash1[31:2]}) ^ ({a_temp_hash1[12:0], a_temp_hash1[31:13]}) ^ ({a_temp_hash1[21:0], a_temp_hash1[31:22]})) + ((a_temp_hash1 & b_temp_hash1) ^ (a_temp_hash1 & c_temp_hash1) ^ (b_temp_hash1 & c_temp_hash1)); //s0 + maj
                        c_d <= c_temp_hash1;
                        
                        //hash 2
                        t11 <= (({e_temp_hash2[5:0], e_temp_hash2[31:6]}) ^ ({e_temp_hash2[10:0], e_temp_hash2[31:11]}) ^ ({e_temp_hash2[24:0], e_temp_hash2[31:25]})) + ((e_temp_hash2 & f_temp_hash2) ^ (~e_temp_hash2 & g_temp_hash2)); //s1 + ch                        

                        if (chunk_flag) begin
                            t12 <= k[main_loop_counter] + w_chunk2_hash2[main_loop_counter] + h_temp_hash2; //k + w(t) + h(t)
                        end
                        else begin
                            t12 <= k[main_loop_counter] + w_chunk1_hash2[main_loop_counter] + h_temp_hash2; //k + w(t) + h(t)
                        end

                        //variable assignments
                        //updated bc for hash 1
                        b_temp_hash1 <= a_temp_hash1;
                        c_temp_hash1 <= b_temp_hash1;

                        //updating fgh for hash 2
                        f_temp_hash2 <= e_temp_hash2;
                        g_temp_hash2 <= f_temp_hash2;
                        h_temp_hash2 <= g_temp_hash2;

                        main_loop_state <= pipeline3;       
                    end
                    
                    pipeline3: begin //9 in sim

                        //hash 1
                        e_temp_hash1 <= t1 + d_temp_hash1; //d(n) + t1 = e(t+1) 
                        a_temp_hash1 <= t1 + t2; // t1 + t2 = a(t+1)
                        d_temp_hash1 <= c_d; //d(t+1)
                        
                        //hash 2
                        t1 <= t11 + t12;                             
                        t2 <= (({a_temp_hash2[1:0], a_temp_hash2[31:2]}) ^ ({a_temp_hash2[12:0], a_temp_hash2[31:13]}) ^ ({a_temp_hash2[21:0], a_temp_hash2[31:22]})) + ((a_temp_hash2 & b_temp_hash2) ^ (a_temp_hash2 & c_temp_hash2) ^ (b_temp_hash2 & c_temp_hash2)); //s0 + maj
                        c_d <= c_temp_hash2;

                        //hash 3
                        t11 <= (({e_temp_hash3[5:0], e_temp_hash3[31:6]}) ^ ({e_temp_hash3[10:0], e_temp_hash3[31:11]}) ^ ({e_temp_hash3[24:0], e_temp_hash3[31:25]})) + ((e_temp_hash3 & f_temp_hash3) ^ (~e_temp_hash3 & g_temp_hash3)); //s1 + ch

                        if (chunk_flag) begin
                            t12 <= k[main_loop_counter] + w_chunk2_hash3[main_loop_counter] + h_temp_hash3; //k + w(t) + h(t)
                        end
                        else begin
                            t12 <= k[main_loop_counter] + w_chunk1_hash3[main_loop_counter] + h_temp_hash3; //k + w(t) + h(t)
                        end

                        //variable assignments
                        //updated bc for hash2
                        b_temp_hash2 <= a_temp_hash2;
                        c_temp_hash2 <= b_temp_hash2;

                        //updating fgh for hash3
                        f_temp_hash3 <= e_temp_hash3;
                        g_temp_hash3 <= f_temp_hash3;
                        h_temp_hash3 <= g_temp_hash3;

                        main_loop_counter <= main_loop_counter + 1; //at this point hash1 has been completed and the next pipeline will need to have main_loop_counter updated for hash1

                        main_loop_state <= pipeline4;
                    end

                    pipeline4: begin //10 in sim
                        //hash 1
                        t11 <= (({e_temp_hash1[5:0], e_temp_hash1[31:6]}) ^ ({e_temp_hash1[10:0], e_temp_hash1[31:11]}) ^ ({e_temp_hash1[24:0], e_temp_hash1[31:25]})) + ((e_temp_hash1 & f_temp_hash1) ^ (~e_temp_hash1 & g_temp_hash1)); //s1 + ch

                        if (chunk_flag) begin
                            t12 <= k[main_loop_counter] + w_chunk2_hash1[main_loop_counter] + h_temp_hash1; //k + w(t) + h(t)
                        end
                        else begin
                            t12 <= k[main_loop_counter] + w_chunk1_hash1[main_loop_counter] + h_temp_hash1; //k + w(t) + h(t)
                        end

                        //hash 2 
                        e_temp_hash2 <= t1 + d_temp_hash2; //d(n) + t1 = e(t+1) 
                        a_temp_hash2 <= t1 + t2; // t1 + t2 = a(t+1)
                        d_temp_hash2 <= c_d; //d(t+1)

                        //hash 3
                        t1 <= t11 + t12;                             
                        t2 <= (({a_temp_hash3[1:0], a_temp_hash3[31:2]}) ^ ({a_temp_hash3[12:0], a_temp_hash3[31:13]}) ^ ({a_temp_hash3[21:0], a_temp_hash3[31:22]})) + ((a_temp_hash3 & b_temp_hash3) ^ (a_temp_hash3 & c_temp_hash3) ^ (b_temp_hash3 & c_temp_hash3)); //s0 + maj
                        c_d <= c_temp_hash3;

                        //variable assignments
                        //updating fgh for hash1
                        f_temp_hash1 <= e_temp_hash1;
                        g_temp_hash1 <= f_temp_hash1;
                        h_temp_hash1 <= g_temp_hash1;
                        
                        //updated bc for hash3
                        b_temp_hash3 <= a_temp_hash3;
                        c_temp_hash3 <= b_temp_hash3;

                        main_loop_state <= pipeline5;                            
                    end
                    pipeline5: begin //11 in sim
                        //hash 1
                        t1 <= t11 + t12;                             
                        t2 <= (({a_temp_hash1[1:0], a_temp_hash1[31:2]}) ^ ({a_temp_hash1[12:0], a_temp_hash1[31:13]}) ^ ({a_temp_hash1[21:0], a_temp_hash1[31:22]})) + ((a_temp_hash1 & b_temp_hash1) ^ (a_temp_hash1 & c_temp_hash1) ^ (b_temp_hash1 & c_temp_hash1)); //s0 + maj
                        c_d <= c_temp_hash1;
                        
                        //hash 2 
                        t11 <= (({e_temp_hash2[5:0], e_temp_hash2[31:6]}) ^ ({e_temp_hash2[10:0], e_temp_hash2[31:11]}) ^ ({e_temp_hash2[24:0], e_temp_hash2[31:25]})) + ((e_temp_hash2 & f_temp_hash2) ^ (~e_temp_hash2 & g_temp_hash2)); //s1 + ch

                        if (chunk_flag) begin
                            t12 <= k[main_loop_counter] + w_chunk2_hash2[main_loop_counter] + h_temp_hash2; //k + w(t) + h(t)
                        end
                        else begin
                            t12 <= k[main_loop_counter] + w_chunk1_hash2[main_loop_counter] + h_temp_hash2; //k + w(t) + h(t)
                        end

                        //hash 3
                        e_temp_hash3 <= t1 + d_temp_hash3; //d(n) + t1 = e(t+1) 
                        a_temp_hash3 <= t1 + t2; // t1 + t2 = a(t+1)
                        d_temp_hash3 <= c_d; //d(t+1)

                        //variable assignments
                        
                        //updated bc for hash1
                        b_temp_hash1 <= a_temp_hash1;
                        c_temp_hash1 <= b_temp_hash1;

                        //updating fgh for hash2
                        f_temp_hash2 <= e_temp_hash2;
                        g_temp_hash2 <= f_temp_hash2;
                        h_temp_hash2 <= g_temp_hash2;

                        //if 64 then ramp down the pipelines, else keep looping                            
                        if (main_loop_counter == 63) begin
                            main_loop_state <= pipeline6;
                        end

                        else
                            main_loop_state <= pipeline3;

                    end
                    pipeline6: begin //12 in sim                           
                        //hash 1
                        e_temp_hash1 <= t1 + d_temp_hash1; //d(n) + t1 = e(t+1) 
                        a_temp_hash1 <= t1 + t2; // t1 + t2 = a(t+1)
                        d_temp_hash1 <= c_d; //d(t+1)

                        //hash 2
                        t1 <= t11 + t12;                             
                        t2 <= (({a_temp_hash2[1:0], a_temp_hash2[31:2]}) ^ ({a_temp_hash2[12:0], a_temp_hash2[31:13]}) ^ ({a_temp_hash2[21:0], a_temp_hash2[31:22]})) + ((a_temp_hash2 & b_temp_hash2) ^ (a_temp_hash2 & c_temp_hash2) ^ (b_temp_hash2 & c_temp_hash2)); //s0 + maj
                        c_d <= c_temp_hash2;

                        //hash 3
                        t11 <= (({e_temp_hash3[5:0], e_temp_hash3[31:6]}) ^ ({e_temp_hash3[10:0], e_temp_hash3[31:11]}) ^ ({e_temp_hash3[24:0], e_temp_hash3[31:25]})) + ((e_temp_hash3 & f_temp_hash3) ^ (~e_temp_hash3 & g_temp_hash3)); //s1 + ch

                        if (chunk_flag) begin
                            t12 <= k[main_loop_counter] + w_chunk2_hash3[main_loop_counter] + h_temp_hash3; //k + w(t) + h(t)
                        end
                        else begin
                            t12 <= k[main_loop_counter] + w_chunk1_hash3[main_loop_counter] + h_temp_hash3; //k + w(t) + h(t)
                        end

                        //variable assignments
                        //updated bc for hash2
                        b_temp_hash2 <= a_temp_hash2;
                        c_temp_hash2 <= b_temp_hash2;

                        //updating fgh for hash3
                        f_temp_hash3 <= e_temp_hash3;
                        g_temp_hash3 <= f_temp_hash3;
                        h_temp_hash3 <= g_temp_hash3;

                        main_loop_state <= pipeline7;

                    end
                    pipeline7: begin //13 in sim
                        //final assignment for hash 1
                        h0_hash1 <= h0_hash1 + a_temp_hash1;
                        h1_hash1 <= h1_hash1 + b_temp_hash1;
                        h2_hash1 <= h2_hash1 + c_temp_hash1;
                        h3_hash1 <= h3_hash1 + d_temp_hash1;
                        h4_hash1 <= h4_hash1 + e_temp_hash1;
                        h5_hash1 <= h5_hash1 + f_temp_hash1;
                        h6_hash1 <= h6_hash1 + g_temp_hash1;
                        h7_hash1 <= h7_hash1 + h_temp_hash1;

                        //hash 2 
                        e_temp_hash2 <= t1 + d_temp_hash2; //d(n) + t1 = e(t+1) 
                        a_temp_hash2 <= t1 + t2; // t1 + t2 = a(t+1)
                        d_temp_hash2 <= c_d; //d(t+1)

                        //hash 3
                        t1 <= t11 + t12;                             
                        t2 <= (({a_temp_hash3[1:0], a_temp_hash3[31:2]}) ^ ({a_temp_hash3[12:0], a_temp_hash3[31:13]}) ^ ({a_temp_hash3[21:0], a_temp_hash3[31:22]})) + ((a_temp_hash3 & b_temp_hash3) ^ (a_temp_hash3 & c_temp_hash3) ^ (b_temp_hash3 & c_temp_hash3)); //s0 + maj
                        c_d <= c_temp_hash3;

                        //variable assignments
                        
                        //updated bc for hash3
                        b_temp_hash3 <= a_temp_hash3;
                        c_temp_hash3 <= b_temp_hash3;

                        main_loop_state <= pipeline8;

                    end
                    pipeline8: begin //14 in sim
                        //final assignment for hash 2 
                        h0_hash2 <= h0_hash2 + a_temp_hash2;
                        h1_hash2 <= h1_hash2 + b_temp_hash2;
                        h2_hash2 <= h2_hash2 + c_temp_hash2;
                        h3_hash2 <= h3_hash2 + d_temp_hash2;
                        h4_hash2 <= h4_hash2 + e_temp_hash2;
                        h5_hash2 <= h5_hash2 + f_temp_hash2;
                        h6_hash2 <= h6_hash2 + g_temp_hash2;
                        h7_hash2 <= h7_hash2 + h_temp_hash2;

                        //hash 3
                        e_temp_hash3 <= t1 + d_temp_hash3; //d(n) + t1 = e(t+1) 
                        a_temp_hash3 <= t1 + t2; // t1 + t2 = a(t+1)
                        d_temp_hash3 <= c_d; //d(t+1)

                        main_loop_state <= pipeline9;

                    end
                    pipeline9: begin //15 in sim
                        //final assignment for hash 2 
                        h0_hash3 <= h0_hash3 + a_temp_hash3;
                        h1_hash3 <= h1_hash3 + b_temp_hash3;
                        h2_hash3 <= h2_hash3 + c_temp_hash3;
                        h3_hash3 <= h3_hash3 + d_temp_hash3;
                        h4_hash3 <= h4_hash3 + e_temp_hash3;
                        h5_hash3 <= h5_hash3 + f_temp_hash3;
                        h6_hash3 <= h6_hash3 + g_temp_hash3;
                        h7_hash3 <= h7_hash3 + h_temp_hash3;

                        main_loop_flag <= 1;
                        main_loop_state <= pipeline1; //unsure about this 

                    end
                    
                endcase            

                if (main_loop_flag) begin 
                    main_loop_counter <= 0;                    
                    main_loop_flag <= 0;

                    if (chunk_flag || second_hash) begin //chunk_flag is when 2 chunks have been processed already (640 bit hash1) ; second_hash is if there is only 1 chunk (256 bit hash2)                        
                        state <= main_loop_complete;
                    end

                    //not really sure whats the point of this when the extend section already does this
                    //to answer the above, there is a switchover that will start processing chunk 2 if it is the first pass through the 640 bit bitcoin input

                    a_temp_hash1 <= h0_hash1;
                    b_temp_hash1 <= h1_hash1;
                    c_temp_hash1 <= h2_hash1;
                    d_temp_hash1 <= h3_hash1;
                    e_temp_hash1 <= h4_hash1;
                    f_temp_hash1 <= h5_hash1;
                    g_temp_hash1 <= h6_hash1;
                    h_temp_hash1 <= h7_hash1;

                    a_temp_hash2 <= h0_hash2;
                    b_temp_hash2 <= h1_hash2;
                    c_temp_hash2 <= h2_hash2;
                    d_temp_hash2 <= h3_hash2;
                    e_temp_hash2 <= h4_hash2;
                    f_temp_hash2 <= h5_hash2;
                    g_temp_hash2 <= h6_hash2;
                    h_temp_hash2 <= h7_hash2;

                    a_temp_hash3 <= h0_hash3;
                    b_temp_hash3 <= h1_hash3;
                    c_temp_hash3 <= h2_hash3;
                    d_temp_hash3 <= h3_hash3;
                    e_temp_hash3 <= h4_hash3;
                    f_temp_hash3 <= h5_hash3;
                    g_temp_hash3 <= h6_hash3;
                    h_temp_hash3 <= h7_hash3;

                    chunk_flag <= 1; 
                end
            end
            
            main_loop_complete: begin
                hash1 <= {h0_hash1, h1_hash1, h2_hash1, h3_hash1, h4_hash1, h5_hash1, h6_hash1, h7_hash1}; //note that this hash output is not formatted properly so you need to do the (<<byte {) operation if you want to check if this value is less than the target hash 
                hash2 <= {h0_hash2, h1_hash2, h2_hash2, h3_hash2, h4_hash2, h5_hash2, h6_hash2, h7_hash2}; //note that this hash output is not formatted properly so you need to do the (<<byte {) operation if you want to check if this value is less than the target hash 
                hash3 <= {h0_hash3, h1_hash3, h2_hash3, h3_hash3, h4_hash3, h5_hash3, h6_hash3, h7_hash3}; //note that this hash output is not formatted properly so you need to do the (<<byte {) operation if you want to check if this value is less than the target hash 

                hash_complete <= 1;
                chunk_flag <= 0;
            end
            endcase
        end
	end
endmodule
