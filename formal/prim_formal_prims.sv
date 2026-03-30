package prim_count_pkg;
  localparam int Clr  = 1;
  localparam int Set  = 2;
  localparam int Incr = 4;
endpackage

module prim_flop #(
  parameter int Width = 1,
  parameter logic [Width-1:0] ResetValue = '0
) (
  input  logic             clk_i,
  input  logic             rst_ni,
  input  logic [Width-1:0] d_i,
  output logic [Width-1:0] q_o
);
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      q_o <= ResetValue;
    end else begin
      q_o <= d_i;
    end
  end
endmodule

module prim_count #(
  parameter int Width = 1,
  parameter int PossibleActions = 0
) (
  input  logic             clk_i,
  input  logic             rst_ni,
  input  logic             clr_i,
  input  logic             set_i,
  input  logic [Width-1:0] set_cnt_i,
  input  logic             incr_en_i,
  input  logic             decr_en_i,
  input  logic [Width-1:0] step_i,
  input  logic             commit_i,
  output logic [Width-1:0] cnt_o,
  output logic [Width-1:0] cnt_after_commit_o,
  output logic             err_o
);
  logic [Width-1:0] cnt_d;

  always_comb begin
    cnt_d = cnt_o;

    if (clr_i && (PossibleActions & prim_count_pkg::Clr)) begin
      cnt_d = '0;
    end else if (set_i && (PossibleActions & prim_count_pkg::Set)) begin
      cnt_d = set_cnt_i;
    end else if (incr_en_i && (PossibleActions & prim_count_pkg::Incr)) begin
      cnt_d = cnt_o + step_i;
    end else if (decr_en_i) begin
      cnt_d = cnt_o - step_i;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      cnt_o <= '0;
    end else if (commit_i) begin
      cnt_o <= cnt_d;
    end
  end

  assign cnt_after_commit_o = cnt_d;
  assign err_o = 1'b0;
endmodule
