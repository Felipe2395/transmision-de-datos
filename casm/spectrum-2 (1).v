`timescale 1ns / 1ps
/////-- Divisor = 12000000 / BAUDIOS ejemplo =  1250=12000000/9600
`define B9600   1250

module spectrum(clk, reset, amp, midi);

   input clk;
   input midi; // entrada de un vector, donde
   input reset;
   output [15:0]frec;// represntan bandas 
   output [3:0]amp;//De 0 a 10
   output reloc;	
   wire clk_c;

	localparam BAUD = `B9600;
	wire rcv;
	wire [7:0] data;
	wire [7:0] datam;
	wire [3:0] direccion;
	wire [15:0] salidafrec;
	wire txsalmen;
	reg rstn = 0;



always @(posedge clk)
  rstn <= 1;

//-- Instanciar la unidad de recepcion
uartresepcion #(BAUD)
	entradablu (.clk(clk),      //-- Reloj del sistema
		.rstn(rstn),    //-- Señal de reset
		.rx(midi),        //-- Linea de recepción de datos serie
		.rcv(rcv),      //-- Señal de dato recibido
		.data(data)     //-- Datos recibidos
	);

buffer  
	salidasfre(
		.clk(clk),
		.rx(midi),
		.tx(txsalmen),
		.datos(datam),
		.debug(direccion)
	);

divider
	divisorfrec(
		.clk_in(datam), 
		.clk_out(salidafrec[15:0])
    );

always @(posedge clk)
    //-- Capturar el dato cuando se reciba
    if (rcv == 1'b1)
    begin
        amp <= data[3:0]; 
        frec <= salidafrec[15:0];
        reloc<=clk;
    end
endmodule