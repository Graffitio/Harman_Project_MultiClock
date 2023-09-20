`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/07 09:18:12
// Design Name: 
// Module Name: button_cntr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module button_cntr(
    input clk, reset_p,
    input btn,
    output btn_pe, btn_ne
    );
    
    // DFF를 위한 분주기
    reg [16:0] clk_div = 0; // 이렇게 = 0 해놓으면 시뮬레이션에서 자동으로 0으로 초기화된다.
                            // 보드에서 쓸 때는 시스템적으로 0으로 초기화
    always @(posedge clk) clk_div = clk_div + 1;
    
    // Debounce
    wire debounced_btn;
    D_flip_flop_n debnc(.d(btn), .clk(clk_div[16]), .rst(reset_p), .q(debounced_btn)); // 바운싱 제거용 DFF
    
    // synchronization(Edge Detecting)
    edge_detector_n edg(.clk(clk), .cp_in(debounced_btn), .rst(reset_p), .p_edge(btn_pe), .n_edge(btn_ne)); // Edge Detector
    // p_edge(btn_pe) : 버튼을 눌렀을 때 동작
    // n_edge(btn_ne) : 버튼을 눌렀다 뗄 떄 동작
    // 둘 중에 필요한 것만 골라서 쓰면 된다.

endmodule
