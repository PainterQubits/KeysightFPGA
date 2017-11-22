# KeysightFPGA
These codes help in reading data using custom FPGA codes uploaded on Keysight Digitizer M3102A. Currently, the only code there to use is the IQ Demodulator code which would demodulate intermediate frequency readout signal to DC giving out just two numbers, I and Q, which can be used to get the Phase and Amplitude of the pulse.

## Usage

```jl
Pkg.clone("https://github.com/PainterQubits/KeysightFPGA")
using KeysightFPGA
```
