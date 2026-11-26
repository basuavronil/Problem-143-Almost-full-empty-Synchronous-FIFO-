<img width="570" height="99" alt="image" src="https://github.com/user-attachments/assets/c2165f66-c10f-4907-b560-4356875e4aa0" />

<img width="608" height="127" alt="image" src="https://github.com/user-attachments/assets/105dfacc-3280-452e-a748-a95029efe3aa" />

<img width="476" height="206" alt="image" src="https://github.com/user-attachments/assets/248a7663-a1e9-493b-8a83-5e92cfd85fa8" />

# Implementation & Post-Route Analysis (`xc7a12ticsg325-1L`)

* **Project Name:** `Almost_EF_Sync_FIFO`
* **Top Module:** `sync_fifo`
* **Product Family:** Xilinx Artix-7 (Low-Power `-1L` Speed Grade)
* **Target Part:** `xc7a12ticsg325-1L`
* **Target Language:** Verilog

---

## 1. Timing Analysis (Post-Route STA)

All user-specified timing constraints are met with zero failing endpoints across Setup, Hold, and Pulse Width checks:

| Timing Check | Metric | Value | Status / Notes |
| :--- | :--- | :--- | :--- |
| **Setup** | **Worst Negative Slack (WNS)** | **`+5.584 ns`** | Met ($\text{WNS} \ge 0\text{ ns}$) |
| **Setup** | Total Negative Slack (TNS) | `0.000 ns` | `0` failing endpoints (out of `164`) |
| **Hold** | **Worst Hold Slack (WHS)** | **`+0.236 ns`** | Met ($\text{WHS} \ge 0\text{ ns}$) |
| **Hold** | Total Hold Slack (THS) | `0.000 ns` | `0` failing endpoints (out of `164`) |
| **Pulse Width** | **Worst Pulse Width Slack (WPWS)** | **`+4.500 ns`** | Met ($\text{WPWS} \ge 0\text{ ns}$) |
| **Pulse Width** | Total Pulse Width Negative Slack (TPWS) | `0.000 ns` | `0` failing endpoints (out of `147`) |

### Maximum Operating Frequency ($F_{\max}$)
* Assuming a **10.000 ns** (`100 MHz`) target clock constraint (consistent with $\text{WPWS} = 4.500\text{ ns}$):
  $$T_{\min} = T_{\text{target}} - \text{WNS} = 10.000\text{ ns} - 5.584\text{ ns} = 4.416\text{ ns}$$
  $$F_{\max} = \frac{1}{4.416\text{ ns}} \approx \mathbf{226.45\text{ MHz}}$$

---

## 2. Power Analysis (Post-Implementation)

Power estimation derived from the post-implementation netlist under typical process conditions:

| Power Category | Power (W) | Share (%) | Breakdown / Notes |
| :--- | :--- | :--- | :--- |
| **Total On-Chip Power** | **0.065 W** | **100%** | Junction Temp: **25.3 °C** \| Thermal Margin: **74.7 °C (14.1 W)** |
| **Device Static Power** | **0.059 W** | **90%** | Transistor leakage and baseline IP bias current (`-1L` low-power silicon) |
| **Dynamic Power** | **0.006 W** | **10%** | Active switching power across clocks, signals, logic, and I/O |
| ↳ *I/O* | *0.005 W* | *75% of Dynamic* | External pin switching and load capacitance across 24 bonded IOBs |
| ↳ *Clocks* | *0.001 W* | *9% of Dynamic* | Global clock tree distribution (`BUFGCTRL`) |
| ↳ *Signals* | *0.001 W* | *9% of Dynamic* | Interconnect / routing net transitions |
| ↳ *Logic* | *<0.001 W* | *7% of Dynamic* | LUT and flip-flop switching |

> **Engineering Takeaway:** Because `sync_fifo` is a compact datapath module occupying under 1.3% of the fabric, **90% (0.059 W)** of total on-chip power is baseline static power, while active dynamic switching consumes just **0.006 W** (driven primarily by external I/O pin transitions).

---

## 3. Resource Utilization

Post-implementation utilization for `sync_fifo` on the `xc7a12ticsg325-1L` device:

| Resource | Used | Available (`xc7a12t`) | Utilization (%) |
| :--- | :--- | :--- | :--- |
| **Slice LUTs** | `75` | `8,000` | **0.94%** |
| ↳ *LUT as Logic* | `75` | `8,000` | **0.94%** |
| **Slice Registers (Flip-Flops)** | `146` | `16,000` | **0.91%** |
| **Occupied Slices** | `47` | `3,650` | **1.29%** |
| **Bonded IOBs** | `24` | `150` | **16.00%** |
| **BUFGCTRL (Global Clock Buffers)** | `1` | `32` | **3.13%** |
