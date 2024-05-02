





`timescale 1ns/100ps

`include "parameters.vh"

module tb_APB;

  //  Global signals
  logic           PCLK      ;
  logic           PRESETn     ;

  //  MASTER SIDE
  logic [`ADDR_WIDTH-1:0] ADDR_mst_i    ;
  logic           RW_mst_i    ;
  logic           TRANSFER_mst_i  ;
  logic [`DATA_WIDTH-1:0] WDATA_mst_i   ;
  logic           TOUT_mst_i    ;

  logic [`ERR_WIDTH-1:0]  FAIL_mst_o    ;
  logic           DONE_mst_o    ;
  logic [`DATA_WIDTH-1:-0]  RDATA_mst_o   ;

  logic [`ADDR_WIDTH-1:0] PADDR_mst_o   ;
  logic           PWRITE_mst_o  ;
  logic           PSEL_mst_o    ;
  logic           PENABLE_mst_o ;
  logic [`DATA_WIDTH-1:0] PWDATA_mst_o  ;

  logic           PREADY_mst_i  ;
  logic           PSLVERR_mst_i ;
  logic [`DATA_WIDTH-1:0] PRDATA_mst_i  ;

  //  SLAVE SIDE
  logic [`ADDR_WIDTH-1:0] PADDR_m_s   ;
  logic           PWRITE_m_s    ;
  logic           PSEL_m_s    ;
  logic           PENABLE_m_s   ;
  logic [`DATA_WIDTH-1:0] PWDATA_m_s    ;

  logic           PREADY_s_m    ;
  logic           PSLVERR_s_m   ;
  logic [`DATA_WIDTH-1:0] PRDATA_s_m    ;

  logic [`ADDR_WIDTH-1:0] ADDR_p_e    ;
  logic           WRITE_p_e   ;
  logic [`DATA_WIDTH-1:0] WDATA_p_e   ;
  logic           REQ_p_e     ;

  logic           GRANT_e_p   ;
  logic [`DATA_WIDTH-1:0] RDATA_e_p   ;

  logic [`ADDR_WIDTH-1:0] MaxAddr     ;

  //  Instance
  apb_master mAPB_0(
    .PCLK     (PCLK     ),
    .PRESETn    (PRESETn    ),

    .ADDR_mst_i   (ADDR_mst_i   ),
    .RW_mst_i   (RW_mst_i   ),
    .TRANSFER_mst_i (TRANSFER_mst_i ),
    .WDATA_mst_i  (WDATA_mst_i  ),
    .TOUT_mst_i   (TOUT_mst_i   ),

    .FAIL_mst_o   (FAIL_mst_o   ),
    .DONE_mst_o   (DONE_mst_o   ),
    .RDATA_mst_o  (RDATA_mst_o  ),

    .PADDR_mst_o  (PADDR_mst_o  ),
    .PWRITE_mst_o (PWRITE_mst_o ),
    .PSEL_mst_o   (PSEL_mst_o   ),
    .PENABLE_mst_o  (PENABLE_mst_o  ),
    .PWDATA_mst_o (PWDATA_mst_o ),

    .PREADY_mst_i (PREADY_mst_i ),
    .PSLVERR_mst_i  (PSLVERR_mst_i  ),
    .PRDATA_mst_i (PRDATA_mst_i )
  );

  APB_slave sAPB_0(
    .PCLK     (PCLK     ),
    .PRESETn    (PRESETn    ),

    .PADDR_m_s    (PADDR_m_s    ),
    .PWRITE_m_s   (PWRITE_m_s   ),
    .PSEL_m_s   (PSEL_m_s   ),
    .PENABLE_m_s  (PENABLE_m_s  ),
    .PWDATA_m_s   (PWDATA_m_s   ),

    .PREADY_s_m   (PREADY_s_m   ),
    .PSLVERR_s_m  (PSLVERR_s_m  ),
    .PRDATA_s_m   (PRDATA_s_m   ),

    .ADDR_p_e   (ADDR_p_e   ),
    .WRITE_p_e    (WRITE_p_e    ),
    .WDATA_p_e    (WDATA_p_e    ),
    .REQ_p_e    (REQ_p_e    ),

    .GRANT_e_p    (GRANT_e_p    ),
    .RDATA_e_p    (RDATA_e_p    ),

    .MaxAddr    (MaxAddr    )
  );

  //  Wiring
  assign  PADDR_m_s   = PADDR_mst_o   ;
  assign  PWRITE_m_s    = PWRITE_mst_o  ;
  assign  PSEL_m_s    = PSEL_mst_o    ;
  assign  PENABLE_m_s   = PENABLE_mst_o ;
  assign  PWDATA_m_s    = PWDATA_mst_o  ;

  assign  PREADY_mst_i  = PREADY_s_m    ;
  assign  PSLVERR_mst_i = PSLVERR_s_m   ;
  assign  PRDATA_mst_i  = PRDATA_s_m    ;

  //  Testbench
  initial
  begin
    PCLK  = 1'b1;
    forever #5 PCLK = ~PCLK;
  end

  //  Load test cases

  `include "./test_cases/PTP_0a.v"

  //`include "./test_cases/PTP_1a.v"
  //`include "./test_cases/PTP_2a.v"
  //`include "./test_cases/PTP_3a.v"
  `include "./test_cases/PTP_4a.v"

  initial
  begin
    #500;
    $finish();
  end

  initial
  begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars;
  end


endmodule