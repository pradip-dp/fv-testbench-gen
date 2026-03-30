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

  logic cov_d1_bypass_seen;
  logic cov_d1_stored_seen;
  logic cov_d1_full_seen;
  logic cov_d1_read_seen;
  logic cov_d1_clear_seen;
  logic cov_dgt1_fill_seen;
  logic cov_dgt1_full_seen;
  logic cov_dgt1_read_seen;
  logic cov_dgt1_clear_seen;
  logic cov_dgt1_clear_bypass_seen;
  logic cov_dgt1_wrap_seen;

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

  always_ff @(posedge clk_i) begin
    if ($initstate) begin
      assume (!rst_ni);
    end else begin
      if ($past($initstate)) begin
        assume (rst_ni);
      end
      if ($past(rst_ni)) begin
        assume (rst_ni);
      end
    end

    if (rst_ni && NeverClears) begin
      // TP-02
      assume (!clr_i);
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_ni) begin
      // TP-01
      assert (Width >= 1);

      // TP-01
      if (Depth == 0) begin
        assert (Pass);
      end

      // TP-22
      if (Depth > 0) begin
        assert (ref_count <= Depth);
        assert (depth_o == ref_count[DepthW-1:0]);
      end

      // TP-23
      if (!Secure) begin
        assert (err_o == 1'b0);
      end

      // TP-24
      if (!$initstate && $past(!rst_ni) && Secure) begin
        assert (err_o == 1'b0);
      end

      // TP-07
      if (Depth == 0) begin
        assert (rvalid_o == wvalid_i);
        assert (rdata_o == wdata_i);
        assert (wready_o == rready_i);
        assert (full_o == 1'b1);
        assert (depth_o == '0);
        assert (err_o == 1'b0);
      end

      // TP-08 / TP-09 / TP-20
      if (Depth == 1) begin
        assert (full_o == (ref_count == 1));
        assert (wready_o == (ref_count == 0));
        assert (rvalid_o == ((ref_count == 1) || (Pass && wvalid_i)));

        if (Pass && (ref_count == 0) && rvalid_o) begin
          assert (rdata_o == wdata_i);
        end

        if ((ref_count == 1) && rvalid_o) begin
          assert (rdata_o == ref_mem[ref_head]);
        end

        if (OutputZeroIfEmpty && !rvalid_o) begin
          assert (rdata_o == '0);
        end
      end

      // TP-12 / TP-13 / TP-14 / TP-20
      if (Depth > 1) begin
        assert (full_o == (ref_count == Depth));
        assert (wready_o == ((ref_count < Depth) && !exp_under_rst));

        if (Pass) begin
          assert (rvalid_o == (((ref_count > 0) || wvalid_i) && !exp_under_rst));

          if ((ref_count == 0) && rvalid_o) begin
            assert (rdata_o == wdata_i);
          end

          if ((ref_count > 0) && rvalid_o) begin
            assert (rdata_o == ref_mem[ref_head]);
          end

          if (OutputZeroIfEmpty && (ref_count == 0) && !wvalid_i) begin
            assert (rdata_o == '0);
          end
        end else begin
          assert (rvalid_o == (ref_count > 0));

          if (ref_count > 0) begin
            assert (rdata_o == ref_mem[ref_head]);
          end

          if (OutputZeroIfEmpty && (ref_count == 0)) begin
            assert (rdata_o == '0);
          end
        end
      end

      // TP-21
      if ((Depth > 0) && rd_hs) begin
        if (Pass && (ref_count == 0)) begin
          assert (rdata_o == wdata_i);
        end else begin
          assert (ref_count > 0);
          assert (rdata_o == ref_mem[ref_head]);
        end
      end

      // TP-04 / TP-22
      if ((Depth > 0) && wr_hs && !rd_hs) begin
        assert (ref_count < Depth);
      end

      // TP-04 / TP-22
      if ((Depth > 0) && !wr_hs && rd_hs) begin
        assert (ref_count > 0);
      end

      // TP-10 / TP-17
      if ((Depth > 0) && full_o) begin
        assert (!wready_o);
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      cov_d1_bypass_seen <= 1'b0;
      cov_d1_stored_seen <= 1'b0;
      cov_d1_full_seen <= 1'b0;
      cov_d1_read_seen <= 1'b0;
      cov_d1_clear_seen <= 1'b0;
      cov_dgt1_fill_seen <= 1'b0;
      cov_dgt1_full_seen <= 1'b0;
      cov_dgt1_read_seen <= 1'b0;
      cov_dgt1_clear_seen <= 1'b0;
      cov_dgt1_clear_bypass_seen <= 1'b0;
      cov_dgt1_wrap_seen <= 1'b0;
    end else begin
      // TP-07 / TP-25
      if ((Depth == 0) && wvalid_i && rready_i && wr_hs && rd_hs) begin
        cover (1'b1);
      end

      if ((Depth == 1) && Pass) begin
        // TP-09
        if ((ref_count == 0) && wvalid_i && !rready_i && wr_hs && !rd_hs) begin
          cov_d1_bypass_seen <= 1'b1;
        end
        if (cov_d1_bypass_seen && (depth_o == 1)) begin
          cov_d1_stored_seen <= 1'b1;
        end
        if (cov_d1_stored_seen && rready_i && rd_hs) begin
          cover (1'b1);
        end
      end

      if (Depth == 1) begin
        // TP-10
        if (full_o) begin
          cov_d1_full_seen <= 1'b1;
        end
        if (cov_d1_full_seen && rd_hs) begin
          cov_d1_read_seen <= 1'b1;
        end
        if (cov_d1_read_seen && wr_hs) begin
          cover (1'b1);
        end

        // TP-18
        if ((ref_count == 1) && clr_i) begin
          cov_d1_clear_seen <= 1'b1;
        end
        if (cov_d1_clear_seen && (depth_o == 0)) begin
          cover (1'b1);
        end
      end

      if ((Depth > 1) && Pass) begin
        // TP-13 / TP-15
        if (!exp_under_rst && (ref_count == 0) && wvalid_i && rready_i && wr_hs && rd_hs) begin
          cover (1'b1);
        end

        // TP-18
        if (!exp_under_rst && (ref_count == 0) && clr_i && wvalid_i && rready_i && wr_hs && rd_hs) begin
          cov_dgt1_clear_bypass_seen <= 1'b1;
        end
        if (cov_dgt1_clear_bypass_seen && (depth_o == 0)) begin
          cover (1'b1);
        end
      end

      if (Depth > 1) begin
        // TP-17 / TP-25
        if ((ref_count == Depth - 1) && wr_hs) begin
          cov_dgt1_fill_seen <= 1'b1;
        end
        if (cov_dgt1_fill_seen && full_o) begin
          cov_dgt1_full_seen <= 1'b1;
        end
        if (cov_dgt1_full_seen && rd_hs) begin
          cov_dgt1_read_seen <= 1'b1;
        end
        if (cov_dgt1_read_seen && wr_hs) begin
          cover (1'b1);
        end

        // TP-16
        if ((ref_count > 0) && (ref_count < Depth) && wr_hs && rd_hs) begin
          cover (1'b1);
        end

        // TP-18
        if ((ref_count > 0) && clr_i) begin
          cov_dgt1_clear_seen <= 1'b1;
        end
        if (cov_dgt1_clear_seen && (depth_o == 0)) begin
          cover (1'b1);
        end

        // TP-25
        if ((ref_tail == Depth - 1) && wr_hs) begin
          cov_dgt1_wrap_seen <= 1'b1;
        end
        if (cov_dgt1_wrap_seen && (ref_tail == 0)) begin
          cover (1'b1);
        end
      end

      // TP-20
      if ((Depth > 0) && OutputZeroIfEmpty && !rvalid_o && (rdata_o == '0)) begin
        cover (1'b1);
      end
    end
  end

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
