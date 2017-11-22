export DetectDelayMismatches
export DecryptIntegData
export CalculateAmpPhase

"""
function DetectDelayMismatches(AWGs::Vector{InsAWGM320XA}, dig::InsDigitizerM3102A, Rchannels::Array{Int64}=[1,2], Mchannel::Integer=4, Dchannels::Array{Int64}=[1,2] ,ShowMessages=2)
AWGs    :   Array of AWG Instrument Objects [Fast AWG, Slow AWG].
dig     :   Digitizer Object.
Rchannels:  Channels of Fast AWG used for outputting readout pulse.
Mchannel :  Channel of Slow AWG used for outputting marker pulse.
Dchannels:   Channel Array which is receiving the readout signal.
ShowMessages: Shows printed instructions if set to 2. Shows only phase offset for 1.
This function does a test to determine how much delay is needed in Marker Pulse and how to configure DAQ to get good IQ Demodulation.
For some reason (stll undetermined), this function has to be used twice consequetively to get meaningful result.
Outputs:
EMD     :   Exact Matching Delay. (in ticks of 10 ns)
MBAT    :   Marker Beforetime Arrival Ticks (ticks of 2 ns).
POffset :   Phase offset from 0.
"""
function DetectDelayMismatches(AWGs::Vector{InsAWGM320XA}, dig::InsDigitizerM3102A, Rchannels::Array{Int64}=[1,2], Mchannel::Integer=4, Dchannels::Array{Int64}=[1,2] ,ShowMessages=2)
    prepFPGAIQ(dig,10e6,0,0)
    @KSerror_handler SD_AIN_triggerIOconfig(dig.ID, 1)
    ch=3;
    dig[DAQPointsPerCycle, ch] = 100;
    dig[FullScale, ch] = 1;
    dig[DAQTrigDelay, ch] = 0;
    dig[DAQCycles,ch] = 1;
    dig[DAQTrigMode,ch] = :External;
    dig[ExternalTrigSource,ch] = :TRGPort;
    dig[ExternalTrigBehavior,ch] = :Rising;
    dig[Prescaler,ch] = 0;
    awg_configIQ(AWGs,10e6,1,400e-9,0,:OneShot,9,Rchannels,Mchannel,0)
    triggerReadout(AWGs,dig,Rchannels,Mchannel,[3])
    Data3 = daq_read(dig, 3, 100, 1);
    i=1;
    while Data3[i]<25000 && i<100
        i=i+1;
    end
    ExtraPoints = i-2;
    EMD = Int64(9 + floor(ExtraPoints/5));
    MBAT = mod(ExtraPoints,5);
    if ShowMessages == 2
        println("Extra Points = ", ExtraPoints)
        println("Use EMD = ", EMD)
        println("Use MBAT = ", MBAT)
    end

    #Rerun to get phase offset
    prepFPGAIQ(dig,10e6,MBAT,0)
    daq_configIQ(dig,1,[1,2],0)
    awg_configIQ(AWGs,10e6,0.8,400e-9,0,:OneShot,EMD,Rchannels,Mchannel,0)
    triggerReadout(AWGs,dig,Rchannels,Mchannel,Dchannels)
    IntegData = daq_readIQ(dig,1,MBAT,Dchannels)
    POffset = floor((atan(IntegData[1,2]/IntegData[1,1]))*100)/100;
    if ShowMessages > 0
        println("Phase Offset = ",POffset)
    end
    return EMD,MBAT,POffset
end

"""
function DecryptIntegData(data::Array{Int16},MBAT::Integer=0)
data    :   Array of Int16 numbers read from DAQ buffer by daq_readIQ
MBAT    :   Marker Beforetime Arrival Ticks (ticks of 2 ns), if known.
This function decrypts the integrated data sent by FPGA (which is actually a 48 bit number sent as three 16 bit numbers).
"""
function DecryptIntegData(data::Array{Int16},MBAT::Integer=0)
    L = length(data)
    N = Int32(floor(L/6))
    extData = Vector{Int64}(N);
    extFltData = Vector{Float64}(N);
    for i=1:1:N
        extData[i] = to_integer(string(to_signed(data[6*i-2]),to_signed(data[6*i-3]),to_signed(data[6*i-2])));
        extFltData[i] = extData[i]./((5*data[6*i-1]-MBAT)*(2^30));
    end
    return extFltData
end

"""
CalculateAmpPhase(IntegData::Array{Float64,2})
IntegData   :   Output from daq_readIQ function. Column 1 is I, Column 2 is Q. Each row is different readout instance.
This function calculates the Amplitude and Phase of the readout.
Output:
Amp     :   Amplitude read.
Phase   :   Phase of the readout.
"""
function CalculateAmpPhase(IntegData::Array{Float64,2})
    Amp = sqrt.(IntegData[:,1].^2 + IntegData[:,2].^2);
    Phase = atan.(IntegData[:,2]./IntegData[:,1]);
    return Amp, Phase
end
