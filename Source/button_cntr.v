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
    
    // DFF�� ���� ���ֱ�
    reg [16:0] clk_div = 0; // �̷��� = 0 �س����� �ùķ��̼ǿ��� �ڵ����� 0���� �ʱ�ȭ�ȴ�.
                            // ���忡�� �� ���� �ý��������� 0���� �ʱ�ȭ
    always @(posedge clk) clk_div = clk_div + 1;
    
    // Debounce
    wire debounced_btn;
    D_flip_flop_n debnc(.d(btn), .clk(clk_div[16]), .rst(reset_p), .q(debounced_btn)); // �ٿ�� ���ſ� DFF
    
    // synchronization(Edge Detecting)
    edge_detector_n edg(.clk(clk), .cp_in(debounced_btn), .rst(reset_p), .p_edge(btn_pe), .n_edge(btn_ne)); // Edge Detector
    // p_edge(btn_pe) : ��ư�� ������ �� ����
    // n_edge(btn_ne) : ��ư�� ������ �� �� ����
    // �� �߿� �ʿ��� �͸� ��� ���� �ȴ�.

endmodule
