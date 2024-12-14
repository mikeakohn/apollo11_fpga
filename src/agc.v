// Apollo Guidance Computer FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2024 by Michael Kohn

module agc
(
  output [7:0] leds,
  output [3:0] column,
  input raw_clk,
  //output speaker_p,
  //output speaker_m,
  output ioport_0,
  output ioport_1,
  output ioport_2,
  output ioport_3,
  input  joystick_0,
  input  joystick_1,
  input  joystick_2,
  input  joystick_3,
  input  joystick_4,
  input  button_reset,
  input  button_halt,
  input  button_program_select,
  input  button_0,
  output display_cs,
  output display_clk,
  output display_do,
  output spi_clk_0,
  output spi_mosi_0,
  input  spi_miso_0
);

// iceFUN 8x4 LEDs used for debugging.
reg [7:0] leds_value;
reg [3:0] column_value;

assign leds = leds_value;
assign column = column_value;

// Memory bus (ROM, RAM, peripherals).
reg [11:0] mem_address;
reg [15:0] mem_write;
wire [15:0] mem_read;
//wire mem_data_ready;
reg mem_bus_enable;
reg mem_write_enable;
reg mem_reset;

// I/O bus.
reg [8:0] io_address;
reg [15:0] io_write;
wire [15:0] io_read;
reg io_bus_enable;
reg io_write_enable;

// Clock.
reg [21:0] count = 0;
reg [5:0]  state = 0;
reg [5:0]  next_state = 0;
reg [4:0]  clock_div;
reg [14:0] delay_loop;
wire clk;
assign clk = clock_div[0];

// Registers.
// accum is K which is 16 bit where bit 15 is a duplicate of 15 and used
// to detect overflow.
// PC is Z (12 bit).
wire [15:0] reg_a;
wire [14:0] reg_l;
wire [15:0] reg_q;
wire [11:0] reg_z;
wire [15:0] zrupt;
wire [15:0] brupt;

wire [28:0] reg_al;
wire [28:0] temp_d;
assign reg_al = { reg_a[14:0], reg_l[13:0] };
assign temp_d = { mem_read[14:0], temp[13:0] };
reg [29:0] temp_das;

reg interrupt_enable;
reg in_interrupt;
wire [5:0]  interrupt_flags;
reg  [5:0]  interrupt_clear;
reg  [2:0]  interrupt_index;
reg  [11:0] interrupt_addr;

parameter ADDR_A     =  0;
parameter ADDR_L     =  1;
parameter ADDR_Q     =  2;
parameter ADDR_Z     =  5;
parameter ADDR_ZRUPT = 13;
parameter ADDR_BRUPT = 15;

// Instruction
reg [15:0] instruction;
reg extra_code;
wire [2:0] opcode;
wire [2:0] opcode_pc;
wire [1:0] qc;
wire [11:0] k;
reg use_k10;

assign opcode    = instruction[14:12];
assign opcode_pc = instruction[11:9];
assign qc        = instruction[11:10];
assign k         = instruction[11:0];

reg [11:0] wb_address;
reg [15:0] temp;
reg [15:0] temp_xch;
reg [11:0] addr_xch;
reg [27:0] dividend;
reg quotient_sign;
//reg [27:0] result_double;
reg [15:0] temp_2;
reg [2:0] alu_op;
reg do_complement_read;

wire [14:0] abs_temp_minus_one;
assign abs_temp_minus_one = ~temp - 1;

reg [13:0] mul_a;
reg [13:0] mul_b;
reg [27:0] mul_c;

reg skip;
reg index_enable;
reg [11:0] index_k;
reg index_carry;
reg exch_count;

parameter ALU_OP_ADD  = 0;
parameter ALU_OP_SUB  = 1;
parameter ALU_OP_INCR = 2;
parameter ALU_OP_COM  = 3;
parameter ALU_OP_AND  = 4;
parameter ALU_OP_AUG  = 5;
parameter ALU_OP_DIM  = 7;

parameter STATE_RESET            =  0;
parameter STATE_DELAY_LOOP       =  1;
parameter STATE_FETCH_OP_0       =  2;
parameter STATE_FETCH_OP_1       =  3;
parameter STATE_FETCH_UPDATE_Z_0 =  4;
parameter STATE_FETCH_UPDATE_Z_1 =  5;
parameter STATE_START_DECODE     =  6;
parameter STATE_START_EXTRA      =  7;
parameter STATE_READ_EA_0        =  8;
parameter STATE_READ_EA_1        =  9;

parameter STATE_EXECUTE_TC_0     = 10;
parameter STATE_EXECUTE_TC_1     = 11;
parameter STATE_EXECUTE_ALU      = 12;
parameter STATE_EXECUTE_ALU_1    = 13;
parameter STATE_EXECUTE_ALU_2    = 14;
parameter STATE_EXECUTE_ALU_2S   = 15;
parameter STATE_EXECUTE_CCS_0    = 16;
parameter STATE_EXECUTE_CCS_1    = 17;

parameter STATE_EXECUTE_DAS_0    = 18;
parameter STATE_EXECUTE_DAS_1    = 19;
parameter STATE_EXECUTE_DAS_2    = 20;
parameter STATE_EXECUTE_DAS_3    = 21;
parameter STATE_EXECUTE_DAS_4    = 22;

parameter STATE_EXECUTE_XCH_0    = 23;
parameter STATE_EXECUTE_XCH_1    = 24;
parameter STATE_EXECUTE_XCH_2    = 25;
parameter STATE_EXECUTE_XCH_3    = 26;

parameter STATE_EXECUTE_DALU_0   = 27;
parameter STATE_EXECUTE_DALU_1   = 28;
parameter STATE_EXECUTE_DALU_2   = 29;
parameter STATE_EXECUTE_DALU_3   = 30;

parameter STATE_EXECUTE_RESUME_0 = 31;
parameter STATE_EXECUTE_RESUME_1 = 32;

parameter STATE_READ_IO_0        = 33;
parameter STATE_READ_IO_1        = 34;

parameter STATE_MULTIPLY_0       = 35;
parameter STATE_MULTIPLY_1       = 36;
parameter STATE_MULTIPLY_2       = 37;
parameter STATE_MULTIPLY_3       = 38;
parameter STATE_MULTIPLY_4       = 39;
parameter STATE_MULTIPLY_5       = 40;

parameter STATE_DIVIDE_0         = 41;
parameter STATE_DIVIDE_1         = 42;
parameter STATE_DIVIDE_2         = 43;

parameter STATE_TCAA_0           = 44;
parameter STATE_TCAA_1           = 45;

parameter STATE_SET_INDEX        = 46;

parameter STATE_INTERRUPT_0      = 47;
parameter STATE_INTERRUPT_1      = 48;
parameter STATE_INTERRUPT_2      = 49;
parameter STATE_INTERRUPT_3      = 50;
parameter STATE_INTERRUPT_4      = 51;
parameter STATE_INTERRUPT_5      = 52;

parameter STATE_WRITEBACK_0      = 57;
parameter STATE_WRITEBACK_1      = 58;
parameter STATE_WRITE_IO_0       = 59;
parameter STATE_WRITE_IO_1       = 60;

parameter STATE_DEBUG            = 61;
parameter STATE_ERROR            = 62;
parameter STATE_HALTED           = 63;

// This block is simply a clock divider for the raw_clk.
always @(posedge raw_clk) begin
  count <= count + 1;
  clock_div <= clock_div + 1;
end

// Debug: This block simply drives the 8x4 LEDs.
always @(posedge raw_clk) begin
  case (count[9:7])
    3'b000: begin column_value <= 4'b0111; leds_value <= ~reg_a[7:0]; end
    3'b010: begin column_value <= 4'b1011; leds_value <= ~reg_a[15:8]; end
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~instruction[7:0]; end
    //3'b010: begin column_value <= 4'b1011; leds_value <= ~instruction[15:8]; end
    //3'b010: begin column_value <= 4'b1011; leds_value <= ~{ extra_code, skip }; end
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~temp[7:0]; end
    //3'b010: begin column_value <= 4'b1011; leds_value <= ~temp[15:8]; end
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~instruction[7:0]; end
    //3'b010: begin column_value <= 4'b1011; leds_value <= ~instruction[15:8]; end
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~reg_z[7:0]; end
    //3'b010: begin column_value <= 4'b1011; leds_value <= ~reg_z[11:8]; end
    3'b100: begin column_value <= 4'b1101; leds_value <= ~reg_z[7:0]; end
    3'b110: begin column_value <= 4'b1110; leds_value <= ~state; end
    default: begin column_value <= 4'b1111; leds_value <= 8'hff; end
  endcase
end

// This block is the main CPU instruction execute state machine.
always @(posedge clk) begin
  if (!button_reset)
    state <= STATE_RESET;
  else if (!button_halt)
    state <= STATE_HALTED;
  else
    case (state)
      STATE_RESET:
        begin
          mem_bus_enable   <= 0;
          mem_write_enable <= 0;
          io_bus_enable    <= 0;
          io_write_enable  <= 0;
          //mem_address <= 0;
          //mem_write <= 0;
          extra_code <= 0;
          delay_loop <= 12000;
          interrupt_clear <= 0;
          interrupt_index <= 0;
          skip <= 0;
          state <= STATE_DELAY_LOOP;
          // FIXME: Does this default to 0?
          interrupt_enable <= 0;
          in_interrupt     <= 0;
        end
      STATE_DELAY_LOOP:
        begin
          // This is probably not needed. The chip starts up fine without it.
          if (delay_loop == 0) begin
            mem_reset <= 0;
            state <= STATE_FETCH_OP_0;
          end else begin
            mem_reset <= 1;
            delay_loop <= delay_loop - 1;
          end
        end
      STATE_FETCH_OP_0:
        begin
          mem_bus_enable   <= 1;
          mem_write_enable <= 0;
          mem_address      <= reg_z;
          state <= STATE_FETCH_OP_1;
        end
      STATE_FETCH_OP_1:
        begin
          mem_bus_enable <= 0;
          instruction <= mem_read;

          // Can't interrupt in the middle of an extra code or a skip or
          // if index is updating the next instruction.
          if (interrupt_flags != 0 &&
              in_interrupt == 0 &&
              skip == 0 &&
              extra_code == 0 &&
              index_enable == 0)
            state <= STATE_INTERRUPT_0;
          else
            state <= STATE_FETCH_UPDATE_Z_0;
        end
      STATE_FETCH_UPDATE_Z_0:
        begin
          mem_bus_enable   <= 1;
          mem_write_enable <= 1;
          mem_write        <= reg_z + 1;
          mem_address      <= ADDR_Z;

          exch_count <= 0;
          do_complement_read <= 0;
          use_k10 <= 0;

          state <= STATE_FETCH_UPDATE_Z_1;
        end
      STATE_FETCH_UPDATE_Z_1:
        begin
          mem_bus_enable   <= 0;
          mem_write_enable <= 0;

          if (index_enable == 1 && instruction != 6) begin
            { index_carry, instruction[11:0] } <= instruction[11:0] + index_k;
            index_enable <= 0;
            state <= STATE_FETCH_UPDATE_Z_1;
          end else begin
            if (index_carry) begin
              instruction[11:0] <= instruction[11:0] + 1;
              index_carry <= 0;
            end

            if (extra_code == 1) begin
              if (skip == 1) begin
                skip <= 0;
                extra_code <= 0;
                state <= STATE_FETCH_OP_0;
              end else begin
                state <= STATE_START_EXTRA;
              end
            end else begin
              if (skip == 1 && instruction != 6) begin
                // FIXME: Could be a better way to do this. If this is a skip
                // but the instruction is an extra code, need to read in the
                // next word so it can be skipped also.
                skip <= 0;
                state <= STATE_FETCH_OP_0;
              end else begin
                state <= STATE_START_DECODE;
              end
            end
          end
        end
      STATE_START_DECODE:
        begin
          case (opcode)
            3'b000:
              if (k == 3) begin
                // relint.
                interrupt_enable <= 1;
                state <= STATE_FETCH_OP_0;
              end else if (k == 4) begin
                // inhint.
                interrupt_enable <= 0;
                state <= STATE_FETCH_OP_0;
              end else if (k == 6) begin
                // extend.
                extra_code <= 1;
                state <= STATE_FETCH_OP_0;
              end else begin
                // tc k.
                // tc a (xxalq).
                // tc l (xlq).
                // tc q (return).
                case (k)
                  ADDR_A:  temp <= reg_a;
                  ADDR_L:  temp <= reg_l;
                  ADDR_Q:  temp <= reg_q;
                  default: temp <= k;
                endcase

                state <= STATE_EXECUTE_TC_0;
              end
            3'b001:
              begin
                if (qc == 0) begin
                  // ccs (k is erasable memory)
                  use_k10 <= 1;
                  next_state <= STATE_EXECUTE_CCS_0;
                  state <= STATE_READ_EA_0;
                end else begin
                  // tcf (k is fixed memory)
                  temp <= k;
                  wb_address = ADDR_Z;
                  state <= STATE_WRITEBACK_0;
                end
              end
            3'b010:
              begin
                // das
                // lxch
                // incr
                // ads
                case (qc)
                  //0: alu_op <= ALU_OP_DAS;
                  //1: alu_op <= ALU_OP_LXCH;
                  2: alu_op <= ALU_OP_INCR;
                  3: alu_op <= ALU_OP_ADD;
                endcase

                wb_address = k[9:0];
                use_k10 <= 1;

                if      (qc == 0) next_state <= STATE_EXECUTE_DAS_0;
                else if (qc == 1) next_state <= STATE_EXECUTE_XCH_0;
                else              next_state <= STATE_EXECUTE_ALU;

                temp_xch <= reg_l;
                addr_xch <= ADDR_L;

                state <= STATE_READ_EA_0;
              end
            3'b011:
              begin
                // ca
                wb_address = ADDR_A;
                next_state <= STATE_WRITEBACK_0;
                state <= STATE_READ_EA_0;
              end
            3'b100:
              begin
                // cs, com
                alu_op <= ALU_OP_COM;
                next_state <= STATE_EXECUTE_ALU;
                state <= STATE_READ_EA_0;
              end
            3'b101:
              begin
                case (qc)
                  2'b00:
                    // index
                    // resume
                    if (k == 'o17) begin
                      state <= STATE_EXECUTE_RESUME_0;
                    end else begin
                      use_k10 <= 1;
                      next_state <= STATE_SET_INDEX;
                      state <= STATE_READ_EA_0;
                    end
                  2'b01:
                    begin
                      // dxch
                      exch_count <= 1;
                      temp_xch   <= reg_l;
                      addr_xch   <= ADDR_L;
                      use_k10    <= 1;
                      next_state <= STATE_EXECUTE_XCH_0;
                      state <= STATE_READ_EA_0;
                    end
                  2'b10:
                    if (k[9:0] == 0) begin
                      // ovsk
                      if (reg_a[15] == 1) skip <= 1;
                      state <= STATE_FETCH_OP_0;
                    end else begin
                      // ts, tcaa
                      temp <= reg_a;
                      wb_address <= k[9:0];

                      if (k[9:0] == 5 && reg_a[15] == 1)
                        state <= STATE_TCAA_0;
                      else
                        state <= STATE_WRITEBACK_0;
                    end
                  2'b11:
                    begin
                      // xch
                      temp_xch   <= reg_a;
                      addr_xch   <= ADDR_A;
                      use_k10    <= 1;
                      next_state <= STATE_EXECUTE_XCH_0;
                      state <= STATE_READ_EA_0;
                    end
                endcase
              end
            3'b110:
              begin
                // ad
                alu_op <= ALU_OP_ADD;
                wb_address <= ADDR_A;
                next_state <= STATE_EXECUTE_ALU;
                state <= STATE_READ_EA_0;
              end
            3'b111:
              begin
                // mask
                alu_op <= ALU_OP_AND;
                wb_address <= ADDR_A;
                next_state <= STATE_EXECUTE_ALU;
                state <= STATE_READ_EA_0;
              end
          endcase
        end
      STATE_START_EXTRA:
        begin
          case (opcode)
            3'b000:
              begin
                if (opcode_pc == 3'b111) begin
                  // edrupt - not sure about this, use as HALT for now.
                  state <= STATE_HALTED;
                end else begin
                  // read
                  // write
                  // rand
                  // wand
                  // ror
                  // wor
                  // rxor
                  state <= STATE_READ_IO_0;
                end
              end
            3'b001:
              begin
                if (qc != 0) begin
                  // bzf
                  if (reg_a[13:0] == 0 || reg_a[14:0] == 15'h7fff) begin
                    temp <= k;
                    wb_address <= ADDR_Z;
                    state <= STATE_WRITEBACK_0;
                  end else begin
                    state <= STATE_FETCH_OP_0;
                  end
                end else begin
                  // dv
                  dividend <= { reg_a[13:0], reg_l[13:0] };
                  temp_2 <= 0;
                  next_state <= STATE_DIVIDE_0;
                  state <= STATE_READ_EA_0;
                end
              end
            3'b010:
              begin
                case (qc)
                  0:
                    begin
                      // msu
                      alu_op <= ALU_OP_SUB;
                      wb_address <= ADDR_A;
                      next_state <= STATE_EXECUTE_ALU_2S;
                      state <= STATE_READ_EA_0;
                    end
                  1:
                    begin
                      // qxch
                      temp_xch   <= reg_q;
                      addr_xch   <= ADDR_Q;
                      use_k10    <= 1;
                      next_state <= STATE_EXECUTE_XCH_0;
                      state <= STATE_READ_EA_0;
                    end
                  2:
                    begin
                      // aug
                      alu_op <= ALU_OP_AUG;
                      wb_address <= k[9:0];
                      next_state <= STATE_EXECUTE_ALU;
                      state <= STATE_READ_EA_0;
                    end
                  3:
                    begin
                      // dim
                      alu_op <= ALU_OP_DIM;
                      wb_address <= k[9:0];
                      next_state <= STATE_EXECUTE_ALU;
                      state <= STATE_READ_EA_0;
                    end
                endcase

                use_k10 <= 1;
              end
            3'b011:
              begin
                // dca
                next_state <= STATE_EXECUTE_DALU_0;
                state <= STATE_READ_EA_0;
              end
            3'b100:
              begin
                // dcs
                next_state <= STATE_EXECUTE_DALU_0;
                state <= STATE_READ_EA_0;
              end
            3'b101:
              begin
                // index
                next_state <= STATE_SET_INDEX;
                state <= STATE_READ_EA_0;
              end
            3'b110:
              begin
                if (qc != 0) begin
                  // bzmf
                  if (reg_a[13:0] == 0 || reg_a[14] == 1) begin
                    temp       <= k;
                    wb_address <= ADDR_Z;
                    state <= STATE_WRITEBACK_0;
                  end else begin
                    state <= STATE_FETCH_OP_0;
                  end
                end else begin
                  // su
                  alu_op <= ALU_OP_ADD;
                  do_complement_read <= 1;
                  wb_address <= ADDR_A;
                  next_state <= STATE_EXECUTE_ALU;
                  state <= STATE_READ_EA_0;
                end
              end
            3'b111:
              begin
                // mp
                next_state <= STATE_MULTIPLY_0;
                state <= STATE_READ_EA_0;
              end
          endcase

          if (instruction != 15'b101_00_00_0000_0000) extra_code <= 0;
        end
      STATE_READ_EA_0:
        begin
          mem_bus_enable <= 1;
          if (use_k10)
            mem_address <= k[9:0];
          else
            mem_address <= k;
          state <= STATE_READ_EA_1;
        end
      STATE_READ_EA_1:
        begin
          mem_bus_enable <= 0;

          if (do_complement_read == 0)
            temp <= mem_read;
          else
            temp <= ~mem_read[14:0];

          state <= next_state;
        end
      STATE_EXECUTE_TC_0:
        begin
          mem_bus_enable <= 1;
          mem_write_enable <= 1;
          mem_address <= ADDR_Q;
          mem_write <= reg_z;
          state <= STATE_EXECUTE_TC_1;
        end
      STATE_EXECUTE_TC_1:
        begin
          mem_bus_enable <= 0;
          mem_write_enable <= 0;
          wb_address <= ADDR_Z;
          //temp <= reg_z;
          state <= STATE_WRITEBACK_0;
        end
      STATE_EXECUTE_ALU:
        begin
          case (alu_op)
            ALU_OP_ADD:  temp_2 <= reg_a[14:0] + temp[14:0];
            ALU_OP_INCR: temp <= temp + 1;
            ALU_OP_COM:  temp <= { 1'b0, ~temp[14:0] };
            ALU_OP_AND:  temp <= temp & reg_a[14:0];
            ALU_OP_AUG:  temp[13:0] <= temp[13:0] + 1;
            ALU_OP_DIM:  if (temp[13:0] != 0) temp[13:0] <= temp[13:0] - 1;
          endcase

          if (alu_op == ALU_OP_ADD)
            state <= STATE_EXECUTE_ALU_1;
          else
            state <= STATE_WRITEBACK_0;
        end
      STATE_EXECUTE_ALU_1:
        begin
          // This 1's complement could be wired and not take extra cycles.
          temp_2 <= temp_2[14:0] + temp_2[15];
          state <= STATE_EXECUTE_ALU_2;
        end
      STATE_EXECUTE_ALU_2:
        begin
          temp[14:0] <= temp_2[14:0];
          temp[15] <= (temp[14] == reg_a[14] && temp[14] != temp_2[14]);
          state <= STATE_WRITEBACK_0;
        end
      STATE_EXECUTE_ALU_2S:
        begin
          // 2's complement.
          case (alu_op)
            ALU_OP_SUB:  temp <= reg_a - temp;
          endcase

          state <= STATE_WRITEBACK_0;
        end
      STATE_EXECUTE_CCS_0:
        begin
          mem_bus_enable   <= 1;
          mem_write_enable <= 1;
          mem_address      <= ADDR_A;

          wb_address <= ADDR_Z;

          if (temp[14] == 0) begin
            if (temp[13:0] == 0) begin
              // [K] == +0
              temp      <= reg_z + 1;
              mem_write <= 15'b111_1111_1111_1111;
            end else begin
              // [K] > +0
              temp      <= reg_z;
              mem_write <= temp - 1;
            end
          end else begin
            if (temp[13:0] == 14'h3fff) begin
              // [K] == -0
              temp      <= reg_z + 3;
              mem_write <= 15'b000_0000_0000_0000;
            end else begin
              // [K] < -0
              temp      <= reg_z + 2;
              mem_write <= { 1'b0, abs_temp_minus_one };
            end
          end

          state <= STATE_EXECUTE_CCS_1;
        end
      STATE_EXECUTE_CCS_1:
        begin
          mem_bus_enable <= 0;
          mem_write_enable <= 0;
          state <= STATE_WRITEBACK_0;
        end
      STATE_EXECUTE_DAS_0:
        begin
          mem_bus_enable <= 1;
          mem_address    <= { k[11:1], 1'b0 };

          state <= STATE_EXECUTE_DAS_1;
        end
      STATE_EXECUTE_DAS_1:
        begin
          mem_bus_enable <= 0;

          temp_das <= reg_al + temp_d;
          temp_2[14:0] <= reg_l + temp;

          state <= STATE_EXECUTE_DAS_2;
        end
      STATE_EXECUTE_DAS_2:
        begin
          temp_das <= temp_das[28:0] + temp_das[29];
          temp_2[14:0] <= temp_2[13:0] + temp_2[14];

          state <= STATE_EXECUTE_DAS_3;
        end
      STATE_EXECUTE_DAS_3:
        begin
          mem_bus_enable   <= 1;
          mem_write_enable <= 1;
          mem_address      <= k;
          mem_write        <= { temp_2[14], temp_das[13:0] };

          temp_das[29] <= reg_al[28] == temp_d[28] && reg_al[28] != temp_das[28];

          state <= STATE_EXECUTE_DAS_4;
        end
      STATE_EXECUTE_DAS_4:
        begin
          mem_bus_enable   <= 0;
          mem_write_enable <= 0;

          wb_address <= { k[11:1], 1'b0 };
          temp <= temp_das[29:14];

          state <= STATE_WRITEBACK_0;
        end
      STATE_EXECUTE_XCH_0:
        begin
          mem_bus_enable   <= 1;
          mem_write_enable <= 1;
          mem_address      <= k[9:0];
          mem_write        <= temp_xch;

          state <= STATE_EXECUTE_XCH_1;
        end
      STATE_EXECUTE_XCH_1:
        begin
          mem_bus_enable   <= 0;
          mem_write_enable <= 0;
          state            <= STATE_EXECUTE_XCH_2;
        end
      STATE_EXECUTE_XCH_2:
        begin
          mem_bus_enable   <= 1;
          mem_write_enable <= 1;
          mem_address      <= addr_xch;
          mem_write        <= temp;

          state <= STATE_EXECUTE_XCH_3;
        end
      STATE_EXECUTE_XCH_3:
        begin
          mem_bus_enable <= 0;
          mem_write_enable <= 0;

          if (exch_count != 0) begin
            instruction[0] <= 0;
            temp_xch <= reg_a;
            addr_xch[0] = 0;
            state <= STATE_READ_EA_0;
            exch_count <= 0;
          end else begin
            state <= STATE_FETCH_OP_0;
          end
        end
      STATE_EXECUTE_DALU_0:
        begin
          mem_bus_enable   <= 1;
          mem_write_enable <= 1;
          mem_address      <= ADDR_L;

          if (opcode == 3'b011)
            mem_write <=  temp[14:0];
          else
            mem_write <= { 1'b0, ~temp[14:0] };

          state <= STATE_EXECUTE_DALU_1;
        end
      STATE_EXECUTE_DALU_1:
        begin
          mem_bus_enable   <= 0;
          mem_write_enable <= 0;

          state <= STATE_EXECUTE_DALU_2;
        end
      STATE_EXECUTE_DALU_2:
        begin
          mem_bus_enable <= 1;
          mem_address    <= { k[11:1], 1'b0 };

          state <= STATE_EXECUTE_DALU_3;
        end
      STATE_EXECUTE_DALU_3:
        begin
          mem_bus_enable <= 0;

          case (opcode)
            3'b011: temp <=  mem_read[14:0];
            3'b100: temp <= { 1'b0 , ~mem_read[14:0] };
          endcase

          wb_address       <= ADDR_A;

          state <= STATE_WRITEBACK_0;
        end
      STATE_EXECUTE_RESUME_0:
        begin
          mem_bus_enable   <= 1;
          mem_write_enable <= 1;
          mem_address      <= ADDR_Z;
          mem_write        <= zrupt;
          state <= STATE_EXECUTE_RESUME_1;
        end
      STATE_EXECUTE_RESUME_1:
        begin
          mem_bus_enable   <= 0;
          mem_write_enable <= 0;

          instruction  <= brupt;
          in_interrupt <= 0;
          state <= STATE_FETCH_UPDATE_Z_0;
//temp <= zrupt;
//temp <= brupt;
//temp <= 7;
//state <= STATE_DEBUG;
        end
      STATE_READ_IO_0:
        begin
          io_bus_enable <= 1;
          io_address <= k[8:0];
          state <= STATE_READ_IO_1;
        end
      STATE_READ_IO_1:
        begin
          io_bus_enable <= 0;

          case (opcode_pc[2:1])
            0: temp <= opcode_pc == 0 ? io_read : reg_a;
            1: temp <= reg_a & io_read;
            2: temp <= reg_a | io_read;
            3: temp <= reg_a ^ io_read;
          endcase

          if (opcode_pc[0] == 0) begin
            wb_address <= ADDR_A;
            state <= STATE_WRITEBACK_0;
          end else begin
            state <= STATE_WRITE_IO_0;
          end
        end
      STATE_MULTIPLY_0:
        begin
          if (reg_a[14] == 0)
            mul_a <=  reg_a[13:0];
          else
            mul_a <= ~reg_a[13:0];

          if (temp[14] == 0)
            mul_b <=  temp[13:0];
          else
            mul_b <= ~temp[13:0];

          state <= STATE_MULTIPLY_1;
        end
      STATE_MULTIPLY_1:
        begin
          mul_c = mul_a * mul_b;

          state <= STATE_MULTIPLY_2;
        end
      STATE_MULTIPLY_2:
        begin
          //result_double <= reg_a * temp;
          mem_bus_enable   <= 1;
          mem_write_enable <= 1;
          mem_address <= ADDR_L;

          if (reg_a[14] ^ temp[14] == 0)
            { temp_2[13:0], mem_write[13:0] } <= mul_c;
          else
            { temp_2[13:0], mem_write[13:0] } <= ~mul_c;

          mem_write[14] <= 0;
          mem_write[15] <= 0;
          temp_2[14] <= reg_a[14] ^ temp[14];
          temp_2[15] <= 0;

          state <= STATE_MULTIPLY_3;
        end
      STATE_MULTIPLY_3:
        begin
          mem_bus_enable   <= 0;
          mem_write_enable <= 0;
          state <= STATE_MULTIPLY_4;
        end
      STATE_MULTIPLY_4:
        begin
          mem_bus_enable   <= 1;
          mem_write_enable <= 1;
          mem_address      <= ADDR_A;
          mem_write        <= temp_2;

          state <= STATE_MULTIPLY_5;
        end
      STATE_MULTIPLY_5:
        begin
          mem_bus_enable   <= 0;
          mem_write_enable <= 0;
          state <= STATE_FETCH_OP_0;
        end
      STATE_DIVIDE_0:
        begin
          quotient_sign <= reg_a[14] ^ temp[14];

          if (dividend == 0) begin
            // Dividing anything by zero comes out 0.
            temp <= 0;
            wb_address <= ADDR_A;
            state <= STATE_WRITEBACK_0;
          end else if (temp == 0) begin
            // Divide by zero.
            temp <= 'o37777;
            wb_address <= ADDR_A;
            state <= STATE_WRITEBACK_0;
          end else begin
            if (reg_a[14] == 1)
              dividend[27:14] <= ~dividend[27:14];

            if (reg_l[14] == 1)
              dividend[13:0] <= ~dividend[13:0];

            if (temp[14] == 1)
              temp <= ~temp[13:0];

            state <= STATE_DIVIDE_1;
          end
        end
      STATE_DIVIDE_1:
        begin
          if (dividend < temp) begin
            if (quotient_sign == 1) temp_2 <= ~temp_2[14:0];

            // If dividend is finally less than temp, save remainder in Q
            // and quotient in A.
            mem_bus_enable   <= 1;
            mem_write_enable <= 1;
            mem_address      <= ADDR_Q;
            mem_write        <= dividend[27:14];
            state <= STATE_DIVIDE_2;
          end else begin
            // Keep subtracting temp from dividend and count.
            dividend <= dividend - temp[13:0];
            temp_2 <= temp_2 + 1;
            //state <= STATE_DIVIDE_1;
          end
        end
      STATE_DIVIDE_2:
        begin
          mem_bus_enable   <= 0;
          mem_write_enable <= 0;
          //temp <= dividend[13:0];
          temp <= { quotient_sign, temp_2[13:0] };
          wb_address <= ADDR_A;
          state <= STATE_WRITEBACK_0;
        end
      STATE_TCAA_0:
        begin
          mem_bus_enable   <= 1;
          mem_write_enable <= 1;
          mem_address      <= ADDR_A;

          if (reg_a[14] == 0)
            mem_write <= { reg_a[15:14],  14'b0 };
          else
            mem_write <= { reg_a[15:14], ~14'd0 };

          state <= STATE_TCAA_1;
          //state <= STATE_ERROR;
        end
      STATE_TCAA_1:
        begin
          mem_bus_enable   <= 0;
          mem_write_enable <= 0;
          state <= STATE_WRITEBACK_0;
        end
      STATE_SET_INDEX:
        begin
          index_enable = 1;
          index_k <= temp;
          state <= STATE_FETCH_OP_0;
        end
      STATE_INTERRUPT_0:
        begin
          mem_bus_enable   <= 1;
          mem_write_enable <= 1;
          mem_write        <= reg_z;
          mem_address      <= ADDR_ZRUPT;

          in_interrupt <= 1;

          if (interrupt_flags[0] == 1)
            interrupt_index = 0;
          else if (interrupt_flags[1] == 1)
            interrupt_index = 1;
          else if (interrupt_flags[2] == 1)
            interrupt_index = 2;
          else if (interrupt_flags[3] == 1)
            interrupt_index = 3;
          else if (interrupt_flags[4] == 1)
            interrupt_index = 4;
          else if (interrupt_flags[5] == 1)
            interrupt_index = 5;

          state <= STATE_INTERRUPT_1;
        end
      STATE_INTERRUPT_1:
        begin
          interrupt_clear[interrupt_index] <= 1;

          mem_bus_enable <= 0;
          mem_write_enable <= 0;
          state <= STATE_INTERRUPT_2;
        end
      STATE_INTERRUPT_2:
        begin
          mem_bus_enable   <= 1;
          mem_write_enable <= 1;
          mem_write        <= instruction;
          mem_address      <= ADDR_BRUPT;
          state <= STATE_INTERRUPT_3;
        end
      STATE_INTERRUPT_3:
        begin
          mem_bus_enable <= 0;
          mem_write_enable <= 0;

          // FIXME: interrupt_addr could be a wire.
          case (interrupt_index)
            0: interrupt_addr <= 'o4014;
            1: interrupt_addr <= 'o4020;
            2: interrupt_addr <= 'o4010;
            3: interrupt_addr <= 'o4004;
            default: interrupt_addr <= 'o4000;
          endcase

          state <= STATE_INTERRUPT_4;
        end
      STATE_INTERRUPT_4:
        begin
          mem_bus_enable   <= 1;
          mem_write_enable <= 1;
          mem_write        <= interrupt_addr;
          mem_address      <= ADDR_Z;

          state <= STATE_INTERRUPT_5;
        end
      STATE_INTERRUPT_5:
        begin
          mem_bus_enable   <= 0;
          mem_write_enable <= 0;

          interrupt_clear <= 0;

          state <= STATE_FETCH_OP_0;
// DEBUG HERE
//state <= STATE_DEBUG;
//temp <= interrupt_addr;
//temp <= zrupt;
//temp <= brupt;
//state <= STATE_DEBUG;
        end
      STATE_WRITEBACK_0:
        begin
          mem_bus_enable <= 1;
          mem_write_enable <= 1;
          mem_address <= wb_address;

          // Remove overflow on everything but A or Q.
/*
          if (mem_address == ADDR_A || mem_address == ADDR_Q)
            mem_write <= temp;
          else
            mem_write <= { 1'b0, temp[14:0] };
*/
            mem_write <= temp;

          state <= STATE_WRITEBACK_1;
        end
      STATE_WRITEBACK_1:
        begin
          mem_bus_enable <= 0;
          mem_write_enable <= 0;
          state <= STATE_FETCH_OP_0;
        end
      STATE_WRITE_IO_0:
        begin
          io_bus_enable   <= 1;
          io_write_enable <= 1;
          io_write        <= temp;
          io_address      <= k[8:0];
          state <= STATE_WRITE_IO_1;
        end
      STATE_WRITE_IO_1:
        begin
          io_bus_enable   <= 0;
          io_write_enable <= 0;
          state <= STATE_FETCH_OP_0;
        end
      STATE_DEBUG:
        begin
          state <= STATE_DEBUG;
        end
      STATE_ERROR:
        begin
          state <= STATE_ERROR;
        end
      STATE_HALTED:
        begin
          state <= STATE_HALTED;
        end
    endcase
end

memory memory_0(
  .address          (mem_address),
  .data_in          (mem_write),
  .data_out         (mem_read),
  .bus_enable       (mem_bus_enable),
  .write_enable     (mem_write_enable),
  .clk              (clk),
  .raw_clk          (raw_clk),
  .io_address       (io_address),
  .io_data_in       (io_write),
  .io_data_out      (io_read),
  .io_bus_enable    (io_bus_enable),
  .io_write_enable  (io_write_enable),
  .interrupt_enable (interrupt_enable),
  .out_a            (reg_a),
  .out_l            (reg_l),
  .out_q            (reg_q),
  .out_z            (reg_z),
  .out_zrupt        (zrupt),
  .out_brupt        (brupt),
  .interrupt_flags  (interrupt_flags),
  .interrupt_clear  (interrupt_clear),
  .ioport_0         (ioport_0),
  .ioport_1         (ioport_1),
  .ioport_2         (ioport_2),
  .ioport_3         (ioport_3),
  .joystick_0       (joystick_0),
  .joystick_1       (joystick_1),
  .joystick_2       (joystick_2),
  .joystick_3       (joystick_3),
  .joystick_4       (joystick_4),
  .button_0         (button_0),
  .display_cs       (display_cs),
  .display_clk      (display_clk),
  .display_do       (display_do),
  .spi_clk_0        (spi_clk_0),
  .spi_mosi_0       (spi_mosi_0),
  .spi_miso_0       (spi_miso_0),
  .reset            (mem_reset)
);

endmodule

