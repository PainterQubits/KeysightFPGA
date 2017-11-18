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
Freq = 100e6;
Phase = 0.25;
Dt = 2e-9;
clr = Vector{Cint}(zeros(200));
daq_stop(dig)
println("Stopped DAQs. Creating seed Data...")

t = Array(0:1023);
int1Data = Vector{Int64}(1024);
flt1Data = Vector{Float64}(1024);
int2Data = Vector{Int64}(1024);
flt2Data = Vector{Float64}(1024);
for i=1:1:1024
    flt1Data[i] = sin.(2*pi*Freq*Dt*t[i]);
    flt2Data[i] = cos.(2*pi*Freq*Dt*t[i]);
end

int1Data = ADC(flt1Data,-1,1,16);
raw1Data = Vector{Cint}(int1Data);
int2Data = ADC(flt2Data,-1,1,16);
raw2Data = Vector{Cint}(int2Data);

raw1Data0 = Vector{Cint}(200);
raw1Data1 = Vector{Cint}(200);
raw1Data2 = Vector{Cint}(200);
raw1Data3 = Vector{Cint}(200);
raw1Data4 = Vector{Cint}(200);

raw2Data0 = Vector{Cint}(200);
raw2Data1 = Vector{Cint}(200);
raw2Data2 = Vector{Cint}(200);
raw2Data3 = Vector{Cint}(200);
raw2Data4 = Vector{Cint}(200);

for i=1:1:200
    raw1Data0[i] = raw1Data[5*i-4];
    raw1Data1[i] = raw1Data[5*i-3];
    raw1Data2[i] = raw1Data[5*i-2];
    raw1Data3[i] = raw1Data[5*i-1];
    raw1Data4[i] = raw1Data[5*i];

    raw2Data0[i] = raw2Data[5*i-4];
    raw2Data1[i] = raw2Data[5*i-3];
    raw2Data2[i] = raw2Data[5*i-2];
    raw2Data3[i] = raw2Data[5*i-1];
    raw2Data4[i] = raw2Data[5*i];
end

println("Created seed Data. Writing Data on FPGA RAM...")

SD_Module_FPGAwritePCport(dig.ID,1,raw1Data0,0,0,1);
sleep(1)
SD_Module_FPGAwritePCport(dig.ID,1,raw1Data1,1024,0,1);
sleep(1)
SD_Module_FPGAwritePCport(dig.ID,1,raw1Data2,2*1024,0,1);
sleep(1)
SD_Module_FPGAwritePCport(dig.ID,1,raw1Data3,3*1024,0,1);
sleep(1)
SD_Module_FPGAwritePCport(dig.ID,1,raw1Data4,4*1024,0,1);
sleep(1)

SD_Module_FPGAwritePCport(dig.ID,1,raw2Data0,8192,0,1);
sleep(1)
SD_Module_FPGAwritePCport(dig.ID,1,raw2Data1,8192+1024,0,1);
sleep(1)
SD_Module_FPGAwritePCport(dig.ID,1,raw2Data2,8192+2*1024,0,1);
sleep(1)
SD_Module_FPGAwritePCport(dig.ID,1,raw2Data3,8192+3*1024,0,1);
sleep(1)
SD_Module_FPGAwritePCport(dig.ID,1,raw2Data4,8192+4*1024,0,1);
sleep(1)

println("Wrote Data on the FPGA. Configuring DAQs...");

@KSerror_handler SD_AIN_triggerIOconfig(dig.ID, 1)

ch=1;
dig[DAQPointsPerCycle, ch] = DataSize;
dig[FullScale, ch] = 1;
dig[DAQTrigDelay, ch] = 0;
dig[DAQCycles,ch] = 1;
dig[DAQTrigMode,ch] = :External;
dig[ExternalTrigSource,ch] = :TRGPort;
dig[ExternalTrigBehavior,ch] = :Rising;
dig[Prescaler,ch] = 0;

ch=2;
dig[DAQPointsPerCycle, ch] = DataSize;
dig[FullScale, ch] = 1;
dig[DAQTrigDelay, ch] = 0;
dig[DAQCycles,ch] = 1;
dig[DAQTrigMode,ch] = :External;
dig[ExternalTrigSource,ch] = :TRGPort;
dig[ExternalTrigBehavior,ch] = :Rising;
dig[Prescaler,ch] = 0;

ch=3;
dig[DAQPointsPerCycle, ch] = 2*L+1;
dig[FullScale, ch] = 1;
dig[DAQTrigDelay, ch] = 0;
dig[DAQCycles,ch] = 1;
dig[DAQTrigMode,ch] = :External;
dig[ExternalTrigSource,ch] = :TRGPort;
dig[ExternalTrigBehavior,ch] = :Rising;
dig[Prescaler,ch] = 0;

ch=4;
dig[DAQPointsPerCycle, ch] = 2*L+1;
dig[FullScale, ch] = 1;
dig[DAQTrigDelay, ch] = 0;
dig[DAQCycles,ch] = 1;
dig[DAQTrigMode,ch] = :External;
dig[ExternalTrigSource,ch] = :TRGPort;
dig[ExternalTrigBehavior,ch] = :Rising;
dig[Prescaler,ch] = 0;

println("Set DAQ properties. Configuring AWGs...")

fltIData = Amp*cos.(2*pi*Freq*Dt*t[1:2*L] + Phase*pi/180);
fltQData = Amp*sin.(2*pi*Freq*Dt*t[1:2*L] + Phase*pi/180);
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

IntegData = daq_readIQ(dig,12)
