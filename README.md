# UART Transmitter in SystemVerilog

**Author:** Krishnav Gaur  

---

## Overview
This project is a synthesizable **UART (Universal Asynchronous Receiver-Transmitter) Transmitter** implemented in SystemVerilog, designed for deployment on an FPGA running on a **100 MHz internal clock**. It supports dynamic baud rate selection and configurable parity checking.

---

## Features
- **Configurable Baud Rates:** Choose dynamically from 5 standard baud rates:
  - 9600
  - 19200
  - 38400
  - 115200 *(Default)*
  - 921600
- **Programmable Parity:** Supports optional Even Parity checking via a dedicated control flag.
- **2 block FSM Architecture:** Separate combinational and sequential logic.
- **Handshake Signaling:** Clear tx start and tx done handshake signals.

---

## Controller & Integration Guidelines
If you are designing an external host controller to drive this UART transmitter, keep the following timing and protocol rules in mind:

1. **Configuration Setup:** The controller must set the baude mode and parity mode inputs first.
2. **Setup Delay:** Allow at least 10 x clk val clock cycles for the selected baud rate counter to settle before changing tx data.
3. **Input Stability:** The controller **must ensure** that tx data, baude mode, and parity mode remain completely stable and are **not driven or changed during an active transmission** (while transmission is underway).

---

## Future Project Ideas
- **UART Host Controller:** Design and implement a controller to automatically feed data and manage inputs for this transmitter with AMBA write protocols.
- **UART Receiver:** Build a matching oversampling receiver module to poll the line, synchronize clocks, check parity, and recover received bytes.
