module spi_pmod_da4 (
    input clk100mhz,
    input [11:0] data_in,
    input st_wrt,
    output reg cs,
    output reg mosi,
    output sclk,
    output reg done
);
    parameter IDLE = 0,
              INITIAL = 1,
              DAC_DATA = 2,
              SEND_DATA = 3;
    
    integer clk_count = 0;
    integer count = 0;
    reg clk1mhz = 0;
    reg [31:0] setup_dac = 32'h08000001;
    reg [31:0] data = 32'h0;
    reg dac_init = 0;
    reg [1:0] state, next_state;

    ///// SCLK LOGIC
    always @(posedge clk100mhz) begin
        if (clk_count == 49) begin
            clk1mhz <= ~clk1mhz;
            clk_count <= 0;
        end 
        else begin
            clk1mhz <= clk1mhz;
            clk_count <= clk_count + 1;
        end
    end
    
    always @(posedge clk1mhz) begin
        state <= next_state;
    end
    always @(*) begin
        if (~st_wrt) begin
            next_state <= IDLE;
            cs <= 1;
            mosi <= 0;
            done <= 0;
        end
        else begin
            case (state)

                /////////////////////////////////

                IDLE : begin
                    cs <= 1;
                    mosi <= 0;
                    done <= 0;
                    if (dac_init == 1) begin
                        cs <= 1;
                        next_state <= DAC_DATA;
                    end
                    else begin
                        cs <= 1;
                        next_state <= INITIAL;
                    end
                end

                /////////////////////////////////

                INITIAL : begin
                    if (count == 31) begin
                        cs <= 0;
                        dac_init <= 1;
                        mosi <= setup_dac[0];
                        next_state <= DAC_DATA;
                    end
                    else begin
                        cs <= 0;
                        mosi <= setup_dac[31-count];
                        next_state <= INITIAL;
                    end
                end

                /////////////////////////////////

                DAC_DATA : begin
                    cs <= 1;
                    mosi <= 0;
                    data <= {12'h030, data_in, 8'h00};
                    next_state <= SEND_DATA;
                end

                /////////////////////////////////

                SEND_DATA : begin
                    if (count == 31)
                     begin
                        next_state <= IDLE;
                        cs <= 0;
                        mosi <= data[0];
                        done <= 1;
                    end
                    else begin
                        mosi <= data[31-count];
                        cs <= 0;
                        next_state <= SEND_DATA;
                    end
                end

                /////////////////////////////////

                default: state <= IDLE;
            endcase
        end
    end

    always @(posedge clk1mhz) begin
        if (state == SEND_DATA | state == INITIAL) begin
            if (count == 31) begin
                count <= 0;
            end
            else begin
                count <= count + 1;
            end
        end
        else begin
            count <= 0;
        end
    end

    assign sclk = clk1mhz;

endmodule

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

