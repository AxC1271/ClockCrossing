# Clock Domain Crossing Techniques

## Abstract
This GitHub repository explores the concept of clock domain crossing using different techniques, from multi-flop synchronizers to 
asychronous FIFOs and handshaking. Each subdirectory will come with a schematic of the synchronizer, block diagrams Verilog code, physical
layout on Magic VLSI, and SPICE directives that can capture parasitics and be simulated on ngspice. This repo not only aims
to explain the process as a way to teach myself but also provide educational content to a reader interested in knowing about clock domain crossing.

## A Critical Problem in Digital Circuit Design
Modern digital systems contain multiple clock domains—processors, memory interfaces, peripherals, and I/O all running at different frequencies. When signals cross between these domains, metastability can occur: a flip-flop enters an undefined state, potentially causing:
- ❌ Data corruption
- ❌ System crashes
- ❌ Unpredictable behavior
- ❌ Silicon respins costing millions

Clock Domain Crossing bugs are:

- Difficult to debug (non-deterministic, timing-dependent)
- Catastrophic when they occur in production
- Preventable with proper synchronization techniques

This repository teaches you how to design CDC circuits correctly and verify them thoroughly.

## Different Types of Synchronizers

### Multi-Flop Synchronizers

### Toggle Synchronizers

### Multiplexer Synchronizers (Mux Recirculation)

### Pulse Synchronizers

### Gray Code Counters

### Asynchronous FIFOs

### Handshaking

## Why do I need to know this?

---

I hope you find this repository helpful!
