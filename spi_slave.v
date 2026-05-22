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
                if (cs == 0) state <= SAMPLE;
            end

            //////////////////////////////////

            SAMPLE : begin
                if (count < 8) begin
                    count <= count + 1;
                    data <= {data[7:1], mosi};
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