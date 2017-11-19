export DetectDelayMismatches

function DetectDelayMismatches(AWGs::Vector{InsAWGM320XA}, dig::InsDigitizerM3102A, Rchannels::Array{Int64}=[1,2], Mchannel::Integer=4, Dchannels::Array{Int64}=[1,2])
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
    awg_configIQ(AWGs,10e6,0.8,400e-9,0,:OneShot,9,Rchannels,Mchannel,0)
    triggerReadout(AWGs,dig,Rchannels,Mchannel,[3])
    Data3 = daq_read(dig, 3, 100, 1);
    i=1;
    while Data3[i]<25000 && i<100
        i=i+1;
    end
    ExtraPoints = i-2;
    EMD = Int64(9 + floor(ExtraPoints/5));
    MBAT = mod(ExtraPoints,5);
    println("Extra Points = ", ExtraPoints)
    println("Use EMD = ", EMD)
    println("Use MBAT = ", MBAT)

    #Rerun to get phase offset
    prepFPGAIQ(dig,10e6,MBAT,0)
    daq_configIQ(dig,1,[1,2],0)
    awg_configIQ(AWGs,10e6,0.8,400e-9,0,:OneShot,EMD,Rchannels,Mchannel,0)
    triggerReadout(AWGs,dig,Rchannels,Mchannel,Dchannels)
    IntegData = daq_readIQ(dig,1,Dchannels)
    POffset = floor((atan(IntegData[1,2]/IntegData[1,1]))*100)/100;
    println("Phase Offset = ",POffset)
    return EMD,MBAT,POffset
end
