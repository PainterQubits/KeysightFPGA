export ADC
export to_integer
export to_signed

"""
function ADC(ana, L, U, nbits)
ana     :   Array of analog values.
L       :   Lower limit of scale.
U       :   Upper limit of scale.
nbits   :   Number of bits to convert to.
This function is the software version of ADC. Converts analog values to digital integers.
"""
function ADC(ana::Array{Float64}, L::Real=-1.0, U::Real=1.0, nbits::Integer=16)
    ana -= L
    ana /= (U - L)
    ana *= 1 << nbits
    ana = map(x -> min(max(x, 0), 2^nbits - 1), ana)
    return convert(Array{Int64}, round.(ana) - 1 << (nbits - 1))
end

"""
function to_integer(a::String)
a   :   Binary string.
This function converts a binary string to number assuming 2's complement signed convention
"""
function to_integer(a::String)
    if a[1]=='0'
        b = parse(Int64,a[2:end],2);
    else
        b = -(2^(length(a)-1)-parse(Int64,a[2:end],2));
    end
end

"""
function to_signed(a::Integer,nbits::Integer=16)
a   :   Integer number.
This function converts a integer digital value to 2's complement signed representation.
"""
function to_signed(a::Integer,nbits::Integer=16)
    if a>=0
        mag = bin(a,nbits-1);
        b = string('0',mag[end-nbits+2:end]);
    else
        mag = bin(2^(nbits-1)+a,nbits-1);
        b = string('1',mag[end-nbits+2:end]);
    end
end
