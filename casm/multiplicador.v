
module divider(
input wire x, 
output wire outmul
);

reg [16:0]mul;

always @(posedge x)
	for(i=0; i<x ; i++)
	begin 
		mul[i]=mul[i]+x;
	end
endmodule

//-- Contador módulo M: Otra manera de implementarlo
/*
always @(posedge clk_in)
  if (divcounter == M - 1) 
    divcounter <= 0;
  else 
    divcounter <= divcounter + 1;
*/
