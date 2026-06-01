module slave1(
input PCLK, PRESETn,
input PSEL1, PENABLE, PWRITE,
  input [7:0] PADDR,PWDATA,
  output [7:0] PRDATA1
  output reg PREAD);
  reg [7:0]reg_addr;
  reg[7:0] mem [0:63];
  
  assign PRDATA1 = mem[reg_addr];
  always@(*)
    begin
      if(!PRESETn)
        	PREAD =0;
      else
        if(PSEL1 && !PENABLE && !PWRITE)
          begin PREAD = 0; end
      else if(PSEL1 && PENABLE && !PWRITE)
        begin PREAD = 1;
          		reg_addr = PADDR;
        end
      else if(PSEL1 && !PENABLE && PWRITE)
        begin PREAD =0; 
        end
      
      else if(PSEL1 && PENABLE && PWRITE)
          begin PREAD =1;
            mem[PADDR]= PWDATA;
          end
      else PREAD =0;
    end
endmodule
