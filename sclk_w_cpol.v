module top;
    reg clk = 0;
    integer clk_count = 0;
    reg ready = 1;
    integer spi_edges = 0;
    reg start = 0;
    reg sclk = 1;
    reg cpol = 1;
    reg spi_t = 0, spi_l = 0;

    always #5 clk = ~clk;

    initial begin
        @(posedge clk);
        start = 1;
        #11;
        start = 0;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        repeat(40) @(posedge clk);
        $finish;
    end

    always @(posedge clk) begin
        if (start) begin
            ready <= 0;
            spi_edges <= 16;
            sclk <= cpol;
        end
        else if (spi_edges > 0) begin
            spi_l <= 0;
            spi_t <= 0;

            if (clk_count == 1) begin
                spi_l <= 1;
                sclk <= ~sclk;
                clk_count <= clk_count + 1;
                spi_edges <= spi_edges - 1;
            end

            else if (clk_count == 3) begin
                spi_t <= 1;
                sclk <= ~sclk;
                clk_count <= 0;
                spi_edges <= spi_edges - 1;
            end

            else begin
                clk_count <= clk_count + 1;
            end
        end
        else begin
            ready <= 1;
            spi_t <= 0;
            spi_l <= 0;
            sclk <= cpol;
        end
    end
endmodule