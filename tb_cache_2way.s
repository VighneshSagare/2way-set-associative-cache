module tb_cache_2way;
    logic clk=0, rst_n=0;
    logic req_valid, req_write;
    logic [31:0] req_addr, req_wdata, resp_rdata;
    logic resp_valid, hit, mem_valid, mem_write, mem_ready;
    logic [31:0] mem_addr;
    logic [63:0] mem_wdata, mem_rdata;

    cache_2way dut(.*);

    always #5 clk=~clk;

    initial begin
        req_valid=0; req_write=0; req_addr=0; req_wdata=0;
        mem_ready=0; mem_rdata=64'h1122334455667788;
        repeat(2) @(posedge clk);
        rst_n=1;

        // First access: miss, memory supplies a line.
        @(negedge clk);
        req_addr=32'h0000_0040; req_valid=1;
        @(negedge clk);
        mem_ready=1;
        @(negedge clk);
        mem_ready=0; req_valid=0;

        // Same line: should hit.
        @(negedge clk);
        req_addr=32'h0000_0044; req_valid=1;
        @(negedge clk);
        req_valid=0;

        repeat(3) @(posedge clk);
        $display("Cache test completed. Last read data = %h", resp_rdata);
        $finish;
    end
endmodule
