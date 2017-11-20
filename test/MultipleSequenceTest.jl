using KeysightFPGA
using InstrumentControl
using InstrumentControl: AWGM320XA, DigitizerM3102A
using KeysightInstruments
using KeysightQubits
using Plots; Plots.plotlyjs();
awg4 = InsAWGM320XA(4)
awg6 = InsAWGM320XA(2)
dig = InsDigitizerM3102A(16);

#DetectDelayMismatches([awg6,awg4],dig);
#EMD,MBAT,POffset = DetectDelayMismatches([awg6,awg4],dig)
EMD = 11;
MBAT = 1;

DataSize = 60;
Timeout =1;
IQDEMPrepone = 0;
L=200;

Freq = 100e6;

Dt = 2e-9;
N=50000

Amp = 0.8;
Phase = 0;
daq_stop(dig)
println("Stopped DAQs.")
prepFPGAIQ(dig,Freq,MBAT)
daq_configIQ(dig,N)
awg_configIQ([awg6,awg4],Freq,Amp,L*Dt,Phase,:Cyclic,EMD)
triggerReadout([awg6,awg4],dig)
IntegData1 = daq_readIQ(dig,N,MBAT)
awg_stop(awg4,4)
awg_stop(awg6,1,2)
TrialAmp1,TrialPhase1 = CalculateAmpPhase(IntegData1);
avgTrialAmp1 = mean(TrialAmp1)
println("Mean Amplitude in Trial 1 = ",avgTrialAmp1)
println("RMS error in Amplitude in Trial 1 = ", sqrt.(sum((TrialAmp1-avgTrialAmp1).^2)/N))
avgTrialPhase1 = mean(TrialPhase1)
println("Mean Phase in Trial 1 = ",avgTrialPhase1)
println("RMS error in Amplitude in Trial 1 = ", sqrt.(sum((TrialPhase1-avgTrialPhase1).^2)/N))

Amp = 0.8;
Phase = pi/4;
daq_stop(dig)
println("Stopped DAQs.")
prepFPGAIQ(dig,Freq,MBAT)
daq_configIQ(dig,N)
awg_configIQ([awg6,awg4],Freq,Amp,L*Dt,Phase,:Cyclic,EMD)
triggerReadout([awg6,awg4],dig)
IntegData2 = daq_readIQ(dig,N,MBAT)
awg_stop(awg4,4)
awg_stop(awg6,1,2)
TrialAmp2,TrialPhase2 = CalculateAmpPhase(IntegData2);
avgTrialAmp2 = mean(TrialAmp2)
println("Mean Amplitude in Trial 2 = ",avgTrialAmp2)
println("RMS error in Amplitude in Trial 2 = ", sqrt.(sum((TrialAmp2-avgTrialAmp2).^2)/N))
avgTrialPhase2 = mean(TrialPhase2)
println("Mean Phase in Trial 2 = ",avgTrialPhase2)
println("RMS error in Amplitude in Trial 2 = ", sqrt.(sum((TrialPhase2-avgTrialPhase2).^2)/N))

Amp = 0.8;
Phase = pi/2;
daq_stop(dig)
println("Stopped DAQs.")
prepFPGAIQ(dig,Freq,MBAT)
daq_configIQ(dig,N)
awg_configIQ([awg6,awg4],Freq,Amp,L*Dt,Phase,:Cyclic,EMD)
triggerReadout([awg6,awg4],dig)
IntegData3 = daq_readIQ(dig,N,MBAT)
awg_stop(awg4,4)
awg_stop(awg6,1,2)
TrialAmp3,TrialPhase3 = CalculateAmpPhase(IntegData3);
avgTrialAmp3 = mean(TrialAmp3)
println("Mean Amplitude in Trial 3 = ",avgTrialAmp3)
println("RMS error in Amplitude in Trial 3 = ", sqrt.(sum((TrialAmp3-avgTrialAmp3).^2)/N))
avgTrialPhase3 = mean(TrialPhase3)
println("Mean Phase in Trial 3 = ",avgTrialPhase3)
println("RMS error in Amplitude in Trial 3 = ", sqrt.(sum((TrialPhase3-avgTrialPhase3).^2)/N))


Plots.scatter(IntegData1[:,1],IntegData1[:,2],title="IQ Demodulation Testing")
Plots.scatter!(IntegData2[:,1],IntegData2[:,2])
Plots.scatter!(IntegData3[:,1],IntegData3[:,2])
