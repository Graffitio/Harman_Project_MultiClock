`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/23 12:31:03
// Design Name: 
// Module Name: exam02_sequential_logic
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

module SR_latch(
    input R, S,
    output Q, Qbar
    );
    
    nor(Q, R, Qbar);  //// 따지고 보면 인스턴스 만든 것. ----> primitive gate는 인스턴스명을 생략할 수 있다.
    nor(Qbar, S, Q);  //// 시뮬레이션하면 발진 안 함. 왜?? 시뮬레이션은 이상적인 연산만 하기 때문에.
    
endmodule

module Gated_SR_latch( //// SR 플립플롭이라고도 부르는데, 아직은 FF가 아님.
                        //// edge trigering하면 FF, level trigering하면 LATCH
    input R, S, en,
    output Q, Qbar
    );
    
    wire and1_out, and2_out;
   
    and(and1_out, R, en);
    and(and2_out, S, en);
    nor(Q, and1_out, Qbar);
    nor(Qbar, and2_out, Q);
    
endmodule

module Gated_D_latch( //// 
    input D, en,
    output Q, Qbar
    );
    
    wire and1_out, and2_out, Dbar;
    
    not(Dbar, D);
    and(and1_out, Dbar, en);
    and(and2_out, D, en);
    nor(Q, and1_out, Qbar);
    nor(Qbar, and2_out, Q);
    
endmodule


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////LATCH 사용 금지////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////



module D_flip_flop_n(
    input d,
    input clk,rst,
    output reg q
);
    always @(negedge clk, posedge rst) begin /// edge trigering
        if(rst) q = 0; ///// FF는 리셋 기능이 꼭 있어야 한다.
        else q = d; 
    end
    
//    always @(clk) begin /// high level에서 동작하는 level-trigering ----> LATCH
//        if(clk) q = d;  /// FPGA 에서는 LATCH가 생기지 않도록 주의해야 하는 회로.
//        else q = q;     /// 중간 과정들을 거쳐서 나오기 때문에 pdt가 길어짐(타이밍 관리가 힘들다.)
//    end                 /// 요즘같이 고속 반도체가 나오는 시대에서 LATCH의 pdt는 감당 못 함
                          /// FF는 edge에서 동작하기 때문에 타이밍 문제가 없다.
endmodule

//  always @(clk) begin
//      in(clk) q = d;
//  end  //// vivado는 이 문장을 보고 LATCH를 만들어 버림
//       //// clk의 변화가 생기면 동작하는 건데, if (clk) 때문에 clk가 0이면 q값을 유지시킨다 ---> LATCH
         //// 그러므로 조합논리회로를 always를 이용해서 만들지 마라. LATCH가 생성된다.
         //// 그래도 써야 된다면, if문을 쓴다면 반드시 else만들어주고, case쓴다면 경우의수를 다 쓰거나 default를 꼭 써주던가 해야 된다.
         //// 골치아프니까 그냥 쓰지 마. 
         
module D_flip_flop_p(
    input d,
    input clk, rst,
    output reg q
);
    always @(posedge clk, posedge rst) begin /// edge trigering
        if(rst) q = 0;
        else q = d; 
    end
endmodule

module t_flip_flop_n( ///// 저렇게 만들지 않을 것이다. FPGA 안에는 DFF만 들어있다.(LUT마다 뒤에 DFF 하나씩 붙어있는 구조)
    input clk,        ///// 결국 DFF로 다른 FF를 만들어야 한다.
    input rst, /// active high - rst, active low --- rstn
    output reg q
//    output reg q = 0 //----> 이렇게 만들면, 시뮬레이션할 때만 초기화됨.
);
//    wire d;
//    assign d = ~q;
    
//    always@(posedge clk) begin
//        q = d;

//    reg temp = 0; /// reg 초기화는 시뮬레이션할 때만 쓴다.
//                 /// wire는 사용하지 마라. 0을 줘버리면 접지에 연결해버린다.
    always@(negedge clk, posedge rst) begin //// 
        if(rst) q = 0;
        else q = ~q; //// d = ~q 이니까 이렇게 단축 가능
    end
endmodule

module t_flip_flop_p(
    input clk, rst,
    input t, /// t = cp_in으로 보면 됨.
    output reg q
);

    always@(posedge clk, posedge rst) begin
        if(rst) q=0;
        else if (t) q = ~q;
              else q = q;  //// 사실 FF(순차논리회로)에서는 굳이 안써줘도 됨. 어짜피 값을 유지하기 때문에.
                            //// 조합논리회로에서는 꼭 써줘야 한다. 안 해주면 LATCH가 만들어짐.
    end
endmodule


module up_counter_async(
    input clk, rst,
    output [3:0] count
);
    t_flip_flop_n T0(.clk(clk), .rst(rst), .q(count[0]));
    t_flip_flop_n T1(.clk(count[0]), .rst(rst), .q(count[1]));
    t_flip_flop_n T2(.clk(count[1]), .rst(rst), .q(count[2]));
    t_flip_flop_n T3(.clk(count[2]), .rst(rst), .q(count[3]));

endmodule


module down_counter_async(
    input clk, rst,
    output [3:0] count
);
    t_flip_flop_p T0(.clk(clk), .rst(rst), .q(count[0])); //// 하위 bit가 0->1 이 될 때, 다음 bit 토글 ===> posedge일 때, 출력이 토글
    t_flip_flop_p T1(.clk(count[0]), .rst(rst), .q(count[1]));
    t_flip_flop_p T2(.clk(count[1]), .rst(rst), .q(count[2]));
    t_flip_flop_p T3(.clk(count[2]), .rst(rst), .q(count[3]));

endmodule


module up_counter_sync( //// 동기식 업카운터
    input clk, rst,
    output reg [3:0] count
);
    always @(posedge clk, posedge rst) begin //// 동작적 모델링으로 해주면 알아서 만들어줌.
        if(rst) count = 0; //// 초기값 지정을 필수, 안 해주면 z 출력
        else count = count + 1;
    end       

endmodule

module down_counter_sync( //// 동기식 다운카운터
    input clk, rst,
    output reg [3:0] count
);
    always @(posedge clk, posedge rst) begin //// 동작적 모델링으로 해주면 알아서 만들어줌.
        if(rst) count = 0; //// 초기값 지정을 필수, 안 해주면 z 출력
        else count = count - 1;
    end       

endmodule

module up_down_counter_sync(
    input clk, rst,
    input up_down,   ///// up_down = 1이면, up_counter
    output reg [3:0] count
);
    always @ (posedge clk, posedge rst) begin
        if(rst) count = 0; //// 항상 리셋이 우선이 되어야 한다.
        else if (up_down) count = count + 1;
        else count = count - 1;
    end
endmodule


module up_counter_sync_BCD( //// 동기식 10진 업카운터(0~9)
    input clk, rst,
    output reg [3:0] count
);
    always @(posedge clk, posedge rst) begin
        if(rst) count = 0; 
        else begin
            if(count >= 9) count = 0; //// =이라 안 쓰고 >=라고 한 이유 : 하드웨어는 9를 건너뛸 수도 있기 때문에(에러의 가능성을 배제)
            else count = count + 1;
        end
    end       
endmodule


module up_down_counter_sync_BCD( //// 동기식 10진 업다운카운터(0~9)
    input clk, rst, up_down,
    output reg [3:0] count
);
    always @(posedge clk, posedge rst) begin
        if(rst) count = 0; 
        else begin
            if(up_down) begin
                if(count >= 9) count = 0; //// 0~9까지이므로 9 넘어가면 다시 0으로 리셋
                else count = count + 1;
            end
            else begin
                if(count == 0) count = 9; //// 0~9까지이므로 0이되면 다시 9부터 시작
                else count = count - 1;
            end
        end
    end       
endmodule


//=============================================================================================================//
////////////////////////////////////////////////counter 활용/////////////////////////////////////////////////////
//=============================================================================================================//


module ring_count_fnd(  //// 라운드 로그인 방식
    input clk,
    output [3:0] com
);
    reg [3:0] temp; //// 초기값을 정해줘야 하므로 temp 선언
    
    always @ (posedge clk) begin /// FND가 common anode type
        if(temp != 4'b1110 && temp != 4'b1101 && temp != 4'b1011 && temp != 4'b0111) temp = 4'b1110; // 
                                 /// rst 누르면, count = 0은 맞아, 왜 com까지 0000이 되는 거지?
                                 /// 만약 common cathod type일 경우에는 rst 누르면 com = 4'b1111이 되어야 하는데 이건 어떻게 코딩?
                                 /// 초기값은 1110 
                                 /// 0줬을 때 켜지는 FND는 4'b1110
        else if (temp == 4'b0111) temp = 4'b1110; //// 0111 되면 1110로 돌아와라
              else temp = {temp[2:0], 1'b1}; /// 결합연산자 이용하여 좌시프트
    end //// 1110 1101 1011 0111 을 반복하는 링카운터 
    
//    always @ (posedge clk) begin /// FND가 common cathode type일 경우.
//        if(rst) com = 4b'1111;
//        else if (com != 4'b0001 && com != 4'b0010 && com != 4'b0100 && com != 4'b1000) com = 4'b0001;
//            else if (com == 4'b1000) com = 4'b0001;
//                  else com = {com[2:0], 1'b0};
//    end
    
    assign com = temp; //// temp를 다시 com이라는 출력에 연결시켜준다.
endmodule


module up_down_counter_Nbit #(parameter N = 4)( //// Nbit 업다운 카운터 
    input clk, rst, up_down,
    output reg [N-1:0] count
);

    always @(posedge clk, posedge rst) begin
        if(rst) count = 0; 
        else begin
            if(up_down)
                count = count + 1;
            else 
                count = count - 1;
        end
    end       
endmodule


module edge_detector_n( /// falling edge detector ./// 2bit짜리 쉬프트 레지스터(SI-PO)
    input clk, cp_in, rst, /// cp : clock pulse
    output p_edge, n_edge /// 아주 짧은 펄스 하나를 내보냄.
);
    reg cp_in_old, cp_in_cur;
    
    always @ (negedge clk, posedge rst) begin
        if(rst) begin
             cp_in_old = 0;
             cp_in_cur = 0;
        end
        else begin
            cp_in_old <= cp_in_cur; /// <= : 대입 연산자(=과 유사한 기능) non-blocking 값이 들어가는 순서가 있을 때는 무조건 non-blocking
            cp_in_cur <= cp_in;     /// 순차논리회로에서는 non-blocking을 무조건 쓰는 것이 안전하다.
                                    /// 조합논리회로(level triggering)에서는 무조건 blocking
                                    /// 블록 내에 한 줄일때는 아무거나 써도 상관없어.
        end
    end
    
    assign p_edge = ~cp_in_old & cp_in_cur; //// cp_old는 아직 0이니까 반전
    assign n_edge = cp_in_old & ~cp_in_cur; //// cp_cur는 먼저 0이 되었으므로 반전시켜줌

endmodule

//=============================================================================================================//
////////////////////////////////////////////////   Register   ///////////////////////////////////////////////////
//=============================================================================================================//


//module shift_register_SISO_s( /// SISO register 구조적 모델링
//    input clk, rst, d,
//    output q
//);
////    wire w1, w2, w3;  // 이렇게 wire 선언해줘도 된다.
//    wire [2:0] w;
//    D_flip_flop_n SS1(.d(d), .clk(clk), .rst(rst), .q(w[2]));
//    D_flip_flop_n SS2(.d(w[2]), .clk(clk), .rst(rst), .q(w[1]));
//    D_flip_flop_n SS3(.d(w[1]), .clk(clk), .rst(rst), .q(w[0]));
//    D_flip_flop_n SS4(.d(w[0]), .clk(clk), .rst(rst), .q(q));

//endmodule /// 구조적 모델링은 안 쓸 거야.

module shift_register_SISO_b_n( /// SISO register 동작적 모델링
    input clk, rst, d,
    output reg q
);    
    reg [3:0] siso;    
//    always@(negedge clk, posedge rst) begin /// 이렇게 만들면 안 된다~
////        if(rst) siso = 0;
////        else begin
////            siso[3] = d;                        /// blocking으로 만들면 안돼
////            siso[2] = siso[3];                  /// 4bit가 다 1이 되어버린다.
////            siso[1] = siso[2];
////            siso[0] = siso[1];
////            q = siso[0];
////        end
////    end    
     always@(negedge clk, posedge rst) begin 
        if(rst) siso = 0;
        else begin
            siso[3] <= d;
            siso[2] <= siso[3];
            siso[1] <= siso[2];
            siso[0] <= siso[1];
            q = siso[0];
        end
    end    
endmodule


module shift_register_PISO( /// 병렬 입력 - 직렬 출력
    input clk, rst, w_piso, /// 입력은 w(write), 출력은 r(read)로 쓴다.
    input [3:0] d,
    output q
);
    reg [3:0] data;
    
    always @ (posedge clk, posedge rst) begin
        if(rst) data = 0;
        else if(w_piso) data = {1'b0, data[3:1]}; //// 클락마다 병렬로 입력된 것이 한 bit씩 출력된다.
             else data = d;
    end
    
    assign q = data[0];

endmodule


module shift_register_SIPO_s( /// 직렬 입력-병렬 출력 
    input clk, rst, d, r_en,
    output [3:0] q
);
    wire [3:0] shift_register;
    D_flip_flop_n SP1(.d(d), .clk(clk), .rst(rst), .q(shift_register[3]));
    D_flip_flop_n SP2(.d(shift_register[3]), .clk(clk), .rst(rst), .q(shift_register[2]));
    D_flip_flop_n SP3(.d(shift_register[2]), .clk(clk), .rst(rst), .q(shift_register[1]));
    D_flip_flop_n SP4(.d(shift_register[1]), .clk(clk), .rst(rst), .q(shift_register[0]));
    
    bufif0 (q[0], shift_register[0], ~r_en); /// bufif : 3-state buffer
    bufif0 (q[1], shift_register[1], ~r_en); /// r_en = 0일때, q[] = shift_register[]
    bufif0 (q[2], shift_register[2], ~r_en); /// bufif0 (출력, 입력, 제어신호)
    bufif0 (q[3], shift_register[3], ~r_en);

endmodule


module shift_register_SIPO_h(
    input d, clk, rst, r_en,
    output [3:0] q
);
    reg [3:0] register;
    always@(negedge clk or posedge rst) begin
        if(rst) register <= 0;
        else register <= {d,register[3:1]}; //// 하나씩 밀고 최상위비트부터 받는 시프트 레지스터
    end
    assign q = (r_en) ? register : 4'bzzzz; //// r_en = 1, register 출력, 아니면 z
endmodule




module shift_register_PIPO #(parameter N=8)(//// 병렬입력 - 병렬출력 reg ---> 이걸 그냥 레지스터라고 부른다.
     input [N-1:0] d,
     input clk, rst, w_en, r_en,
     output q
);
    reg [N-1:0] register;
    always@(posedge clk, posedge rst) begin
        if(rst) register = 0;
        else if(w_en) register = d; /// 4bit짜리 4bit로 받음(PI)
            else register = register; 
    end
    
    assign q = r_en ? register : 'bz;
     /// 4bit짜리 4bit로 출력함.(PO)
     /// 'bz : 몇 bit가 되던 z로 다 채워지니 괜찮음.

endmodule




module shift_register( /// 범용 시프트 레지스터
    input clk, rst, shift, load, sin, /// sin : serial input
    input [7:0] data_in, /// data_in : parallel input
    output reg [7:0] data_out
);
    
    always@(posedge clk, posedge rst) begin
        if(rst) data_out = 0;
        else if(shift) data_out = {sin, data_out[7:1]}; /// 직렬입력받아서 시프트하고 출력
             else if(load) data_out = data_in; /// 
                  else data_out = data_out;
     end
endmodule


module sram_8bit_1024( /// 1kbyte static 메모리(reg 이어 붙인 것을 static memory라고 한다.)
                       /// address(select bit)가 10bit(2^10이니까)
    input clk, w_en, r_en, /// 메모리는 리셋하지 않으므로 rst 없다.
    input [9:0] addr,
    inout [7:0] data/// inout : 인풋도 되고 아웃풋도 되고 만능
);

    reg [7:0] mem [0:1023]; //// 0~1023까지의 array
    always @(posedge clk)
        if(w_en) mem[addr] <= data; /// else이면 그냥 유지
                                    /// 0번 메모리에 접근하는 것은 mem[0],
                                    /// 여기서 []는 bit가 아닌, 배열을 의미한다.

    assign data = r_en ? mem[addr] : 8'bz; /// w_en / r_en 평소에는 0으로 유지하고 있다가 필요할 때만 1 줘서 씀.
    
endmodule