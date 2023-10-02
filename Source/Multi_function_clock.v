`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/18 14:40:32
// Design Name: 
// Module Name: Multi_function_clock
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

module Multi_function_clock_top(
  input clk, reset_p, all_rst,
  input [3:0] btn,
  output [3:0] com,
  output [7:0] seg_7,
  output reg [7:0] LED_bar,
  output Alarm_LED
);
  
  wire [1:0] mode;
  button_cntr btn_cntr_mode(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(mode_btn));
  counter_dec_mode mode_select(.clk(clk), .btn(mode_btn), .dec1(mode));
  
  reg [3:0] btn_watch_buf, btn_stp_buf, btn_cook_buf;
  reg reset_watch_buf, reset_stp_buf, reset_cook_buf;
//  reg [15:0] value_buf;
  
//  wire [3:0] btn_watch, btn_stp, btn_cook;
//  wire reset_watch, reset_stp, reset_cook;
  wire [15:0] value;
  // 1bit짜리는 자동적으로 wire가 연결되기 때문에 굳이 assign으로 안 만들어줘도 된다.
  // 하지만, 1bit 이상의 값들은 1bit만 짤려서 연결되므로 꼭 wire로 따로 연결해줘야 한다.
  assign btn_watch = btn_watch_buf;
  assign btn_stp = btn_stp_buf;
  assign btn_cook = btn_cook_buf;
//  assign value = value_buf;
  
  wire [15:0] value_watch, value_stp_watch, value_cook;
  assign value = (mode == 0) ? value_watch : (mode == 1) ? value_stp_watch : (mode == 2) ? value_cook : 16'b1111_1111_1111_1111;
  
  // 이렇게 각각 버튼을 나눠줘야 백그라운드에서 다른 기능이 동작하지 않는다.
  always @(posedge clk) begin
    case(mode)
      0 : begin // Watch
		btn_watch_buf[1] = btn[1]; // setmode
		btn_watch_buf[2] = btn[2]; // hour
		btn_watch_buf[3] = btn[3]; // min
		reset_watch_buf = reset_p;
//		value_buf = value_watch;
		LED_bar = 8'b0000_0001;
      end
      
      1 : begin // Stopwatch
		btn_stp_buf[1] = btn[1]; // start/stop
		btn_stp_buf[2] = btn[2]; // lap
		btn_stp_buf[3] = btn[3];
		reset_stp_buf = reset_p;
//		value_buf = value_stp_watch;
		LED_bar = 8'b0000_0010;
      end
      
      2 : begin // Cooktimer  
		btn_cook_buf[1] = btn[1]; // start/stop
		btn_cook_buf[2] = btn[2]; // min+
		btn_cook_buf[3] = btn[3]; // sec+
		reset_cook_buf = reset_p;
//        value_buf = value_cook;
        LED_bar = 8'b0000_0100;
      end
      
      default : begin
//        value_buf = 16'b1111_1111_1111_1111;
        LED_bar = 8'b1110_0000;
      end
    endcase
  end
      
//      wire [2:0] btn_watch;
      Watch_Top_proj watch(.clk(clk), .reset_p(reset_watch_buf | all_rst), .btn(btn_watch), .value_watch(value_watch));
      
//      wire [2:0] btn_stp;
      Stop_Watch_10ms_proj stp_wt(.clk(clk), .reset_p(reset_stp_buf | all_rst), .btn(btn_stp), .value_stp_watch(value_stp_watch));
      
//      wire [2:0] btn_cook;
  	  cook_timer_proj cook_tim(.clk(clk), .reset_p(reset_cook_buf | all_rst), .btn(btn_cook), .value_cook(value_cook), .Alarm_LED(Alarm_LED));
      
      FND_4digit_cntr fnd_cntr(.clk(clk), .rst(reset_p), .value(value), .com(com), .seg_7(seg_7));  /// 컨트롤러가 분주기 가지고 있으니 그냥 clk준다.
      
endmodule
