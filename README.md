# Low-Power 17-Tap Symmetric FIR Filter (Verilog + MATLAB)

A 17-tap linear-phase low-pass FIR filter in Verilog, designed to reduce hardware
(and therefore power) through **coefficient symmetry** and a **3-stage pipeline**.
A MATLAB model checks the filter on a noisy signal and studies reduced-precision
coefficients. Implemented with Xilinx ISE 14.7 on an Artix-7 `xc7a100t-3csg324`.

**Author:** Pradhyumna D Rao  
**Project started:** 16 April 2026 (filter coefficients and MATLAB model). RTL and ISE project: 28 April 2026. Verification, bug fix and results: November 2026.

## Contents
1. [Design overview](#design-overview)
2. [Architecture](#architecture)
3. [Repository layout](#repository-layout)
4. [Verification](#verification)
5. [How to run](#how-to-run)
6. [Results](#results)
7. [Limitations](#limitations)
8. [Authorship and AI assistance](#authorship-and-ai-assistance)
9. [License](#license)

## Design overview

| Item | Value |
|---|---|
| Taps | 17, symmetric (`h[n] = h[16-n]`), linear phase |
| Coefficients | Q8 integers: `-1 -1 -2 0 7 19 34 47 52 47 34 19 7 0 -2 -1 -1` |
| DC gain | 258/256 (about 1.008) |
| Input / output | 16-bit signed in, 32-bit signed out |
| Latency | 3 clock cycles |
| Output scaling | None. Shift `y_out` right by 8 (divide by 256) to get unity gain |
| Target | Xilinx Artix-7 `xc7a100t-3csg324`, ISE 14.7 |

Power-oriented techniques:

| Technique | Effect |
|---|---|
| Symmetric folding | Input samples sharing a coefficient are added first, so **8 multipliers instead of 17** |
| Zero coefficient (`h3 = 0`) | Its multiplier is dropped |
| 3-stage pipeline | Pre-add, multiply, accumulate in separate stages: shorter critical path |
| Reduced-precision study (MATLAB) | Coefficients rounded to 1/64 steps to see the accuracy cost of cheaper hardware |

## Architecture

```
x_in -> [x1] -> [x2] -> ... -> [x16]          (16-sample delay line)

Stage 1 (pre-add)    s0 = x_in + x16     s4 = x4 + x12
                     s1 = x1  + x15      s5 = x5 + x11
                     s2 = x2  + x14      s6 = x6 + x10
                     s3 = x3  + x13      s7 = x7 + x9      s8 = x8
Stage 2 (multiply)   m_k = s_k * h_k      (k = 0..8, no m3 since h3 = 0)
Stage 3 (accumulate) y_out = m0 + m1 + m2 + m4 + m5 + m6 + m7 + m8
```

## Repository layout

```
LowPowerVLSI/
  fir_filter_17tap_pipeline3.v   RTL
  tb.v                           author's original random-stimulus testbench (waveform viewing)
  tb_selfcheck.v                 verification layer added with AI help: self-checking PASS/FAIL testbench
  LowPowerVLSI.xise              ISE 14.7 project
matlab/
  Low_power_FIR.m                filter model, noisy-signal demo, low-power comparison
  h_values.txt                   coefficient list
```

## Verification

- `tb_selfcheck.v` drives an impulse followed by 360 pseudo-random samples and compares
  `y_out` with a behavioural 17-tap convolution using the same integer coefficients.
  Result: **PASS, 400 samples match** (Icarus Verilog).
- The impulse response of the RTL reproduces the coefficient list exactly, delayed by the
  pipeline latency.
- `matlab/Low_power_FIR.m` uses the same coefficients and checks its pipeline model against
  `filter()` (difference about 4e-16).

## How to run

### A. Self-checking simulation (Icarus Verilog)
```sh
cd LowPowerVLSI
iverilog -o sim fir_filter_17tap_pipeline3.v tb_selfcheck.v
vvp sim
# PASS: 400 samples match the golden 17-tap response
```

### B. Waveforms in ISE 14.7 (ISim)
1. Open `LowPowerVLSI/LowPowerVLSI.xise` in Project Navigator (File, Open Project).
2. In the Design panel set **View** to **Simulation** and select `tb`.
3. In Processes expand **ISim Simulator** and double-click **Simulate Behavioral Model**.
4. In ISim click **Zoom to Full View**. Right-click `y_out` and `x_in`, choose
   **Radix, Signed Decimal**.

### C. Synthesis and place-and-route
1. Set **View** to **Implementation** and select `fir_filter_17tap_pipeline3`.
2. Double-click **Synthesize - XST**, then **Implement Design**.
3. Read the **Design Summary** for utilization and the post-PAR timing report for the
   minimum clock period.

### D. Power estimate (XPower Analyzer)
1. In Processes expand **Implement Design, Place & Route** and double-click
   **Analyze Power Distribution (XPower Analyzer)**.
2. Keep the default activity rates (12.5% toggle on flip-flops, I/O and DSP).
3. Under **By Clock Domain** set the `clk` frequency to **100 MHz**.
4. Run **Tools, Update Power Analysis** and read the **Summary** view.

### E. MATLAB model
Run `matlab/Low_power_FIR.m`. It filters a 500 Hz plus 1.2 kHz signal corrupted with
Gaussian noise (fixed seed, so runs repeat) and a 3 kHz tone, then plots the input, the
normal output, the reduced-precision output and the error between them.
The "power" it prints is output signal energy and is only a relative reference. It is not
a hardware power figure, and rounding the coefficients also shifts the DC gain
(258/256 to 67/64), so compare error or SNR rather than that number.

## Results

Post place-and-route, ISE 14.7, `xc7a100t-3csg324`, default "Balanced" strategy.

### Resource utilization

| Resource | Used | Available |
|---|---|---|
| Slice registers | 327 | 126,800 (1%) |
| Slice LUTs | 178 (138 logic, 16 shift-register, 24 route-thru) | 63,400 (1%) |
| Occupied slices | 85 | 15,850 (1%) |
| DSP48E1 | 5 | 240 (2%) |
| Bonded IOBs | 49 | 210 (23%) |
| BUFG | 1 | 32 (3%) |

All signals routed, no errors.

### Timing

| Metric | Value |
|---|---|
| Minimum clock period (post-PAR) | 9.439 ns |
| Maximum clock frequency | about 105.9 MHz |
| Max clock-to-output delay | 8.435 ns (`y_out<31>`) |

No clock constraint was set, so this is the unconstrained post-PAR figure.

### Power estimate (XPower Analyzer, vectorless)

Conditions: `clk` = 100 MHz, default activity rates (12.5% toggle), 25 C ambient,
5 pF output load. No simulation activity file was used, so this is a rough estimate.

| Component | Power (W) |
|---|---|
| Clocks | 0.003 |
| Logic | 0.002 |
| Signals | 0.002 |
| DSP48E1 | 0.004 |
| I/O | 0.025 |
| **Dynamic total** | **0.036** |
| Device leakage (static) | 0.082 |
| **Total** | **0.119** |

XPower confidence level: **Low overall**.

| Input | Confidence | Reason |
|---|---|---|
| Design implementation state | High | Completely routed |
| Clock nodes activity | High | User-specified clock |
| I/O nodes activity | Low | More than 75% of inputs have no user-specified activity |
| Internal nodes activity | Medium | Less than 25% of internal nodes specified |
| Device models | High | Production silicon models |

Junction temperature about 25.5 C. Core dynamic power (clocks, logic, signals, DSPs) is
about 11 mW. The I/O share comes from the 49 pins of the standalone module driving 5 pF
and would not appear when the filter is embedded in a larger design. Leakage is a
property of the device and is the same for any design on this part.

## Limitations

- Power numbers are estimates with default activity, not measured values. A
  post-place-and-route simulation (VCD or SAIF) would improve accuracy.
- No baseline comparison against a direct-form 17-multiplier version has been made yet,
  so the power saving from symmetry folding is argued from the multiplier count (8 vs 17),
  not measured.
- Coefficients are fixed (Q8). Changing them means editing the parameters in the RTL.
- The output is not rescaled and has no overflow or saturation handling beyond the
  32-bit width.

## Authorship and AI assistance

**Original work (April 2026), by Pradhyumna D Rao, without AI:** the filter design and
coefficients, the MATLAB model, the Verilog RTL, the testbench and the ISE project.

**Work done on 23-24 November 2026 with AI assistance (Claude, by Anthropic):**
- Review of the project, which found a bug in the original RTL: the symmetric pre-adders
  paired the wrong samples, so the filter did not match the intended 17-tap response.
  The fix (pairing `x_in` with `x16`, `x1` with `x15`, and so on) was made with AI help.
- A verification layer added on top of the author's original testbench (`tb.v`): the
  self-checking testbench `tb_selfcheck.v`, which compares the RTL with a golden convolution.
- Revisions to `matlab/Low_power_FIR.m`: original H values, fixed random seed, corrected
  pipeline block.
- This README, the `.gitignore` and the MIT `LICENSE` text.

The synthesis, place-and-route, simulation and XPower runs were done by the author in
ISE 14.7, and the figures in the Results section come from those runs. The git history
dates match the original file dates for the April work and the real dates for the
November changes.

## License

MIT. See [LICENSE](LICENSE). Copyright (c) 2026 Pradhyumna D Rao.
