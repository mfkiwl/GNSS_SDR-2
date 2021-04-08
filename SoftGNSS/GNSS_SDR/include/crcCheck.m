function f = crcCheck(rx,msgLen)
% crcCheck.m check received message passing the crc
% crcCheck(rx,msgLen)
%   Inputs:
%       rx              - received message including crc.
%       msgLen          - message length excluding crc.
%
%   Outputs:
%       f               - crc checking result   
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

%CRC polynomial
divisor = [ 1,1,0,0,0,0,1,1,0,0, ...
            1,0,0,1,1,0,0,1,1,1, ...
            1,1,0,1,1 ...
          ];  

dividend = rx;
dividend(msgLen+1:end) = 0;
crcRx = rx(msgLen+1:end);

% Modulo-2 division
for i = 1:msgLen	
    if dividend(i) == 1    
        for j=1:length(divisor)
            dividend(j+i-1) = xor(dividend(j+i-1),divisor(j));
        end
    end	
end

% Check received CRC with generated 
if dividend(msgLen+1:end) == crcRx
    f = 1;
else
	f = 0;
end