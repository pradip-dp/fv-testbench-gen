`timescale 1ns / 1ps
`default_nettype none

module prim_fifo_sync_cfg_tb #(
  parameter int unsigned Width            = 8,
  parameter bit          Pass             = 1'b1,
  parameter int unsigned Depth            = 4,
  parameter bit          OutputZeroIfEmpty = 1'b1,
  parameter bit          NeverClears      = 1'b0,
  parameter bit          Secure           = 1'b0
) (
  input  logic             clk_i,
  input  logic             rst_ni,
  input  logic             clr_i,
  input  logic             wvalid_i,
  input  logic [Width-1:0] wdata_i,
  input  logic             rready_i
);
  localparam int unsigned DepthW = prim_util_pkg::vbits(Depth + 1);
  localparam int unsigned ModelDepth = (Depth > 0) ? Depth : 1;

  logic                 wready_o;
  logic                 rvalid_o;
  logic [Width-1:0]     rdata_o;
  logic                 full_o;
  logic [DepthW-1:0]    depth_o;
  logic                 err_o;

  logic exp_under_rst;

  int unsigned ref_count;
  int unsigned ref_head;
  int unsigned ref_tail;
  logic [Width-1:0] ref_mem [0:ModelDepth-1];

  wire wr_hs = wvalid_i && wready_o;
  wire rd_hs = rvalid_o && rready_i;

  function automatic int unsigned bump_idx(input int unsigned idx);
    if (ModelDepth <= 1) begin
      bump_idx = 0;
    end else if (idx == ModelDepth - 1) begin
      bump_idx = 0;
    end else begin
      bump_idx = idx + 1;
    end
  endfunction

  prim_fifo_sync #(
    .Width(Width),
    .Pass(Pass),
    .Depth(Depth),
    .OutputZeroIfEmpty(OutputZeroIfEmpty),
    .NeverClears(NeverClears),
    .Secure(Secure)
  ) dut (
    .clk_i,
    .rst_ni,
    .clr_i,
    .wvalid_i,
    .wready_o,
    .wdata_i,
    .rvalid_o,
    .rready_i,
    .rdata_o,
    .full_o,
    .depth_o,
    .err_o
  );

  generate
    if (Depth > 1) begin : gen_under_rst_model
      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          exp_under_rst <= 1'b1;
        end else if (exp_under_rst) begin
          exp_under_rst <= 1'b0;
        end
      end
    end else begin : gen_no_under_rst_model
      always_comb begin
        exp_under_rst = 1'b0;
      end
    end
  endgenerate

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ref_count <= 0;
      ref_head <= 0;
      ref_tail <= 0;
    end else if (Depth > 0) begin
      if (clr_i) begin
        ref_count <= 0;
        ref_head <= 0;
        ref_tail <= 0;
      end else begin
        unique case ({wr_hs, rd_hs})
          2'b10: begin
            if (ref_count < Depth) begin
              ref_mem[ref_tail] <= wdata_i;
              ref_tail <= bump_idx(ref_tail);
              ref_count <= ref_count + 1;
            end
          end
          2'b01: begin
            if (ref_count > 0) begin
              ref_head <= bump_idx(ref_head);
              ref_count <= ref_count - 1;
            end
          end
          2'b11: begin
            if (!(Pass && (ref_count == 0)) && (ref_count > 0) && (ref_count < Depth)) begin
              ref_mem[ref_tail] <= wdata_i;
              ref_tail <= bump_idx(ref_tail);
              ref_head <= bump_idx(ref_head);
            end
          end
          default: begin
          end
        endcase
      end
    end
  end

  // TP-01
  width_legal_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    1'b1 |-> (Width >= 1)
  );

  // TP-01
  depth0_requires_pass_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth == 0) |-> Pass
  );

  // Formal reset model: start in reset, release immediately after init, never re-assert.
  reset_starts_low_M: assume property (
    @(posedge clk_i)
    $initstate |-> !rst_ni
  );

  reset_releases_after_init_M: assume property (
    @(posedge clk_i)
    $past($initstate) |-> rst_ni
  );

  reset_stays_high_M: assume property (
    @(posedge clk_i)
    (!$initstate && $past(rst_ni)) |-> rst_ni
  );

  // TP-02
  never_clears_assume_A: assume property (
    @(posedge clk_i) disable iff (!rst_ni)
    NeverClears |-> !clr_i
  );

  // TP-22
  ref_count_in_range_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth > 0) |-> (ref_count <= Depth)
  );

  // TP-22
  depth_matches_ref_count_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth > 0) |-> (depth_o == ref_count[DepthW-1:0])
  );

  // TP-23
  nonsecure_err_zero_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    !Secure |-> (err_o == 1'b0)
  );

  // TP-24
  secure_err_low_on_reset_release_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    Secure && $rose(rst_ni) |-> (err_o == 1'b0)
  );

  // TP-07
  depth0_rvalid_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth == 0) |-> (rvalid_o == wvalid_i)
  );

  // TP-07
  depth0_rdata_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth == 0) |-> (rdata_o == wdata_i)
  );

  // TP-07
  depth0_wready_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth == 0) |-> (wready_o == rready_i)
  );

  // TP-07
  depth0_full_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth == 0) |-> (full_o == 1'b1)
  );

  // TP-07
  depth0_depth_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth == 0) |-> (depth_o == '0)
  );

  // TP-07
  depth0_err_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth == 0) |-> (err_o == 1'b0)
  );

  // TP-08
  depth1_full_matches_ref_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth == 1) |-> (full_o == (ref_count == 1))
  );

  // TP-08
  depth1_wready_matches_ref_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth == 1) |-> (wready_o == (ref_count == 0))
  );

  // TP-08
  depth1_rvalid_matches_mode_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth == 1) |-> (rvalid_o == ((ref_count == 1) || (Pass && wvalid_i)))
  );

  // TP-09
  depth1_pass_bypass_data_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth == 1) && Pass && (ref_count == 0) && rvalid_o |-> (rdata_o == wdata_i)
  );

  // TP-08
  depth1_stored_data_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth == 1) && (ref_count == 1) && rvalid_o |-> (rdata_o == ref_mem[ref_head])
  );

  // TP-20
  depth1_zero_if_empty_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth == 1) && OutputZeroIfEmpty && !rvalid_o |-> (rdata_o == '0)
  );

  // TP-12
  depthgt1_full_matches_ref_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth > 1) |-> (full_o == (ref_count == Depth))
  );

  // TP-12
  depthgt1_wready_matches_ref_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth > 1) |-> (wready_o == ((ref_count < Depth) && !exp_under_rst))
  );

  // TP-13
  depthgt1_pass_rvalid_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth > 1) && Pass |-> (rvalid_o == (((ref_count > 0) || wvalid_i) && !exp_under_rst))
  );

  // TP-13
  depthgt1_pass_bypass_data_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth > 1) && Pass && (ref_count == 0) && rvalid_o |-> (rdata_o == wdata_i)
  );

  // TP-13
  depthgt1_pass_stored_data_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth > 1) && Pass && (ref_count > 0) && rvalid_o |-> (rdata_o == ref_mem[ref_head])
  );

  // TP-14
  depthgt1_nopass_rvalid_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth > 1) && !Pass |-> (rvalid_o == (ref_count > 0))
  );

  // TP-14
  depthgt1_nopass_stored_data_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth > 1) && !Pass && (ref_count > 0) |-> (rdata_o == ref_mem[ref_head])
  );

  // TP-20
  depthgt1_zero_if_empty_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth > 1) && OutputZeroIfEmpty && !Pass && (ref_count == 0) |-> (rdata_o == '0)
  );

  // TP-20
  depthgt1_pass_zero_if_empty_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth > 1) && OutputZeroIfEmpty && Pass && (ref_count == 0) && !wvalid_i |-> (rdata_o == '0)
  );

  // TP-21
  read_data_matches_reference_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth > 0) && rd_hs && Pass && (ref_count == 0) |-> (rdata_o == wdata_i)
  );

  // TP-21
  read_data_matches_stored_reference_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth > 0) && rd_hs && !(Pass && (ref_count == 0)) |-> ((ref_count > 0) && (rdata_o == ref_mem[ref_head]))
  );

  // TP-10 / TP-17
  full_blocks_write_A: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    (Depth > 0) && full_o |-> !wready_o
  );

  generate
    if (Depth == 0) begin : gen_depth0_covers
      // TP-07 / TP-25
      depth0_transfer_C: cover property (
        @(posedge clk_i) disable iff (!rst_ni)
        wvalid_i && rready_i && wr_hs && rd_hs
      );
    end

    if ((Depth == 1) && Pass) begin : gen_depth1_pass_covers
      // TP-09
      depth1_bypass_then_store_then_read_C: cover property (
        @(posedge clk_i) disable iff (!rst_ni)
        (ref_count == 0) && wvalid_i && !rready_i && wr_hs && !rd_hs
        |-> ##1 (depth_o == 1)
        ##1 rready_i && rd_hs
      );
    end

    if (Depth == 1) begin : gen_depth1_common_covers
      // TP-10
      depth1_read_then_write_after_full_C: cover property (
        @(posedge clk_i) disable iff (!rst_ni)
        full_o
        ##1 rd_hs
        ##1 wr_hs
      );

      // TP-18
      depth1_clear_flush_C: cover property (
        @(posedge clk_i) disable iff (!rst_ni)
        (ref_count == 1) && clr_i
        |-> ##1 (depth_o == 0)
      );
    end

    if ((Depth > 1) && Pass) begin : gen_depthgt1_pass_covers
      // TP-13 / TP-15
      depthgt1_empty_bypass_transfer_C: cover property (
        @(posedge clk_i) disable iff (!rst_ni)
        !exp_under_rst && (ref_count == 0) && wvalid_i && rready_i && wr_hs && rd_hs
      );

      // TP-18
      depthgt1_clear_during_bypass_C: cover property (
        @(posedge clk_i) disable iff (!rst_ni)
        !exp_under_rst && (ref_count == 0) && clr_i && wvalid_i && rready_i && wr_hs && rd_hs
        |-> ##1 (depth_o == 0)
      );
    end

    if (Depth > 1) begin : gen_depthgt1_common_covers
      // TP-17 / TP-25
      depthgt1_fill_read_write_C: cover property (
        @(posedge clk_i) disable iff (!rst_ni)
        (ref_count == Depth - 1) && wr_hs
        ##1 full_o
        ##1 rd_hs
        ##1 wr_hs
      );

      // TP-16
      depthgt1_simultaneous_rd_wr_C: cover property (
        @(posedge clk_i) disable iff (!rst_ni)
        (ref_count > 0) && (ref_count < Depth) && wr_hs && rd_hs
      );

      // TP-18
      depthgt1_clear_flush_C: cover property (
        @(posedge clk_i) disable iff (!rst_ni)
        (ref_count > 0) && clr_i
        |-> ##1 (depth_o == 0)
      );

      // TP-25
      depthgt1_wrap_tail_C: cover property (
        @(posedge clk_i) disable iff (!rst_ni)
        (ref_tail == Depth - 1) && wr_hs
        |-> ##1 (ref_tail == 0)
      );
    end

    if ((Depth > 0) && OutputZeroIfEmpty) begin : gen_zero_if_empty_cover
      // TP-20
      zero_if_empty_C: cover property (
        @(posedge clk_i) disable iff (!rst_ni)
        !rvalid_o && (rdata_o == '0)
      );
    end
  endgenerate

endmodule

module prim_fifo_sync_tb (
  input  logic       clk_i,
  input  logic       rst_ni,
  input  logic       clr_i,
  input  logic       wvalid_i,
  input  logic [7:0] wdata_i,
  input  logic       rready_i
);
  // Depth == 0 pure pass-through coverage.
  prim_fifo_sync_cfg_tb #(
    .Width(8),
    .Pass(1'b1),
    .Depth(0),
    .OutputZeroIfEmpty(1'b1),
    .NeverClears(1'b0),
    .Secure(1'b0)
  ) u_depth0 (
    .clk_i,
    .rst_ni,
    .clr_i,
    .wvalid_i,
    .wdata_i,
    .rready_i
  );

  // Depth == 1 without bypass.
  prim_fifo_sync_cfg_tb #(
    .Width(8),
    .Pass(1'b0),
    .Depth(1),
    .OutputZeroIfEmpty(1'b1),
    .NeverClears(1'b0),
    .Secure(1'b0)
  ) u_depth1_nopass (
    .clk_i,
    .rst_ni,
    .clr_i,
    .wvalid_i,
    .wdata_i,
    .rready_i
  );

  // Depth == 1 with bypass and secure singleton integrity logic.
  prim_fifo_sync_cfg_tb #(
    .Width(8),
    .Pass(1'b1),
    .Depth(1),
    .OutputZeroIfEmpty(1'b0),
    .NeverClears(1'b0),
    .Secure(1'b1)
  ) u_depth1_pass_secure (
    .clk_i,
    .rst_ni,
    .clr_i,
    .wvalid_i,
    .wdata_i,
    .rready_i
  );

  // Depth > 1 non-power-of-two with bypass enabled.
  prim_fifo_sync_cfg_tb #(
    .Width(8),
    .Pass(1'b1),
    .Depth(3),
    .OutputZeroIfEmpty(1'b1),
    .NeverClears(1'b0),
    .Secure(1'b0)
  ) u_depth3_pass (
    .clk_i,
    .rst_ni,
    .clr_i,
    .wvalid_i,
    .wdata_i,
    .rready_i
  );

  // Depth > 1 non-bypass secure case with NeverClears enabled.
  prim_fifo_sync_cfg_tb #(
    .Width(8),
    .Pass(1'b0),
    .Depth(4),
    .OutputZeroIfEmpty(1'b0),
    .NeverClears(1'b1),
    .Secure(1'b1)
  ) u_depth4_nopass_secure (
    .clk_i,
    .rst_ni,
    .clr_i,
    .wvalid_i,
    .wdata_i,
    .rready_i
  );

endmodule

`default_nettype wire
