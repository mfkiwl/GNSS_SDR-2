function H = generateLDPCmatixH(dimA,dimB,dimC,dimD,dimE,dimT,fileA,fileB,fileC,fileD,fileE,fileT)
% generateLDPCmatixH.m read LDPC Table file tables to assemble parity check matrix
% generateLDPCmatixH(dimA,dimB,dimC,dimD,dimE,dimT,fileA,fileB,fileC,fileD,fileE,fileT)
%   Inputs:
%       dimA            - dimemsion A.
%       dimB            - dimemsion B.
%       dimC            - dimemsion C.
%       dimD            - dimemsion D.
%       dimE            - dimemsion E.
%       dimT            - dimemsion T.
%       fileA           - file path and name for A.
%       fileB           - file path and name for B.
%       fileC           - file path and name for C.
%       fileD           - file path and name for D.
%       fileE           - file path and name for E.
%       fileT           - file path and name for T.
%
%   Outputs:
%       H               - parity check matrix   
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

%% Initialize Matrices
A = zeros(dimA);
B = zeros(dimB);
C = zeros(dimC);
D = zeros(dimD);
E = zeros(dimE);
T = zeros(dimT);
%% Read table from files
[rowA, columnA]= readLDPCTable2RC(fileA);
[rowB, columnB]= readLDPCTable2RC(fileB);
[rowC, columnC]= readLDPCTable2RC(fileC);
[rowD, columnD]= readLDPCTable2RC(fileD);
[rowE, columnE]= readLDPCTable2RC(fileE);
[rowT, columnT]= readLDPCTable2RC(fileT);


A(rowA + (columnA-1)*dimA(1)) = 1;
B(rowB + (columnB-1)*dimB(1)) = 1;
C(rowC + (columnC-1)*dimC(1)) = 1;
D(rowD + (columnD-1)*dimD(1)) = 1;
E(rowE + (columnE-1)*dimE(1)) = 1;
T(rowT + (columnT-1)*dimT(1)) = 1;

%% Assemble H
H = [A B T;C D E];