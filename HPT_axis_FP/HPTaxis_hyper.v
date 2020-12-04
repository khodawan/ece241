//hyperthyroidism cycle 

module HPTaxis_hyper(resetn, trigger, treatment, clk, data_hyper, image_hyper);
	input resetn, trigger, treatment, clk;
	output [7:0] data_hyper; 
	output [9:0] image_hyper;
	
	wire [1:0] response; 
	wire FSH, FRH, T3_T4;
	wire [1:0] bodystate;
	wire [2:0] currentstate; 
	
	FSM_hyper B1 (
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
		.currentImage(image_hyper)); 
	
	datapath_hyper B2(
		.clock(clk), 
		.currentstate(currentstate),
		.bodystate(bodystate),
		.FRH(FRH),
		.FSH(FSH),
		.T3_T4(T3_T4)); 
	
	assign data_hyper={currentstate, response, FRH, FSH, T3_T4};

endmodule 

// controls progression thru all states in HPT response cycle
module FSM_hyper
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
	output reg [1:0] response;
	output reg [9:0] currentImage; 
	output [2:0] currentstate;
	
	reg [2:0] currentS, nextS;
	
	// state parameters 
	parameter normal = 3'b000;
	parameter triggered = 3'b001;
	parameter active_hypothalamus = 3'b010;
	parameter active_pituitary = 3'b011;
	parameter active_thyroid = 3'b100;
	parameter reestablishment = 3'b101;
	parameter ab_stim_thyroid = 3'b110;
	parameter muted_thyroid = 3'b111;
	
	//response parameters 
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
	parameter overact_thyroid_Im = 10'b0100000000;
	parameter medicated2_Im = 		10'b1000000000; 
	
	// response cycle 
	always @ (*)
	case(currentS)
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
	
	reestablishment: nextS=ab_stim_thyroid;
	
	/* reestablishment: if (bodystate==high) nextS=ab_stim_thyroid;
		else nextS=reestablishment;
	*/
	
	ab_stim_thyroid: if (treatment) nextS=muted_thyroid;
		else nextS=ab_stim_thyroid;
	
	muted_thyroid: nextS=normal; 	
	
	/*muted_thyroid: if (bodystate==healthy) nextS=normal;
		else nextS=muted_thyroid; 
	*/
	
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
		active_thyroid: begin
			response<=low;
			currentImage<=thyroid_Im;
		end
		reestablishment: begin 
			response<=healthy;
			currentImage<=reestablish_Im;
		end 
		ab_stim_thyroid: begin
			response<=high; 
			currentImage<=overact_thyroid_Im;
		end 
		muted_thyroid: begin
			response<=high;
			currentImage<=medicated2_Im;
		end 
		default: begin
			response<=healthy;
			currentImage<=healthy_Im;
		end 
	endcase 
	
	assign currentstate = currentS; 

endmodule 

// controls logic of hormone release and body response in different states 
module datapath_hyper 
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
	parameter ab_stim_thyroid = 3'b110;
	parameter muted_thyroid = 3'b111;
	
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
		if (currentstate==ab_stim_thyroid) begin
			bodystate<=high;
			FRH<=0;
			FSH<=0;
			T3_T4<=1;
		end
		if (currentstate==muted_thyroid) begin
			bodystate<=high;
			FRH<=0;
			FSH<=0;
			T3_T4<=0;
		end
	end 
endmodule 