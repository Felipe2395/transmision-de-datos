module trasmitir (
         input wire clk,        //-- Reloj del sistema
         input wire rstn,       //-- Reset global (activo nivel bajo)
         input wire start,      //-- Activar a 1 para transmitir
         input wire [7:0] data, //-- Byte a transmitir
         output reg tx,         //-- Salida de datos serie (hacia el PC)
         output wire ready      //-- Transmisor listo / ocupado
       );

//-- Pvelocidad de transmision
parameter BAUD =  1250;

//-- Señal de start registrada
reg start_r; 

//-- Reloj para la transmision
wire clk_baud;

//-- Bitcounter
reg [3:0] bitc;

//-- Datos registrados
reg [7:0] data_r;

//--------- Otras ordenes
wire load;    //-- Carga del registro de desplazamiento. Puesta a 0 del
              //-- contador de bits
wire baud_en; //-- Habilitar el generador de baudios para la transmision

//-------------------------------------
//-- DATAPATH
//-------------------------------------

//-- Registrar la entrada start
always @(posedge clk)
  start_r <= start;

always @(posedge clk)
  if (start == 1 && state == IDLE)
    data_r <= data;

//-- Registro de 10 bits para almacenar la trama a enviar:
//-- 1 bit start + 8 bits datos + 1 bit stop
reg [9:0] shifter;

//-- Cuando la microorden load es 1 se carga la trama
//-- con load 0 se desplaza a la derecha y se envia un bit, al
//-- activarse la señal de clk_baud que marca el tiempo de bit
//-- Se introducen 1s por la izquierda
always @(posedge clk)
  //-- Reset
  if (rstn == 0)
    shifter <= 10'b11_1111_1111;

  //-- Modo carga
  else if (load == 1)
    shifter <= {data_r,2'b01};

  //-- Modo desplazamiento
  else if (load == 0 && clk_baud == 1)
    shifter <= {1'b1, shifter[9:1]};

//-- Contador de bits enviados
//-- Con la microorden load (=1) se hace un reset del contador
//-- con load = 0 se realiza la cuenta de los bits, al activarse
//-- clk_baud, que indica el tiempo de bit
always @(posedge clk)
  if (load == 1)
    bitc <= 0;
  else if (load == 0 && clk_baud == 1)
    bitc <= bitc + 1;

//-- Sacar por tx el bit menos significativo del registros de desplazamiento
always @(posedge clk)
  tx <= shifter[0];

//-- Divisor para obtener el reloj de transmision
generadorbaudios #(BAUD)
  BAUD0 (
    .clk(clk),
    .clk_ena(baud_en),
    .clk_out(clk_baud)
  );

//------------------------------
//-- CONTROLADOR
//------------------------------

//-- Estados del automata finito del controlador
localparam IDLE  = 0;  //-- Estado de reposo
localparam START = 1;  //-- Comienzo de transmision
localparam TRANS = 2;  //-- Estado: transmitiendo dato

//-- Estados del autómata del controlador
reg [1:0] state;

//-- Transiciones entre los estados
always @(posedge clk)

  //-- Reset
  if (rstn == 0)
    state <= IDLE;

  else
    //-- Transiciones a los siguientes estados
    case (state)

      //-- Estado de reposo. Se sale cuando la señal
      //-- de start se pone a 1
      IDLE: 
        if (start_r == 1) 
          state <= START;
        else 
          state <= IDLE;

      //-- Estado de comienzo. Prepararse para empezar
      //-- a transmitir. Duracion: 1 ciclo de reloj
      START:
        state <= TRANS;

      //-- TransmitiR
      TRANS:
        if (bitc == 11)
          state <= IDLE;
        else
          state <= TRANS;

      //-- Por defecto
      default:
        state <= IDLE;

    endcase

//-- Generacion de las microordenes
assign load = (state == START) ? 1 : 0;
assign baud_en = (state == IDLE) ? 0 : 1;

//-- Señal de salida. Esta a 1 cuando estamos en reposo
//. En caso contrario esta a 0
assign ready = (state == IDLE) ? 1 : 0;

endmodule
