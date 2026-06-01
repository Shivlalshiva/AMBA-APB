module slave2(
input PCLK, PRESETn,
input PSEL2, PENABLE, PWRITE,
  input [7:0]PADDR,PWDATA,
  output [7:0]PRDATA2
  output reg PREAD);
  reg [7:0]reg_addr;
  reg[7:0] mem2 [0:63];
  
  assign PRDATA2 = mem2[reg_addr];
  always@(*)
    begin
      if(!PRESETn)
        	PREAD =0;
      else
        if(PSEL2 && !PENABLE && !PWRITE)
          begin PREAD = 0; end
      else if(PSEL2 && PENABLE && !PWRITE)
        begin PREAD = 1;
          		reg_addr = PADDR;
        end
      else if(PSEL2 && !PENABLE && PWRITE)
        begin PREAD =0; end
      
      else if(PSEL2 && PENABLE && PWRITE)
          begin PREAD =1;
            mem2[PADDR]= PWDATA;
          end
      else PREAD =0;
    end
endmodule
