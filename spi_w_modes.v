module top ();
    reg clk = 0;
    reg ready = 1;
    reg cpol = 0;
    reg sclk = 0;
    reg start = 0;
    integer spi_edges = 0;
    integer clk_count = 0;


    always #5 clk =  ~clk;

    initial begin
        @(posedge clk);
        start = 1;
        #11;
        start = 0;
    end   

    initial begin
        din = 8'b10101010;
        $dumpfile("dump.vcd");
        $dumpvars;
        repeat(40) @(posedge clk);
        $finish; 
    end

    always @(posedge clk) begin
        if (start) begin
            ready <= 0;
            count <= 0;
            spi_edges <= 16;
            sclk <= cpol;
        end
        else if (spi_edges > 0) begin
            if (clk_count == 1) begin
                clk_count <= clk_count + 1;
                sclk <= ~sclk;
                spi_edges <= spi_edges - 1;
            end

            else if (clk_count == 3) begin
                clk_count <= 0;
                sclk <= ~sclk;
                spi_edges <= spi_edges - 1;
            end

            else begin
                clk_count <= clk_count + 1;
            end
        end
        else begin
            ready <= 1;
            sclk <= cpol;
        end
    end

    reg [7:0] din = 0;
    integer count = 0;
    integer bit_count = 0;
    reg mosi = 0;
    reg cs = 1;
    reg cpha = 0;
    reg [2:0] state;

    parameter IDLE = 0, TRANSFER = 1, WAIT1 = 2, WAIT2 = 3, STOP = 4;

    always @(posedge clk) begin
        case (state)
            IDLE : begin
                bit_count <= 0;
                count <= 0;
                if (start) begin
                    cs <= 0;
                    if (cpha) begin
                        state <= WAIT1;
                    end
                    else begin
                        state <= TRANSFER;
                    end
                end
                else begin
                    cs <= 1;
                    state <= IDLE;
                end
            end

            //////////////////////////////

            TRANSFER : begin
                if (count == 3) begin
                    count <= 0;
                    if (bit_count == 7) begin
                        state <= STOP;
                        bit_count <= 0;
                    end
                    else begin
                        bit_count <= bit_count + 1;
                        state <= TRANSFER;
                    end
                end
                else begin
                    mosi <= din[7-bit_count];
                    count <= count + 1;
                    state <= TRANSFER;
                end
            end

            //////////////////////////////
            
            WAIT1 : begin
                if (clk_count == 1) begin
                    state <= TRANSFER;
                end
                else begin
                    state <= WAIT1;
                end
            end

            //////////////////////////////

            STOP : begin
                cs <= 1;
                state <= IDLE;
                mosi <= 0;
            end

            //////////////////////////////

            default: state <= IDLE;
        endcase
    end

    /// slave
    reg [7:0] rx_data = 0;
    integer r_count = 0;
    always @(posedge sclk ) begin
        if (cs == 0) begin
            if (r_count < 8) begin
                rx_data <= {rx_data[6:0], mosi};
                r_count <= r_count + 1;
            end
            else begin
                r_count <= 0;
            end
        end
        else begin
            rx_data <= 0;
            r_count <= 0;
        end
    end
endmodule