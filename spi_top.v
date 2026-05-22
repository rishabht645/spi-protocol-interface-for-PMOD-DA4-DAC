module spi_master (
    input clk, rst, tx_enable,
    output reg cs, mosi,
    output sclk
);

    integer count;
    integer bit_count;
    reg spi_clk;
    reg [1:0] state;
    reg [1:0] next_state;
    reg done;

    reg [7:0] din = 8'b10101010;

    always @(posedge clk) begin
        if (rst) count <= 0;
        else begin 
            if (state == IDLE) begin
                count <= 0;
            end
            else begin
                if (count == 7) count <= 0;
                else count <= count + 1;
            end
        end  
    end

    always @(posedge clk) begin
        if (state == TRANSFER) begin
            if (bit_count == 7) begin
                if (count == 7) begin
                    bit_count <= 0;
                end
                else begin
                    bit_count <= bit_count;
                end
            end
            else begin
                if (count == 7) begin
                    bit_count <= bit_count + 1;
                end
                else bit_count <= bit_count;
            end
        end
        else bit_count <= 0;
    end

    parameter IDLE = 0, START = 1, TRANSFER = 2, STOP = 3;

    always @(posedge clk) begin
        case (next_state)
            IDLE : spi_clk <= 0;

            START : begin
                if (count < 3 || count == 7) begin
                    spi_clk <= 1;
                end
                else spi_clk <= 0;
            end

            TRANSFER : begin
                if (count < 3 || count == 7) begin
                    spi_clk <= 1;
                end
                else spi_clk <= 0;
            end

            STOP : begin
                if (count < 3 || count == 7) begin 
                    spi_clk <= 1;
                end
                else spi_clk <= 0;
            end
            default: spi_clk <= 0;
        endcase
    end

    // SPI FSM

    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end

    always @(*) begin
        case (state)
            IDLE : begin
                cs <= 1;
                mosi <= 0;
                if (tx_enable) begin
                    next_state <= START;
                end
                else begin
                    next_state <= IDLE;
                end
            end

            //////////////////////////////////////

            START : begin
                cs <= 0;
                if (count == 7) begin
                    next_state <= TRANSFER;
                end
                else begin
                    next_state <= START;
                end
            end

            //////////////////////////////////////

            TRANSFER : begin
                mosi = din[7-bit_count];
                if (bit_count == 7) begin
                    if (count == 7) begin
                        next_state <= STOP;
                        mosi = 0;
                    end
                    else begin
                        next_state <= TRANSFER;
                    end
                end
                else begin
                next_state = TRANSFER;
                end
            end

            //////////////////////////////////////

            STOP : begin
                cs <= 1;
                mosi <= 0;
                if (count == 7) begin
                    next_state <= IDLE;
                    done <= 1;
                end
                else begin
                    next_state <= STOP;
                end
            end

            //////////////////////////////////////

            default: next_state <= IDLE;
        endcase
    end

    assign sclk = spi_clk;

endmodule

module spi_slave (
    input sclk, mosi, cs,
    output [7:0] dout,
    output reg done
);
    integer count;
    reg state;
    reg [7:0] data;

    parameter IDLE = 0, SAMPLE = 1;

    always @(negedge sclk) begin
        case (state)
            IDLE : begin
                done <= 0;
                data <= 0;
                count <= 0;
                if (cs == 0) state <= SAMPLE;
            end

            //////////////////////////////////

            SAMPLE : begin
                if (count < 8) begin
                    count <= count + 1;
                    data <= {data[6:0], mosi};
                end
                else begin
                    done <= 1;
                    state <= IDLE;
                    count <= 0;
                end
            end
            default: state <= IDLE;
        endcase
    end

    assign dout = data;
endmodule

module top (
    input clk, rst, tx_enable,
    output [7:0] dout,
    output done
);

    wire cs, mosi, sclk;

    spi_master MASTER (clk, rst, tx_enable, cs, mosi, sclk);
    spi_slave SLAVE (sclk, mosi, cs, dout, done);
endmodule

module tb;
    reg clk = 0;
    reg rst = 0;
    reg tx_enable = 0;
    wire [7:0] dout;
    wire done;

    top TOP(clk, rst, tx_enable, dout, done);

    always #5 clk <= ~clk;

    initial begin
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
    end

    initial begin
        tx_enable = 0;
        repeat(5) @(posedge clk);
        tx_enable = 1;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        @(posedge done);
        repeat(5) @(posedge clk);
        $finish;
    end
endmodule