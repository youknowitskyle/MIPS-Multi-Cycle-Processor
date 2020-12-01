//-------------------------------------------------------
// Multicycle MIPS processor
//------------------------------------------------

module mips(input        clk, reset,
            output [31:0] adr, writedata,
            output        memwrite,
            input [31:0] readdata);

  wire        zero, pcen, irwrite, regwrite,
               alusrca, iord, memtoreg, regdst;
  wire [1:0]  alusrcb, pcsrc;
  wire [2:0]  alucontrol;
  wire [5:0]  op, funct;

  controller c(clk, reset, op, funct, zero,
               pcen, memwrite, irwrite, regwrite,
               alusrca, iord, memtoreg, regdst, 
               alusrcb, pcsrc, alucontrol);
  datapath dp(clk, reset, 
              pcen, irwrite, regwrite,
              alusrca, iord, memtoreg, regdst,
              alusrcb, pcsrc, alucontrol,
              op, funct, zero,
              adr, writedata, readdata);
endmodule

module controller(input       clk, reset,
                  input [5:0] op, funct,
                  input       zero,
                  output       pcen, memwrite, irwrite, regwrite,
                  output       alusrca, iord, memtoreg, regdst,
                  output [1:0] alusrcb, pcsrc,
                  output [2:0] alucontrol);

    wire pcwrite;
    wire branch;
    wire [1:0] aluop;
    wire [14:0] controlWord;

    assign pcen = (branch & zero) | pcwrite;

    reg [3:0] currentState;
    reg [3:0] nextState;

    always @(posedge clk) begin
      if (reset) begin
        currentState = 4'b0000;
      end else begin
        currentState = nextState;
      end
    end

    always @(op, currentState) begin
      if (currentState == 4'b0000) begin                // Fetch state
        nextState = 4'b0001;
      end else if (currentState == 4'b0001) begin       // Decode state
        case (op)
            6'b100011: nextState = 4'b0010;     // lw
            6'b101011: nextState = 4'b0010;     // sw
            6'b000000: nextState = 4'b0110;     // r-type
            6'b000100: nextState = 4'b1000;     // beq
            6'b001000: nextState = 4'b1001;     // addi
            6'b000010: nextState = 4'b1011;     // j
            default: nextState = 4'b0000;       // default to fetch state
        endcase
      end else if (currentState == 4'b0010) begin       // MemAdr state
        case (op)
            6'b100011: nextState = 4'b0011;     // lw
            6'b101011: nextState = 4'b0101;     // sw
            default: nextState = 4'b0000;       // default to fetch state
        endcase
      end else if (currentState == 4'b0011) begin       // MemRead state
        nextState = 4'b0100;
      end else if (currentState == 4'b0100) begin       // Mem Writeback state
        nextState = 4'b0000;
      end else if (currentState == 4'b0101) begin       // MemWrite state
        nextState = 4'b0000;
      end else if (currentState == 4'b0110) begin       // Execute state
        nextState = 4'b0111;
      end else if (currentState == 4'b0111) begin       // ALU Writeback state
        nextState = 4'b0000;
      end else if (currentState == 4'b1000) begin       // Branch state
        nextState = 4'b0000;
      end else if (currentState == 4'b1001) begin       // ADDI Execute state
        nextState = 4'b1010;
      end else if (currentState == 4'b1010) begin       // Addi Writeback state
        nextState = 4'b0000;
      end else if (currentState == 4'b1011) begin       // Jump state
        nextState = 4'b0000;
      end else begin
        nextState = 4'b0000;                            // default to Fetch state
      end       
    end


    // Control signal logic
    assign pcwrite = (currentState == 4'b0000 || currentState == 4'b1011) ? 1 : 0;
    assign memwrite = (currentState == 4'b0101) ? 1 : 0;
    assign irwrite = (currentState == 4'b0000) ? 1 : 0;
    assign regwrite = (currentState == 4'b0100 || currentState == 4'b0111 || currentState == 4'b1010) ? 1 : 0;
    assign alusrca = (currentState == 4'b0010 || currentState == 4'b0110 || currentState == 4'b1000 || currentState == 4'b1001) ? 1 : 0;
    assign branch = (currentState == 4'b1000) ? 1 : 0;
    assign iord = (currentState == 4'b0011 || currentState == 4'b0101) ? 1 : 0;
    assign memtoreg = (currentState == 4'b0100) ? 1 : 0;
    assign regdst = (currentState == 4'b0111) ? 1 : 0;
    assign alusrcb = (currentState == 4'b0110 || currentState == 4'b1000) ? 2'b00 :
            (currentState == 4'b0000) ? 2'b01 :
            (currentState == 4'b0010 || currentState == 4'b1001) ? 2'b10 : 
            (currentState == 4'b0001) ? 2'b11 : 2'b00;
    assign pcsrc = (currentState == 4'b0000) ? 2'b00 :
            (currentState == 4'b1000) ? 2'b01 : 
            (currentState == 4'b1011) ? 2'b10 : 2'b00;
    assign aluop = (currentState == 4'b0110) ? 2'b10 :
            (currentState == 4'b1000) ? 2'b01 : 2'b00;

    assign controlWord = {pcwrite, memwrite, irwrite, regwrite, alusrca, branch, iord, memtoreg, regdst, alusrcb, pcsrc, aluop};


    // ALU decoding logic
    assign alucontrol = (aluop == 2'b00) ? 3'b010 :     // add op code
            (aluop == 2'b01) ? 3'b110 :                  // sub op code
            (funct == 6'b100000) ? 3'b010 :             // add instr
            (funct == 6'b100010) ? 3'b110 :             // sub instr
            (funct == 6'b100100) ? 3'b000 :             // and instr
            (funct == 6'b100101) ? 3'b001 :             // or instr
                3'b111;                                 // slt instr

endmodule

module datapath(input        clk, reset,
                input        pcen, irwrite, regwrite,
                input        alusrca, iord, memtoreg, regdst,
                input [1:0]  alusrcb, pcsrc, 
                input [2:0]  alucontrol,
                output [5:0]  op, funct,
                output        zero,
                output [31:0] adr, writedata, 
                input [31:0] readdata);


    reg [32:0] pc;                                                   // declare all wire and reg variables
    reg [31:0] aluOut;
    reg [31:0] instr;
    reg [31:0] A;
    reg [31:0] B;
    reg [31:0] regFile [63:0];
    reg [31:0] data;
    wire [31:0] aluResult;
    wire [31:0] pcJump;
    wire [31:0] rd1;
    wire [31:0] rd2;
    wire [31:0] src_a;
    wire [31:0] src_b;
    wire [31:0] immExt;
    wire [27:0] jumpShift;

    assign adr = (iord) ? aluOut : pc;                              // set address to be pc or ALUOut depending on IorD

    assign jumpShift = instr[25:0] << 2;                            // PCJump logic
    assign pcJump = {{pc[31:28]}, jumpShift};

    always @(posedge clk) begin                                    // pc register logic
      if (reset) begin
        pc = 32'h00000000;
      end
      else begin
        if (pcen) begin
          case (pcsrc)
            2'b00: pc <= aluResult;
            2'b01: pc <= aluOut;
            2'b10: pc <= pcJump;
          endcase
        end
      end
    end

    always @(posedge clk) begin                                   // instr register logic
      if (irwrite) begin
        instr <= readdata;
      end
    end 

    assign op = instr[31:26];
    assign funct = instr[5:0];

    assign writedata = B;                                        // set WD = B register
    
    assign rd1 = (instr[25:21] == 0) ? 0 : regFile[instr[25:21]];   // set register file outputs
    assign rd2 = (instr[20:16] == 0) ? 0 : regFile[instr[20:16]];

    always @(posedge clk) begin                                     // set data register
        data = readdata;
    end

    always @(negedge clk) begin                                     // register file write logic
      if (regwrite == 1) begin
          if (regdst == 1) begin
            regFile[instr[15:11]] = memtoreg ? data : aluOut;
          end else begin
            regFile[instr[20:16]] = memtoreg ? data : aluOut;
          end
      end
    end



    always @(posedge clk) begin                                     // set A and B registers
      A = rd1;
      B = rd2;
    end

    assign immExt = {{16{instr[15]}}, instr[15:0]};                 // set sign extension value

    assign src_a = alusrca ? A : pc;                                // set inputs to alu

    assign src_b = (alusrcb == 2'b00) ? B :
        (alusrcb == 2'b01) ? 4 : 
            (alusrcb == 2'b10) ? immExt : immExt << 2;

    ALU alu (                                                     // instantiate alu module
        .a (src_a),
        .b (src_b),
        .f (alucontrol),
        .y (aluResult),
        .zero (zero)
    );

    always @(posedge clk) begin                                     // ALUOut register
      aluOut = aluResult;
    end

endmodule
