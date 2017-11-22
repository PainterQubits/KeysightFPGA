# KeysightFPGA
These codes help in reading data using custom FPGA codes uploaded on Keysight Digitizer M3102A. Currently, the only code there to use is the IQ Demodulator code which would demodulate intermediate frequency readout signal to DC giving out just two numbers, I and Q, which can be used to get the Phase and Amplitude of the pulse.

## Usage

```jl
Pkg.clone("https://github.com/PainterQubits/KeysightFPGA")
using KeysightFPGA
```
##Functions provided

###AWGFunctions

####function HowToConfigAWG(AWGs,dig)
AWGs    :   Array of AWG Instrument Objects [Fast AWG, Slow AWG].
dig     :   Digitizer Object.
Rchannels:  Channels of Fast AWG used for outputting readout pulse.
Mchannel :  Channel of Slow AWG used for outputting marker pulse.
Dchannels:   Channel Array which is receiving the readout signal.
ShowMessages: Shows printed instructions if set to 1.
This function should be sued before running the experiment to know the delay to be set to Marker Pulse
with respect to the Readout Pulse and a parameter called MBAT that would be used in prepFPGAIQ and
daq_readIQ functions.
In case you want to use this function in a script, it outputs the two values as MarkerDelay, MBAT.
Usage example: MarkerDelay, MBAT = HowToConfigAWG(AWGs,dig,Rchannels,Mchannel,Dchannels,0)
```jl
function HowToConfigAWG(AWGs::Vector{InsAWGM320XA}, dig::InsDigitizerM3102A, Rchannels::Array{Int64}=[1,2], Mchannel::Integer=4, Dchannels::Array{Int64}=[1,2],ShowMessages=1)
```

####function awg_configIQ(AWGs,Freq, Amp, Len, Phase,Rchannels,Mchannel)
AWGs    :   Array of AWG Instrument Objects [Fast AWG, Slow AWG].
Freq    :   Intermediate Frequency of readout pulse (in Hz).
Amp     :   Amplitude of readout pulse (in V).
Len     :   Length of readout pulse (in s).
Phase   :   Phase of readout pulse (in radians)
EMD     :   Exact Matching Delay. (in ticks of 10 ns)
Rchannels:  Channels of Fast AWG used for outputting readout pulse.
Mchannel :  Channel of Slow AWG used for outputting marker pulse.
This function configures the selected Fast AWG for sending readout pulse and configures the selected Slow AWG for sending marker pulse appropriately.
```jl
function awg_configIQ(AWGs::Vector{InsAWGM320XA},Freq::Real, Amp::Real, Len::Real, Phase::Real, QCMode::Symbol = :Cyclic, EMD::Integer = 10, Rchannels::Array{Int64}=[1,2],Mchannel::Integer=4,ShowMessages::Integer=1)
```
