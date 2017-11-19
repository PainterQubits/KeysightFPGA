using KeysightFPGA
using InstrumentControl
using InstrumentControl: AWGM320XA, DigitizerM3102A
using KeysightInstruments
using KeysightQubits
using Plots; Plots.plotlyjs();
awg4 = InsAWGM320XA(4)
awg6 = InsAWGM320XA(2)
dig = InsDigitizerM3102A(16);

DetectDelayMismatches([awg6,awg4],dig);
EMD,MBAT,POffset = DetectDelayMismatches([awg6,awg4],dig)

DataSize = 60;
Timeout =1;
IQDEMPrepone = 0;
L=200;
Amp = 0.8;
Freq = 10e6;
Phase = 0;
Dt = 2e-9;
clr = Vector{Cint}(zeros(200));
daq_stop(dig)
println("Stopped DAQs.")

prepFPGAIQ(dig,Freq,MBAT)

daq_configIQ(dig,1)

awg_configIQ([awg6,awg4],Freq,Amp,L*Dt,Phase,:OneShot,EMD)

triggerReadout([awg6,awg4],dig)

IntegData = daq_readIQ(dig,1)
