`default_nettype none

/////-- Divisor = 12000000 / BAUDIOS ejemplo =  1250=12000000/9600
`define B9600   1250

module uartresepcion (	input wire clk,         //-- Reloj del sistema
                	input wire rstn,        //-- Reset
                	input wire midi,          //-- Linea de recepcion 
                	output reg rcv,         //-- Decir si el dato esta disponible
                	output reg [7:0] data); //-- dato recibido

//-- velocidad de recepcion
parameter BAUD = `B9600;

//-- Reloj para la recepcion
wire clk_baud;

reg rx_r;
//--mantiene un registro de los datos de recepcion 

//-- ordenes
reg bauden;  //-- activa la señal de reloj de datos
reg clear;   //-- poner contador de bits en cero
reg load;    //-- cargar el dato recibido
//--mantiene un tiempo de espera en los registro, me permite poner en ceros apenas termine la trasmision, me permite verificar si los datos estan siendo enviados

//-------------------------------------------------------------------
//--     DATAPATH
//-------------------------------------------------------------------

//-- Registrar la señal de recepcion de datos
always @(posedge clk)
  rx_r <= midi;
//--cada vez que sea 1 guarda un dato con corrimiento de sentido
//-- divisor para la generacion del reloj de llegada de datos 
generadorbaudios#(BAUD) //--generador de baudios para la sincronizacion de señal 
  baudgen0 ( 
    .clk(clk),
    .clk_enable(bauden), 
    .clk_out(clk_baud)//--llama la funcion que me permite sincronizar los datos con los baudios de transferencia
  );

//-- Contador de bits
reg [3:0] bitc;

always @(posedge clk)
  if (clear)
    bitc <= 4'd0;
  else if (clear == 0 && clk_baud == 1)
    bitc <= bitc + 1;
//--cuando el reloj este encendido, el clear este en 1 refresca los datos y los deja preparado para una nueva recepcion


//-- desplazamiento para almacenar los bits recibidos
reg [9:0] raw_data;

always @(posedge clk)
  if (clk_baud == 1)
 begin raw_data = {rx_r, raw_data[9:1]};
  end
//--siempre que el reloj este en 1 muestre los datos almacenados
//-- Registro de datos. almacena dato recibido
always @(posedge clk)
  if (rstn == 0)
    data <= 0;
  else if (load)
    data <= raw_data[8:1];
// si ya ha terminado de contar los datos y guardarlos, se refresca el conteo
//-------------------------------------
//-- CONTROLADOR
//-------------------------------------
localparam IDLE = 2'd0;  //-- estado de reposo
localparam RECV = 2'd1;  //-- recibe datos
localparam LOAD = 2'd2;  //-- almacenamiento dato recibido
localparam DAV = 2'd3;   //-- señala dato disponible 
//--nos permite identificar una salida nitida de lo que se recibio
reg [1:0] state;

//-- Transiciones entre estados
always @(posedge clk)

  if (rstn == 0)
    state <= IDLE;

  else
    case (state)
      //-- Reposo
      IDLE : 
        //-- Al llegar el bit de start se pasa al estado siguiente
        if (rx_r == 0)  
          state <= RECV;
        else
          state <= IDLE;
      //--- Recibiendo datos      
      RECV:
        //-- pasar al siguiente estado
        if (bitc == 4'd10)
          state <= LOAD;
        else
          state <= RECV;
      //-- almacenar dato
      LOAD:
        state <= DAV;
      //-- Señalizar dato disponible
      DAV:
        state <= IDLE;
    default:
      state <= IDLE;
    endcase
//-- Salidas de ordenes
always @* begin
  bauden <= (state == RECV) ? 1 : 0;
  clear <= (state == IDLE) ? 1 : 0;
  load <= (state == LOAD) ? 1 : 0;
  rcv <= (state == DAV) ? 1 : 0;
end
endmodule