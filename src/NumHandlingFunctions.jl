function ADC(ana, L, U, nbits)
    ana -= L
    ana /= (U - L)
    ana *= 1 << nbits
    ana = map(x -> min(max(x, 0), 2^nbits - 1), ana)
    return convert(Array{Int64}, round.(ana) - 1 << (nbits - 1))
end

function to_integer(a)
    if a[1]=='0'
        b = parse(Int64,a[2:end],2);
    else
        b = -(2^(length(a)-1)-parse(Int64,a[2:end],2));
    end
end

function to_signed(a,nbits)
    if a>=0
        mag = bin(a,nbits-1);
        b = string('0',mag[end-nbits+2:end]);
    else
        mag = bin(2^(nbits-1)+a,nbits-1);
        b = string('1',mag[end-nbits+2:end]);
    end
end
