# Multi-Flop Synchronizers

## Preface
Multi-flop synchronizers are the most common approach to addressing metastability in clock domain crossings. The premise is to use
two (sometimes more) D flip-flops to chain the asynchronous input and synchronize it to the new clock domain. The inherent issue 
with asynchronous inputs is that it could come at any time; this is fundamentally problematic if a change in the asynchronous input
happens within the setup or hold time of a D flip-flop. When this happens, the output of the D flip-flop can be unpredictable, leading
to failure in larger integrated systems. We cannot prevent an asynchronous input from being sampled within the setup/hold time, but we 
can reduce the effect of them by allowing the metastable signal to resolve itself before we sample and use it.

## Circuit Schematic
<p align="center">
    <img src="./TwoFlopSynch.png" />
</p>

The first flip flop is run on some source clock, whereas the last two flip flops are clocked using the destination clock. Output Q from
the first flip flop is sampled onto the first flop, where it could run the risk of metastability. It takes at least two clock cycles for the
metastable signal to propagate to the second flop, which should be resolved by then.

## Verilog Implementation (Behavioral)

Here's the HDL implementation of a double flop synchronizer using Verilog:

```Verilog
`timescale 1ns / 1ps

// creating a simple two flop synchronizer

module multi_flop (
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
We're using a testbench with random signals to verify for correctness and see if the pulse is synchronized to the new clock domain:
```Verilog
`timescale 1ns/1ps

module tb_multi_flop();
    reg async_data;
    reg dst_clk;
    reg rst_n;
    wire sync_data;

    // instantiate the unit under test
    multi_flop uut (
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
```

Unfortunately, metastability will not be visible under a simulator and we will need to resort to either physical or analog simulations
to visually see the metastability phenomenon happen in the synchronizer (particularly the waveform output of the first flip flop in the
synchronizer).

## Analog Simulation with Parasitics

### Magic VLSI Physical Layout
Here we first implement the D-latch in Magic in order to create our two flip-flops. Since we are using a positively edge triggered flip flop the master D flip-flop should be transparent when clock is low and we want the slave D flip-flop to be opaque when clock is high (reversing these two gets a negatively edge triggered flip flop. For those who don't know why, drawing the waveforms from the two D-latches is a simple but intuitive exercise). 
<p align="center">
    <img src="./DLatchMagicLayout.png" />
    <br>
    <em>Figure 1: Layout of a D latch with NAND gates.</em>
</p>

### SPICE Directive/Simulations (ngspice)
First we will create the SPICE directive of the D-latch and verify that it works. Quick note: the specific CMOS technology I'm using in Magic is the AMI 0.5µm CMOS node.
```SPICE
Vin_d d 0 PULSE(0 3.3 1n 0.1n 0.1n 10n 20n)
Vin_en en 0 PULSE(0 3.3 0n 0.1n 0.1n 40n 80n)

.tran 0.1n 200n
.control
run
plot d
plot en
plot Q
plot Q_not
.endc

.end
```
Let's now look at the waveform and verify that it indeed works as a D-latch before we make our D flip-flop. 

<p align="center">
    <img src="./DLatchSimulation.png" />
    <br>
    <em>This looks correct!</em>
</p>

By extension we can now create a positive edge-triggered D flip-flop using two of those latches that we just made and two inverters (technically you can get away with using just one inverter for the master D-latch):
<p align="center">
    <img src="./DFFMagicLayout.png" />
    <br>
    <em>D Flip-Flop Layout.</em>
</p>

Here's the SPICE level simulation of that layout using this SPICE directive:
```SPICE
* clock: 3 pulses, 150ns period, 60ns high / 90ns low
Vin_clk clk 0 PULSE(0 3.3 0n 0.1n 0.1n 60n 150n)

* d starts HIGH, then goes LOW at 30ns (while clock is HIGH!)
Vin_d d_latch_0/d 0 PULSE(3.3 0 30n 0.1n 0.1n 400n 1000n)

* transient simulation
.tran 0.1n 400n

.control
run
plot clk
plot v(d_latch_0/d) 
plot v(d_latch_1/q) 
plot v(d_latch_1/q_not) 
.endc

.end
```
Here's the waveform to see the flip flop output being driven by the edge of the clock, not the logic level. Notice that D
changes while the clock is high but Q does not change as it only samples during the rising edge.
<p align="center">
    <img src="./DFFWaveform.png" />
    <br>
    <em>These waveforms are beautiful. 😍</em>
</p>

### Setup and Hold Times of D flip-flop

Doing some playing around for the setup time, I was able to identify `0.78ns` as the bare minimum setup time needed
between the D input toggling and the clock transitionining in order for the flip flop to sample correctly. Note that setup
time is the time that D must be stable before the rising clock edge. Here's the spice directive:

```SPICE
* visual setup time test
.param tsetup=0.77n

Vin_clk clk 0 PULSE(0 3.3 100n 0.1n 0.1n 50n 500n)
Vin_d d_latch_0/d 0 PULSE(0 3.3 {100n-tsetup} 0.1n 0.1n 200n 500n)

.tran 0.01n 150n

.control
run
plot clk xlimit 90n 130n
plot v(d_latch_0/d) xlimit 90n 130n
plot v(d_latch_1/q) xlimit 90n 130n
.endc
```

Here's the waveform when setup time is not violated (>= 0.78ns):
<p align="center">
    <img src="./GoodWaveform.png" />
    <em>Q is sampled correctly with the input D as D changes before the rising edge of the clock.</em>
</p>

Here's the waveform when setup time **is** violated (< 0.78ns):
<p align="center">
    <img src="./BadWaveform.png" />
    <em>Q is completely wrong here and stays low when it should be high. 😱 </em>
</p>

This is the core issue that we are trying to solve! Let's see how we can fix this with a double flop synchronizer now.

## Advantages/Disadvantages
A multi-flop synchronizer sounds like an easy solution to solving metastability issues; adding an additional flop to the end of the first flop statistically allows for enough time for the metastable signal to settle before being sampled again by the second flip flop, only requiring an additional clock cycle. It's very simple to implement, very inexpensive in FPGA fabric (due to only using 2 flip flops), and has predictable latency. However, there are drawbacks as well:
- Only works for single bits; in multi-bit buses different bits may resolve at different times, which could lead to race conditions. Usually a different technique like handshaking is used instead.
- Metastability isn't fully resolved; while the chance of the second flip flop is exponentially lower than the first flip flop, it is still theoretically possible. With this said, it is extremely cheap and reliable enough for most applications.
- Short pulses or back-to-back transitions can be lost since flop synchronizers only guarantee safe transfer of signal levels, not event pulses.
- Additional latency: in critical ultra-low latency applications those additional two clock cycles that it takes for the signal to propagate can be detrimental.
