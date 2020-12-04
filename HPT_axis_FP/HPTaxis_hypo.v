// hypothyroidism cycle 

module HPTaxis_hypo(resetn, trigger, treatment, clk, data_hypo, image_hypo);
	input resetn, trigger, treatment, clk;
	output [7:0] data_hypo; 
	output [9:0] image_hypo;
	
	wire [1:0] response; 
	wire FSH, FRH, T3_T4;
	wire [1:0] bodystate;
	wire [2:0] currentstate;
	
	FSM_hypo C1 (
		.resetn(resetn),
		.trigger(trigger),
		.clock(clk),
		.treatment(treatment),
		.currentstate(currentstate),
		.response(response),
		.FRH(FRH),
		.FSH(FSH),
		.T3_T4(T3_T4),
		.bodystate(bodystate),
		.currentImage(image_hypo)); 
	
	datapath_hypo C2(
		.clock(clk), 
		.currentstate(currentstate),
		.bodystate(bodystate),
		.FRH(FRH),
		.FSH(FSH),
		.T3_T4(T3_T4)); 
		
	assign data_hypo={currentstate, response, FRH, FSH, T3_T4};

endmodule 

// controls progression thru all states in HPT response cycle
module FSM_hypo
	(
		resetn,
		trigger,
		clock,
		treatment,
		currentstate,
		response,
		FRH,
		FSH,
		T3_T4,
		bodystate,
		currentImage
	); 

	input clock, resetn, trigger, treatment, FRH, FSH, T3_T4;
	input [1:0] bodystate;
	output [2:0] currentstate;
	output reg [1:0] response;
	output reg [9:0] currentImage;
	
	reg [2:0] currentS, nextS;
	
	// state parameters 
	parameter normal = 3'b000;
	parameter triggered = 3'b001;
	parameter active_hypothalamus = 3'b010;
	parameter active_pituitary = 3'b011;
	parameter no_thyroid = 3'b100;
	parameter medicated = 3'b101;
	parameter reestablishment = 3'b110;
	
	// response parameters
	parameter healthy = 2'b00;
	parameter low = 2'b01;
	parameter high = 2'b10; 
	
	//image parameters 
	parameter healthy_Im = 			10'b0000000001;
	parameter triggered_Im = 		10'b0000000010;
	parameter hypothalamus_Im = 	10'b0000000100;
	parameter pituitary_Im = 		10'b0000001000;
	parameter thyroid_Im =	    	10'b0000010000;
	parameter reestablish_Im = 	10'b0000100000;
	parameter no_thyroid_Im = 		10'b0001000000;
	parameter medicated1_Im = 		10'b0010000000;
	
	// response cycle 
	always @ (*)
	case(currentS)
	normal: if (trigger) nextS=triggered;
		else nextS=normal;
	
	triggered: if (bodystate==low) nextS=active_hypothalamus;
		else nextS=triggered;
		
	active_hypothalamus: if (FRH) nextS=active_pituitary;
		else nextS=active_hypothalamus;
	
	active_pituitary: if (FSH) nextS=no_thyroid;
		else nextS=active_pituitary; 
	
	no_thyroid: if (treatment) nextS=medicated;
		else nextS=no_thyroid; 
	
	medicated: if (T3_T4) nextS=reestablishment;
		else nextS=medicated;
	
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
			currentImage<=hypothalamus_Im;
		end 
		active_pituitary: begin
			response<=low;
			currentImage<=pituitary_Im; 
		end 
		no_thyroid: begin
			response<=low;
			currentImage<=no_thyroid_Im; 
		end 
		medicated: begin 
			response<=low; 
			currentImage<=medicated1_Im; 
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

// controls logic of hormone release and body response in different states 
module datapath_hypo 
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
	parameter no_thyroid = 3'b100;
	parameter medicated = 3'b101;
	parameter reestablishment = 3'b110;
	
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
		if (currentstate==no_thyroid) begin
			bodystate<=low;
			FRH<=1;
			FSH<=1;
			T3_T4<=0;
		end
		if (currentstate==medicated) begin
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