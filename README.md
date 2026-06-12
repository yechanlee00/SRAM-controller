# SRAM Controller

SRAM is a static SRAM, a volatile memory in which information is lost when the computer's power is cut off.  
Unlike DRAM, it does not require a refresh process and is a storage circuit capable of faster memory input/output due to its FET-based operation.  
However, it has the disadvantage of low integration density and requiring a continuous power supply because it generally has a structure of 6T or more.  
This code implements an SRAM Controller in Verilog to control such SRAM.  

---

## Pin Discription

The input/output ports of the SRAM controller are as shown in the photo below.
<img width="1149" height="478" alt="Image" src="https://github.com/user-attachments/assets/b9aa0c60-1ae8-44bf-8e61-22d8ed4b83a9" />

| Port Name | Description |
|---|---|
| `clk` | Clock signal |
| `rst_n` | Active-low reset signal |
| `addr` | SRAM address signal used by the CPU for read or write operations |
| `data_in` | Data that the CPU wants to write to SRAM |
| `data_out` | Data that the CPU reads from SRAM |
| `rd_req` | CPU read request signal for reading data from SRAM |
| `wr_req` | CPU write request signal for writing data to SRAM |
| `ready` | Signal indicating whether the SRAM controller has completed its operation and is ready to receive a new request |
| `sram_addr` | SRAM access address, connected to `addr` |
| `sram_data_out` | Data to be written to SRAM, connected to `data_in` |
| `sram_data_in` | Data read from SRAM, connected to `data_out` |
| `sram_ce_n` | SRAM chip enable signal; connects to SRAM only during read or write operations |
| `sram_we_n` | Signal that determines the SRAM operation according to `wr_req` or `rd_req` |

---

## Detailed Conditions

### Read

When `rd_req` is 1, the controller must output the data corresponding to the SRAM address matching the `addr` input to `data_out`, and also output the `ready` signal.

### Write

When `wr_req` is 1, the controller must write the value of `data_in` to the SRAM address specified by `addr`.

### SRAM write

Data is written at the same clock cycle as the `sram_ce_n` signal.

### SRAM read

Data becomes valid one clock cycle after the `sram_ce_n` signal changes from `1 → 0`.

---
## Simulation Result
<img width="1607" height="384" alt="Image" src="https://github.com/user-attachments/assets/4111018b-c8e1-4b72-a6cb-8d6da2180812" />
