using KeysightFPGA
using InstrumentControl
using InstrumentControl: AWGM320XA, DigitizerM3102A
using KeysightInstruments
using KeysightQubits
using Plots; Plots.plotlyjs();
awg4 = InsAWGM320XA(4)
awg6 = InsAWGM320XA(2)
dig = InsDigitizerM3102A(16);

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

prepFPGAIQ(dig,Freq)

daq_configIQ(dig,1)

println("Configuring AWGs...")

#fltIData = Amp*cos.(2*pi*Freq*Dt*t[1:2*L] + Phase*pi/180);
#fltQData = Amp*sin.(2*pi*Freq*Dt*t[1:2*L] + Phase*pi/180);
readout = DigitalPulse(Freq, Amp, L*Dt, RectEnvelope, awg6[SampleRate], Phase)
marker = DCPulse(1.5, L*Dt + 10e-9 + IQDEMPrepone*10e-9, RectEdge, awg4[SampleRate]) #1 is amplitude, 440e-9 is length
load_pulse(awg6, readout); load_pulse(awg4, marker)

#Configuring Readout channels
awg6[OutputMode, 1,2] = :Arbitrary
awg6[Amplitude, 1,2] = readout.amplitude
awg6[DCOffset, 1,2] = 0
awg6[QueueCycleMode, 1,2] = :OneShot
awg6[QueueSyncMode, 1,2] = :CLK10
awg6[TrigSource, 1,2] = 0 #PXI line
awg6[TrigBehavior, 1,2] = :Falling
awg6[TrigSync, 1,2] = :CLK10
awg6[AmpModMode, 1,2] = :Off
awg6[AngModMode, 1,2] = :Off

#Configuring marker channel
awg4[OutputMode, 4] = :Arbitrary
awg4[Amplitude, 4] = marker.amplitude
awg4[DCOffset, 4] = 0
awg4[QueueCycleMode, 4] = :OneShot
awg4[QueueSyncMode, 4] = :CLK10
awg4[TrigSource, 4] = 0
awg4[TrigBehavior, 4] = :Falling
awg4[TrigSync, 4] = :CLK10
awg4[AmpModMode, 4] = :Off
awg4[AngModMode, 4] = :Off
queue_flush(awg6, 1); queue_flush(awg6, 2); queue_flush(awg4, 4)
queue_waveform(awg6, 1, readout.I_waveform, :External, delay = 8+  IQDEMPrepone)
queue_waveform(awg6, 2, readout.Q_waveform, :External, delay = 8+ IQDEMPrepone)
queue_waveform(awg4, 4, marker.waveform, :External, delay = 18)

println("Configured AWG.")

RTDelay = 3;
PETDelay = 9;
sleep(0.5)
SD_Module_FPGAwritePCport(dig.ID,0,PETDelay,1,1,1);
sleep(0.5)
SD_Module_FPGAwritePCport(dig.ID,0,RTDelay,2,1,1);
sleep(0.5)
println("Configured IPs. Flushing DAQs and Starting AWGs and DAQs")

SD_Module_PXItriggerWrite(awg4.ID,0,1);  #Set Trigger to High
awg_start(awg6, 1, 2)
awg_start(awg4, 4)
ch=1;
SD_AIN_DAQflush(dig.ID, ch)
SD_AIN_DAQstart(dig.ID, ch)
ch=2;
SD_AIN_DAQflush(dig.ID, ch)
SD_AIN_DAQstart(dig.ID, ch)
ch=3;
SD_AIN_DAQflush(dig.ID, ch)
SD_AIN_DAQstart(dig.ID, ch)
ch=4;
SD_AIN_DAQflush(dig.ID, ch)
SD_AIN_DAQstart(dig.ID, ch)

println("Flushed and started DAQs. DAQs waiting for trigger...")

SD_Module_PXItriggerWrite(awg4.ID, 0, 0) #Trigger
SD_Module_PXItriggerWrite(awg4.ID, 0, 1)  #Switch off Trigger

println("Gave trigger and hopefully acquiring Data...")

IntegData = daq_readIQ(dig,1)
