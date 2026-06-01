// Code your design here  master_bridge
`timescale 1ns/1ns
module master_bridge(
  input [8:0] apb_write_paddr, apb_read_paddr,
  input [7:0]  apb_write_data,apb_read_data, PRDATA,
  input PRESETn, PCLK, read_write,transfer,PREADY,READ_WRITE,
  output reg PSEL1, PSEL2,
  output reg PENABLE,
  output reg [8:0] PADDR,
  output reg PWRITE,
  output reg [7:0] PWDATA, apb_read_data_out,
  output reg PSLVERR
);
   
  
  //simple synchronous FSM with registered output
  localparam IDLE   = 3'b001,
           SETUP  = 3'b010,
           ENABLE = 3'b100;
  reg [2:0]state, next_state;
  
  //next output signala(combinational)
  
  reg next_enable;
  reg [8:0] next_paddr;
  reg next_pwrite;
  reg [7:0] next_pwdata;
  reg capture_read_data;
  
  //error flags(combinational)
  reg setup_error;
  reg invalid_read_paddr;
  reg invalid_read_data;
  reg invalid_write_paddr;
  reg invalid_write_data;
  reg invalid_setup_error_next;
  reg capture_setip_error_nrxt
  
  //synchronous state and registered output
  
  always@ (posedge PCLK or negedge PRESETn)begin
    if(!PRESETn)begin
      state <= next_state;
      PENABLE <= 1'b0;
      PADDR <= 9'b0;
      PWRITE <= 1'b0;
      PWDATA <= 8'b0;
      apb_read_data_out <= 8'b0;
      PSEL1 <= 1'b0;
      PSEL2 <= 1'b0;
      PSLVERR <= 1'b0;
    end else begin
       state <= next_state;
      PENABLE <= next_enable;
      PADDR <= next_paddr;
      PWRITE <= next_pwrite;
      PWDATA <= next_pwdata;
      
      if(capture_read_data) apb_read_data_out<= PRDATA;  // PSEL signals derived from registered PADDR and state
      
      if(state !=IDLE && (next_state == SETUP || next_state == ENABLE || PENABLE))
        begin
          if(next_paddr[8])
            begin PSEL1 <= 1'b0; PSEL2 <=1'b1; 
            end
          else
            begin PSEL1 <= 1'b1; PSEL2 <=1'b0; 
            end
        end
      else begin
        PSEL1 <= 1'b0; PSEL2 <=1'b0;
      end
      PSLVERR <= invalid_setup_error_next;
    end
  end
    
  // combinational next_state and next-output logic
  always@(*) begin
    //default->hold values
    next_state = state;
    next_enable = 1'b0;
    next_paddr = PADDR;
    next_pwrite = PWRITE;
    next_pwdata = PWDATA;
    capture_setup_error_next = 1'b0;
    
    case(state)
      IDLE: begin
        // drive PWRITE/paddr/pwdata for nrxt setup if transfer asserted
        if(transfer)begin
          next_state = SETUP;
          next_pwrite = ~READ_WRITE;
          next_paddr = READ_WRITE ? apb_read_paddr : apb_write_paddr;
          next_pwdata = apb_write_data;
          end
        else begin
          next_state = IDLE;
        end
      end
        
      SETUP: begin
        // stay in SETUP untill we move to ENABLE or IDLE on PSLVERR
        next_enable = 1'b0;
        next_pwrite = ~READ_WRITE;
        next_paddr = READ_WRITE ? apb_read_paddr : apb_write_paddr;
        next_pwdata = apb_write_data;
      end
        if(!PSLVERR) next_state = ENABLE;
        else next_state = IDLE;
      end
      
      ENABLE: begin
        next_enable = 1'b1 ;
        // if PSLVERR go to IDLE;
        if(PSLVERR)begin
          next_state = IDLE;
        end else begin
          // wait for PREADY to complete transfer
          if(PREADY) begin
            // capture read data when read transfer still asserted, else IDLE
            next_state = transfer ? SETUP : IDLE;
            // prepare PWRITE/paddr/pwdata for the next transfer if SETUP
            next_pwrite = ~READ_WRITE;
            next_paddr = READ_WRITE ? apb_read_paddr : apb_write_data;
          else begin
            next_state = ENABLE; // remain in enable
          end
       
      end
      default: next_state = IDLE;
    endcase
            
    //error checks (deterministics)
    // invalid data/address when bus expects values
    if((apb_write_data == 8'bx) && (!READ_WRITE) && (state==SETUP || state== ENABLE))
      invalid_write_data = 1'b1;
    
    if((apb_read_data == 9'bxxxxxxxxx) && (READ_WRITE) && (state==SETUP || state== ENABLE))
      invalid_read_data = 1'b1;
    
    if((apb_write_data == 9'bxxxxxxxxx) && (!READ_WRITE) && (state==SETUP || state== ENABLE))
      invalid_write_data = 1'b1;
    
    //setup correctness only when in SeETUP : check PADDR/PWDATA will match expected
    if(state == SETUP)begin
      if(next_pwrite)begin
        if((next_paddr != apb_write_paddr) || (next_paddr !== apb_write_data))
          setup_error =1'b1;
      end else begin
        if(next_paddr !==apb_read_paddr)
           setup_error =1'b1;
      end
    end
    
    invalid_setup_error_next = setup_error || invalid_read_paddr || invalid_write_data || invalid_write_paddr;
  end
endmodule
    
