%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% JRSNZ RRST ANALYSIS: PSYCHOMETRIC FUNCTION ESTIMATION - SENSITIVITY %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
% Ella McLeod
% Created: 07/07/2024
% -------------------------------------------------------------------------
% TO RUN:   metrics     = RRST_estPF(options, behaviour, physiology)
% INPUTS:   options     = PPID-specific matrix output from RRST_setOptions
%           behaviour   = Structure with task and response data for the
%                         specific task type (RRST)
%           physiology  = Structure with preprocessed physiology data for 
%                         the specific task type (RRST)
% OUTPUTS:  PFmetrics     = Structure with interoceptive metrics
% -------------------------------------------------------------------------
% DESCRIPTION:
% This script calculates the Alpha/threshold sensitivity value for individual 
% participants using Maximum Likelihood, and a fixed slope value from Bayesian
% fit grand mean psychometric function calculated in RRST_analysis_master. 
% The data was collected as part of a study conducted 
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

function PFmetrics = RRST_estPF(options, behaviour, physiology)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIRM PRESENCE OF INPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check inputs and label the outputs, ignore post instances where post data
% are missing assign 'skip' label
if strcmp(behaviour.type, 'RRST') && strcmp(physiology.type, 'RRST')
    PFmetrics.type = 'RRST';
elseif strcmp(behaviour.type, 'skip') && strcmp(physiology.type, 'skip')
    PFmetrics.type = 'skip';
    return;
else
    error('Incorrect task type specified (should be RRST) - check all required files are present');
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ESTIMATE SENSITIVITY - Using Weibull PF, and Weber Contrast
% Values for Pressure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Estimate Sensitivity Psychometric Function
PFmetrics = [];

% Replace zeros with NaN in the weber contrast arrays to avoid taking the
% log of 0
physiology.trials.webers_contrast.pressure(physiology.trials.webers_contrast.pressure == 0) = NaN;

%% Calculate Sensitivity using FitWeib function from Psychtoolbox for pressure and resistance variables
%  INPUTS required for FitWeibTAFC:
%  levels = webers_contrast values for pressure and resistance
%  nCorrect = Number of correct responses for each weber contrast value
%  nIncorrect = Number of Incorrect responses for each weber contrast value

%% Interoceptive Sensitivity - Pressure
% Find PF for Pressure Weber Contrast Values
pressure = physiology.trials.webers_contrast.pressure;

% Round the pressure values to the nearest 0.05 to allow for calculation of
% psychometeric function
roundedPressure = round(pressure / 0.05) * 0.05;

% Create unique stimulus levels based on roundedPressure Values
PFmetrics.stimulusLevelsPressure = unique(roundedPressure); % extract all unique rounded pressure values

% Predefine nCorrectP and nIncorrectP length based on binIndices
PFmetrics.nCorrectPressure = zeros(size(PFmetrics.stimulusLevelsPressure));
PFmetrics.nIncorrectPressure = zeros(size(PFmetrics.stimulusLevelsPressure));

% Iterate through each bin in binIndices
for i = 1:length(PFmetrics.stimulusLevelsPressure) 
    level = PFmetrics.stimulusLevelsPressure(i);

     % Filter correct trials based on the current level and non-NaN
     % pressure
      correct_trials = behaviour.trials.correct == 1 & ~isnan(roundedPressure);
      PFmetrics.nCorrectPressure(i) = sum(correct_trials & (roundedPressure == level));
    
     % Filter incorrect trials based on the current level and non-NaN
     % pressure
      incorrect_trials = behaviour.trials.correct == 0 & ~isnan(roundedPressure);
      PFmetrics.nIncorrectPressure(i) = sum(incorrect_trials & (roundedPressure == level));

end

% Remove NaN Values e.g., those rows corresponding to trials with pressure outside of expected pressure levels
nanRows = isnan(PFmetrics.stimulusLevelsPressure);
PFmetrics.stimulusLevelsPressure(nanRows) = []; % Remove NaN values from binIndices/stimulus input levels for PF
PFmetrics.nCorrectPressure(nanRows) = []; % Remove rows corresponding NaN values in binIndices from nCorrectPressure/number of correct trials per stimulus input level
PFmetrics.nIncorrectPressure(nanRows) = []; % Remove rows corresponding NaN values in binIndices from nInorrectPressure/number of incorrect trials per stimulus input leve

% FitWeibTAFC for Pressure Weber Contrast Value
[PFmetrics.pressureAlpha , PFmetrics.pressureSlope , PFmetrics.pressureThresh92] = FitWeibTAFC(PFmetrics.stimulusLevelsPressure, PFmetrics.nCorrectPressure, PFmetrics.nIncorrectPressure);

% calculated total number of trials at each stimulus level for grand mean figure
PFmetrics.nTotalPressure = PFmetrics.nCorrectPressure + PFmetrics.nIncorrectPressure

