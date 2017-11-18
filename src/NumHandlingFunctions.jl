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

function DecryptIntegData(data)
    L = length(data)
    N = Int32(floor((L-1)/5))
    extData = Vector{Int64}(N);
    extFltData = Vector{Float64}(N);
    for i=1:1:N
        extDataI[i] = to_integer(string(to_signed(data[5*i-1],16),to_signed(data[5*i-2],16),to_signed(data[5*i-3],16)));
        extFltData[i] = extData[i]./(5*data[5*i]*(2^30));
    end
    return extFltData
end
