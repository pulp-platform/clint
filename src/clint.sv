// Copyright 2018-2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Florian Zaruba, ETH Zurich
// Date: 15/07/2017
// Description: A RISC-V privilege spec 1.11 (WIP) compatible CLINT (core local interrupt controller)
//

// Platforms provide a real-time counter, exposed as a memory-mapped machine-mode register, mtime. mtime must run at
// constant frequency, and the platform must provide a mechanism for determining the timebase of mtime (device tree).

`include "common_cells/registers.svh"

module clint import clint_reg_pkg::*; #(
    parameter type apb_req_t = logic,
    parameter type apb_rsp_t = logic
) (
    input  logic                clk_i,       // Clock
    input  logic                rst_ni,      // Asynchronous reset active low
    input  logic                testmode_i,
    input  apb_req_t            apb_req_i,
    output apb_rsp_t            apb_rsp_o,
    input  logic                rtc_i,       // Real-time clock in (usually 32.768 kHz)
    output logic [NumCores-1:0] timer_irq_o, // Timer interrupts
    output logic [NumCores-1:0] ipi_o        // software interrupt (a.k.a inter-process-interrupt)
);

    logic [63:0]               mtime_q;
    logic [NumCores-1:0][63:0] mtimecmp_q;
    // increase the timer
    logic increase_timer;

    clint_reg_pkg::clint__out_t reg2hw;
    clint_reg_pkg::clint__in_t hw2reg;

    clint_reg_top i_clint_reg_top (
      .clk (clk_i),
      .arst_n (rst_ni),
      .s_apb_psel    (apb_req_i.psel),
      .s_apb_penable (apb_req_i.penable),
      .s_apb_pwrite  (apb_req_i.pwrite),
      .s_apb_pprot   (apb_req_i.pprot),
      .s_apb_paddr   (apb_req_i.paddr[CLINT_REG_TOP_MIN_ADDR_WIDTH-1:0]),
      .s_apb_pwdata  (apb_req_i.pwdata),
      .s_apb_pstrb   (apb_req_i.pstrb),
      .s_apb_pready  (apb_rsp_o.pready),
      .s_apb_prdata  (apb_rsp_o.prdata),
      .s_apb_pslverr (apb_rsp_o.pslverr),
      .hwif_out (reg2hw), // Write
      .hwif_in  (hw2reg) // Read
    );

    assign mtime_q = {reg2hw.mtime.mtime_high.MTIME_HIGH.value,
                      reg2hw.mtime.mtime_low.MTIME_LOW.value};
    for (genvar i = 0; i < NumCores; i++) begin : gen_mtimecmp
        assign mtimecmp_q[i] = {reg2hw.mtimecmp[i].mtimecmp_high.MTIMECMP_HIGH.value,
                                reg2hw.mtimecmp[i].mtimecmp_low.MTIMECMP_LOW.value};
        assign ipi_o[i] = reg2hw.msip[i].P.value;
    end

    assign {hw2reg.mtime.mtime_high.MTIME_HIGH.next,
            hw2reg.mtime.mtime_low.MTIME_LOW.next} = mtime_q + 1;
    assign hw2reg.mtime.mtime_low.MTIME_LOW.we = increase_timer;
    assign hw2reg.mtime.mtime_high.MTIME_HIGH.we = increase_timer;

    // -----------------------------
    // IRQ Generation
    // -----------------------------
    // The mtime register has a 64-bit precision on all RV32, RV64, and RV128 systems. Platforms provide a 64-bit
    // memory-mapped machine-mode timer compare register (mtimecmp), which causes a timer interrupt to be posted when the
    // mtime register contains a value greater than or equal (mtime >= mtimecmp) to the value in the mtimecmp register.
    // The interrupt remains posted until it is cleared by writing the mtimecmp register. The interrupt will only be taken
    // if interrupts are enabled and the MTIE bit is set in the mie register.
    always_comb begin : irq_gen
        // check that the mtime cmp register is set to a meaningful value
        for (int unsigned i = 0; i < NumCores; i++) begin
            if (mtime_q >= mtimecmp_q[i]) begin
                timer_irq_o[i] = 1'b1;
            end else begin
                timer_irq_o[i] = 1'b0;
            end
        end
    end

    // -----------------------------
    // RTC time tracking facilities
    // -----------------------------
    // 1. Put the RTC input through a classic two stage edge-triggered synchronizer to filter out any
    //    metastability effects (or at least make them unlikely :-))
    clint_sync_wedge i_sync_edge (
        .clk_i,
        .rst_ni,
        .serial_i  ( rtc_i          ),
        .r_edge_o  ( increase_timer ),
        .f_edge_o  (                ), // left open
        .serial_o  (                )  // left open
    );


endmodule

// TODO(zarubaf): Replace by common-cells 2.0
module clint_sync_wedge #(
    parameter int unsigned STAGES = 2
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic r_edge_o,
    output logic f_edge_o,
    output logic serial_o
);
    logic serial, serial_q;

    assign serial_o =  serial_q;
    assign f_edge_o = (~serial) & serial_q;
    assign r_edge_o =  serial & (~serial_q);

    clint_sync #(
        .STAGES (STAGES)
    ) i_sync (
        .clk_i,
        .rst_ni,
        .serial_i,
        .serial_o (serial)
    );

    `FF(serial_q, serial, 1'b0)
endmodule

module clint_sync #(
    parameter int unsigned STAGES = 2
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

  logic [STAGES-1:0] reg_q;
  `FF(reg_q, {reg_q[STAGES-2:0], serial_i}, 'h0)
  assign serial_o = reg_q[STAGES-1];

endmodule

