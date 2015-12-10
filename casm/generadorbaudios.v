/////-- Divisor = 12000000 / BAUDIOS ejemplo =  1250=12000000/9600
`define B9600   1250
`define F_1KHz 12000

/*
entrada y salida de datos las cuales varian en el tiempo
*/
module generadorbaudios(input wire clk, input wire clk_enable, output wire clk_out);
 //me permite sinconizar los relojes //
parameter M = 1250;

localparam N = $clog2(M);//ACOMODA LA FRECUENCIA PARA QUE SE PUEDA TRABAJAR EN EL MODULO
localparam M2 = (M >> 1);
//-------------------------------------------------------------------------------
reg [N-1:0] divcounter = 0;

//-- Contador módulo M
always @(posedge clk)

  if (clk_enable)
    //-- Funcionamiento normal
    divcounter <= (divcounter == M - 1) ? 0 : divcounter + 1;
  else
    //-- Contador en el valor maximo
    divcounter <= M - 1;
assign clk_out = (divcounter == M2) ? clk_enable : 0;

endmodule
