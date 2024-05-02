`include "/home/ftv_training/SFD/4_Intern/2024_Mar/tuan_huynh/verilog_introduction/verilog/parameters.vh"
module apb_master #(parameter DATA_WIDTH = `DATA_WIDTH, parameter ADDR_WIDTH = `ADDR_WIDTH, parameter ERR_WIDTH = `ERR_WIDTH) (
  // Global and control signals
  input PCLK, PRESETn,
  // TAP - APB interfaces
  input TRANSFER_mst_i, RW_mst_i,
  input [ADDR_WIDTH - 1 : 0] ADDR_mst_i,
  input [DATA_WIDTH - 1 : 0] WDATA_mst_i,
  output reg [ERR_WIDTH - 1 : 0] FAIL_mst_o,
  output reg DONE_mst_o,
  output reg [DATA_WIDTH - 1 : 0] RDATA_mst_o,
  // APB master - APB slave interfaces
  output reg PWRITE_mst_o, PSEL_mst_o, PENABLE_mst_o,
  output reg [ADDR_WIDTH - 1 : 0] PADDR_mst_o,
  output reg [DATA_WIDTH - 1 : 0] PWDATA_mst_o,
  input [DATA_WIDTH - 1 : 0] PRDATA_mst_i,
  input PREADY_mst_i, PSLVERR_mst_i,
  // APB master - Timeout checker
  input TOUT_mst_i
);

  localparam IDLE = 0;
  localparam SETUP = 1;
  localparam ACCESS = 2;
  localparam DONE = 3;

  reg [1:0] state; // a flip-flop for storing the current state of FSM
  reg [1:0] nstate; // a wire containing next state of FSM, so that no need to reset ("reg" used in combinational logic will be synthesized to "wire")

  // Pipelined variables for the outputs
  // These variables are synthesized to wires (used in combinational logic)
  reg [ERR_WIDTH - 1 : 0] FAIL_mst_o_p;
  reg DONE_mst_o_p;
  reg [DATA_WIDTH - 1 : 0] RDATA_mst_o_p;
  reg PWRITE_mst_o_p, PSEL_mst_o_p, PENABLE_mst_o_p;
  reg [ADDR_WIDTH - 1 : 0] PADDR_mst_o_p;
  reg [DATA_WIDTH - 1 : 0] PWDATA_mst_o_p;

  // Reset logic - Sequential logic
  always@(posedge PCLK or negedge PRESETn)
    begin
      if(PRESETn == 0) // negative reset
        begin
          // All the outputs become 0
          PWRITE_mst_o <= 0;
          PSEL_mst_o <= 0;
          PENABLE_mst_o <= 0;
          PADDR_mst_o <= {ADDR_WIDTH{1'b0}};
          PWDATA_mst_o <= {DATA_WIDTH{1'b0}};
          RDATA_mst_o <= {DATA_WIDTH{1'b0}};
          DONE_mst_o <= 0;
          FAIL_mst_o <= 2'b00;
          state <= IDLE;
        end
      else
        begin
          PWRITE_mst_o <= PWRITE_mst_o_p;
          PSEL_mst_o <= PSEL_mst_o_p;
          PENABLE_mst_o <= PENABLE_mst_o_p;
          PADDR_mst_o <= PADDR_mst_o_p;
          PWDATA_mst_o <= PWDATA_mst_o_p;
          RDATA_mst_o <= RDATA_mst_o_p;
          DONE_mst_o <= DONE_mst_o_p;
          FAIL_mst_o <= FAIL_mst_o_p;
          state <= nstate;
        end
    end

  // Next state logic - Combinational Logic
  always@(*)
    begin
      nstate = state;
      case(state)
        IDLE:
          begin
            if(TRANSFER_mst_i)
              begin
                nstate = SETUP;
              end
            else
              begin
                nstate = IDLE;
              end
          end
        SETUP:
          begin
            if(TOUT_mst_i)
              nstate = DONE;
            else
              nstate = ACCESS;
          end
        ACCESS:
          begin
            if(PREADY_mst_i || TOUT_mst_i || PSLVERR_mst_i)
              begin
                nstate = DONE;
              end
            else
              begin
                nstate = ACCESS;
              end
          end
        DONE:
          begin
            nstate = IDLE;
          end
        default: nstate = IDLE;
      endcase
    end

  // Output logic - Combinational Logic - Updating the pipelined variables
  always@(*)
    begin
      PSEL_mst_o_p = PSEL_mst_o;
      PENABLE_mst_o_p = PENABLE_mst_o;
      DONE_mst_o_p = DONE_mst_o;
      FAIL_mst_o_p = FAIL_mst_o;
      case(nstate)
        IDLE:
          begin
            PSEL_mst_o_p = 0;
            PENABLE_mst_o_p = 0;
            DONE_mst_o_p = 0;
            FAIL_mst_o_p = 2'b00;
          end
        SETUP:
          begin
            PSEL_mst_o_p = 1;
          end
        ACCESS:
          begin
            PENABLE_mst_o_p = 1;
          end
        DONE:
          begin
            PSEL_mst_o_p = 0;
            PENABLE_mst_o_p = 0;
            DONE_mst_o_p = 1;
            FAIL_mst_o_p = {TOUT_mst_i, PSLVERR_mst_i};
          end
        default:
          begin
            PSEL_mst_o_p = 0;
            PENABLE_mst_o_p = 0;
            DONE_mst_o_p = 0;
            FAIL_mst_o_p = 2'b00;
          end
      endcase
    end

  always@(*) begin
     PWRITE_mst_o_p = PWRITE_mst_o;
     PADDR_mst_o_p = PADDR_mst_o;
     PWDATA_mst_o_p = PWDATA_mst_o;
     RDATA_mst_o_p = RDATA_mst_o;
    if(TRANSFER_mst_i) begin
      PADDR_mst_o_p = ADDR_mst_i;
      if(!RW_mst_i) // read operation
        begin
          PWRITE_mst_o_p = 0;
        end
      else // write operation
        begin
          PWDATA_mst_o_p = WDATA_mst_i;
          PWRITE_mst_o_p = 1;
        end
    end
    if(PREADY_mst_i) begin
      RDATA_mst_o_p = PRDATA_mst_i;
    end
  end

endmodule
