in_table = 0:511; 
enc_table = zeros(length(table),52);
for i = 1 : length(in_table)
    T1 = (de2bi(in_table(i),9)*(-2)+1);
    enc_table(i,:) = (encodeL1cBCH(T1));
end