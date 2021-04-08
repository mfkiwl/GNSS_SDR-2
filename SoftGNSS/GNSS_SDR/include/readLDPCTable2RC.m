function [row, column] = readLDPCTable2RC(filename)
% readLDPCTable2RC.m read LDPC Table file table to form ones of row and column.
%
% readLDPCTable2RC(filename)
%
%   Inputs:
%       filename        - file path and name.
%
%   Outputs:
%       row             - row index.  
%       column          - column index.  
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


%% Set up the Import Options and import the data
dataLines = [1, Inf];
opts = delimitedTextImportOptions("NumVariables", 1);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = "";

% Specify column names and types
opts.VariableNames = "VarName1";
opts.VariableTypes = "string";

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "VarName1", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "VarName1", "EmptyFieldRule", "auto");

% Import the data
c = readmatrix(filename, opts);

%% Read row and column index
row = [];
column = [];
mode = 0; % 0 for row, 1 for column
for i = 1:size(c,1)
    if c(i) == 'R'
        mode = 0;
    elseif c(i) == 'C'
        mode = 1;
    elseif c(i) ~= ','
        if mode == 0
            row = [row str2double(c(i))];
        else
            column = [column str2double(c(i))];
        end        
    end    
end
