IP Timer Project

Introduction  
This project is an IP Timer design using Verilog HDL.  
The IP follows the APB bus interface standard, making it easy to integrate into SoC systems.  

System Architecture  

Main modules in the design:  
- APB  
  - APB bus interface.  
  - Handles read/write operations from CPU/SoC.  

- Register  
  - Stores configuration values written via APB.  
  - Includes: `div_val`, `timer_en`, `interrupt_en`, etc.  

- Counter 
  - The main counter, running based on clock and divider value.  

- Control_Counter  
  - Controls counter behavior (start, stop, reset).  

- Interrupt  
  - Generates interrupt signal when timer reaches the programmed value.  

---

Key Features

64-bit up-counter with continuous counting.

12-bit APB slave interface (addressable registers).

APB bus access:

Standard level: 32-bit transfer only, no wait states, no error handling.

Advanced level: supports wait state (1 cycle), error handling, byte access, and halt mode in debug state.

Active-low asynchronous reset.

Configurable counting modes:

Default mode: counter increments with system clock.

Control mode: counter speed controlled by div_val (division up to 256).

Timer enable/disable via control register.

Interrupt support:

Hardware, maskable, level-triggered interrupt.

Generated when counter value matches compare value.

Interrupt can be enabled/disabled and cleared via registers.

Debug support (Advanced level only): halt counter when dbg_mode is active and halt request is set.




