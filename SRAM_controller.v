`timescale 1ns / 1ps

module sync_sram_ctrl #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire rst_n,

    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,

    input wire rd_req,
    input wire wr_req,
    output reg ready,

    output reg [ADDR_WIDTH-1:0] sram_addr,
    output reg [DATA_WIDTH-1:0] sram_data_out,
    input wire [DATA_WIDTH-1:0] sram_data_in,
    output reg sram_ce_n,
    output reg sram_we_n
);

    localparam IDLE         = 2'd0;
    localparam READ_WAIT    = 2'd1;
    localparam READ_CAPTURE = 2'd2;
    localparam WRITE        = 2'd3;

    reg [1:0] state;
    reg [1:0] next_state;

    //============================================================
    // 1. State Register
    //============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    //============================================================
    // 2. Next State Logic
    //============================================================
    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (wr_req) begin
                    next_state = WRITE;
                end else if (rd_req) begin
                    next_state = READ_WAIT;
                end else begin
                    next_state = IDLE;
                end
            end

            WRITE: begin
                next_state = IDLE;
            end

            READ_WAIT: begin
                next_state = READ_CAPTURE;
            end

            READ_CAPTURE: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    //============================================================
    // 3. Output and Control Logic
    //============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out      <= {DATA_WIDTH{1'b0}};
            ready         <= 1'b0;

            sram_addr     <= {ADDR_WIDTH{1'b0}};
            sram_data_out <= {DATA_WIDTH{1'b0}};
            sram_ce_n     <= 1'b1;
            sram_we_n     <= 1'b1;
        end else begin
            // default value
            sram_ce_n <= 1'b1;
            sram_we_n <= 1'b1;
            ready     <= 1'b0;

            case (state)
                IDLE: begin
                    ready <= 1'b1;

                    if (wr_req) begin
                        sram_addr     <= addr;
                        sram_data_out <= data_in;
                        sram_ce_n     <= 1'b0;
                        sram_we_n     <= 1'b0;
                        ready         <= 1'b0;
                    end else if (rd_req) begin
                        sram_addr <= addr;
                        sram_ce_n <= 1'b0;
                        sram_we_n <= 1'b1;
                        ready     <= 1'b0;
                    end
                end

                WRITE: begin
                    ready     <= 1'b1;
                    sram_ce_n <= 1'b1;
                    sram_we_n <= 1'b1;
                end

                READ_WAIT: begin                       // SRAM read data is being updated in this cycle.
                    ready     <= 1'b0;
                    sram_ce_n <= 1'b1;
                    sram_we_n <= 1'b1;
                end

                READ_CAPTURE: begin                    // Now sram_data_in is valid.
                    data_out  <= sram_data_in;
                    ready     <= 1'b1;
                    sram_ce_n <= 1'b1;
                    sram_we_n <= 1'b1;
                end

                default: begin
                    ready     <= 1'b1;
                    sram_ce_n <= 1'b1;
                    sram_we_n <= 1'b1;
                end
            endcase
        end
    end

endmodule
