# The Fundamental Basics

## What is Metastability?

## Analog Simulation with Parasitics

### Magic VLSI Physical Layout
Here we first implement the D-latch in Magic in order to create our two flip-flops. Since we are using a positively edge triggered flip flop the master D flip-flop should be transparent when clock is low and we want the slave D flip-flop to be opaque when clock is high (reversing these two gets a negatively edge triggered flip flop. For those who don't know why, drawing the waveforms from the two D-latches is a simple but intuitive exercise). 
<p align="center">
    <img src="./Images/DLatchMagicLayout.png" />
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
    <img src="./Images/DLatchSimulation.png" />
    <br>
    <em>This looks correct!</em>
</p>

By extension we can now create a positive edge-triggered D flip-flop using two of those latches that we just made and two inverters (technically you can get away with using just one inverter for the master D-latch):
<p align="center">
    <img src="./Images/DFFMagicLayout.png" />
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
    <img src="./Images/DFFWaveform.png" />
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
    <img src="./Images/GoodWaveform.png" />
    <em>
        Q is sampled correctly with the input D as D changes before the rising edge of the clock.
        Admittedly it is a bit sharp of a curve but the output stays above 3V.
    </em>
</p>

Here's the waveform when setup time **is** violated (< 0.78ns):
<p align="center">
    <img src="./Images/BadWaveform.png" />
    <em>Q is completely wrong here and stays low when it should be high. 😱 </em>
</p>

In most cases, setup/hold time violations only result in corrupted
bits, not metastability. 

## MBTF Calculations

## Timing Theory
