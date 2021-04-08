function enc_bits = encodeL1cBCH(x)
% generateL1COcode.m generates one of the 32 GPS satellite L1CO codes.
%
% enc_bits = encodeL1cBCH(x)
%
%   Inputs:
%       x           - data bits (9 bits TOI).
%
%   Outputs:
%       enc_bits    - encoded bits (52 bits)
%                     
%--------------------------------------------------------------------------
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or (at your option) any later version.
%
%This program is distributed in the hope that it will be useful,
%but WITHOUT ANY WARRANTY; without even the implied warranty of
%MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%GNU General Public License for more details.
%
%You should have received a copy of the GNU General Public License
%along with this program; if not, write to the Free Software
%Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
%USA.
%--------------------------------------------------------------------------

bch51_8poly = 763; %%/* BCH Polynomial Coefficient (Octal) */ ...
     
T1o = oct2poly(bch51_8poly,'ascending')*(-2)+1;   %/* BCH Polynomial Coefficient */

T1 = ones(1,8); T1(1:length(T1o)-1) = T1o(2:end);  
    
R1 = x(1:8);

P = 1;
for i=1:51
    S(i)=R1(8);
    
    C1 = 1; 
    for j=1:8
        if (T1(j)==-1)
            C1 = C1*R1(j);
        end
    end
    
    R1(2:end) = R1(1:end-1);
    
    R1(1) = C1;
    P = P*S(i);    
end

 enc_bits(1) = P*x(9);
 enc_bits(2) = S(1)*x(9);
 enc_bits(3:52) = S(2:51);
