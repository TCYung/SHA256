module SHA256_base
(   input clk,
   output reg [255:0] hash
);

//there seems to be a bunch of arbitrary variables as well as math operations, is there any way to understand the purpose of all the operations?

reg [31:0] h0 = 32'h6a09e667;
reg [31:0] h1 = 32'hbb67ae85;
reg [31:0] h2 = 32'h3c6ef372;
reg [31:0] h3 = 32'ha54ff53a;
reg [31:0] h4 = 32'h510e527f;
reg [31:0] h5 = 32'h9b05688c;
reg [31:0] h6 = 32'h1f83d9ab;
reg [31:0] h7 = 32'h5be0cd19;
reg [31:0] k [0:63];
//for this test scenario we are going to be using bitcoin block 923948
//target hash = 000000000000000000001f276a92e92679e23e610e3392d7d15b1684089af45c

reg [31:0] bitcoin_version = 32'h3fff0000;
reg [255:0] previous_hash = 256'h00000000000000000000a94278b1c645a52dfc46bf6f985010f5626093b0eb9f; //this is the hash of block 923947
reg [255:0] merkle_root = 256'h8d6f9f82908f4e916af2eb57010de762f46ea5923374898033b0599acf6c8bc0;
reg [31:0] timestamp = 32'h691A4FB4; //1763332020 or 11/16/25 5:27pm
reg [31:0] difficulty = 32'h1701d936;
reg [31:0] nonce = 32'h7481a217; // 1954652695 in decimal
reg [63:0] length_bits = {bitcoin_version, previous_hash, merkle_root, timestamp, difficulty, nonce} >> 32; //this will be the modulo (right shift 32 times of the original block header)

//i thought that you would be able to parallelize and compute both chunks at the same time but the values for chunk 2 depend on the output of chunk 1
reg [511:0] chunk1;
reg [511:0] chunk2;

reg [31:0] a_temp, b_temp, c_temp, d_temp, e_temp, f_temp, g_temp, h_temp;

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

reg [31:0] w_chunk1 [0:63];
reg [31:0] w_chunk2 [0:63];

reg [8:0] main_loop = 0;
reg [8:0] main_loop2 = 0;
reg [8:0] loop_val = 16;

//for chunk 1
reg [31:0] s0_1; 
reg [31:0] s1_1;

//for chunk 2
reg [31:0] s0_2;
reg [31:0] s1_2;

reg [31:0] s1, ch, temp1, s0, maj, temp2; //temporary variables named according to sha2 wiki main loop

reg [7:0] loop1;
parameter idle_state = 8'b0000001; //pick binary value
parameter loop1_start = 8'b0000010; 
parameter loop1_end = 8'b0000011;
parameter main_loop_chunk1 = 8'b0000100;
parameter main_loop_chunk2 = 8'b0000101;
parameter main_loops_complete = 8'b0000110;

reg [7:0] main_loop_case;
parameter main_loop_variables = 8'b0000111;
parameter main_loop_temp = 8'b0001000;
parameter main_loop_assign = 8'b0001001;

always_comb begin
    //loop1_end chunk 1 and chunk 2
    s0_1 = ({w_chunk1[loop_val-15][6:0], w_chunk1[loop_val-15][31:7]}) ^ ({w_chunk1[loop_val-15][17:0], w_chunk1[loop_val-15][31:18]}) ^ (w_chunk1[loop_val-15] >> 3); //right rotate 7, right rotate 18, right shift 3
    s1_1 = ({w_chunk1[loop_val-2][16:0], w_chunk1[loop_val-2][31:17]}) ^ ({w_chunk1[loop_val-2][18:0], w_chunk1[loop_val-2][31:19]}) ^ (w_chunk1[loop_val-2] >> 10); //right rotate 17, right rotate 19, right shift 10

    s0_2 = ({w_chunk2[loop_val-15][6:0], w_chunk2[loop_val-15][31:7]}) ^ ({w_chunk2[loop_val-15][17:0], w_chunk2[loop_val-15][31:18]}) ^ (w_chunk2[loop_val-15] >> 3); //right rotate 7, right rotate 18, right shift 3
    s1_2 = ({w_chunk2[loop_val-2][16:0], w_chunk2[loop_val-2][31:17]}) ^ ({w_chunk2[loop_val-2][18:0], w_chunk2[loop_val-2][31:19]}) ^ (w_chunk2[loop_val-2] >> 10); //right rotate 17, right rotate 19, right shift 10

end

always_ff @(posedge clk) begin 
	case(loop1)
	
        default: begin
           loop1 <= idle_state;
        end
        
		idle_state: begin
			//this will be needed in the future when i process header after header
			//length_bits <= {bitcoin_version, previous_hash, merkle_root, timestamp, difficulty, nonce} >> 32; //modulo 2^32 of the 80 byte block header

			//chunk1 <= {bitcoin_version, previous_hash, merkle_root[255:32]};
			//chunk2 <= {merkle_root[31:0], timestamp, difficulty, nonce, 1'b1, 319'b0, length_bits};

            
            //testing 
            chunk1 <= {96'b10100100110010101100100010000100110110001101111011000110110101101000010011011000111010101100101, 1'b1, 351'b0, 64'd96};
            chunk2 <= 512'h0;

            // chunk1 <= 512'h0;
            // chunk2 <= 512'h0;

            loop1 <= loop1_start;
        end
             
		loop1_start: begin
			w_chunk1[0] <= chunk1[511 - 0*32 : 480 - 0*32];		//[512 : 480]
			w_chunk1[1] <= chunk1[511 - 1*32 : 480 - 1*32];		//[479 : 448]
			w_chunk1[2] <= chunk1[511 - 2*32 : 480 - 2*32];		//[447 : 416]
			w_chunk1[3]  <= chunk1[511 - 3*32 : 480 - 3*32];		//[415 : 384]
			w_chunk1[4]  <= chunk1[511 - 4*32 : 480 - 4*32];		//[383 : 352]
			w_chunk1[5]  <= chunk1[511 - 5*32 : 480 - 5*32];		//[351 : 320]
			w_chunk1[6]  <= chunk1[511 - 6*32 : 480 - 6*32];		//[319 : 288]
			w_chunk1[7]  <= chunk1[511 - 7*32 : 480 - 7*32];		//[287 : 256]
			w_chunk1[8]  <= chunk1[511 - 8*32 : 480 - 8*32];		//[255 : 224]
			w_chunk1[9]  <= chunk1[511 - 9*32 : 480 - 9*32];		//[223 : 192]
			w_chunk1[10] <= chunk1[511 - 10*32: 480 - 10*32];	//[191 : 160]
			w_chunk1[11] <= chunk1[511 - 11*32: 480 - 11*32];	//[159 : 128]
			w_chunk1[12] <= chunk1[511 - 12*32: 480 - 12*32];	//[127 : 96]
			w_chunk1[13] <= chunk1[511 - 13*32: 480 - 13*32];	//[95  : 64]
			w_chunk1[14] <= chunk1[511 - 14*32: 480 - 14*32];	//[63  : 32]
			w_chunk1[15] <= chunk1[511 - 15*32: 480 - 15*32];	//[31  : 0]

			w_chunk2[0] <= chunk2[511 - 0*32 : 480 - 0*32];		//[512 : 480]
			w_chunk2[1]  <= chunk2[511 - 1*32 : 480 - 1*32];		//[479 : 448]
			w_chunk2[2]  <= chunk2[511 - 2*32 : 480 - 2*32];		//[447 : 416]
			w_chunk2[3]  <= chunk2[511 - 3*32 : 480 - 3*32];		//[415 : 384]
			w_chunk2[4]  <= chunk2[511 - 4*32 : 480 - 4*32];		//[383 : 352]
			w_chunk2[5]  <= chunk2[511 - 5*32 : 480 - 5*32];		//[351 : 320]
			w_chunk2[6]  <= chunk2[511 - 6*32 : 480 - 6*32];		//[319 : 288]
			w_chunk2[7]  <= chunk2[511 - 7*32 : 480 - 7*32];		//[287 : 256]
			w_chunk2[8]  <= chunk2[511 - 8*32 : 480 - 8*32];		//[255 : 224]
			w_chunk2[9]  <= chunk2[511 - 9*32 : 480 - 9*32];		//[223 : 192]
			w_chunk2[10] <= chunk2[511 - 10*32: 480 - 10*32];	//[191 : 160]
			w_chunk2[11] <= chunk2[511 - 11*32: 480 - 11*32];	//[159 : 128]
			w_chunk2[12] <= chunk2[511 - 12*32: 480 - 12*32];	//[127 : 96]
			w_chunk2[13] <= chunk2[511 - 13*32: 480 - 13*32];	//[95  : 64]
			w_chunk2[14] <= chunk2[511 - 14*32: 480 - 14*32];	//[63  : 32]
			w_chunk2[15] <= chunk2[511 - 15*32: 480 - 15*32];	//[31  : 0]
			
			loop1 <= loop1_end;
        end

		loop1_end: begin
			//this should be the extension from 16 to 63 (see if you can use systemverilog)
            //chunk 1 and chunk 2 should be able to be processed at the same time here			

			//this would save a clock cycle since putting it in the main_loop section would mean you need to wait a cycle

            if (loop_val == 64) begin 
                a_temp <= h0;
                b_temp <= h1;
                c_temp <= h2;
                d_temp <= h3;
                e_temp <= h4;
                f_temp <= h5;
                g_temp <= h6;
                h_temp <= h7;
                
                loop_val <= 16;

                loop1 <= main_loop_chunk1;
            end
            
            if (loop_val !== 64) begin 
                loop_val <= loop_val + 1;
                //chunk 1
                
                w_chunk1[loop_val] <= w_chunk1[loop_val-16] + s0_1 + w_chunk1[loop_val-7] + s1_1; 
                
                //chunk 2
                
                w_chunk2[loop_val] <= w_chunk2[loop_val-16] + s0_2 + w_chunk2[loop_val-7] + s1_2;

                loop1 <= loop1_end;
                
            end
        end

		main_loop_chunk1: begin
			if (main_loop == 64) begin
				h0 <= h0 + a_temp;
				h1 <= h1 + b_temp;
				h2 <= h2 + c_temp;
				h3 <= h3 + d_temp;
				h4 <= h4 + e_temp;
				h5 <= h5 + f_temp;
				h6 <= h6 + g_temp;
				h7 <= h7 + h_temp;

                main_loop <= main_loop + 1; 

                loop1 <= main_loop_chunk1;
                
			end

            if (main_loop == 65) begin
                a_temp <= h0;
                b_temp <= h1;
                c_temp <= h2;
                d_temp <= h3;
                e_temp <= h4;
                f_temp <= h5;
                g_temp <= h6;
                h_temp <= h7;

                main_loop <= 0;

				loop1 <= main_loop_chunk2;
            end

            if (main_loop !== 64 && main_loop !== 65) begin //splitting this into 3 solved my issues but it looks like from the github example one of these can be changed to combinatorial logic
                case (main_loop_case)
                    default: begin
                        main_loop_case <= main_loop_variables;
                    end

                    main_loop_variables: begin
                        //main loop
                        s1 = ({e_temp[5:0], e_temp[31:6]}) ^ ({e_temp[10:0], e_temp[31:11]}) ^ ({e_temp[24:0], e_temp[31:25]}); //right rotate 6, right rotate 11, right rotate 25
                        ch = (e_temp & f_temp) ^ (~e_temp & g_temp);

                        s0 = ({a_temp[1:0], a_temp[31:2]}) ^ ({a_temp[12:0], a_temp[31:13]}) ^ ({a_temp[21:0], a_temp[31:22]}); //right rotate 2, right rotate 13, right rotate 22
                        maj = (a_temp & b_temp) ^ (a_temp & c_temp) ^ (b_temp & c_temp);

                        main_loop_case <= main_loop_temp;
                    end

                    main_loop_temp: begin     

                        temp1 <= h_temp + s1 + ch + k[main_loop] + w_chunk1[main_loop]; //only difference between chunk 1 and 2 should be the w variable                
                        temp2 <= s0 + maj;	
                        
                        main_loop_case <= main_loop_assign;
                    end
                    
                    main_loop_assign: begin
                        h_temp <= g_temp;
                        g_temp <= f_temp;
                        f_temp <= e_temp;
                        e_temp <= d_temp + temp1;
                        d_temp <= c_temp;
                        c_temp <= b_temp;
                        b_temp <= a_temp;
                        a_temp <= temp1 + temp2;

                        main_loop <= main_loop + 1;

                        main_loop_case <= main_loop_variables;
                    end

                endcase

                loop1 <= main_loop_chunk1;
            end
        end

		main_loop_chunk2: begin
			if (main_loop2 == 64) begin
				h0 <= h0 + a_temp;
				h1 <= h1 + b_temp;
				h2 <= h2 + c_temp;
				h3 <= h3 + d_temp;
				h4 <= h4 + e_temp;
				h5 <= h5 + f_temp;
				h6 <= h6 + g_temp;
				h7 <= h7 + h_temp;
				
                main_loop2 <= 0;

				loop1 <= main_loops_complete;
			end
			
			if (main_loop2 !== 64) begin
			    main_loop2 <= main_loop2 + 1;
                    
                temp1 <= h_temp + s1 + ch + k[main_loop2] + w_chunk2[main_loop2]; //only difference between chunk 1 and 2 should be the w variable
                temp2 <= s0 + maj;
                
                if (main_loop2 > 0) begin            
                    h_temp <= g_temp;
                    g_temp <= f_temp;
                    f_temp <= e_temp;
                    e_temp <= d_temp + temp1;
                    d_temp <= c_temp;
                    c_temp <= b_temp;
                    b_temp <= a_temp;
                    a_temp <= temp1 + temp2;	
                    
                    loop1 <= main_loop_chunk2;
                end
			end
        end
		
		main_loops_complete: begin
			hash <= {h0, h1, h2, h3, h4, h5, h6, h7};
        end

		endcase
	end
endmodule