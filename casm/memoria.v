module Memoria(enable, rw, data_in, data_out, address);
	input enable,rw;
	input [15:0]data_in;
	input [3:0]address; //--
	output reg [15:0] data_out;

	reg [15:0] mem [0:15]; // memoria 16 x 16

always @(posedge enable or posedge rw)
	if(enable)
		if(rw)
			data_out = mem[address]; //leer
		else 
			mem[address] = data_in;  // escribir
	else
		data_out = 16'bz;
endmodule
