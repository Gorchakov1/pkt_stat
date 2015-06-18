module stat_pkt #(
  parameter A_WIDTH = 10,
  parameter D_WIDTH = 32
) 
(
  input                      clk_i,
  input                      rst_i,

  input [A_WIDTH-1:0]        rx_flow_num_i,
  input [15:0]               pkt_size_i,
  input                      pkt_size_ena_i,
                             
  input                      rd_stb_i,
  input [A_WIDTH-1:0]        rd_flow_num_i,

  output logic [D_WIDTH-1:0] rd_data_o,
  output logic               rd_data_val_o
);

logic [A_WIDTH-1:0] rx_flow_num_d1;
logic [15:0]        pkt_size_d1;
logic               pkt_size_ena_d1;

logic [A_WIDTH-1:0] rx_flow_num_d2;
logic [15:0]        pkt_size_d2;
logic [15:0]        pkt_size2;
logic               pkt_size_ena_d2;

logic [A_WIDTH-1:0] wr_addr;
logic [D_WIDTH-1:0] sum_size;
logic [D_WIDTH-1:0] wr_size;
logic               pkt_size_ena_d3;

logic [A_WIDTH-1:0] rd_flow_num;
logic               rd_stb;

logic check_eq_wr_flow;
logic check_eq_wr_flow_d;
logic check_eq_wr_rd_flow_d;
logic wr_ena;
logic check_eq_wr_rd_flow;
// ѕроверка на то, что два подр€д такта идет один адрес
assign check_eq_wr_flow    = ( ( rx_flow_num_i == rx_flow_num_d1 ) &&
                               ( pkt_size_ena_d1 && pkt_size_ena_i ) );
// ѕроверка одинаковый ли адрес чтени€ и записи
assign check_eq_wr_rd_flow = ( ( rd_flow_num == rx_flow_num_d2 ) &&
                                 pkt_size_ena_d2 && rd_stb );



always_ff @( posedge clk_i or posedge rst_i )
  begin
    if( rst_i )
      begin
        rx_flow_num_d1  <= '0;
        pkt_size_d1     <= '0;
        pkt_size_ena_d1 <= 1'b0;

	check_eq_wr_flow_d <= 1'b0;
	check_eq_wr_rd_flow_d <= 1'b0;
    
        rx_flow_num_d2  <= '0;
        pkt_size_d2     <= '0;
        pkt_size_ena_d2 <= 1'b0;

	pkt_size_ena_d3 <= '0;
      end
    else
      begin
        rx_flow_num_d1        <= rx_flow_num_i;
        pkt_size_d1           <= pkt_size_i;

	//  огда приход€т два подр€д запроса на запись, но с одинаковыми
        // адресами мы их сразу складываем и поэтому убираем pkt_size_ena_d1
        pkt_size_ena_d1       <= ( ~check_eq_wr_flow )? pkt_size_ena_i : 1'b0;

        check_eq_wr_flow_d    <= check_eq_wr_flow;
	check_eq_wr_rd_flow_d <= check_eq_wr_rd_flow;

        rx_flow_num_d2        <= rx_flow_num_d1;   
        pkt_size_d2           <= pkt_size_d1;
        pkt_size_ena_d2       <= pkt_size_ena_d1;

	pkt_size_ena_d3       <= pkt_size_ena_d2;
      end
  end
logic [A_WIDTH-1:0] rd_addr;
logic [A_WIDTH-1:0] rd_addr_d;
logic [A_WIDTH-1:0] clean_ena;
assign rd_addr = ( pkt_size_ena_d1 )? rx_flow_num_d1 : rd_flow_num;
// ћомент когда можно записать занулить в пам€ти
assign clean_ena = ( ( rd_stb && pkt_size_ena_d3 ) && ( rd_flow_num == rd_addr_d ) );
always_ff @( posedge clk_i or posedge rst_i )
  begin
    if( rst_i )
      pkt_size2 <= '0;
    else
      begin
        if( check_eq_wr_flow )
	  pkt_size2 <= pkt_size_i;
        else
          pkt_size2 <= '0;
      end
  end

always_comb
  begin
    wr_addr <= ( pkt_size_ena_d2                           )? 
	         rx_flow_num_d2 : rd_flow_num;
    wr_size <= ( pkt_size_ena_d2                           )?
	         pkt_size_d2 + ( sum_size * !check_eq_wr_rd_flow ) + pkt_size2 : '0;
    wr_ena  <= ( pkt_size_ena_d2 )? 
                 pkt_size_ena_d2 : ( rd_stb && !check_eq_wr_rd_flow_d && clean_ena );
  end


always_ff @( posedge clk_i or posedge rst_i )
  begin
    if( rst_i )
      begin
        rd_flow_num <= '0;
        rd_addr_d   <= '0;
      end
    else
      begin
	rd_addr_d <= rd_addr;
	if( rd_stb_i )
          begin
            rd_flow_num <= rd_flow_num_i;
          end
      end
  end
always_ff @( posedge clk_i or posedge rst_i )
  begin
    if( rst_i )
      rd_stb <= '0;
    else
      begin
	if( rd_stb_i )
          rd_stb <= 1'b1;
        if( rd_data_val_o )
          rd_stb <= 1'b0;
      end
  end

always_ff @( posedge clk_i or posedge rst_i )
  begin
    if( rst_i )
      begin
        rd_data_o     <= '0;
        rd_data_val_o <= 1'b0; 
      end
    else
      begin
        rd_data_o     <= sum_size;
	rd_data_val_o <= clean_ena;
      end
  end
 

ram_2port_1clk
#(
  .DATA_WIDTH  ( D_WIDTH  ),
  .ADDR_WIDTH  ( A_WIDTH  )
)
ram (
.clk                                    ( clk_i             ),

.data                                   ( wr_size           ),

.read_addr                              ( rd_addr           ),
.write_addr                             ( wr_addr           ),
.we                                     ( wr_ena            ),

.q                                      ( sum_size          )
);




endmodule

