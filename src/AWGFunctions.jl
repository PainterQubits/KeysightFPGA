export HowToConfigAWG
export awg_configIQ

global IntialTicksToBeCropped = 0;

"""
function HowToConfigAWG(AWGs,dig)
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
"""
function HowToConfigAWG(AWGs::Vector{InsAWGM320XA}, dig::InsDigitizerM3102A, Rchannels::Array{Int64}=[1,2], Mchannel::Integer=4, Dchannels::Array{Int64}=[1,2],ShowMessages=1)
    DetectDelayMismatches(AWGs,dig,Rchannels,Mchannel,Dchannels,0);
    EMD,MBAT,POffset = DetectDelayMismatches(AWGs,dig,Rchannels,Mchannel,Dchannels,1);
    if ShowMessages == 1
        println("Use the following settings while configuring AWG for using FPGA IQ Demodulation code:")
        println("Set the marker pulse to have a delay of ",(EMD + IntialTicksToBeCropped)," with respect to readout pulse. (Delay is in ticks of 10 ns).")
        println("While using prepFPGAIQ, use it with prepFPGAIQ(dig,Freq,MBAT=",MBAT,").")
        println("While using prepFPGAIQ, use it with prepFPGAIQ(dig,Freq,MBAT=",MBAT,").")
        println("While using daq_readIQ, use it with daq_readIQ(dig,N,MBAT=",MBAT,").")
        println("For using this function in script, it outputs the two values as MarkerDelay, MBAT")
        println("Example: MarkerDelay, MBAT = HowToConfigAWG(AWGs,dig,Rchannels,Mchannel,Dchannels,0)")
    end
    return (EMD + IntialTicksToBeCropped),MBAT
end

"""
function awg_configIQ(awg::InsAWGM320XA, Freq::Real, Amp::Real, Len::Real, Phase::Real,channels::Array{Int64}=[1,2])
awg     :   AWG Instrument Object (Fast one).
Freq    :   Intermediate Frequency of readout pulse (in Hz).
Amp     :   Amplitude of readout pulse (in V).
Len     :   Length of readout pulse (in s).
Phase   :   Phase of readout pulse (in radians)
QCMode  :   Queue Cyclic Mode. Set to :Cyclic for indefinite readout sequence and :OneShot
channels:   Channels of AWG used for outputting readout pulse.
This function configures the selected Fast AWG for sending readout pulse.
"""
function awg_configIQ(awg::InsAWGM320XA, Freq::Real, Amp::Real, Len::Real, Phase::Real,QCMode::Symbol = :Cyclic, channels::Array{Int64}=[1,2] ,ShowMessages::Integer=1)
    for ch in channels
        awg_stop(awg,ch)
    end
    readout = DigitalPulse(Freq, Amp, Len, RectEnvelope, awg[SampleRate], Phase)
    load_pulse(awg, readout);
    #Configuring Readout channels
    awg[OutputMode, channels[1],channels[2]] = :Arbitrary
    awg[Amplitude, channels[1],channels[2]] = readout.amplitude
    awg[DCOffset, channels[1],channels[2]] = 0
    awg[QueueCycleMode, channels[1],channels[2]] = QCMode
    awg[QueueSyncMode, channels[1],channels[2]] = :CLK10
    awg[TrigSource, channels[1],channels[2]] = 0 #PXI line
    awg[TrigBehavior, channels[1],channels[2]] = :Low
    awg[TrigSync, channels[1],channels[2]] = :CLK10
    awg[AmpModMode, channels[1],channels[2]] = :Off
    awg[AngModMode, channels[1],channels[2]] = :Off
    #Flush and queue waveform
    queue_flush(awg, channels[1]); queue_flush(awg, channels[2]);
    queue_waveform(awg, channels[1], readout.I_waveform, :External, delay = 0)
    queue_waveform(awg, channels[2], readout.Q_waveform, :External, delay = 0)
    if Len<4e-6
        DelayWaveform = Waveform(make_Delay(4e-6-Len, awg[SampleRate]), "Delay")
        load_waveform(awg,DelayWaveform,10);
        queue_waveform(awg, channels[1], DelayWaveform, :Auto, delay = 0)
        queue_waveform(awg, channels[2], DelayWaveform, :Auto, delay = 0)
    else
        DelayWaveform = Waveform(make_Delay(100e-9, awg[SampleRate]), "Delay")
        load_waveform(awg,DelayWaveform,10);
        queue_waveform(awg, channels[1], DelayWaveform, :Auto, delay = 0)
        queue_waveform(awg, channels[2], DelayWaveform, :Auto, delay = 0)
    end
    if ShowMessages==1
        println("Configured AWG at slot ",awg.slot_num)
    end
end

"""
function awg_configIQ(awg::InsAWGM320XA,Len::Real,channel::Integer=4)
awg     :   AWG Instrument Object (Slow one).
Len     :   Length of readout pulse (in s).
EMD     :   Exact Matching Delay. (in ticks of 10 ns)
channel :   Channel of AWG used for outputting marker pulse.
This function configures the selected Slow AWG for sending marker pulse appropriately.
"""
function awg_configIQ(awg::InsAWGM320XA, Len::Real, QCMode::Symbol = :Cyclic, EMD::Integer = 10, channel::Integer=4,ShowMessages::Integer=1)
    awg_stop(awg,channel)
    DelayBetweenMarkerandReadout = EMD + IntialTicksToBeCropped;
    ExtraLengthForMarker = 10e-9*(1-IntialTicksToBeCropped);
    marker = DCPulse(1.5, Len + ExtraLengthForMarker, RectEdge, awg[SampleRate])
    load_pulse(awg, marker);
    #Configuring marker channel
    awg[OutputMode, channel] = :Arbitrary
    awg[Amplitude, channel] = marker.amplitude
    awg[DCOffset, channel] = 0
    awg[QueueCycleMode, channel] = QCMode
    awg[QueueSyncMode, channel] = :CLK10
    awg[TrigSource, channel] = 0
    awg[TrigBehavior, channel] = :Low
    awg[TrigSync, channel] = :CLK10
    awg[AmpModMode, channel] = :Off
    awg[AngModMode, channel] = :Off
    #Flush and queue waveform
    queue_flush(awg, channel)
    queue_waveform(awg, channel, marker.waveform, :External, delay = DelayBetweenMarkerandReadout)
    if Len<4e-6
        DelayWaveform = Waveform(make_Delay(4e-6- Len - ExtraLengthForMarker- DelayBetweenMarkerandReadout*10e-9, awg[SampleRate]), "Delay")
        load_waveform(awg,DelayWaveform,10);
        queue_waveform(awg, channel, DelayWaveform, :Auto, delay = 0)
    else
        DelayWaveform = Waveform(make_Delay(100e-9- ExtraLengthForMarker - DelayBetweenMarkerandReadout*10e-9, awg[SampleRate]), "Delay")
        load_waveform(awg,DelayWaveform,10);
        queue_waveform(awg, channel, DelayWaveform, :Auto, delay = 0)
    end
    if ShowMessages==1
        println("Assumed that marker will be sent out from channel ",channel,". Connect channel ",channel," of selected slow AWG to trigger port of digitizer.")
        println("Configured AWG at slot ",awg.slot_num)
    end
end

"""
function awg_configIQ(AWGs::Vector{InsAWGM320XA},Freq::Real, Amp::Real, Len::Real, Phase::Real,Rchannels::Array{Int64}=[1,2],Mchannel::Integer=4)
AWGs    :   Array of AWG Instrument Objects [Fast AWG, Slow AWG].
Freq    :   Intermediate Frequency of readout pulse (in Hz).
Amp     :   Amplitude of readout pulse (in V).
Len     :   Length of readout pulse (in s).
Phase   :   Phase of readout pulse (in radians)
EMD     :   Exact Matching Delay. (in ticks of 10 ns)
Rchannels:  Channels of Fast AWG used for outputting readout pulse.
Mchannel :  Channel of Slow AWG used for outputting marker pulse.
This function configures the selected Fast AWG for sending readout pulse and configures the selected Slow AWG for sending marker pulse appropriately.
"""
function awg_configIQ(AWGs::Vector{InsAWGM320XA},Freq::Real, Amp::Real, Len::Real, Phase::Real, QCMode::Symbol = :Cyclic, EMD::Integer = 10, Rchannels::Array{Int64}=[1,2],Mchannel::Integer=4,ShowMessages::Integer=1)
    awg_configIQ(AWGs[1],Freq,Amp,Len,Phase,QCMode,Rchannels,ShowMessages);
    awg_configIQ(AWGs[2],Len,QCMode,EMD,Mchannel,ShowMessages);
end

"""
function awg_configIQ(AWGs::Vector{InsAWGM320XA},Amp::Real, IQWaveforms::Array{Waveform},IQwfID::Array{Int64}, IQinput_type::Array{Symbol}=[:Analog16,:Analog16],Rchannels::Array{Int64}=[1,2],Mchannel::Integer=4)
function awg_configIQ(AWGs::Vector{InsAWGM320XA},Amp::Real, IQWaveformvalues::Array{Float64}, IQwfID::Array{Int64}, IQwfname::Array{AbstractString} = [string(IQwfID[1]),string(IQwfID[2])], IQinput_type::Array{Symbol}=[:Analog16,:Analog16],Rchannels::Array{Int64}=[1,2],Mchannel::Integer=4)
AWGs    :   Array of AWG Instrument Objects [Fast AWG, Slow AWG].
Amp     :   Amplitude of readout pulse (in V).
IQWaveforms:Array of two Waveform objects for I and Q.
IQwfID  :   Array of two integers to be used as IDs for I and Q waveforms respectively.
IQwfname:   Array of two strings to be used as waveform names for I and Q.
IQinput_type:Array of two symbols referring to input type of waveform. Refer to Table 9 of the userguide for discussion on input types.
EMD     :   Exact Matching Delay. (in ticks of 10 ns)
Rchannels:  Channels of Fast AWG used for outputting readout pulse.
Mchannel :  Channel of Slow AWG used for outputting marker pulse.
In case you want to use a custom waveform for readout, use these functions.
"""
function awg_configIQ(AWGs::Vector{InsAWGM320XA},Amp::Real, IQWaveforms::Array{Waveform},IQwfID::Array{Int64}, IQinput_type::Array{Symbol}=[:Analog16,:Analog16], QCMode::Symbol = :Cyclic,EMD::Integer = 10, Rchannels::Array{Int64}=[1,2],Mchannel::Integer=4,ShowMessages::Integer=1)
    load_waveform(AWGs[1],IQWaveforms[1],IQwfID[1],IQinput_type[1]);
    load_waveform(AWGs[1],IQWaveforms[2],IQwfID[2],IQinput_type[2]);
    #Configuring Readout channels
    awg[OutputMode, Rchannels[1],Rchannels[2]] = :Arbitrary
    awg[Amplitude, Rchannels[1],Rchannels[2]] = Amp
    awg[DCOffset, Rchannels[1],Rchannels[2]] = 0
    awg[QueueCycleMode, Rchannels[1],Rchannels[2]] =  QCMode
    awg[QueueSyncMode, Rchannels[1],Rchannels[2]] = :CLK10
    awg[TrigSource, Rchannels[1],Rchannels[2]] = 0 #PXI line
    awg[TrigBehavior, Rchannels[1],Rchannels[2]] = :Falling
    awg[TrigSync, Rchannels[1],Rchannels[2]] = :CLK10
    awg[AmpModMode, Rchannels[1],Rchannels[2]] = :Off
    awg[AngModMode, Rchannels[1],Rchannels[2]] = :Off
    #Flush and queue waveform
    queue_flush(awg, Rchannels[1]); queue_flush(awg, Rchannels[2]);
    queue_waveform(awg, Rchannels[1], IQWaveforms[1], :External, delay = 0)
    queue_waveform(awg, Rchannels[2], IQWaveforms[2], :External, delay = 0)
    if ShowMessages==1
        println("Configured AWG at slot ",awg.slot_num)
    end

    Len = Length(IQWaveforms[1].waveformvalues);
    awg_configIQ(AWGs[2],Len,QCMode,EMD,Mchannel,ShowMessages);
end

function awg_configIQ(AWGs::Vector{InsAWGM320XA},Amp::Real, IQWaveformvalues::Array{Float64}, IQwfID::Array{Int64}, IQwfname::Array{AbstractString} = ["Iwf","Qwf"], IQinput_type::Array{Symbol}=[:Analog16,:Analog16], QCMode::Symbol = :Cyclic,EMD::Integer = 11, Rchannels::Array{Int64}=[1,2],Mchannel::Integer=4,ShowMessages::Integer=1)
    IQWaveforms = Array{Waveform}(2);
    IQwaveforms[1] = Waveform(waveformValues[:,1], IQwfname[1]);
    IQwaveforms[2] = Waveform(waveformValues[:,2], IQwfname[2]);
    awg_configIQ(AWGs,Amp,IQWaveforms,IQwfID,IQinput_type,QCMode,EMD,Rchannels,Mchannel,ShowMessages);
end
