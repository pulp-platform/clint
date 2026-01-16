// Copyright 2018-2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Florian Zaruba, ETH Zurich

`include "apb/assign.svh"
`include "apb/typedef.svh"

module clint_tb;

  localparam time ClkPeriod = 10ns;
  localparam time RTCClkPeriod = 30ns;

  `APB_TYPEDEF_ALL(dut, logic [31:0], logic [31:0], logic [3:0])

  logic clk, rst_n, rtc;
  logic [1:0] timer_irq, ipi;
  logic rtc_en;

  // ----------------
  // Clock generation
  // ----------------
  initial begin
    rst_n = 0;
    repeat (3) begin
      #(ClkPeriod/2) clk = 0;
      #(ClkPeriod/2) clk = 1;
    end
    rst_n = 1;
    forever begin
      #(ClkPeriod/2) clk = 0;
      #(ClkPeriod/2) clk = 1;
    end
  end

  initial begin
    rtc_en = 1'b1;
    rtc = 1'b0;
    forever begin
      if (rtc_en) begin
        #(RTCClkPeriod/2) rtc = 0;
        #(RTCClkPeriod/2) rtc = 1;
      end else begin
        rtc = 0;
        #(RTCClkPeriod);
      end
    end
  end

  APB_DV #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) apb_dut(clk);
  dut_req_t dut_req;
  dut_resp_t dut_rsp;

  `APB_ASSIGN_TO_REQ(dut_req, apb_dut)
  `APB_ASSIGN_FROM_RESP(apb_dut, dut_rsp)

  typedef apb_test::apb_driver #(
    .ADDR_WIDTH (32), .DATA_WIDTH (32), .TA (ClkPeriod*0.2), .TT (ClkPeriod*0.8)
  ) apb_driver_t;

  apb_driver_t driver = new (apb_dut);

  clint #(
    .apb_req_t (dut_req_t),
    .apb_rsp_t (dut_resp_t)
  ) dut (
    .clk_i (clk),
    .rst_ni (rst_n),
    .testmode_i (1'b0),
    .apb_req_i (dut_req),
    .apb_rsp_o (dut_rsp),
    .rtc_i (rtc),
    .timer_irq_o (timer_irq),
    .ipi_o (ipi)
  );

  localparam logic [31:0] MSIPBase = 32'h0;
  localparam logic [31:0] MTIMECMPBase = 32'h4000;
  localparam logic [31:0] MTIMEBase = 32'hbff8;

  initial begin
    automatic logic error;
    automatic logic [31:0] rdata;
    driver.reset_master();
    @(posedge rst_n);

    // ---------------------------------------------------------
    // 1. MSIP Test
    // ---------------------------------------------------------
    driver.write(MSIPBase, 1, 1, error);
    @(posedge clk);
    assert(ipi[0] == 1) else $error("MSIP[0] assertion failed");

    // ---------------------------------------------------------
    // 2. MTIMECMP 64-bit Access Test
    // ---------------------------------------------------------
    // Write Low 32-bits
    driver.write(MTIMECMPBase, 32'hffff_ffff, 4'hf, error);
    // Write High 32-bits
    driver.write(MTIMECMPBase + 4, 32'h0000_0001, 4'hf, error);

    // Read back to verify
    driver.read(MTIMECMPBase, rdata, error);
    assert(rdata == 32'hffff_ffff) else $error("MTIMECMP Low readback failed: expected ffffffff, got %h", rdata);
    driver.read(MTIMECMPBase + 4, rdata, error);
    assert(rdata == 32'h0000_0001) else $error("MTIMECMP High readback failed: expected 1, got %h", rdata);

    // ---------------------------------------------------------
    // 3. MTIME 64-bit Access Test & IRQ Logic
    // ---------------------------------------------------------
    // Disable RTC to check read/write without increment
    rtc_en = 0;
    #100ns;

    // Set mtime to 0x1_FFFFFFFE (just below mtimecmp)
    driver.write(MTIMEBase, 32'hffff_fffe, 4'hf, error);
    driver.write(MTIMEBase + 4, 32'h0000_0001, 4'hf, error);

    // Read back mtime
    driver.read(MTIMEBase, rdata, error);
    assert(rdata == 32'hffff_fffe) else $error("MTIME Low readback failed");
    driver.read(MTIMEBase + 4, rdata, error);
    assert(rdata == 32'h0000_0001) else $error("MTIME High readback failed");

    // Check IRQ: mtime (1_fffffffe) < mtimecmp (1_ffffffff) -> irq should be 0
    @(posedge clk);
    assert(timer_irq[0] == 0) else $error("Timer IRQ[0] should be 0 (mtime < mtimecmp)");

    // Enable RTC and Advance mtime to equal mtimecmp
    rtc_en = 1;
    driver.write(MTIMEBase, 32'hffff_ffff, 4'hf, error);
    // mtime (1_ffffffff) >= mtimecmp (1_ffffffff) -> irq should be 1
    // We wait enough time for potential sync/update
    repeat(10) @(posedge clk);
    assert(timer_irq[0] == 1) else $error("Timer IRQ[0] should be 1 (mtime == mtimecmp)");

    // ---------------------------------------------------------
    // 4. MTIMECMP[1] Test (High core)
    // ---------------------------------------------------------
    // mtimecmp[1] base is 0x4000 + 0x8 = 0x4008
    // Set mtimecmp[1] to 0x2_00000000
    driver.write(MTIMECMPBase + 8, 32'h0000_0000, 4'hf, error);
    driver.write(MTIMECMPBase + 12, 32'h0000_0002, 4'hf, error);

    // Disable RTC to ensure stability
    rtc_en = 0;
    #100ns;
    
    // Set mtime to 0x0
    driver.write(MTIMEBase, 0, 4'hf, error);
    driver.write(MTIMEBase + 4, 0, 4'hf, error);

    // mtime is 0. 0 < 2_00000000. irq[1] should be 0.
    @(posedge clk);
    assert(timer_irq[1] == 0) else $error("Timer IRQ[1] should be 0 (mtime < mtimecmp[1])");

    // Advance mtime high to 2
    driver.write(MTIMEBase + 4, 32'h0000_0002, 4'hf, error); // mtime = 0x2_00000000
    // mtime (2_00000000) >= mtimecmp[1] (2_00000000). irq[1] should be 1.
    @(posedge clk);
    assert(timer_irq[1] == 1) else $error("Timer IRQ[1] should be 1 (mtime >= mtimecmp[1])");

    #3000ns;
    $finish();
  end

endmodule
