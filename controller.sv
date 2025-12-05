module controller #(parameter WIDTH = 16,
parameter INSTR_LEN = 20,
parameter ADDR = 5) (
input logic clk,
input logic reset,
input logic go,
input logic [INSTR_LEN-1:0] instruction,
input logic done,
output logic enable,
output logic [ADDR-1:0] pc,
output logic [3:0] opcode,
output logic [7:0] a, b,
output logic invalid_opcode
);

typedef enum logic [1:0] {
    IDLE,
    FETCH,
    DECODE,
    EXECUTE
} state_t;

state_t state, next_state;
logic [ADDR-1:0] pc_reg, next_pc;
logic is_alu_op, is_gcd_op, is_valid_op;
logic [3:0] current_opcode;

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        pc_reg <= '0;
    end else begin
        state <= next_state;
        pc_reg <= next_pc;
    end
end

always_comb begin
    automatic logic [3:0] current_opcode = instruction[19:16];
    next_state = state;
    next_pc = pc_reg;
    enable = 1'b0;
    opcode = 4'b0;
    a = 8'b0;
    b = 8'b0;
    invalid_opcode = 1'b0;
    is_alu_op = (current_opcode == 4'b0001) || (current_opcode == 4'b0010) || (current_opcode == 4'b0011);
    is_gcd_op = (current_opcode == 4'b1011);
    is_valid_op = is_alu_op || is_gcd_op;
    opcode = instruction[19:16]; 
    a = instruction[15:8];
    b = instruction[7:0];
    case(state)
        IDLE: begin
            if (go) begin
                next_state = FETCH;
                next_pc = '0;
            end
        end
        FETCH: begin
            next_state = DECODE;
        end
        DECODE: begin
            next_state = EXECUTE;
        end
        EXECUTE: begin
            enable = 1'b1;
            if (!is_valid_op) begin
                invalid_opcode = 1'b1;
            end
            if (done) begin
                next_state = FETCH;
                next_pc = pc_reg + 1;
            end else begin
                next_state = EXECUTE;
            end
        end
        default: begin
            next_state = IDLE;
        end
    endcase
    pc = pc_reg;
end
endmodule