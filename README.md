# D Flip-Flop UVM Verification Environment

A robust, reusable verification environment built using **SystemVerilog** and **UVM (Universal Verification Methodology)** to functionally validate a synthesizable **D Flip-Flop** digital design under multiple stimulus conditions.

---

## Architecture & Components

The verification environment follows standard UVM layered architecture to ensure modularity and stimulus reuse:

* **Transaction (`transaction`):** Defines the data payload (inputs `d`, `clk`, `reset`) and transaction-level properties.
* **Sequences (`uvm_sequence`):** Includes dedicated stimulus generators for different test scenarios:
  * **Reset Sequence:** Validates asynchronous reset (active high) behavior and ensures the output correctly drives to 0 (q) and 1 (q_bar).
  * **Data Sequence:** Drives randomized and directed data patterns (`d` inputs) across clock edges to verify normal latching and storage functionality.
* **Sequencer:** Routes transactions from sequences to the driver.
* **Driver (`driver`):** Pin-level driver that converts transactions into physical signals and applies them to the DUT interface.
* **Monitors:** Divided into two distinct functional blocks to capture signals at both boundaries:
  * **Input Monitor:** Samples interface signals on the driver side to observe stimulus being applied to the DUT.
  * **Output Monitor:** Samples interface signals on the output side to capture actual DUT response behavior.
* **Agent (`agent`):** Encapsulates the sequencer, driver, and monitors into a cohesive unit.
* **Scoreboard (`scoreboard`):** Compares DUT output behavior (collected via the output monitor) against the input itself to verify correctness across both reset and active data cycles.
* **Environment (`env`):** Top-level container integrating the agent and scoreboard.
* **Test (`test`):** Instantiates the environment and kicks off verification sequences.

---

## Directory Structure

```text
D_flip_flop/
├── D_FF.srcs/          # RTL source files and UVM testbench components
├── D_FF.xpr            # Project file
└── README.md           # Project documentation
