# Transformer Attention Mechanism - Hardware Implementation

## 📋 Project Overview

This project implements a simplified version of the transformer attention mechanism in hardware using Verilog. The design computes the attention mechanism through matrix operations: **W = Q × K^T** and **O = W × V**, where Q, K, and V are 8×8 matrices representing Query, Key, and Value matrices respectively.

## 🎯 Features

- **Hardware-accelerated Attention Computation**: Efficient matrix multiplication using Chipware components
- **8×8 Matrix Support**: Processes three input matrices (Q, K, V) to produce attention output
- **Pipelined Architecture**: Optimized for throughput with systematic data flow
- **Low-Power Design**: Includes power optimization synthesis and Cadence low power IP(intellectual property) for energy efficiency
- **Comprehensive Testing**: Complete testbench with timing and latency verification

## 🏗️ Architecture

### System Function Diagram
```
Matrix Q (8×8) × Matrix K^T (8×8) = Matrix W (8×8)
Matrix W (8×8) × Matrix V (8×8) = Matrix O (8×8)
```

### Key Components
- **State Machine**: 5-state FSM controlling the computation flow
- **Memory Arrays**: Storage for Q, K, V, W, and O matrices
- **Multiplication Units**: 16 CW_mult instances for parallel computation
- **Control Logic**: Index management and timing control

## 📊 Specifications

| Signal | I/O | Width (bits) | Description |
|--------|-----|--------------|-------------|
| clk | Input | 1 | Clock signal |
| reset | Input | 1 | Reset signal (active-high asynchronous) |
| en | Input | 1 | Enable signal for matrix data input |
| MATRIX_Q | Input | 4 | Query data (unsigned) |
| MATRIX_K | Input | 4 | Key data (unsigned) |
| MATRIX_V | Input | 4 | Value data (unsigned) |
| done | Output | 1 | Computation completion signal |
| answer | Output | 18 | Final computation result |

## ⚡ Performance Requirements

- **Latency**: < 300 clock cycles
- **Clock Period**: 0.55 ns (1.82 GHz)
- **Data Input**: 64 cycles for matrix loading
- **Output**: 64 cycles for result transmission

## 🔄 State Machine

| State | Description |
|-------|-------------|
| s0 | Matrix loading (Q, K, V) |
| s1 | W = Q × K^T computation |
| s2 | O = W × V computation |
| s3 | Output generation |
| finish | Completion state |

## 📊 Detailed Power Analysis

### Synthesis Configuration
| Parameter | Description |
|-----------|-------------|
| **Technology** | N16ADFP | 16nm FinFET process |
| **Library** | StdCells0p72v125c_ccs | 0.72V supply, 125°C, CCS timing |
| **Clock Period** | 0.55 ns | 1.82 GHz target frequency |
| **Power Weight** | 0.1 | Leakage Power vs Dynamic power optimization trade-off |
| **Clock Gating** | Enabled | Automatic insertion for power reduction |

### Power Optimization Features
- ✅ **Discrete Clock Gating Logic**: Automatically inserted
- ✅ **Operand Isolation**: Reduces unnecessary switching
- ✅ **Power-Aware Mapping**: Cell selection based on power metrics
- ✅ **Leakage Optimization**: Controlled effort level
- ✅ **Activity-Based Analysis**: Uses switching activity from simulation
- ✅ **Low power IP**: Uses Cadenece low power multiplier

## 🚀 Prerequisites

- **Verilog Simulator**: NC-Verilog 15.20
- **Waveform Viewer**: nWave (Verdi_P-2019.06)
- **Synthesis Tools**: Genus 20.10

## 🧪 Verification and Testing

### RTL Result

![tb_result](https://github.com/user-attachments/assets/03954069-3cf1-4fe1-b21f-13608c3d41b1)

### Power Consumption Comparison

| Metric | Before Optimization | After RTL Optimization | After Low-Power Synthesis |
|--------|-------------------|----------------------|--------------------------|
| **Total Power (mW)** | 21.85 | 19.52 | 5.74 |
| **Internal Power (mW)** | 16.79 | 15.63 | 3.35 |
| **Switching Power (mW)** | 3.24 | 3.28 | 1.88 |
| **Leakage Power (mW)** | 1.82 | 0.61 | 0.51 |
| **Cell Count** | 7330 | 7429 | 7737 |
| **Cell Area (μm²)** | 5548.746 | 5573.163 | 5169.485 |

### Clock Gating Summary Report

#### Clock Gating Instances Summary

| Category | Number | % | Average Toggle Saving % |
|----------|--------|---|-------------------------|
| **Total Clock Gating Instances** | 202 | 100.00 | - |
| RC Clock Gating Instances | 202 | 100.00 | 98.15 |
| Non-RC Clock Gating Instances | 0 | 0.00 | 0.00 |

#### Flip-Flop Gating Analysis

| Category | Number | % | Average Toggle Saving % |
|----------|--------|---|-------------------------|
| **RC Gated Flip-flops** | 2832 | 99.82 | 97.76 |
| **Non-RC Gated Flip-flops** | 0 | 0.00 | 0.00 |
| **Total Gated Flip-flops** | 2832 | 99.82 | - |
| **Total Ungated Flip-flops** | 5 | 0.18 | - |
| **Enable not found** | 1 | 20.00 | - |
| **Register bank width too small** | 4 | 80.00 | - |
| **Total Flip-flops** | 2837 | 100.00 | - |

#### Multibit Flip-flop Summary

| Width | Number | Bits | RC Gated | Ungated |
|-------|--------|------|----------|---------|
| **1-bit** | 2837 | 2837 | 2832 (99.82%) | 5 (0.18%) |
