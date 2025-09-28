`timescale 1ns/1ps

module tb_multi_flop_sync;
    reg async_data;
    reg dst_clk;
    reg rst_n;
    wire sync_data;

    // instantiate the unit under test
    multi_flop_sync uut (
        .async_data(async_data),
        .dst_clk(dst_clk),
        .rst_n(rst_n),
        .sync_data(sync_data)
    );

    // destination clock (period = 10ns)
    initial dst_clk = 0;
    always #5 dst_clk = ~dst_clk;

    initial begin
        async_data = 0;
        rst_n = 0;
        #20;              // hold reset low first
        rst_n = 1;

        // toggle async_data at irregular times
        #7  async_data = 1;
        #13 async_data = 0;
        #11 async_data = 1;
        #19 async_data = 0;
        #4  async_data = 1;
        #30 async_data = 0;

        // random-ish toggles
        repeat (10) begin
            #($urandom_range(3,15)) async_data = ~async_data;
        end

        #100 $finish;
    end
endmodule
