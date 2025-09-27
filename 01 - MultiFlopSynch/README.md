# Multi-Flop Synchronizers

## Preface

## Circuit Schematic

## Verilog Implementation (Behavioral)
```Verilog
`timescale 1ns / 1ps

// creating a simple two flop synchronizer

module multi_flop_sync (
    input  wire async_data,    // asynchronous input
    input  wire dst_clk,       // destination clock domain
    input  wire rst_n,         // active low rst     
    output wire sync_data      
);

    // two flip-flops for synchronization
    reg sync_ff1;
    reg sync_ff2;
    
    // flops clocked by destination domain clock
  always @(posedge dst_clk or negedge rst_n) begin
    if (!rst_n) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end else begin
            sync_ff1 <= async_data;  // first flip flop can go metastable here
            sync_ff2 <= sync_ff1;    // takes an additional clock cycle to propagate
        end
    end
    
    assign sync_data = sync_ff2;

endmodule
```
## Simulation Waveform
