function navBits = postNavigationL1C(trackResults, settings)
%Function calculates navigation solutions for the receiver (pseudoranges,
%positions). At the end it converts coordinates from the WGS84 system to
%the UTM, geocentric or any additional coordinate system.
%
%[navSolutions, eph] = postNavigation(trackResults, settings)
%
%   Inputs:
%       trackResults    - results from the tracking function (structure
%                       array).
%       settings        - receiver settings.
%   Outputs:
%       navSolutions    - contains measured pseudoranges, receiver
%                       clock error, receiver coordinates in several
%                       coordinate systems (at least ECEF and UTM).
%       eph             - received ephemerides of all SV (structure array).

%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
% 
% Copyright (C) Darius Plausinaitis
% Written by Darius Plausinaitis with help from Kristin Larson
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

%CVS record:
%$Id: postNavigation.m,v 1.1.2.22 2006/08/09 17:20:11 dpl Exp $

%% Check is there enough data to obtain any navigation solution ===========
% It is necessary to have at least three subframes (number 1, 2 and 3) to
% find satellite coordinates. Then receiver position can be found too.
% The function requires all 5 subframes, because the tracking starts at
% arbitrary point. Therefore the first received subframes can be any three
% from the 5.
% One subframe length is 6 seconds, therefore we need at least 30 sec long
% record (5 * 6 = 30 sec = 30000ms). We add extra seconds for the cases,
% when tracking has started in a middle of a subframe.

if (settings.msToProcess < 36000) || (sum([trackResults.status] ~= '-') < 4)
    % Show the error message and exit
    disp('Record is to short or too few satellites tracked. Exiting!');
    navSolutions = [];
    eph          = [];
    return
end

%% Initialize navbit structure ============================================
numOfFrame = floor(settings.msToProcess/18000);
% Navbit status
navBits.status               = '-';

% Subframe one TOI
navBits.TOI                  = zeros(1, numOfFrame);
navBits.bitPolarity          = zeros(1, numOfFrame);

% Subframe two bits
navBits.subframe2Bits        = zeros(576, numOfFrame);

% Subframe two CRC
navBits.subframe2Crc         = zeros(1, numOfFrame);

% Subframe three bits
navBits.subframe3Bits        = zeros(250, numOfFrame);

% Subframe two CRC
navBits.subframe3Crc         = zeros(1, numOfFrame);

%--- Copy initial settings for all channels -------------------------------
if settings.codeSelection == 3
    navBits = repmat(navBits, 1, settings.numberOfChannels*2);
else
    navBits = repmat(navBits, 1, settings.numberOfChannels);
end


%% Find preamble start positions ==========================================

[subFrameStart, activeChnList] = findFrameStart(trackResults, settings);

%% Make BCH Table and LDPC matrices
% BCH encoded TOI for subframe 1
toiTable = 0:511;
toiBchEncoded = zeros(length(toiTable),52);
for i = 1 : length(toiTable)
    toiBchEncoded(i,:) = (encodeL1cBCH((de2bi(toiTable(i),9)*(-2)+1)));
end

% LDPC matrix for subframe 2
dimA = [599 600];
dimB = [599 1];
dimC = [1 600];
dimD = [1 1];
dimE = [1 599];
dimT = [599 599];
fileA = 'sub2_LDPC_H_A';
fileB = 'sub2_LDPC_H_B';
fileC = 'sub2_LDPC_H_C';
fileD = 'sub2_LDPC_H_D';
fileE = 'sub2_LDPC_H_E';
fileT = 'sub2_LDPC_H_T';
H2 = generateLDPCmatixH(dimA,dimB,dimC,dimD,dimE,dimT,fileA,fileB,fileC,fileD,fileE,fileT);

% LDPC matrix for subframe 3
dimA = [273 274];
dimB = [273 1];
dimC = [1 274];
dimD = [1 1];
dimE = [1 273];
dimT = [273 273];
fileA = 'sub3_LDPC_H_A';
fileB = 'sub3_LDPC_H_B';
fileC = 'sub3_LDPC_H_C';
fileD = 'sub3_LDPC_H_D';
fileE = 'sub3_LDPC_H_E';
fileT = 'sub3_LDPC_H_T';
H3 = generateLDPCmatixH(dimA,dimB,dimC,dimD,dimE,dimT,fileA,fileB,fileC,fileD,fileE,fileT);


%% Decode ephemerides =====================================================

for channelNr = activeChnList

    if trackResults(channelNr).codeSelection == "L1CD"
        navBits(channelNr).status               = "nav";

        %=== Convert tracking output to navigation bits =======================
        for frameNr = 1:numOfFrame
            %---Subframe 1: look for the highest TOI   ---------------
            frameOne = trackResults(channelNr).I_P(subFrameStart(channelNr)+(frameNr-1)*1800:subFrameStart(channelNr)+(frameNr-1)*1800+51);
            corr = toiBchEncoded*frameOne';
            [~, maxIdx] = max(abs(corr));
            navBits(channelNr).TOI(frameNr) = maxIdx - 1; 
            navBits(channelNr).bitPolarity(frameNr) = sign(corr(maxIdx));

            %---Deinterleave for subframe 2 and 3  ---------------
            interleaveIP = trackResults(channelNr).I_P(subFrameStart(channelNr)+(frameNr-1)*1800+52:subFrameStart(channelNr)+(frameNr)*1800-1);
            deInterleaveIP = reshape((reshape(interleaveIP,38,46))',1,1748)*sign(corr(maxIdx));
            
            frameTwo = deInterleaveIP(1:1200);
            frameThr = deInterleaveIP(1201:end); 
            
            %---Subframe 2: decode LDPC  ---------------
            postLDPCFrameTwo = decodeLogDomainSimple(-frameTwo', H2, 5);
            navBits(channelNr).subframe2Bits(:,frameNr) = postLDPCFrameTwo(1:576)';
            navBits(channelNr).subframe2Crc(frameNr) = crcCheck(postLDPCFrameTwo(1:600),576);
            
            %---Subframe 3: decode LDPC  ---------------
            postLDPCFrameThr = decodeLogDomainSimple(-frameThr', H3, 5);
            navBits(channelNr).subframe3Bits(:,frameNr) = postLDPCFrameThr(1:250)';
            navBits(channelNr).subframe3Crc(frameNr) = crcCheck(postLDPCFrameThr(1:274),250);

        end
    end
end

