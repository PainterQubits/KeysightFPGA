export daq_readIQ
export daq_configIQ
export prepFPGAIQ

using InstrumentControl
using InstrumentControl: DigitizerM3102A
using KeysightInstruments

"""
function daq_readIQ(dig::InsDigitizerM3102A,N::Integer,channels::Array{Int64}=[1,2],timeout::Integer=1)
dig     :   Digitizer Object.
N       :   Number of Readout Pulse Sequences.
channels:   Channel Array which is receiving the readout signal.
timeout :   Timeout in case DAQ did not read anything (in s).
"""
function daq_readIQ(dig::InsDigitizerM3102A,N::Integer,channels::Array{Int64}=[1,2],timeout::Integer=1)
    noch = length(channels);
    if length(N)==1
        DS = 5*N*ones(Integer,noch)+1;
    elseif length(N)!= noch
        println("Error in specifing Number of Pulse Sequences. Either give single number same for all channels or give a vector of length same as channel vector");
    end
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

"""
function daq_configIQ(dig::InsDigitizerM3102A,N::Integer,channels::Array{Int64}=[1,2])
dig     :   Digitizer Object.
N       :   Number of Readout Pulse Sequences.
channels:   Channel Array which is receiving the readout signal.
This function configures DAQs so that they are ready for use of FPGA code.
"""
function daq_configIQ(dig::InsDigitizerM3102A,N::Integer,channels::Vector{Int64}=[1,2],ShowMessages::Integer=1)
    if ShowMessages==1
        println("Configuring DAQs...");
    end
    @KSerror_handler SD_AIN_triggerIOconfig(dig.ID, 1)
    for ch in channels
        dig[DAQPointsPerCycle, ch] = 6;
        dig[FullScale, ch] = 1;
        dig[DAQTrigDelay, ch] = 0;
        dig[DAQCycles,ch] = N;
        dig[DAQTrigMode,ch] = :External;
        dig[ExternalTrigSource,ch] = :TRGPort;
        dig[ExternalTrigBehavior,ch] = :Rising;
        dig[Prescaler,ch] = 0;
    end
    if ShowMessages==1
        println("DAQs configured for IQ Demodulation.")
    end
end

"""
function prepFPGAIQ(dig::InsDigitizerM3102A,Freq::Real,MBAT::Integer=0)
dig     :   Digitizer Object.
Freq    :   Intermediate Frequency of readout pulse (in Hz).
MBAT    :   Marker Beforetime Arrival Ticks (ticks of 2 ns), if known.
This function writes required sine and cosine data for IQ Demodulation on FPGA
RAM and also sets some internal parameters in IPs.
"""
function prepFPGAIQ(dig::InsDigitizerM3102A,Freq::Real,MBAT::Integer=0,ShowMessages::Integer=1)
    if ShowMessages==1
        println("Preping FPGA...");
    end

    t = Array(0:(1019-MBAT));
    intSine = Vector{Int64}(1020-MBAT);
    fltSine = Vector{Float64}(1020-MBAT);
    intCosine = Vector{Int64}(1020-MBAT);
    fltCosine = Vector{Float64}(1020-MBAT);
    for i=1:1:1020-MBAT
        fltSine[i] = sin.(2*pi*Freq*2e-9*t[i]);
        fltCosine[i] = cos.(2*pi*Freq*2e-9*t[i]);
    end
    for i=1:1:MBAT
        push!(fltSine,0);
        push!(fltCosine,0);
    end

    intSine = ADC(fltSine,-1,1,16);
    rawSine = Vector{Cint}(intSine);
    intCosine = ADC(fltCosine,-1,1,16);
    rawCosine = Vector{Cint}(intCosine);

    rawSine0 = Vector{Cint}(204);
    rawSine1 = Vector{Cint}(204);
    rawSine2 = Vector{Cint}(204);
    rawSine3 = Vector{Cint}(204);
    rawSine4 = Vector{Cint}(204);

    rawCosine0 = Vector{Cint}(204);
    rawCosine1 = Vector{Cint}(204);
    rawCosine2 = Vector{Cint}(204);
    rawCosine3 = Vector{Cint}(204);
    rawCosine4 = Vector{Cint}(204);

    for i=1:1:200
        rawSine0[i] = rawSine[5*i-4];
        rawSine1[i] = rawSine[5*i-3];
        rawSine2[i] = rawSine[5*i-2];
        rawSine3[i] = rawSine[5*i-1];
        rawSine4[i] = rawSine[5*i];

        rawCosine0[i] = rawCosine[5*i-4];
        rawCosine1[i] = rawCosine[5*i-3];
        rawCosine2[i] = rawCosine[5*i-2];
        rawCosine3[i] = rawCosine[5*i-1];
        rawCosine4[i] = rawCosine[5*i];
    end

    SD_Module_FPGAwritePCport(dig.ID,1,rawSine0,0,0,1);
    SD_Module_FPGAwritePCport(dig.ID,1,rawSine1,1024,0,1);
    SD_Module_FPGAwritePCport(dig.ID,1,rawSine2,2048,0,1);
    SD_Module_FPGAwritePCport(dig.ID,1,rawSine3,3072,0,1);
    SD_Module_FPGAwritePCport(dig.ID,1,rawSine4,4096,0,1);

    SD_Module_FPGAwritePCport(dig.ID,1,rawCosine0,8192,0,1);
    SD_Module_FPGAwritePCport(dig.ID,1,rawCosine1,9216,0,1);
    SD_Module_FPGAwritePCport(dig.ID,1,rawCosine2,10240,0,1);
    SD_Module_FPGAwritePCport(dig.ID,1,rawCosine3,11264,0,1);
    SD_Module_FPGAwritePCport(dig.ID,1,rawCosine4,12288,0,1);

    if ShowMessages==1
        println("Wrote Sine and Cosine Data on FPGA.");
    end

    RTDelay = 3;
    PETDelay = 9;
    SD_Module_FPGAwritePCport(dig.ID,0,PETDelay,1,1,1);
    SD_Module_FPGAwritePCport(dig.ID,0,RTDelay,2,1,1);
    if ShowMessages==1
        println("Configured IPs on FPGA.")
    end
end
