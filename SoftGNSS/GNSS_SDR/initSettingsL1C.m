function settings = initSettingsL1C()
%Functions initializes and saves settings. Settings can be edited inside of
%the function, updated from the command line or updated using a dedicated
%GUI - "setSettings".  
%
%All settings are described inside function code.
%
%settings = initSettings()
%
%   Inputs: none
%
%   Outputs:
%       settings     - Receiver settings (a structure). 

%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
% 
% Copyright (C) Darius Plausinaitis
% Written by Darius Plausinaitis
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

% CVS record:
% $Id: initSettings.m,v 1.9.2.31 2006/08/18 11:41:57 dpl Exp $

%% Processing settings ====================================================
% Number of milliseconds to be processed used 36000 + any transients (see
% below - in Nav parameters) to ensure nav subframes are provided
settings.msToProcess        = 65000;        %[ms]

% Number of channels to be used for signal processing
settings.numberOfChannels   = 12;

% Move the starting point of processing. Can be used to start the signal
% processing at any point in the data record (e.g. for long records). fseek
% function is used to move the file read point, therefore advance is byte
% based only. 
settings.skipNumberOfBytes     = 0e6; 

%% Raw signal file name and other parameter ===============================
% This is a "default" name of the data file (signal record) to be used in
% the post-processing mode

% 120s sample worked!
%settings.fileName = ...
%     '/media/shinge/WD1TB2/HackRF/gpsL1_HackRF_Fs4M096_Fq157542_20210220_l40_a1_g36_p1_S1s_csac_4'; 
settings.fileName = ...
     '/home/shinge/Downloads/SpaceWire_Test_20210309_095013_RawData_L1C.bin'; 
settings.dataType           = 'schar';       % uchar, schar = 1 byte
settings.fileType           = 2;             % 2 = IQ, 1 = Real
settings.dataSize           = 1;             % bytes
settings.IF                 = 4.092e6;           % [Hz]
settings.samplingFreq       = 16.368e6;       % [Hz]
% looking for 1,3,9,11,14,16,22,23,26,32, 235

% File Types
%1 - 8 bit real samples S0,S1,S2,...
%2 - 8 bit I/Q samples I0,Q0,I1,Q1,I2,Q2,...                      

settings.codeFreqBasis      = 1.023e6;      %[Hz]

% Define number of chips in a code period
settings.codeLength         = 10230;

% Define code selection
settings.codeSelection      = 3;            % 1 = L1CD, 2 = L1CP, 3 = L1CD/P

%% Acquisition settings ===================================================
% Skips acquisition in the script postProcessing.m if set to 1
settings.skipAcquisition    = 0;
% List of satellites to look for. Some satellites can be excluded to speed
% up acquisition
%settings.acqSatelliteList   = [4 14 18 23];         %[PRN numbers]
settings.acqSatelliteList   = [1:32];% 5 6];         %[PRN numbers]
% Band around IF to search for s」atellite signal. Depends on max Doppler
settings.acqSearchBand      = 10;           %[kHz] total bandwidth not one side!
settings.acqSearchBin       = 50;          %[Hz]  Bin size
% Threshold for the signal presence decision rule
settings.acqThreshold       = 1.75;

%% Tracking loops settings ================================================
% Code tracking loop parameters
settings.dllDampingRatio         = 0.7;
settings.dllNoiseBandwidth       =   2;       %[Hz]
settings.dllCorrelatorSpacing    = 0.2;     %[chips]

% Carrier tracking loop parameters
settings.pllDampingRatio         = 0.7;
settings.pllNoiseBandwidth       = 2.5;      %[Hz]

%% Navigation solution settings ===========================================

% Period for calculating pseudoranges and position
settings.navSolPeriod       = 100;          %[ms]

% Elevation mask to exclude signals from satellites at low elevation
settings.elevationMask      = 10;           %[degrees 0 - 90]
% Enable/dissable use of tropospheric correction
settings.useTropCorr        = 1;            % 0 - Off
                                            % 1 - On

% True position of the antenna in UTM system (if known). Otherwise enter
% all NaN's and mean position will be used as a reference .
settings.truePosition.E     = nan;
settings.truePosition.N     = nan;
settings.truePosition.U     = nan;

%% Plot settings ==========================================================
% Enable/disable plotting of the tracking results for each channel
settings.plotTracking       = 1;            % 0 - Off
                                            % 1 - On

%% Constants ==============================================================
settings.c                  = 299792458;    % The speed of light, [m/s]
settings.startOffset        = 68.802;       %[ms] Initial sign. travel time
% Results are insensitive to value of startOffset it is an initial guess.

%% CNo Settings============================================================
% Accumulation interval in Tracking (in Sec)
settings.CNo.accTime=0.01;
% Show C/No during Tracking;1-on;0-off;
settings.CNo.enableVSM=1;
% Accumulation interval for computing VSM C/No (in ms)
settings.CNo.VSMinterval=400;
% Accumulation interval for computing PRM C/No (in ms)
settings.CNo.PRM_K=200;
% No. of samples to calculate narrowband power;
% Possible Values for M=[1,2,4,5,10,20];
% K should be an integral multiple of M i.e. K=nM
settings.CNo.PRM_M=20;
% Accumulation interval for computing MOM C/No (in ms)
settings.CNo.MOMinterval=200;
% Enable/disable the C/No plots for all the channels
% 0 - Off ; 1 - On;
settings.CNo.Plot = 1;