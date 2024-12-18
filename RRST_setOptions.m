%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% JRSNZ RRST ANALYSIS: SET OPTIONS %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
% Ella McLeod
% Created: 07/07/2024
% -------------------------------------------------------------------------
% DESCRIPTION:
% This script sets the options for the physiological and perceptual data
% related to RRST Task. The data was collected as part of a study conducted 
% at the University of Otago, within the Department of 
% Psychology and School of Pharmacy.
% -------------------------------------------------------------------------
% LICENCE:
% This software is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the 
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version. This software is distributed in the hope that 
% it will be useful, but WITHOUT ANY WARRANTY; without even the implied 
% warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details: 
% <http://www.gnu.org/licenses/>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function options = RRST_setOptions(PPID)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET THE PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Specify the PPID
options.PPID = PPID;

% Specify the main root
% options.paths.root = '/Users/ella/Desktop/MatLab-RRST-code/';
options.paths.root = '/Users/ella/Library/Mobile Documents/com~apple~CloudDocs/MSc/MSc-PB/PB-analysiscode/PB-RRSTAnalysis';

% Specify the paths
options.paths.dataFolder = fullfile(options.paths.root, 'data');
options.paths.outputFolder = fullfile(options.paths.root, 'results');
options.paths.figureFolder = fullfile(options.paths.outputFolder, 'figures');
options.paths.scriptFolder = fullfile(options.paths.root, 'scripts');

% Add necessary paths
addpath(options.paths.scriptFolder);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET THE INPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Specify the files
options.fileNames.RRST.beh = fullfile(options.paths.dataFolder, ['sub-', PPID], 'beh', ['sub-', PPID, '_task-RRST_beh.mat']);
options.fileNames.RRST.physio = fullfile(options.paths.dataFolder, ['sub-', PPID], 'beh', ['sub-', PPID, '_task-RRST_physio.mat']);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET THE OUTPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Specify the file names
options.fileNames.saveNames.matMatrix = fullfile(options.paths.outputFolder, 'results-RRST.mat');
options.fileNames.saveNames.excel = fullfile(options.paths.outputFolder, 'results-RRST.xlsx');


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET ANY FIGURE FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Specify the file names
options.fileNames.saveNames.examplePhysFig = fullfile(options.paths.figureFolder, 'results-examplePhysFig');


end