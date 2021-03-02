function acqResults = acquisitionL1CD(longSignal, settings)
%Function performs cold start acquisition on the collected "data". It
%searches for GPS signals of all satellites, which are listed in field
%"acqSatelliteList" in the settings structure. Function saves code phase
%and frequency of the detected signals in the "acqResults" structure.
%
%acqResults = acquisition(longSignal, settings)
%
%   Inputs:
%       longSignal    - 11 ms of raw signal from the front-end 
%       settings      - Receiver settings. Provides information about
%                       sampling and intermediate frequencies and other
%                       parameters including the list of the satellites to
%                       be acquired.
%   Outputs:
%       acqResults    - Function saves code phases and frequencies of the 
%                       detected signals in the "acqResults" structure. The
%                       field "carrFreq" is set to 0 if the signal is not
%                       detected for the given PRN number. 
 
%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
% 
% Copyright (C) Darius Plausinaitis and Dennis M. Akos
% Written by Darius Plausinaitis and Dennis M. Akos
% Based on Peter Rinder and Nicolaj Bertelsen
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
%$Id: acquisition.m,v 1.1.2.12 2006/08/14 12:08:03 dpl Exp $

%% Initialization =========================================================

% Find number of samples per spreading code
samplesPerCode = round(settings.samplingFreq / ...
                        (settings.codeFreqBasis / settings.codeLength));

% Create two 1msec vectors of data to correlate with and one with zero DC
signal1 = longSignal(1 : samplesPerCode);
signal2 = longSignal(samplesPerCode+1 : 2*samplesPerCode);

signal0DC = longSignal - mean(longSignal);   %%Problems here....

% Find sampling period
ts = 1 / settings.samplingFreq;

% Find phase points of the local carrier wave 
phasePoints = (0 : (samplesPerCode-1)) * 2 * pi * ts;

% Number of the frequency bins for the given acquisition band
numberOfFrqBins = round( (settings.acqSearchBand*1000) / settings.acqSearchBin) + 1;

% Generate all L1CD codes and sample them according to the sampling freq.
L1CDCodesTable = makeL1CDTable(settings);

%--- Initialize arrays to speed up the code -------------------------------
% Search results of all frequency bins and code shifts (for one satellite)
results     = zeros(numberOfFrqBins, samplesPerCode);

% Carrier frequencies of the frequency bins
frqBins     = zeros(1, numberOfFrqBins);


%--- Initialize acqResults ------------------------------------------------
% Carrier frequencies of detected signals
acqResults.carrFreq     = zeros(1, 32);
% L1CD code phases of detected signals
acqResults.codePhase    = zeros(1, 32);
% Correlation peak ratios of the detected signals
acqResults.peakMetric   = zeros(1, 32);

fprintf('(');

% Perform search for all listed PRN numbers ...
for PRN = settings.acqSatelliteList

%% Correlate signals ======================================================   
    %--- Perform DFT of L1CD code ------------------------------------------
    L1CDCodeFreqDom = conj(fft(L1CDCodesTable(PRN, :)));

    %--- Make the correlation for whole frequency band (for all freq. bins)
    for frqBinIndex = 1:numberOfFrqBins

        %--- Generate carrier wave frequency grid -------------------------
        frqBins(frqBinIndex) = settings.IF - ...
                               (settings.acqSearchBand/2) * 1000 + ...
                               settings.acqSearchBin * (frqBinIndex - 1);

        %--- Generate local sine and cosine -------------------------------
        sigCarr = exp(1i*frqBins(frqBinIndex) * phasePoints);
        
        %--- "Remove carrier" from the signal -----------------------------
        I1      = real(sigCarr .* signal1);
        Q1      = imag(sigCarr .* signal1);
        I2      = real(sigCarr .* signal2);
        Q2      = imag(sigCarr .* signal2);

        %--- Convert the baseband signal to frequency domain --------------
        IQfreqDom1 = fft(I1 + 1j*Q1);
        IQfreqDom2 = fft(I2 + 1j*Q2);

        %--- Multiplication in the frequency domain (correlation in time
        %domain)
        convCodeIQ1 = IQfreqDom1 .* L1CDCodeFreqDom;
        convCodeIQ2 = IQfreqDom2 .* L1CDCodeFreqDom;

        %--- Perform inverse DFT and store correlation results ------------
        acqRes1 = abs(ifft(convCodeIQ1)) .^ 2;
        acqRes2 = abs(ifft(convCodeIQ2)) .^ 2;
        
        %--- Check which msec had the greater power and save that, will
        %"blend" 1st and 2nd msec but will correct data bit issues
        if (max(acqRes1) > max(acqRes2))
            results(frqBinIndex, :) = acqRes1;
        else
            results(frqBinIndex, :) = acqRes2;
        end
        
    end % frqBinIndex = 1:numberOfFrqBins

%     figure;
%     mesh(results);
%% Look for correlation peaks in the results ==============================
    % Find the highest peak and compare it to the second highest peak
    % The second peak is chosen not closer than 1 chip to the highest peak
    
    %--- Find the correlation peak and the carrier frequency --------------
    [~, frequencyBinIndex] = max(max(results, [], 2));

    %--- Find code phase of the same correlation peak ---------------------
    [peakSize,  codePhase] = max(max(results));

    %--- Find 1 chip wide L1CD code phase exclude range around the peak ----
    samplesPerCodeChip   = round(settings.samplingFreq / settings.codeFreqBasis);
    excludeRangeIndex1 = codePhase - samplesPerCodeChip;
    excludeRangeIndex2 = codePhase + samplesPerCodeChip;

    %--- Correct L1CD code phase exclude range if the range includes array
    %boundaries
    if excludeRangeIndex1 < 2
        codePhaseRange = excludeRangeIndex2 : ...
                         (samplesPerCode + excludeRangeIndex1);
                         
    elseif excludeRangeIndex2 > samplesPerCode  % PHAHN was >=
        codePhaseRange = (excludeRangeIndex2 - samplesPerCode) : ...
                         excludeRangeIndex1;
                     
    elseif excludeRangeIndex2 == samplesPerCode  % PHAHN was >=
   %     codePhaseRange = (excludeRangeIndex2 - samplesPerCode) : ...
   %                     excludeRangeIndex1;                     
        codePhaseRange = [excludeRangeIndex2, 1 : ...
                         excludeRangeIndex1];

    else
        codePhaseRange = [1:excludeRangeIndex1, ...
                          excludeRangeIndex2 : samplesPerCode];
    end

    %--- Find the second highest correlation peak in the same freq. bin ---
    secondPeakSize = max(results(frequencyBinIndex, codePhaseRange));

    %--- Store result -----------------------------------------------------
    acqResults.peakMetric(PRN) = peakSize/secondPeakSize;
    
    % If the result is above threshold, then there is a signal ...
    if acqResults.peakMetric(PRN) > settings.acqThreshold

%% Fine resolution frequency search =======================================
        
        %--- Indicate PRN number of the detected signal -------------------
        fprintf('%02d ', PRN);
        
        %--- Get 10msec long L1CD codes sequence for given PRN --------
        L1CDCode = L1CDCodesTable(PRN, :);
    
        %--- Remove L1CD code modulation from the original signal ----------
        % (Using detected L1CD code phase)
        xCarrier = ...
            signal0DC(codePhase:(codePhase + samplesPerCode-1)) ...
            .* L1CDCode;
        
        %--- Compute the magnitude of the FFT, find maximum and the
        %associated carrier frequency
        
        %--- Find the next highest power of two and increase by 8x --------
        fftNumPts = 8*(2^(nextpow2(length(xCarrier))));
        
        %--- Compute the magnitude of the FFT, find maximum and the
        %associated carrier frequency 
        fftxc = abs(fft(xCarrier, fftNumPts)); 
        
        
        uniqFftPts = ceil((fftNumPts + 1) / 2);
        [~, fftMaxIndex] = max(fftxc);
        fftFreqBins = (0 : uniqFftPts-1) * settings.samplingFreq/fftNumPts;
        if (fftMaxIndex > uniqFftPts) %and should validate using complex data
            if (rem(fftNumPts,2)==0)  %even number of points, so DC and Fs/2 computed
                fftFreqBinsRev=-fftFreqBins((uniqFftPts-1):-1:2);
                [~, fftMaxIndex] = max(fftxc((uniqFftPts+1):length(fftxc)));
                acqResults.carrFreq(PRN)  = -fftFreqBinsRev(fftMaxIndex);
            else  %odd points so only DC is not included
                fftFreqBinsRev=-fftFreqBins((uniqFftPts):-1:2);
                [~, fftMaxIndex] = max(fftxc((uniqFftPts+1):length(fftxc)));
                acqResults.carrFreq(PRN)  = fftFreqBinsRev(fftMaxIndex);
            end
        else
            acqResults.carrFreq(PRN)  = (-1)^(settings.fileType-1)*fftFreqBins(fftMaxIndex);
        end
        
        acqResults.codePhase(PRN) = codePhase;
    
        if(abs(acqResults.carrFreq(PRN))>=10000)
            %warning(['carrFreq for ' num2str(PRN) ' exceeds 10kHz. Skipping for now. May be bug in code?'])
            acqResults.peakMetric(PRN)   = -1.;
        end
    else
        %--- No signal with this PRN --------------------------------------
        fprintf('. ');
    end   % if (peakSize/secondPeakSize) > settings.acqThreshold
    
end    % for PRN = satelliteList

%=== Acquisition is over ==================================================
fprintf(')\n');
