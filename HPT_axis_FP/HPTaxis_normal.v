// normal cycle module 

module HPTaxis_norm(resetn, trigger, clk, data_norm, image_norm);
	input resetn, trigger, clk;
	output [7:0] data_norm;
	output [9:0] image_norm; 
		
	wire [1:0] response;
	wire FSH, FRH, T3_T4;
	wire [1:0] bodystate;
	wire [2:0] currentstate; 
	
	FSM_norm U1(
		.resetn(resetn),
		.trigger(trigger),
		.clock(clk),
		.FSH(FSH),
		.FRH(FRH),
		.T3_T4(T3_T4),
		.bodystate(bodystate),
		.response(response),
		.currentstate(currentstate),
		.currentImage(image_norm));
	
	datapath_norm U2(
		.clock(clk),
		.currentstate(currentstate),
		.bodystate(bodystate),
		.FRH(FRH),
		.FSH(FSH),
		.T3_T4(T3_T4));
		
	assign data_norm={currentstate, response, FRH, FSH, T3_T4}; 

endmodule 	

module FSM_norm
	(
		resetn,
		trigger,
		clock,
		FSH,
		FRH,
		T3_T4,
		bodystate,
		response, 
		currentstate,
		currentImage
	); 

	input resetn, trigger, clock, FRH, FSH, T3_T4;
	input [1:0] bodystate;
	output [2:0] currentstate; 
	output reg [1:0] response; 
	output reg [9:0] currentImage; 
	
	// state parameters 
	parameter normal = 3'b000;
	parameter triggered = 3'b001;
	parameter active_hypothalamus = 3'b010;
	parameter active_pituitary = 3'b011;
	parameter active_thyroid = 3'b100;
	parameter reestablishment = 3'b101;
	
	//image parameters 
	parameter healthy_Im = 			10'b0000000001;
	parameter triggered_Im = 		10'b0000000010;
	parameter hypothalamus_Im = 	10'b0000000100;
	parameter pituitary_Im = 		10'b0000001000;
	parameter thyroid_Im =	    	10'b0000010000;
	parameter reestablish_Im = 	10'b0000100000;
	
	//respons parameters 
	parameter healthy = 2'b00;
	parameter low = 2'b01;
	parameter high = 2'b10; 

	reg [2:0] currentS, nextS;
	
	always @ (*)
	case (currentS) 
	
	normal: if (trigger) nextS=triggered;
		else nextS=normal;
	
	triggered: if (bodystate==low) nextS=active_hypothalamus;
		else nextS=triggered;
		
	active_hypothalamus: if (FRH) nextS=active_pituitary;
		else nextS=active_hypothalamus;
	
	active_pituitary: if (FSH) nextS=active_thyroid;
		else nextS=active_pituitary; 
	
	active_thyroid: if (T3_T4) nextS=reestablishment;
		else nextS=active_thyroid; 
	
	reestablishment: if (!FRH) nextS=normal;
		else nextS=reestablishment; 
	
	default: nextS=normal;
	
	endcase 
	
	always @ (posedge clock, negedge resetn)
		if (resetn==0)
			currentS<=normal;
		else
		currentS<=nextS;
	
	always @ (posedge clock, negedge resetn)
	case (currentS)
		normal: begin 
			response<=healthy;
			currentImage<=healthy_Im;
		end 
		triggered: begin
			response<=low;
			currentImage<=triggered_Im;
		end 
		active_hypothalamus: begin
			response<=low;
			currentImage<= hypothalamus_Im;
		end 
		active_pituitary: begin
			response<=low;
			currentImage<=pituitary_Im;
		end 	
		active_thyroid: begin
			response<=low;
			currentImage<=thyroid_Im; 
		end 
		reestablishment: begin
			response<=healthy;
			currentImage<=reestablish_Im;
		end 
		default: begin
			response<=healthy;
			currentImage<=healthy_Im; 
		end 
	endcase 
	
	assign currentstate = currentS;

endmodule 

module datapath_norm 
	(
		clock,
		currentstate,
		bodystate,
		FRH,
		FSH,
		T3_T4
	);
	
	input clock;
	input [2:0] currentstate;
	output reg FRH, FSH, T3_T4;
	output reg [1:0] bodystate;
	
	parameter normal = 3'b000;
	parameter triggered = 3'b001;
	parameter active_hypothalamus = 3'b010;
	parameter active_pituitary = 3'b011;
	parameter active_thyroid = 3'b100;
	parameter reestablishment = 3'b101;
	
	parameter healthy = 2'b00;
	parameter low = 2'b01;
	parameter high = 2'b10; 
	
	always @(posedge clock) 
	begin 
		if (currentstate==normal) begin
			bodystate<=healthy;
			FRH<=0;
			FSH<=0;
			T3_T4<=0;
		end 
		if (currentstate==triggered) begin
			bodystate<=low;
			FRH<=0;
			FSH<=0;
			T3_T4<=0;
		end
		if (currentstate==active_hypothalamus) begin
			bodystate<=low;
			FRH<=1;
			FSH<=0;
			T3_T4<=0;
		end
		if (currentstate==active_pituitary) begin
			bodystate<=low;
			FRH<=1;
			FSH<=1;
			T3_T4<=0;
		end
		if (currentstate==active_thyroid) begin
			bodystate<=low;
			FRH<=1;
			FSH<=1;
			T3_T4<=1;
		end
		if (currentstate==reestablishment) begin
			bodystate<=healthy;
			FRH<=0;
			FSH<=0;
			T3_T4<=1;
		end
	end 
endmodule 