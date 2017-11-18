export daq_readIQ

using InstrumentControl
using InstrumentControl: DigitizerM3102A

function daq_readIQ(dig,N,channels=[1,2],timeout=1)
    noch = length(channels);
    if length(N)==1
        DS = N*ones(Int32,noch);
    elseif length(N)!= noch
        println("Error in specifing Number of Pulse Sequences. Either give single number same for all channels or give a vector of length same as channel vector");
    end
    println("Reached here")
    IntegData = Array{Float64}(maximum(N),noch);
    if noch==2
        Idata1 = daq_read(dig, channels[1],DS[1],timeout);
        Qdata1 = daq_read(dig, channels[2],DS[2],timeout);
        if length(Idata1)>1
            IntegData[:,1] = DecryptIntegData(Idata1);
            IntegData[:,2] = DecryptIntegData(Qdata1);
        else
            Println("No data read. Check the configuration of DAQ and AWGs.")
        end
    elseif noch==4
        Idata1 = daq_read(dig, channels[1],DS[1],timeout);
        Qdata1 = daq_read(dig, channels[2],DS[2],timeout);
        Idata2 = daq_read(dig, channels[3],DS[3],timeout);
        Qdata2 = daq_read(dig, channels[4],DS[4],timeout);
        if length(Idata1)>1
            IntegData[:,1] = DecryptIntegData(Idata1);
            IntegData[:,2] = DecryptIntegData(Qdata1);
            IntegData[:,3] = DecryptIntegData(Idata2);
            IntegData[:,4] = DecryptIntegData(Qdata2);
        else
            Println("No data read. Check the configuration of DAQ and AWGs.")
        end
    else
        println("Error in specifying Channels. Channel Vector should be either of length 2 or 4.");
    end
    return IntegData;
end

function daq_configIQ(dig,N,channels=[1,2])
    @KSerror_handler SD_AIN_triggerIOconfig(dig.ID, 1)
    for ch in channels
        dig[DAQPointsPerCycle, ch] = N;
        dig[FullScale, ch] = 1;
        dig[DAQTrigDelay, ch] = 0;
        dig[DAQCycles,ch] = 1;
        dig[DAQTrigMode,ch] = :External;
        dig[ExternalTrigSource,ch] = :TRGPort;
        dig[ExternalTrigBehavior,ch] = :Rising;
        dig[Prescaler,ch] = 0;
    end
end
