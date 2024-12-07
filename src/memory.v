// Apollo Guidance Computer FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2024 by Michael Kohn

// The purpose of this module is to route reads and writes to the 4
// different memory banks. Originally the idea was to have ROM and RAM
// be SPI EEPROM (this may be changed in the future) so there would also
// need a "ready" signal that would pause the CPU until the data can be
// clocked in and out of of the SPI chips.

module memory
(
  input  [11:0] address,
  input  [15:0] data_in,
  output [15:0] data_out,
  input bus_enable,
  input write_enable,
  input clk,
  input raw_clk,
  input  [8:0] io_address,
  input  [15:0] io_data_in,
  output reg [15:0] io_data_out,
  input io_bus_enable,
  input io_write_enable,
  //output speaker_p,
  //output speaker_m,
  output reg ioport_0,
  output reg ioport_1,
  output reg ioport_2,
  output reg ioport_3,
  output reg ioport_4,
  input joystick_0,
  input joystick_1,
  input joystick_2,
  input joystick_3,
  input joystick_4,
  input interrupt_enable,
  output [15:0] out_a,
  output [14:0] out_l,
  output [15:0] out_q,
  output [11:0] out_z,
  output [15:0] out_zrupt,
  output [15:0] out_brupt,
  output reg [5:0] interrupt_flags,
  input  [5:0] interrupt_clear,
  input  button_0,
  output display_clk,
  output display_cs,
  output display_do,
  output spi_clk_0,
  output spi_mosi_0,
  input  spi_miso_0,
  input reset
);

reg [15:0] erasable_memory [2047:0];
reg [15:0] fixed_memory [4095:0];

reg enable_time6 = 1;

initial begin
  $readmemh("rom.txt", fixed_memory);
end

// a: Accumulator.
// l: Lower product.
// q: Return address of called procedure.
// z: Program counter.
// eb: Erasable bank register.
// fb: Fixed bank register.
reg [15:0] reg_a;
reg [14:0] reg_l;
reg [15:0] reg_q;
reg [11:0] reg_z;
reg [15:0] zrupt;
reg [15:0] brupt;
reg [2:0] eb;
reg [4:0] fb;

assign out_a = reg_a;
assign out_l = reg_l;
assign out_q = reg_q;
assign out_z = reg_z;
assign out_zrupt = zrupt;
assign out_brupt = brupt;

reg [15:0] cyr;
reg [15:0] sr;
reg [15:0] cyl;
reg [15:0] edop;

// Timers and interrupt flags.
reg [14:0] time1;
reg [13:0] time2;
reg [14:0] time3;
reg [14:0] time4;
reg [14:0] time5;
reg [14:0] time6;
reg [15:0] clock_div_3;
reg [15:0] clock_div_4;
reg [15:0] clock_div_5;
reg [9:0]  clock_div_6000;

//reg [5:0] update_time;
//reg [5:0] interrupt_flags;

reg display_start;
reg [15:0] display_data;
wire display_busy;

wire [7:0] spi_rx_buffer;
reg  [7:0] spi_tx_buffer;
wire spi_busy;
reg spi_start;

// Each erasable bank is 256 words (0x100).
// 00000 - 00377 (0x0000 - 0x00ff)  E0 Overlap
// 00400 - 00777 (0x0100 - 0x01ff)  E1 Overlap
// 01000 - 01377 (0x0200 - 0x02ff)  E2 Overlap
// 01400 - 01777 (0x0300 - 0x03ff)  Depends on EB (0 to 7)

// Each fixed bank is 1024 words (0x400).
// 02000 - 03777 (0x0400 - 0x07ff) Bank 00 to 31 (FB/BB 00 to 31)
// 04000 - 05777 (0x0800 - 0x0bff) Common-fixed mem (bank 02 overlap)
// 06000 - 07777 (0x0c00 - 0x0fff) Common-fixed mem (bank 03 overlap)

reg [16:0] ea;
wire use_erasable;
assign use_erasable = address[11:10] == 0;
reg [15:0] data_out_reg;
reg [15:0] data_out_ram;
reg [15:0] data_out_rom;

// I/O - Pretty useless here right now. But could be used for something
// later maybe. SUPERBNK is normally used to increase the amount of fixed
// memory, but currently this implementation (on the ICE40 FPGA) doesn't
// have enough block RAM for it.
// There are supposedly more of these I/O ports defined somewhere else.

reg [15:0] hi_scaler;
reg [15:0] lo_scaler;
reg [7:0] pyjets;
reg [7:0] rolljets;
reg [7:0] superbnk;

always @ * begin
  case (address[11:10])
    2'b01: ea <= { fb, address[9:0] };
    2'b10: ea <= { 2,  address[9:0] };
    2'b11: ea <= { 3,  address[9:0] };
    default:
      // Erasable memory.
      if (address[9:8] != 2'b11)
        ea <= address;
      else
        ea <= { eb, address[7:0] };
  endcase
end

assign data_out =
  use_erasable == 0 ? data_out_rom : ea < 'o60 ? data_out_reg : data_out_ram;

always @(posedge raw_clk) begin
  if (reset) begin
    reg_a <= 0;
    reg_l <= 0;
    reg_q <= 0;
    eb <= 0;
    fb <= 0;
    reg_z <= 12'o4000;
    //update_time <= 0;
  end else if (bus_enable) begin
    if (write_enable) begin
      case (ea)
        'o0: reg_a <= data_in[15:0];
        'o1: reg_l <= data_in[14:0];
        'o2: reg_q <= data_in[15:0];
        'o3: eb    <= data_in[10:8];
        'o4: fb    <= data_in[14:10];
        'o5: reg_z <= data_in[11:0];
        'o6: begin fb <= data_in[14:10]; eb <= data_in[2:0]; end
        'o15: zrupt <= data_in[15:0];
        'o17: brupt <= data_in[15:0];
        'o20: cyr   <= { data_in[0],  data_in[14:1] };
        'o21: sr    <= { data_in[14], data_in[14:1] };
        'o22: cyl   <= { data_in[13:0], data_in[14] };
        'o23: edop  <= { 8'b0, data_in[13:7] };
        //'o24: begin update_time2 <= data_in; update_time[2] <= 1; begin
        //'o25: begin update_time1 <= data_in; update_time[2] <= 1; begin
        //'o26: begin update_time3 <= data_in; update_time[2] <= 1; begin
        //'o27: begin update_time4 <= data_in; update_time[2] <= 1; begin
        //'o30: begin update_time5 <= data_in; update_time[2] <= 1; begin
        //'o31: begin update_time6 <= data_in; update_time[2] <= 1; begin
      endcase

      if (use_erasable)
        erasable_memory[ea] <= data_in[14:0];
    end else begin
      case (ea)
         'o0: data_out_reg <= reg_a;
         'o1: data_out_reg <= reg_l;
         'o2: data_out_reg <= reg_q;
         'o3: data_out_reg <= eb;
         'o4: data_out_reg <= fb;
         'o5: data_out_reg <= reg_z;
         'o6: data_out_reg <= { fb, 7'b0, eb };
         'o7: data_out_reg <= 0;
        'o15: data_out_reg <= zrupt;
        'o17: data_out_reg <= brupt;
        'o20: data_out_reg <= cyr;
        'o21: data_out_reg <= sr;
        'o22: data_out_reg <= cyl;
        'o23: data_out_reg <= edop;
        'o24: data_out_reg <= time2;
        'o25: data_out_reg <= time1;
        'o26: data_out_reg <= time3;
        'o27: data_out_reg <= time4;
        'o30: data_out_reg <= time5;
        'o31: data_out_reg <= time6;
      endcase

      if (use_erasable == 0)
        data_out_rom <= fixed_memory[ea];
      else
        data_out_ram <= erasable_memory[ea];
    end
  end

  //ioport_0 <= display_busy;
  //if (display_start && display_busy) display_start <= 0;
  if (spi_start && spi_busy) spi_start <= 0;

  if (reset) begin
    pyjets <= 0;
    rolljets <= 0;
    superbnk <= 0;
    enable_time6 <= 1;
  end else if (io_bus_enable) begin
    if (io_write_enable) begin
      case (io_address)
         1: reg_l     <= io_data_in;
         2: reg_q     <= io_data_in;
         3: hi_scaler <= io_data_in;
         4: lo_scaler <= io_data_in;
         5: pyjets    <= io_data_in;
         6: rolljets  <= io_data_in;
         7: superbnk  <= io_data_in;
        11: enable_time6 <= io_data_in[15];
        // Not in the real AGC.
        12: ioport_0 <= io_data_in[0];
        13: begin display_data <= io_data_in; display_start <= 1; end
        17: { ioport_3, ioport_2, ioport_1 } <= io_data_in;
        18: begin spi_tx_buffer <= io_data_in; spi_start <= 1; end
      endcase
    end else begin
      case (io_address)
         1: io_data_out <= reg_l;
         2: io_data_out <= reg_q;
         3: io_data_out <= hi_scaler;
         4: io_data_out <= lo_scaler;
         5: io_data_out <= pyjets;
         6: io_data_out <= rolljets;
         7: io_data_out <= superbnk;
        11: io_data_out <= { enable_time6, 15'b0 };
        // Not in the real AGC.
        14: io_data_out <= { display_busy };
        15: io_data_out <= interrupt_flags;
        16: io_data_out <= interrupt_clear;
        18: io_data_out <= spi_tx_buffer;
        19: io_data_out <= spi_rx_buffer;
        20: io_data_out <= { spi_start, ~spi_busy };
        21: io_data_out <= { joystick_4, joystick_3, joystick_2, joystick_1, joystick_0 };
      default: io_data_out <= 0;
      endcase
    end
  end else begin
    display_start <= 0;
  end
end

always @(posedge clk) begin
  // clk should be 6MHz.
  // 6,000,000 * 0.010  = 60,000 cycles (10ms)
  // 6,000,000 * 0.0075 = 45,000 cycles (7.5ms)
  // 6,000,000 * 0.005  = 30,000 cycles (5ms)
  // 6,000,000 * (1 / 6000)  = 1000 cycles (updated every 1 / 6000 seconds)
  if (reset == 1) begin
    time1 <= 0;
    time2 <= 0;
    time3 <= 0;
    time4 <= 0; // time4 is 7.5ms out of phase (forward?) with time3.
    time5 <= 0; // time5 is 5ms out of phase (forward?) with time1.
    time6 <= 0;
    clock_div_3 <= 0;
    clock_div_4 <= 45000;
    clock_div_5 <= 30000;
    clock_div_6000 <= 0;
    interrupt_flags <= 0;
  end else begin
    if (interrupt_clear[0]) interrupt_flags[0] <= 0;
    if (interrupt_clear[1]) interrupt_flags[1] <= 0;
    if (interrupt_clear[2]) interrupt_flags[2] <= 0;
    if (interrupt_clear[3]) interrupt_flags[3] <= 0;
    if (interrupt_clear[4]) interrupt_flags[4] <= 0;
    if (interrupt_clear[5]) interrupt_flags[5] <= 0;

    if (clock_div_3 == 59999) begin
      clock_div_3 <= 0;
      if (time1 == 15'h7fff) time2 <= time2 + 1;
      time1 <= time1 + 1;
      time3 <= time3 + 1;

      // T3RUPT.
      if (interrupt_enable && time3 == 15'h7fff) interrupt_flags[0] <= 1;

    end else begin
      clock_div_3 <= clock_div_3 + 1;
    end

    if (clock_div_4 == 59999) begin
      clock_div_4 <= 0;
      time4 <= time4 + 1;

      // T4RUPT.
      if (interrupt_enable && time4 == 15'h7fff) interrupt_flags[1] <= 1;
    end else begin
      clock_div_4 <= clock_div_4 + 1;
    end

    if (clock_div_5 == 59999) begin
      clock_div_5 <= 0;
      time5 <= time5 + 1;

      // T5RUPT.
      if (interrupt_enable && time5 == 15'h7fff) interrupt_flags[2] <= 1;

    end else begin
      clock_div_5 <= clock_div_5 + 1;
    end

    if (clock_div_6000 == 999) begin
      clock_div_6000 <= 0;
      if (enable_time6) time6 <= time6 + 1;

      // T6RUPT.
      if (interrupt_enable && time6 == 15'h7fff) interrupt_flags[3] <= 1;
    end else begin
      clock_div_6000 <= clock_div_6000 + 1;
    end
  end
end

display_spi display_spi_0
(
  .raw_clk (raw_clk),
  .start   (display_start),
  .data_tx (display_data),
  .busy    (display_busy),
  .cs      (display_cs),
  .sclk    (display_clk),
  .mosi    (display_do)
);

spi spi_0
(
  .raw_clk  (raw_clk),
  .start    (spi_start),
  .data_tx  (spi_tx_buffer),
  .data_rx  (spi_rx_buffer),
  .busy     (spi_busy),
  .sclk     (spi_clk_0),
  .mosi     (spi_mosi_0),
  .miso     (spi_miso_0)
);

endmodule

