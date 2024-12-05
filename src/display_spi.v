// Apollo Guidance Computer FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2024 by Michael Kohn

module display_spi
(
  input  raw_clk,
  input  start,
  input  [15:0] data_tx,
  output busy,
  output reg cs,
  output reg sclk,
  output reg mosi
);

reg [1:0] state = 0;
reg [39:0] tx_buffer;
reg [5:0] count;

parameter STATE_IDLE    = 0;
parameter STATE_CLOCK_0 = 1;
parameter STATE_CLOCK_1 = 2;
parameter STATE_LAST    = 3;

assign busy = state != STATE_IDLE;

reg [5:0] divisor = 0;

always @(posedge raw_clk) begin
  case (state)
    STATE_IDLE:
      begin
        if (start) begin
          tx_buffer[39:32] <= 8'h76;
          tx_buffer[31:24] <= data_tx[15:12];
          tx_buffer[23:16] <= data_tx[11:8];
          tx_buffer[15:8]  <= data_tx[7:4];
          tx_buffer[7:0]   <= data_tx[3:0];

          divisor <= 0;
          cs <= 0;

          state <= STATE_CLOCK_0;
          count <= 0;
        end else begin
          cs   <= 1;
          sclk <= 0;
          mosi <= 0;
        end
      end
    STATE_CLOCK_0:
      begin
        sclk <= 0;

        if (divisor == 0) begin
          mosi <= tx_buffer[39];
          tx_buffer <= tx_buffer << 1;
          count <= count + 1;
        end

        if (divisor == 48) begin
          divisor <= 0;
          state <= STATE_CLOCK_1;
        end else begin
          divisor <= divisor + 1;
        end
      end
    STATE_CLOCK_1:
      begin
        sclk <= 1;

        if (divisor == 48) begin
          if (count == 40) begin
            state <= STATE_LAST;
          end else begin
            divisor <= 0;
            state <= STATE_CLOCK_0;
          end
        end else begin
          divisor <= divisor + 1;
        end
      end
    STATE_LAST:
      begin
        sclk <= 0;
        state <= STATE_IDLE;
      end
  endcase
end

endmodule

