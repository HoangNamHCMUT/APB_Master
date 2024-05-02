











`include "parameters.vh"

module APB_slave
  (
    //  Global signals
    input               PCLK    ,
    input               PRESETn   ,

    //  Master signals
    input     [`ADDR_WIDTH-1:0] PADDR_m_s ,
    input               PWRITE_m_s  ,
    input               PSEL_m_s  ,
    input               PENABLE_m_s ,
    input     [`DATA_WIDTH-1:0] PWDATA_m_s  ,

    //  Slave signals
    output  reg             PREADY_s_m  ,
    output  reg             PSLVERR_s_m ,
    output  reg   [`DATA_WIDTH-1:0] PRDATA_s_m  ,

    //  MEM interface
    output  reg   [`ADDR_WIDTH-1:0] ADDR_p_e  ,
    output  reg             WRITE_p_e ,
    output  reg   [`DATA_WIDTH-1:0] WDATA_p_e ,
    output  reg             REQ_p_e   ,

    input               GRANT_e_p ,
    input     [`DATA_WIDTH-1:0] RDATA_e_p ,

    //  Others
    input     [`ADDR_WIDTH-1:0] MaxAddr
  );

//  Pipeline variables

reg             PREADY_s_m_p  ;
reg             PSLVERR_s_m_p ;
reg   [`DATA_WIDTH-1:0] PRDATA_s_m_p  ;

reg   [`ADDR_WIDTH-1:0] ADDR_p_e_p    ;
reg             WRITE_p_e_p   ;
reg   [`DATA_WIDTH-1:0] WDATA_p_e_p   ;
reg             REQ_p_e_p   ;

//  Internal wire
wire            inRange     ;     //  Request addr in range or not
wire            AccOrDone   ;     //  stay in Access if 1, move to Done if 0

//  State variables
reg   [1:0]       cs, ns      ;

//  Assign
assign  inRange   = (PADDR_m_s <= MaxAddr);
assign  AccOrDone = (PSEL_m_s && PENABLE_m_s && (!GRANT_e_p) && inRange);

//  State definition
parameter IDLE  = 2'b00 ,
      SETUP = 2'b01 ,
      ACCESS  = 2'b10 ,
      DONE  = 2'b11 ;

//  FSM
always @(posedge PCLK, negedge PRESETn)
begin
  if (!PRESETn)
  begin
    cs      <=  IDLE        ;

    PREADY_s_m  <=  1'b0        ;
    PSLVERR_s_m <=  1'b0        ;
    PRDATA_s_m  <=  {`ADDR_WIDTH{1'b0}} ;

    ADDR_p_e  <=  {`ADDR_WIDTH{1'b0}} ;
    WRITE_p_e <=  1'b0        ;
    WDATA_p_e <=  {`DATA_WIDTH{1'b0}} ;
    REQ_p_e   <=  1'b0        ;
  end
  else
  begin
    cs      <=  ns          ;

    PREADY_s_m  <=  PREADY_s_m_p    ;
    PSLVERR_s_m <=  PSLVERR_s_m_p   ;
    PRDATA_s_m  <=  PRDATA_s_m_p    ;

    ADDR_p_e  <=  ADDR_p_e_p      ;
    WRITE_p_e <=  WRITE_p_e_p     ;
    WDATA_p_e <=  WDATA_p_e_p     ;
    REQ_p_e   <=  REQ_p_e_p     ;
  end
end

//  FSM - Transition
always @(*)
begin
  case (cs)
    //  IDLE
    IDLE:
    begin
      ns  = PSEL_m_s ? SETUP : IDLE;
    end

    //  SETUP
    SETUP:
    begin
      ns  = ACCESS;
    end

    //  ACCESS
    ACCESS:
    begin
      //assign
      ns  = AccOrDone ? ACCESS : DONE;
    end

    //  DONE
    DONE:
    begin
      ns  = IDLE;
    end

    //  DEFAULT
    default:
    begin
      ns  = IDLE;
    end
  endcase
end

always @(*)
begin
  PREADY_s_m_p  = PREADY_s_m  ;
  PSLVERR_s_m_p = PSLVERR_s_m ;
  PRDATA_s_m_p  = PRDATA_s_m  ;

  ADDR_p_e_p    = ADDR_p_e  ;
  WRITE_p_e_p   = WRITE_p_e ;
  WDATA_p_e_p   = WDATA_p_e ;
  REQ_p_e_p   = REQ_p_e   ;

  case (ns)
    //  IDLE
    IDLE:
    begin
      PREADY_s_m_p  = 1'b0        ;
      PSLVERR_s_m_p = 1'b0        ;
      PRDATA_s_m_p  = {`DATA_WIDTH{1'b0}} ;

      REQ_p_e_p   = 1'b0        ;
    end

    //  SETUP
    SETUP:
    begin
      ADDR_p_e_p    = PADDR_m_s     ;
      WRITE_p_e_p   = PWRITE_m_s      ;
    end

    //  ACCESS
    ACCESS:
    begin
      REQ_p_e_p   = inRange       ;     //  inRange and 1'b1
      if (PWRITE_m_s)
        WDATA_p_e_p   = PWDATA_m_s      ;
    end

    //  DONE
    DONE:
    begin
      REQ_p_e_p   = 1'b0        ;
      PREADY_s_m_p  = GRANT_e_p     ;

      PSLVERR_s_m_p = !inRange      ;
      if ((!PWRITE_m_s) && inRange)
        PRDATA_s_m_p    = RDATA_e_p   ;
    end

  endcase

end

endmodule
