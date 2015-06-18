module tb;
parameter A_WIDTH = 3;
parameter D_WIDTH = 32;

logic               clk;
logic               rst;

logic [A_WIDTH-1:0] rx_flow_num;
logic [15:0]        pkt_size;
logic               pkt_size_ena;
                           
logic               rd_stb;
logic [A_WIDTH-1:0] rd_flow_num;

logic [D_WIDTH-1:0] rd_data;
logic               rd_data_val;




initial 
  begin
    clk = 1'b0;
    forever
      begin
        #10.0 clk = ~clk;
      end
  end

initial 
  begin
    rst = 1'b1;
    #11.0 rst = 1'b0;
  end


logic first_rd;
initial
  begin
    init();
    #30.0
    first_rd = 1'b1;
    #40.0
    first_rd = 1'b0;
  end

initial
  begin
    #30.0 
    for( int i = 0; i < 1000; i++ )
      begin
        wr_stat( $random, $random, 1'b1 );
      end
    end
initial
  begin
    #50.0
    rd_stat( $random, 1'b1 );
    for( int i = 0; i < 1000; i++ )
      begin
        wait ( rd_data_val );
	  @cb;
          rd_stat( $random, 1'b1 );	
      end
  end

/*
initial
  begin
    #30.0 
      wr_stat( 3'b111, 16'haf, 1'b1 );
      wr_stat( 3'b111, 16'h0f, 1'b1 );
      wr_stat( 3'b111, 16'h0f, 1'b1 );
      wr_stat( 3'b111, 16'h0f, 1'b1 );
      wr_stat( 3'b111, 16'h0f, 1'b1 );
      rd_stat( '1, 1'b1);
      wr_stat( 3'b111, 16'h0f, 1'b1 );
      wr_stat( 3'b001, 16'h0f, 1'b1 );
      wr_stat( 3'b011, 16'h0f, 1'b1 );
      wr_stat( 3'b101, 16'h0f, 1'b1 );
      wr_stat( 3'b110, 16'h0f, 1'b1 );
      wr_stat( 3'b011, 16'h0f, 1'b1 );
      wr_stat( 3'b001, 16'h0f, 1'b1 );
      wr_stat( 3'b101, 16'ha0, 1'b1 );
      rd_stat( '1, 1'b1);
   end
*/



clocking cb @( posedge clk );
endclocking
task wr_stat( input [A_WIDTH-1:0]  _rx_flow_num,
              input [15:0]         _pkt_size,
	      input                _pkt_size_ena
                                                );
  @cb;
  rx_flow_num  <= _rx_flow_num;
  pkt_size     <= _pkt_size;
  pkt_size_ena <= _pkt_size_ena;

endtask

task rd_stat( input [A_WIDTH-1:0]  _rd_flow_num,
	      input                _rd_stb
                                                );
  @cb;
  rd_flow_num <= _rd_flow_num;
  rd_stb      <= _rd_stb;

  @cb;
  rd_stb <= 1'b0;
  
endtask

task init();
  rx_flow_num  <= 0;
  pkt_size     <= 0;
  pkt_size_ena <= 0;
  rd_flow_num  <= 0;
  rd_stb       <= 0;
endtask
//////////////////////////////


stat_pkt 
#(
  .D_WIDTH ( D_WIDTH ),
  .A_WIDTH ( A_WIDTH )
)
stat (
.clk_i              ( clk           ),
.rst_i              ( rst           ),

.rx_flow_num_i      ( rx_flow_num   ),
.pkt_size_i         ( pkt_size      ),
.pkt_size_ena_i     ( pkt_size_ena  ),

.rd_stb_i           ( rd_stb        ),
.rd_flow_num_i      ( rd_flow_num   ),

.rd_data_o          ( rd_data       ),
.rd_data_val_o      ( rd_data_val   )
);
endmodule
