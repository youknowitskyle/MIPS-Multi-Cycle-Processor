module tb;

	reg clk;
	reg reset;
    wire [31:0] writedata;
    wire [31:0] adr;
    wire memwrite;

	top top(.clk(clk), .reset(reset), .writedata(writedata), .adr(adr), .memwrite(memwrite));

	initial
		forever #5 clk=~clk;

	initial begin
	    clk=0;
	    reset=1;

	    #10 reset=0;

	    #1000 $finish;
	end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top);
    end

endmodule