# VHDL Sensor Data Filter with Outlier Handling

This repository contains the VHDL source code and documentation for a digital logic module designed for the "Logic Networks" course (Prof. Fabio Salice, 2023/2024). The project implements a robust system for filtering sensor data, handling outliers, and managing data credibility over time.

## Project Overview

In sensor systems, ensuring data integrity is crucial. This project addresses this by creating a hardware module that processes data from a sensor that outputs values between 1 and 255. Any value outside this range, or a zero, is considered an "outlier" or invalid reading.

The core functionality of the module is to intelligently manage these anomalies through a substitution mechanism governed by a "credibility" score.

### Key Features

1.  **Outlier Filtering**: The system identifies invalid sensor readings (values of 0).
2.  **Data Substitution**: When an invalid value is detected, it is replaced with the last known valid value.
3.  **Credibility Mechanism**: A "credibility" score is associated with each substituted value.
    -   Initially, the credibility is at its maximum (31).
    -   For each consecutive invalid reading, the credibility of the substituted value decreases by 1.
    -   If a new valid reading is received, the credibility is reset to its maximum.
    -   If the credibility score reaches zero, it remains at zero, indicating a complete loss of confidence in the substituted data.

This approach provides not just data filtering but an intelligent, stateful handling of data anomalies, preventing stale data from being trusted indefinitely.

## Architecture

The system is designed using a standard hardware design methodology, separating the logic into a **Datapath** and a controlling **Finite State Machine (FSM)** of the Moore type.

### 1. Datapath

The datapath is responsible for all data manipulation and storage. It is composed of several interconnected sub-circuits, including:
-   **Input Acquisition**: Registers and logic to capture and store incoming sensor data (`data_register`) and the last valid data (`prev_data_register`).
-   **Credibility Logic**: A register (`credibility_register`) and a decrementer to manage the credibility score.
-   **Address Management**: An address register (`add_register`) and an incrementer to handle writing data and its corresponding credibility to memory locations.
-   **Control Logic**: Multiplexers (MUX) to route data based on control signals from the FSM.

### 2. Finite State Machine (FSM)

A Moore-type FSM orchestrates the entire process, ensuring deterministic and precise transitions between different operational phases. The FSM cycles through states to handle initialization, data reading, processing, and writing back to memory.

**Key States:**
-   **S0 (Idle)**: Waits for the `i_start` signal.
-   **S1 (Initialization)**: Loads initial parameters, such as the starting memory address and the total number of data points to process (`k`).
-   **S3-S4 (Read Cycle)**: Reads a data word from memory.
-   **S5 (Process)**:
    -   Checks if the data word is zero (invalid).
    -   Updates the `prev_data_register` if the word is valid.
    -   Calculates the new credibility score.
    -   Writes the processed data (either the original or the substituted value) to memory.
-   **S6 (Write Credibility)**: Writes the associated credibility score to the next memory address.
-   **S2 (Next Address)**: Increments the memory address to process the next data word.
-   **S7 (Done)**: The final state, reached after all `k` data points have been processed.

## Experimental Results & Verification

The module was extensively tested and simulated to verify its correctness, especially in corner cases.

-   **Synthesis Report**: The design was synthesized for an FPGA, achieving a **maximum operating frequency of approximately 205 MHz** (with a slack of 15.137 ns on a 20 ns clock period). The implementation utilizes **54 flip-flops** and **105 Look-Up Tables (LUTs)**.
-   **Simulations**:
    -   **K=0**: Correctly handles cases with no data to process.
    -   **Asynchronous Reset**: Verified that a reset signal correctly returns the FSM to the initial state at any point during execution.
    -   **Multiple Consecutive Runs**: The module can handle back-to-back processing requests without requiring a reset.
    -   **Credibility Saturation**: Confirmed that the credibility score correctly decrements to zero and does not underflow.

The results demonstrate that the design is robust, functionally correct, and efficient from a timing perspective.
