__precompile__(true)

module KeysightFPGA

    using InstrumentControl
    using InstrumentControl: AWGM320XA, DigitizerM3102A
    Waveform = AWGM320XA.Waveform
    using KeysightInstruments
    using KeysightQubits
    include("NumHandlingFunctions.jl")
    include("DigFunctions.jl")
    include("AWGFunctions.jl")
    include("TrigFunctions.jl")
    include("HelperFunctions.jl")

end
