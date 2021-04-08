function L1CCodesTable = makeL1CTable(settings)
%Function generates L1C codes for all 32 satellites based on the settings
%provided in the structure "settings". The codes are digitized at the
%sampling frequency specified in the settings structure.
%One row in the "L1CCodesTable" is one L1C code. The row number is the PRN
%number of the L1C code.
%
%L1CCodesTable = makeL1CTable(settings)
%
%   Inputs:
%       settings        - receiver settings
%   Outputs:
%       L1CCodesTable  - an array of arrays (matrix) containing L1C codes
%                       for all satellite PRN-s
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


%--- Find number of samples per spreading code ----------------------------
samplesPerCode = round(settings.samplingFreq / ...
                           (settings.codeFreqBasis / settings.codeLength));

%--- Prepare the output matrix to speed up function -----------------------
L1CCodesTable = zeros(32, samplesPerCode);
bocCodes = [1 -1]; 
%--- Find time constants --------------------------------------------------
ts = 1/settings.samplingFreq;       % Sampling period in sec
tc = 1/settings.codeFreqBasis;      % L1CD chip period in sec
tBoc = 1/settings.codeFreqBasis/2;  % BOC code period in sec 
%=== For all satellite PRN-s ...
for PRN = 1:32
    %--- Generate L1CD code for given PRN -----------------------------------
    if settings.codeSelection > 1
        L1CCode = generateL1CPcode(PRN);
    else
        L1CCode = generateL1CDcode(PRN);
    end
 
    %=== Digitizing =======================================================
    
    %--- Make index array to read L1CD code values -------------------------
    % The length of the index array depends on the sampling frequency -
    % number of samples per millisecond (because one L1CD code period is one
    % millisecond).
    codeValueIndex = ceil((ts * (1:samplesPerCode)) / tc);
    
    %--- Correct the last index (due to number rounding issues) -----------
    codeValueIndex(end) = 10230;
    
    %--- Make index array to read BOC code values -------------------------
    % The length of the index array depends on the sampling frequency -
    % number of samples per millisecond (because one BOC code period is one
    % millisecond).
    bocCodeValueIndex = mod(floor((ts * (1:samplesPerCode)) / tBoc),size(bocCodes,2)) + 1;
    
    bocCodeValueIndex(end) = 2;
    %--- Make the digitized version of the C/A code -----------------------
    % The "upsampled" code is made by selecting values form the L1CD code
    % chip array (caCode) for the time instances of each sample.
    L1CCodesTable(PRN, :) = L1CCode(codeValueIndex) .* bocCodes(bocCodeValueIndex);
    
end % for PRN = 1:32
