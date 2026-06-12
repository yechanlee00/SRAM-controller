`timescale 1ns / 1ps

module tb_sync_sram_ctrl;

    parameter ADDR_WIDTH = 8;
    parameter DATA_WIDTH = 16;

    reg clk;
    reg rst_n;

    reg  [ADDR_WIDTH-1:0] addr;
    reg  [DATA_WIDTH-1:0] data_in;
    wire [DATA_WIDTH-1:0] data_out;

    reg rd_req;
    reg wr_req;
    wire ready;

    wire [ADDR_WIDTH-1:0] sram_addr;
    wire [DATA_WIDTH-1:0] sram_data_out;
    wire [DATA_WIDTH-1:0] sram_data_in;
    wire sram_ce_n;
    wire sram_we_n;

    //============================================================
    // DUT
    //============================================================
    sync_sram_ctrl #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .addr          (addr),
        .data_in       (data_in),
        .data_out      (data_out),
        .rd_req        (rd_req),
        .wr_req        (wr_req),
        .ready         (ready),

        .sram_addr     (sram_addr),
        .sram_data_out (sram_data_out),
        .sram_data_in  (sram_data_in),
        .sram_ce_n     (sram_ce_n),
        .sram_we_n     (sram_we_n)
    );

    //============================================================
    // SRAM Model
    //============================================================
    sync_sram_model #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_sram (
        .clk       (clk),
        .rst_n     (rst_n),
        .ce_n      (sram_ce_n),
        .we_n      (sram_we_n),
        .addr      (sram_addr),
        .data_in   (sram_data_out),
        .data_out  (sram_data_in)
    );

    //============================================================
    // Clock Generation
    //============================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //============================================================
    // Test Sequence
    //============================================================
    initial begin
        rst_n   = 1'b0;
        addr    = {ADDR_WIDTH{1'b0}};
        data_in = {DATA_WIDTH{1'b0}};
        rd_req  = 1'b0;
        wr_req  = 1'b0;

        #20;
        rst_n = 1'b1;

        repeat (2) @(negedge clk);

        write_check(8'h00, 16'ha5a5);
        write_check(8'h01, 16'h5a5a);

        read_check(8'h00, 16'ha5a5);
        read_check(8'h01, 16'h5a5a);

        write_check(8'h02, 16'hffff);
        read_check(8'h02, 16'hffff);

        write_check(8'h00, 16'h7878);
        read_check(8'h00, 16'h7878);

        $display("All tests passed successfully!");

        #50;
        $finish;
    end

    //============================================================
    // Write Task
    //============================================================
    task write_check;
        input [ADDR_WIDTH-1:0] wr_addr;
        input [DATA_WIDTH-1:0] wr_data;
        begin
            wait_ready();

            @(negedge clk);
            addr    = wr_addr;
            data_in = wr_data;
            wr_req  = 1'b1;
            rd_req  = 1'b0;

            @(negedge clk);
            wr_req  = 1'b0;

            wait_ready();

            $display("Write Check: Address %02h, Data %04h", wr_addr, wr_data);
        end
    endtask

    //============================================================
    // Read Task
    //============================================================
    task read_check;
        input [ADDR_WIDTH-1:0] rd_addr;
        input [DATA_WIDTH-1:0] expected_data;
        begin
            wait_ready();

            @(negedge clk);
            addr    = rd_addr;
            data_in = {DATA_WIDTH{1'b0}};
            rd_req  = 1'b1;
            wr_req  = 1'b0;

            @(negedge clk);
            rd_req  = 1'b0;

            wait_ready();

            #1;

            if (data_out === expected_data) begin
                $display("Read Check Passed: Address %02h, Data %04h",
                         rd_addr, data_out);
            end else begin
                $display("Read Check Failed: Address %02h, Expected %04h, Got %04h",
                         rd_addr, expected_data, data_out);
                $finish;
            end
        end
    endtask

    //============================================================
    // Wait Ready
    //============================================================
    task wait_ready;
        begin
            while (ready !== 1'b1) begin
                @(posedge clk);
            end
        end
    endtask

endmodule


//============================================================
// Simple Synchronous SRAM Model
//============================================================
module sync_sram_model #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 16
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    ce_n,
    input  wire                    we_n,
    input  wire [ADDR_WIDTH-1:0]   addr,
    input  wire [DATA_WIDTH-1:0]   data_in,
    output reg  [DATA_WIDTH-1:0]   data_out
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};

            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            if (!ce_n) begin
                if (!we_n) begin
                    mem[addr] <= data_in;
                end else begin
                    data_out <= mem[addr];
                end
            end
        end
    end

endmodule
