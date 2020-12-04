//top level core module 

// Switches 0 to 2 are select signals (001 = normal, 010 = hypo, 100 = hyper)
// switch 9 is trigger (to start cycle)
// switches 4 is hypo treatment signal and switch 5 is hyper treatment signal 

// KEY0 is clock
// KEY1 is resetn

module HPTaxis 
	(
		SW,
		KEY,
		currentstate,
		response,
		FRH,
		FSH,
		T3_T4,
		image
	);
	
	input [9:0] SW;
	input [1:0] KEY;
	output [2:0] currentstate;
	output [1:0] response; // shows body response state (healthy, underactive, overactive) for the selected cycle (norm, hypo, hyper) 
	output FRH, FSH, T3_T4; // shows current state of each hormone for the selected cycle type (norm, hypo, hyper) 
	output [9:0] image; // one-hot encoding to VGA for the 10 different image options 
	
	wire [7:0] data_norm, data_hypo, data_hyper, data_out; 
	wire [9:0] image_norm, image_hypo, image_hyper; 
	wire trigger, resetn, clock; 
	
	assign trigger = SW[9]; 
	assign resetn = KEY[1]; 
	assign clock = KEY[0]; // will need to change to !KEY[0] when working on FPGA board (keys are inverted)
	
	HPTaxis_norm A1(
		.resetn(resetn),
		.trigger(trigger),
		.clk(clock),
		.data_norm(data_norm),
		.image_norm(image_norm));
	
	HPTaxis_hypo A2(
		.resetn(resetn), 
		.trigger(trigger), 
		.treatment(SW[4]), 
		.clk(clock), 
		.data_hypo(data_hypo),
		.image_hypo(image_hypo));
	
	HPTaxis_hyper A3(
		.resetn(resetn), 
		.trigger(trigger), 
		.treatment(SW[5]), 
		.clk(clock), 
		.data_hyper(data_hyper),
		.image_hyper(image_hyper));
	
	mux3to1 A4(
		.in_data_norm(data_norm),
		.in_data_hypo(data_hypo),
		.in_data_hyper(data_hyper),
		.in_Image_norm(image_norm),
		.in_Image_hypo(image_hypo), 
		.in_Image_hyper(image_hyper),
		.select(SW[2:0]),
		.out_data(data_out),
		.out_Image(image)); // mux selects image output of only one cycle type (norm or hyper or hypo)
	
	assign currentstate = data_out[7:5];
	assign response = data_out[4:3];
	assign FRH = data_out[2];
	assign FSH = data_out[1];
	assign T3_T4 = data_out[0]; 
		
endmodule 

module mux3to1
	(
		in_data_norm, 
		in_data_hypo, 
		in_data_hyper, 
		in_Image_norm, 
		in_Image_hypo, 
		in_Image_hyper, 
		select, 
		out_data,
		out_Image
	);
	
	input [7:0] in_data_norm, in_data_hypo, in_data_hyper;
	input [9:0] in_Image_norm, in_Image_hypo, in_Image_hyper; 
	output reg [7:0] out_data; 
	output reg [9:0] out_Image;
	input [2:0] select;
	
	parameter norm = 3'b001;
	parameter hypo = 3'b010;
	parameter hyper = 3'b100; 
	
	always @ (*) begin
		case (select)
			norm: begin
				out_data<=in_data_norm;
				out_Image<=in_Image_norm;
			end 
			hypo: begin
				out_data<=in_data_hypo;
				out_Image<=in_Image_hypo;
			end 
			hyper: begin 
				out_data<=in_data_hyper;
				out_Image<=in_Image_hyper; 
			end 
			default: begin
				out_data<=in_data_norm;
				out_Image<=in_Image_norm;
			end
		endcase 
	end
endmodule 	