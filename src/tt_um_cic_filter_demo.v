/*
 * Copyright (c) 2025 YU ICHI
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_cic_filter_demo (
    input  wire [7:0] ui_in,    // Dedicated inputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uo_out,   // Dedicated outputs
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // --- 内部結線の定義 ---
    // CICフィルタの入出力
    wire       cic_in;
    wire [7:0] cic_out;

    // --- ピン割り当て (Mapping) ---
    // ui_in[0] を PDM入力 (d_in) として使用
    assign cic_in = ui_in[0];

    // uo_out に CICフィルタの出力 (上位8bit) を接続
    assign uo_out = cic_out;

    // 未使用のピンは定数で固定 (不定値を防ぐため必須)
    assign uio_out = 0;
    assign uio_oe  = 0; // 全て入力(Hi-Z)設定、または0出力で使用しない

    // --- CICフィルタの実装 ---
    // ※ここに前回のCICフィルタの中身を直接書くか、別ファイルにしてインスタンス化します。
    // 今回は1ファイルにまとめるのが一番トラブルが少ないので、以下に直書きします。
    
    // --- CIC Filter Core Logic ---
    parameter WIDTH = 16;
    parameter DECIMATION = 32;

    reg [WIDTH-1:0] int1, int2, int3;
    wire [WIDTH-1:0] in_ext = {{WIDTH-1{1'b0}}, cic_in};

    // 1. Integrator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int1 <= 0; int2 <= 0; int3 <= 0;
        end else begin
            int1 <= int1 + in_ext;
            int2 <= int2 + int1;
            int3 <= int3 + int2;
        end
    end

    // 2. Decimator
    reg [$clog2(DECIMATION)-1:0] count;
    reg sample_en;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0; sample_en <= 0;
        end else begin
            if (count == DECIMATION - 1) begin
                count <= 0; sample_en <= 1;
            end else begin
                count <= count + 1; sample_en <= 0;
            end
        end
    end

    // 3. Comb
    reg [WIDTH-1:0] comb1_d, comb2_d, comb3_d;
    reg [WIDTH-1:0] comb1, comb2, comb3;
    
    // int3_sampledを追加してタイミングを明確化
    reg [WIDTH-1:0] int3_sampled;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comb1_d <= 0; comb2_d <= 0; comb3_d <= 0;
            comb1 <= 0; comb2 <= 0; comb3 <= 0;
            int3_sampled <= 0;
        end else if (sample_en) begin
            int3_sampled <= int3;
            comb1   <= int3 - comb1_d;
            comb1_d <= int3;
            comb2   <= comb1 - comb2_d;
            comb2_d <= comb1;
            comb3   <= comb2 - comb3_d;
            comb3_d <= comb2;
        end
    end

    // 出力割り当て (上位8bit)
    assign cic_out = comb3[WIDTH-1 : WIDTH-8];

endmodule
