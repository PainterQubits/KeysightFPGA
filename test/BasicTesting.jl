using KeysightFPGA
using InstrumentControl
using InstrumentControl: AWGM320XA, DigitizerM3102A
using KeysightInstruments
using KeysightQubits
using Plots; Plots.plotlyjs();
awg4 = InsAWGM320XA(4)
awg6 = InsAWGM320XA(2)
dig = InsDigitizerM3102A(16);

DetectDelayMismatches([awg6,awg4],dig,[1,2],4,[1,2],0);
EMD,MBAT,POffset = DetectDelayMismatches([awg6,awg4],dig,[1,2],4,[1,2],1)

Len =400e-9;
Amp = 0.65;
Freq = 100e6;
Phase = 0.5;
clr = Vector{Cint}(zeros(200));
daq_stop(dig)
println("Stopped DAQs.")

prepFPGAIQ(dig,Freq,MBAT)

daq_configIQ(dig,1)

awg_configIQ([awg6,awg4],Freq,Amp,Len,Phase,:OneShot,EMD)

triggerReadout([awg6,awg4],dig)

IntegData = daq_readIQ(dig,1,MBAT)

MeasuredAmp, MeasuredPhase = CalculateAmpPhase(IntegData)

println("Measured Amplitude = ",MeasuredAmp)
println("Measured and Correcte Phase = ",MeasuredPhase-POffset)
