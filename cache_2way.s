module cache_2way #(
    parameter int ADDR_W = 32,
    parameter int CAPACITY_BYTES = 256,
    parameter int LINE_BYTES = 8,
    parameter int WAYS = 2
)(
    input  logic                 clk,
    input  logic                 rst_n,

    input  logic                 req_valid,
    input  logic                 req_write,
    input  logic [ADDR_W-1:0]    req_addr,
    input  logic [31:0]          req_wdata,
    output logic [31:0]          resp_rdata,
    output logic                 resp_valid,
    output logic                 hit,

    output logic                 mem_valid,
    output logic                 mem_write,
    output logic [ADDR_W-1:0]    mem_addr,
    output logic [63:0]          mem_wdata,
    input  logic [63:0]          mem_rdata,
    input  logic                 mem_ready
);

    localparam int SETS = CAPACITY_BYTES / (LINE_BYTES * WAYS);
    localparam int OFFSET_BITS = $clog2(LINE_BYTES);
    localparam int INDEX_BITS = $clog2(SETS);
    localparam int TAG_BITS = ADDR_W - OFFSET_BITS - INDEX_BITS;

    logic [63:0] data [0:SETS-1][0:WAYS-1];
    logic [TAG_BITS-1:0] tag [0:SETS-1][0:WAYS-1];
    logic valid [0:SETS-1][0:WAYS-1];
    logic dirty [0:SETS-1][0:WAYS-1];
    logic lru [0:SETS-1];

    logic [INDEX_BITS-1:0] set_idx;
    logic [TAG_BITS-1:0] req_tag;
    logic [OFFSET_BITS-1:0] byte_off;
    logic way_hit0, way_hit1;

    integer i,j;

    assign byte_off = req_addr[OFFSET_BITS-1:0];
    assign set_idx  = req_addr[OFFSET_BITS +: INDEX_BITS];
    assign req_tag  = req_addr[ADDR_W-1 -: TAG_BITS];

    always_comb begin
        way_hit0 = valid[set_idx][0] && (tag[set_idx][0] == req_tag);
        way_hit1 = valid[set_idx][1] && (tag[set_idx][1] == req_tag);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            resp_rdata <= 32'd0;
            resp_valid <= 1'b0;
            hit        <= 1'b0;
            mem_valid  <= 1'b0;
            mem_write  <= 1'b0;
            mem_addr   <= '0;
            mem_wdata  <= '0;

            for (i=0; i<SETS; i=i+1) begin
                lru[i] <= 1'b0;
                for (j=0; j<WAYS; j=j+1) begin
                    valid[i][j] <= 1'b0;
                    dirty[i][j] <= 1'b0;
                    tag[i][j]   <= '0;
                    data[i][j]  <= '0;
                end
            end
        end else begin
            resp_valid <= 1'b0;
            mem_valid  <= 1'b0;

            if (req_valid) begin
                if (way_hit0 || way_hit1) begin
                    hit        <= 1'b1;
                    resp_valid <= 1'b1;

                    if (way_hit0) begin
                        resp_rdata <= req_write ? req_wdata : data[set_idx][0][byte_off*8 +: 32];
                        if (req_write) begin
                            data[set_idx][0][byte_off*8 +: 32] <= req_wdata;
                            dirty[set_idx][0] <= 1'b1;
                        end
                        lru[set_idx] <= 1'b1;
                    end else begin
                        resp_rdata <= req_write ? req_wdata : data[set_idx][1][byte_off*8 +: 32];
                        if (req_write) begin
                            data[set_idx][1][byte_off*8 +: 32] <= req_wdata;
                            dirty[set_idx][1] <= 1'b1;
                        end
                        lru[set_idx] <= 1'b0;
                    end
                end else begin
                    hit       <= 1'b0;
                    mem_valid <= 1'b1;
                    mem_write <= 1'b0;
                    mem_addr  <= {req_addr[ADDR_W-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};

                    if (mem_ready) begin
                        if (!valid[set_idx][lru[set_idx]]) begin
                            valid[set_idx][lru[set_idx]] <= 1'b1;
                        end

                        data[set_idx][lru[set_idx]]  <= mem_rdata;
                        tag[set_idx][lru[set_idx]]   <= req_tag;
                        dirty[set_idx][lru[set_idx]] <= 1'b0;

                        if (!req_write)
                            resp_rdata <= mem_rdata[byte_off*8 +: 32];
                        else begin
                            data[set_idx][lru[set_idx]][byte_off*8 +: 32] <= req_wdata;
                            dirty[set_idx][lru[set_idx]] <= 1'b1;
                            resp_rdata <= req_wdata;
                        end

                        resp_valid <= 1'b1;
                        lru[set_idx] <= ~lru[set_idx];
                    end
                end
            end
        end
    end
endmodule
