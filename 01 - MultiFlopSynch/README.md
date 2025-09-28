# Multi-Flop Synchronizers

## Preface
Multi-flop synchronizers are the most common approach to addressing metastability in clock domain crossings. The premise is to use
two (sometimes more) D flip-flops to chain the asynchronous input and synchronize it to the new clock domain. The inherent issue 
with asynchronous inputs is that it could come at any time; this is fundamentally problematic if a change in the asynchronous input
happens within the setup or hold time of a D flip-flop. When this happens, the output of the D flip-flop can be unpredictable, leading
to failure in larger integrated systems. We cannot prevent an asynchronous input from being sampled within the setup/hold time, but we 
can reduce the effect of them.

## Circuit Schematic

## Verilog Implementation (Behavioral)

Here's the HDL implementation of a double flop synchronizer using Verilog:

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
## Testbench 

## Simulation Waveform

## Drawbacks
