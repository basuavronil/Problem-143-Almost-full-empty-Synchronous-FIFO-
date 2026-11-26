`timescale 1ns / 1ps

module sync_fifo (
    input  wire       clk,
    input  wire       rst,      // Active-low reset (0 = reset)
    input  wire       wr_en,
    input  wire       rd_en,
    input  wire [7:0] data_in,
    output reg  [7:0] data_out,
    output wire       empty,
    output wire       full,
    output wire       almost_empty,
    output wire       almost_full
);

    reg [7:0] mem [0:15];
    reg [4:0] wr_ptr;
    reg [4:0] rd_ptr;

    wire [4:0] count = wr_ptr - rd_ptr;

    assign empty = (rd_ptr == wr_ptr);
    assign full  = (rd_ptr[4] != wr_ptr[4]) && (rd_ptr[3:0] == wr_ptr[3:0]);

    assign almost_empty = (count <= 5'd2);
    assign almost_full  = (count >= 5'd14);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            wr_ptr <= 5'd0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[3:0]] <= data_in;
            wr_ptr           <= wr_ptr + 1'b1;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            rd_ptr   <= 5'd0;
            data_out <= 8'd0;
        end else if (rd_en && !empty) begin
            data_out <= mem[rd_ptr[3:0]];
            rd_ptr   <= rd_ptr + 1'b1;
        end
    end

endmodule
