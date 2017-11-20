export triggerReadout

using InstrumentControl
using InstrumentControl: AWGM320XA, DigitizerM3102A
using KeysightInstruments

"""
function triggerReadout(AWGs::Vector{InsAWGM320XA},dig::InsDigitizerM3102A,Rchannels::Array{Integer}=[1,2],Mchannel::Integer=4,DChannels::Array{Integer}=[1,2])
AWGs    :   Array of AWG Instrument Objects [Fast AWG, Slow AWG].
dig     :   Digitizer Object.
Rchannels:  Channels of Fast AWG used for outputting readout pulse.
Mchannel :  Channel of Slow AWG used for outputting marker pulse.
Dchannels:   Channel Array which is receiving the readout signal.
This function reset PXItrigger Line 0 to High, starts the AWGs, flushes the DAQs, start the DAQs and send PXItrigger for sending the readout pulses.
"""
function triggerReadout(AWGs::Vector{InsAWGM320XA}, dig::InsDigitizerM3102A, Rchannels::Array{Int64}=[1,2], Mchannel::Integer=4, Dchannels::Array{Int64}=[1,2])
    SD_Module_PXItriggerWrite(AWGs[2].ID,0,1);  #Set Trigger to High
    for ch in Rchannels
        awg_start(AWGs[1],ch);
    end
    awg_start(AWGs[2],Mchannel);
    for ch in Dchannels
        SD_AIN_DAQflush(dig.ID, ch)
        SD_AIN_DAQstart(dig.ID, ch)
    end
    SD_Module_PXItriggerWrite(AWGs[2].ID, 0, 0) #Trigger
    #sleep(10)
    #SD_Module_PXItriggerWrite(AWGs[2].ID, 0, 1)  #Switch off Trigger
end
