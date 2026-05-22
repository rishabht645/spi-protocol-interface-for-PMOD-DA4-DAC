module tb;
 
    reg clk100mhz = 0;
    wire cs;
    wire mosi;
    wire sclk;
    reg st_wrt = 0;
    reg [11:0] data_in = 0;
    wire done;
    
    
    spi_pmod_da4 dut (clk100mhz, data_in, st_wrt, cs, mosi, sclk, done);
    
    always #5 clk100mhz = ~clk100mhz;
    
    initial begin
    st_wrt = 1;
    data_in = 12'b101010101010; 
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        @(posedge done);
        repeat(100) @(posedge clk100mhz);
        $finish;
    end
 
 
 
endmodule