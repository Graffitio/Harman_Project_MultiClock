`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/18 14:41:24
// Design Name: 
// Module Name: Multi_funtcion_clock_source
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

// Mode용 카운터
module counter_dec_mode(
    input clk, reset_p,
    input btn,
    output reg [3:0] dec1
    );
    
//    wire clk_usec;
//    clock_usec_proj usec_mode(.clk(clk), .reset_p(reset_p), .clk_usec(clk_usec));
    
    always @(posedge clk) begin
//    always @(posedge clk, posedge reset_p) begin
//        if(reset_p) begin
//            dec1 = 0;
//        end
      if(btn) begin
//      else if(btn) begin
        if(dec1 >= 2) begin 
                dec1 <= 0;
            end
            else dec1 <= dec1 + 1;
        end
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// clock lib begin
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module clock_usec_proj(
    input clk, reset_p,
    input enable,
    output clk_usec
    );
    
    // 125개 카운트하면 1us
    reg [6:0] cnt_8nsec;
    wire cp_usec; // cp : clock pulse
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) cnt_8nsec = 0; // reset이 들어오면 cnt = 0
            else if(cnt_8nsec >= 124) cnt_8nsec = 0; // 0부터 124번까지 카운트하면 다시 0으로
            else cnt_8nsec = cnt_8nsec + 1;
     end
    
    assign cp_usec = cnt_8nsec < 63 ? 0 : 1; // 0~62 : 0, 63~124 : 1 
    
    // 비정규 clock이므로 동기화가 필요하다.
    edge_detector_n edg(.clk(clk), .cp_in(cp_usec), .rst(reset_p), .n_edge(clk_usec)); /// 안 쓰는 출력은 빼버리면 된다.
    
endmodule

// 1000분주 clock
module clock_div_1000_proj(
    input clk, clk_source, reset_p,
    output clk_div_1000
    );

    reg [8:0] cnt_clk_source;
    reg cp_div_1000; // cp : clock pulse
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) cnt_clk_source = 0; // reset이 들어오면 cnt = 0
        else if(clk_source) begin
            if (cnt_clk_source >= 499) begin
//            if (cnt_clk_source >= 999) begin
                cnt_clk_source = 0; // 0부터 499번까지 카운트하면 다시 0으로
                cp_div_1000 = ~cp_div_1000;
            end
            else cnt_clk_source = cnt_clk_source + 1;
        end
    end // 이렇게 카운트가 짝수일 경우, 위와 같이 코딩하여 1bit 줄일 수 있다.
    
    // 비정규 clock이므로 동기화가 필요하다.
    edge_detector_n edg_div_1000(.clk(clk), .cp_in(cp_div_1000), .rst(reset_p), .n_edge(clk_div_1000)); /// 안 쓰는 출력은 빼버리면 된다.
endmodule

// min clock
module clock_min_proj(
    input clk, clk_sec, reset_p,
    output clk_min
    );

    // 60개 카운트하면 1s
    reg [5:0] cnt_sec;
    reg cp_min; // cp : clock pulse
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) cnt_sec = 0; // reset이 들어오면 cnt = 0
        else if(clk_sec) begin
            if (cnt_sec >= 29) begin
                cnt_sec = 0; // 0부터 번까지 카운트하면 다시 0으로
                cp_min = ~cp_min;
            end
            else cnt_sec = cnt_sec + 1;
        end
    end // 이렇게 카운트가 짝수일 경우, 위와 같이 코딩하여 1bit 줄일 수 있다.
    
    // 비정규 clock이므로 동기화가 필요하다.
    edge_detector_n edg_min(.clk(clk), .cp_in(cp_min), .rst(reset_p), .n_edge(clk_min)); /// 안 쓰는 출력은 빼버리면 된다.
    
endmodule


// hour clock
module clock_hour_proj(
    input clk, clk_min, reset_p,
    output clk_hour
    );

    // 60개 카운트하면 1s
    reg [5:0] cnt_min;
    reg cp_hour; // cp : clock pulse
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) cnt_min = 0; // reset이 들어오면 cnt = 0
        else if(clk_min) begin
            if (cnt_min >= 29) begin
                cnt_min = 0; // 0부터 번까지 카운트하면 다시 0으로
                cp_hour = ~cp_hour;
            end
            else cnt_min = cnt_min + 1;
        end
    end // 이렇게 카운트가 짝수일 경우, 위와 같이 코딩하여 1bit 줄일 수 있다.
    
    // 비정규 clock이므로 동기화가 필요하다.
    edge_detector_n edg_min(.clk(clk), .cp_in(cp_hour), .rst(reset_p), .n_edge(clk_hour)); /// 안 쓰는 출력은 빼버리면 된다.
    
endmodule


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// clock lib end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// counter begin
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Loadable_60bit_Down_Counter
module loadable_down_counter_dec_60_proj(
    input clk, reset_p,
    input clk_time,
    input load_enable, // user가 입력한 값을 받아오는 기능 추가 
    input [3:0] set_value1, set_value10, // 입력한 값
    output reg [3:0] dec1, dec10,
    output reg dec_clk // 다음 자리(예 : minute)에 신호(펄스)를 주기 위한 변수
    );
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin // 출력으로 나가는 것들이 리셋됨
            dec1 <= 0;
            dec10 <= 0;
            dec_clk <= 0;
        end
        // load_enable = 1이면, 입력된 값을 받아온다.
        else if(load_enable == 1) begin
            dec1 <= set_value1;
            dec10 <= set_value10;
        end
        else if(clk_time) begin // 카운팅에 적용한 clk_time = high가 되면 카운팅 시작
            if(dec1 == 0) begin
                dec1 <= 9;
                if(dec10 == 0) begin // 우리는 min과 sec 둘 다 구현하는 것이므로, min down counter에 신호를 넣어줘야 된다. 
                    dec10 <= 5;
                    dec_clk <= 1; // dec10, dec1 = 0, 0 이 되고 이후에 5, 9가 되면서 dec_clk 상승 펄스 발생
                end
                else dec10 <= dec10 - 1;
            end
            else dec1 <= dec1 - 1;
        end
        else dec_clk <= 0;
    end
endmodule



// Loadable_100bit_Down_Counter
module loadable_down_counter_dec_100_proj(
    input clk, reset_p,
    input clk_time,
    input load_enable, // user가 입력한 값을 받아오는 기능 추가 
    input [3:0] set_value1, set_value10, // 입력한 값
    output reg [3:0] dec1, dec10,
    output reg dec_clk // 다음 자리(예 : minute)에 신호(펄스)를 주기 위한 변수
    );
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin // 출력으로 나가는 것들이 리셋됨
            dec1 <= 0;
            dec10 <= 0;
            dec_clk <= 0;
        end
        // load_enable = 1이면, 입력된 값을 받아온다.
        else if(load_enable == 1) begin
            dec1 <= set_value1;
            dec10 <= set_value10;
        end
        else if(clk_time) begin // 카운팅에 적용한 clk_time = high가 되면 카운팅 시작
            if(dec1 == 0) begin
                dec1 <= 9;
                if(dec10 == 0) begin // 우리는 min과 sec 둘 다 구현하는 것이므로, min down counter에 신호를 넣어줘야 된다. 
                    dec10 <= 9;
                    dec_clk <= 1; // dec10, dec1 = 0, 0 이 되고 이후에 5, 9가 되면서 dec_clk 상승 펄스 발생
                end
                else dec10 <= dec10 - 1;
            end
            else dec1 <= dec1 - 1;
        end
        else dec_clk <= 0;
    end
endmodule


// 60bit_loadable_up_Counter
module loadable_up_counter_dec_60_proj(
    input clk, reset_p,
    input clk_time, load_enable,
    input [3:0] set_value1, set_value10,
    output reg [3:0] dec1, dec10
    );
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            dec1 = 0;
            dec10 = 0;
        end
        else if (load_enable) begin
            dec1 = set_value1;
            dec10 = set_value10;
        end
        else if(clk_time) begin
            if(dec1 >= 9) begin 
                dec1 <= 0;
                if(dec10 >= 5) dec10 = 0;
                else dec10 <= dec10 + 1;
            end
            else dec1 <= dec1 + 1;
        end
    end
endmodule


// 24bit_loadable_up_Counter
module loadable_up_counter_dec_24_proj(
    input clk, reset_p,
    input clk_time, load_enable,
    input [3:0] set_value1, set_value10,
    output reg [3:0] dec1, dec10
    );
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            dec1 = 0;
            dec10 = 0;
        end
        else if (load_enable) begin
            dec1 = set_value1;
            dec10 = set_value10;
        end
//        else if(clk_time) begin
//          if(dec1 > 4) begin
//            if(dec10 > 2) begin 
//                    dec1 = 0;
//                    dec10 = 0;
//             end
//             else begin
//                dec1 = dec1 + 1;
//             end
//          end
//          else if((dec10 < 2) && (dec1 >= 9)) begin
//            dec10 = dec10 + 1;
//            dec1 = 0;
//          end
//          else if((dec10 >= 2) && (dec1 < 4)) begin
            
//          end
          
//          else if((dec10 < 2) && (dec1 < 9)) begin
//              dec1 = dec1 + 1;
//          end
//        end
        else if(clk_time) begin
            if(dec10 >= 2) begin
                if(dec1 >= 3) begin
                    dec10 = 0;
                    dec1 = 0;
                end
                else begin
                    dec1 = dec1 + 1;
                end
            end
            else begin
                if(dec1 >= 9) begin
                    dec10 = dec10 + 1;
                    dec1 = 0;
                end
                else begin
                    dec1 = dec1 + 1;
                end
            end
        end
    end
endmodule


// 60bit_Counter
module counter_dec_60_stopwatch_proj(
    input clk, reset_p,
    input clk_time,
    output reg [3:0] dec1, dec10
    );
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            dec1 = 0;
            dec10 = 0;
        end
        else if(clk_time) begin
            if(dec1 >= 9) begin 
                dec1 <= 0;
                if(dec10 >= 5) dec10 = 0;
                else dec10 <= dec10 + 1;
            end
            else dec1 <= dec1 + 1;
        end
    end
endmodule


module bin_to_dec_stopwatch_proj( //// 12bit binary를 받아서 16bit decimal로 변환
    input [11:0] bin, 
    output reg [15:0] bcd /// 올림수가 하나만 나와도 4자리 다 읽어야 해서 vector : 16
);
    reg [3:0] i;
    
    always @(bin) begin //// FND 출력할 때 자주 써먹게 될 것임.
        bcd = 0;
        for (i=0 ; i<12 ; i=i+1) begin
            bcd = {bcd[14:0], bin[11-i]};  //// 쉬프트 연산을 결합연산자로 표현(회로가 더 간단해진다.)
                                           //// 좌로 1bit 쉬프트하고, 빈 자리에는 bin[11-i]를 넣어 준다.
            if ( i < 11 && bcd[3:0] > 4) bcd[3:0] = bcd[3:0] + 3;
            if ( i < 11 && bcd[7:4] > 4) bcd[7:4] = bcd[7:4] + 3;
            if ( i < 11 && bcd[11:8] > 4) bcd[11:8] = bcd[11:8] + 3;
            if ( i < 11 && bcd[15:12] > 4) bcd[15:12] = bcd[15:12] + 3;
        end
    end
endmodule


// 60bit_Counter
module counter_dec_60_proj(
    input clk, reset_p,
    input clk_time,
    output reg [3:0] dec1, dec10
    );
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            dec1 = 0;
            dec10 = 0;
        end
        else if(clk_time) begin
            if(dec1 >= 9) begin 
                dec1 <= 0;
                if(dec10 >= 5) dec10 = 0;
                else dec10 <= dec10 + 1;
            end
            else dec1 <= dec1 + 1;
        end
    end
endmodule


// 100bit_Counter
module counter_dec_100_proj(
    input clk, reset_p,
    input clk_time,
    output reg [3:0] dec1, dec10
    );
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            dec1 = 0;
            dec10 = 0;
        end
        else if(clk_time) begin
            if(dec1 >= 9) begin 
                dec1 = 0;
                if(dec10 >= 9) dec10 = 0;
                else dec10 = dec10 + 1;
            end
            else dec1 = dec1 + 1;
        end
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// counter end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Watch_Top_proj(
    input clk, reset_p,
    input [3:0] btn,
    output [15:0] value_watch
    );
    // 분주기 인스턴스
    wire clk_usec, clk_msec, clk_sec, clk_min;
    wire upcount_sec;
    clock_usec_proj usec_clk(.clk(clk), .reset_p(reset_p), .clk_usec(clk_usec));
    clock_div_1000_proj msec_clk(.clk(clk), .clk_source(clk_usec), .reset_p(reset_p), .clk_div_1000(clk_msec));
    clock_div_1000_proj sec_clk(.clk(clk), .clk_source(clk_msec), .reset_p(reset_p), .clk_div_1000(clk_sec));
    clock_min_proj min_clk(.clk(clk), .clk_sec(clk_sec), .reset_p(reset_p), .clk_min(clk_min));
    clock_hour_proj hour_clk(.clk(clk), .clk_min(upcount_min), .reset_p(reset_p), .clk_hour(clk_hour)); 
    
    // set mode select
    wire set_mode;
    assign upcount_min = set_mode ? incmin : clk_min;
    
    // btn
    button_cntr btn_cntr_setmode(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_set_pe)); // 버튼눌러도 시간 안 바뀌게 고정
    t_flip_flop_p tff_setmode(.clk(clk), .rst(reset_p), .t(btn_set_pe), .q(set_mode)); 
    button_cntr btn_incmin(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pe(incmin)); // sec+
    button_cntr btn_inchour(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(inchour)); // min+

    // Time set
    wire [3:0] min1, min10, hour1, hour10;
    wire [3:0] min1_set, min10_set, hour1_set, hour10_set; // 사용자 경험(UX)애 맞춰서 UI를 설계하는 것이 중요하다. -> min, sec 동작시키자.
    
    // time count 
    loadable_up_counter_dec_60_proj cnter_min(.clk(clk), .reset_p(reset_p), .clk_time(clk_min), .load_enable(btn_set_pe), 
                                         .set_value1(min1_set), .set_value10(min10_set), .dec1(min1), .dec10(min10)); // sec up_counter
    loadable_up_counter_dec_24_proj cnter_hour(.clk(clk), .reset_p(reset_p), .clk_time(clk_hour), .load_enable(btn_set_pe), 
                                          .set_value1(hour1_set), .set_value10(hour10_set), .dec1(hour1), .dec10(hour10)); // min up_counter
	
    // time set
    loadable_up_counter_dec_60_proj set_min(.clk(clk), .reset_p(reset_p), .clk_time(incmin), .load_enable(btn_set_pe),
                                       .set_value1(min1), .set_value10(min10), .dec1(min1_set), .dec10(min10_set)); // sec up_set
    loadable_up_counter_dec_24_proj set_hour(.clk(clk), .reset_p(reset_p), .clk_time(inchour), .load_enable(btn_set_pe),
                                        .set_value1(hour1), .set_value10(hour10), .dec1(hour1_set), .dec10(hour10_set)); // min up_set

	// cur_time / set_time 
        wire [15:0] cur_time, set_time;
        assign cur_time = {hour10, hour1, min10, min1};
        assign set_time = {hour10_set, hour1_set, min10_set, min1_set};
    
//   wire [15:0] value_;
        assign value_watch = set_mode ? set_time : cur_time;
        
//     FND_4digit_cntr fnd_cntr(.clk(clk), .rst(reset_p), .value(value_watch), .com(com), .seg_7(seg_7));  /// 컨트롤러가 분주기 가지고 있으니 그냥 clk준다.
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// watch end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// stop watch begin
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Stop_Watch_10ms_proj(
    input clk,
    input reset_p,
    input [3:0] btn, // 버튼 2개 쓸 것이므로
    output [15:0] value_stp_watch
//    output [3:0] com,
//    output [7:0] seg_7
);
    
    wire start_stop_input, start_stop, start_stop_btn;
    
//     // DFF를 위한 분주기
//     reg [16:0] clk_div;
//     always @(posedge clk) clk_div = clk_div + 1;
    
    // Start_stop 기능 구현 - usec과 연결
//   D_flip_flop_n debnc_60(.d(btn[1]), .clk(clk_div[16]), .rst(reset_p), .q(start_stop_input)); // 바운싱 제거용 DFF
//     edge_detector_n edg_start_stop(.clk(clk), .cp_in(start_stop_input), .rst(reset_p), .n_edge(start_stop_btn)); // Edga Detector
  	button_cntr btn_cntr_start_stop(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(start_stop_btn));
    t_flip_flop_p tff_start_stop(.clk(clk), .rst(reset_p), .t(start_stop_btn), .q(start_stop)); // start_stop 버튼 토글 기능 
  
    
    // Lap 기능 구현
    wire lap_input, lap_btn, lap;
//   D_flip_flop_n debnc_lap(.d(btn[2]), .clk(clk_div[16]), .rst(reset_p), .q(lap_input)); // 바운싱 제거용 DFF
//     edge_detector_n edg_lap(.clk(clk), .cp_in(lap_input), .rst(reset_p), .n_edge(lap_btn)); // Edga Detector
    button_cntr btn_cntr_lap(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(lap_btn));
    t_flip_flop_p tff_lap(.clk(clk), .rst(reset_p), .t(lap_btn), .q(lap)); // 토글을 위한 TFF
    
    // 분주기 인스턴스
    wire clk_usec, clk_msec, clk_sec;
    wire clk_start;
    assign clk_start = start_stop ? clk_usec : 0;
    clock_usec_proj usec_clk(.clk(clk), .reset_p(reset_p), .clk_usec(clk_usec));
    clock_div_1000_proj msec_clk(.clk(clk), .clk_source(clk_start), .reset_p(reset_p), .clk_div_1000(clk_msec));
    clock_div_1000_proj sec_clk(.clk(clk), .clk_source(clk_msec), .reset_p(reset_p), .clk_div_1000(clk_sec));
    clock_min_proj min_clk(.clk(clk), .clk_sec(clk_sec), .reset_p(reset_p), .clk_min(clk_min));
    
    reg [9:0] cnt_clk_msec;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) cnt_clk_msec = 0; // reset이 들어오면 cnt = 0
        else if(clk_msec) begin
            if (cnt_clk_msec >= 999) begin
                cnt_clk_msec = 0;
            end
            else cnt_clk_msec = cnt_clk_msec + 1;
        end
    end
    
    wire [15:0] msec_b2d;
    bin_to_dec_stopwatch_proj msec_clk_b2d(.bin({2'b00, cnt_clk_msec}), .bcd(msec_b2d));
    
    // 카운터 인스턴스
    wire [3:0] sec1, sec10; // sec1 : 1의자리, sec10 : 10의 자리
    counter_dec_60_stopwatch_proj cnt_60_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .dec1(sec1), .dec10(sec10)); // sec count
//    wire [3:0] min1, min10; // min1 : 1의자리, min10 : 10의 자리
//    counter_dec_60_stopwatch_proj cnt_60_min(.clk(clk), .reset_p(reset_p), .clk_time(clk_min), .dec1(min1), .dec10(min10)); // min count
    
    // Lap Value / value Select
    reg [15:0] lap_value;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) lap_value = 0;
        else if(lap_btn) // lap_btn 나올 때 저장
            lap_value = {sec10, sec1, msec_b2d[11:4]};
    end
    
    // lap 버튼에 따른 FND 출력
//   wire [15:0] value_stp_watch;
    assign value_stp_watch = lap ? lap_value : {sec10, sec1, msec_b2d[11:4]};
//     FND_4digit_cntr fnd_cntr(.clk(clk), .rst(reset_p), .value(value_stp_watch), .com(com), .seg_7(seg_7));  /// 컨트롤러가 분주기 가지고 있으니 그냥 clk준다.
    
//     // min을 LED_bar를 통하여 출력
//     always @(posedge clk, posedge reset_p) begin
//         if(reset_p) LED_bar = 0;
//         for (integer i = 0; i < 8; i = i + 1) begin
//             LED_bar[i] = (min1 >= i + 1) ? 1 : 0;
//         end
//     end
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// stop watch end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// cook timer begin
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module cook_timer_proj(
    input clk, reset_p,
    input [3:0] btn,
//    input btn_m,
    output [15:0] value_cook,
    output Alarm_LED
    );
    
    // button 
    wire start, incsec, incmin;
    wire timeout, alarm_start;
    wire t_start_stop;
//    or (t_start_stop, start, alarm_start); // Verilog에서 구조적 모델링 하지 마!!!!
    assign t_start_stop = start ? 1 : (alarm_start ? 1 : 0); // alarm이 발생하거나 start가 1일 때, t_start_stop = 1
    button_cntr btn_start_stop(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(start)); // start/stop
    t_flip_flop_p tff_start_stop(.clk(clk), .rst(reset_p), .t(t_start_stop), .q(start_stop)); // 버튼눌렀을 때, alarm 발생 시, start_stop 변수 토글
    button_cntr btn_incsec(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(incsec)); // sec+
    button_cntr btn_incmin(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pe(incmin)); // min+
    
    // Time Prescaler(clock Library)
    wire clk_usec, clk_msec, clk_sec;
    clock_usec_proj usec_clk(.clk(clk), .reset_p(reset_p), .clk_usec(clk_usec));
    clock_div_1000_proj msec_clk(.clk(clk), .clk_source(clk_usec), .reset_p(reset_p), .clk_div_1000(clk_msec));
    clock_div_1000_proj sec_clk(.clk(clk), .clk_source(clk_msec), .reset_p(reset_p), .clk_div_1000(clk_sec));
    clock_min_proj min_clk(.clk(clk), .clk_sec(clk_sec), .reset_p(reset_p), .clk_min(clk_min));
    
    // Time set
    wire [3:0] sec1_set, sec10_set; // 사용자 경험(UX)애 맞춰서 UI를 설계하는 것이 중요하다. -> min, sec 동작시키자.
    counter_dec_60_proj up_sec(.clk(clk), .reset_p(reset_p), .clk_time(incsec), .dec1(sec1_set), .dec10(sec10_set)); // sec up_counter
    wire [3:0] min1_set, min10_set;
    counter_dec_100_proj up_min(.clk(clk), .reset_p(reset_p), .clk_time(incmin), .dec1(min1_set), .dec10(min10_set)); // min up_counter
       
    // load_enable을 start_stop에 연결하면, start 시(start_stop = 1)계속해서 값을 불러와버린다.
    // 따라서 start_stop = 0일때만 1이 들어가도록 설계(start 변수의 참거짓에 따라 load_enable 변화하도록)
    wire clk_start, load_enable;
    wire dec_clk; // 다음 자리(예 : minute)에 신호(펄스)를 주기 위한 변수
    wire [3:0] sec1, sec10, min1, min10;
    assign clk_start = start_stop ? clk_sec : 0; // 대표적인 MUX 생성 방법
    assign load_enable = ~start_stop ? start : 0; // start_stop = 0 이면, start 변수 사용
    // load_enable에는 edge 한 번만 주어야 하므로 start 사용
    
    loadable_down_counter_dec_60_proj dc_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_start), .load_enable(load_enable), 
                                        .set_value1(sec1_set), .set_value10(sec10_set),
                                        .dec1(sec1), .dec10(sec10), .dec_clk(dec_clk));
    loadable_down_counter_dec_100_proj dc_min(.clk(clk), .reset_p(reset_p), .clk_time(dec_clk), .load_enable(load_enable), 
                                        .set_value1(min1_set), .set_value10(min10_set),
                                        .dec1(min1), .dec10(min10));                                    
    
    // Setting Time for FND
    reg [15:0] set_time;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) set_time = 0;
        else set_time = {min10_set, min1_set, sec10_set, sec1_set};
    end
    
    // Count Time for FND
    reg [15:0] count_time;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) count_time = 0;
        else count_time = {min10, min1, sec10, sec1};
    end
    
    // time = 0 도달 시,
//    wire timeout, alarm_start;  // 여기에 써도 오류는 안 난다.(Verilog의 코드는 병렬구조이기 때문에) 하지만 위에서 해당 변수를 사용하므로 위로 올리도록 하자.
    assign timeout = |count_time; // 뒤의 모든 비트를 OR 연산한 결과(베릴로그에서만 사용할 수 있는 문법)
    edge_detector_n edg_timeout(.clk(clk), .cp_in(timeout), .rst(reset_p), .n_edge(alarm_start)); // timeout 발생 시, alarm edge 발생
    
    // Alarm On/Off를 위한 기능
    wire alarm, alarm_off;
    assign alarm_off = |{btn, reset_p}; // 모든 버튼을 다 묶어버려서 넣어주면, 어떤 버튼을 눌러도 alarm이 다 리셋된다.
    t_flip_flop_p tff_alarm_on_off(.clk(clk), .rst(alarm_off), .t(alarm_start), .q(alarm));
    assign Alarm_LED = alarm;
    
//     wire [15:0] value_cook;
    assign value_cook = start_stop ? count_time : set_time;    
    
    //     FND_4digit_cntr fnd_cntr(.clk(clk), .rst(reset_p), .value(value_cook), .com(com), .seg_7(seg_7));  /// 컨트롤러가 분주기 가지고 있으니 그냥 clk준다.
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// cook timer end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////