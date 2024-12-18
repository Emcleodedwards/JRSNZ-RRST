%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% JRSNZ RRST ANALYSIS: CALCULATE METRICS %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
% Ella McLeod
% Created: 07/07/2024
% -------------------------------------------------------------------------
% TO RUN:   metrics     = RRST_calcMetrics(options, behaviour, physiology)
% INPUTS:   options     = PPID-specific matrix output from RRST_setOptions
%           behaviour   = Structure with task and response data for the
%                         specific task type (RRST)
%           physiology  = Structure with preprocessed physiology data for 
%                         the specific task type (RRST)
% OUTPUTS:  metrics     = Structure with interoceptive metrics
% -------------------------------------------------------------------------
% DESCRIPTION:
% This script calculates the summary interoceptive metrics for the 
% Respiratory Resistance Sensitivity Task. The  
% data was collected as part of a study conducted at the University of
% Otago, within the Department of Psychology and School of Pharmacy.
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

function metrics = RRST_calcMetrics(options, behaviour, physiology, slopeEst)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIRM PRESENCE OF INPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check inputs and label the outputs, ignore instances where data
% are missing assign 'skip' label
if strcmp(behaviour.type, 'RRST') && strcmp(physiology.type, 'RRST')
    metrics.type = 'RRST';
elseif strcmp(behaviour.type, 'skip') && strcmp(physiology.type, 'skip')
    metrics.type = 'skip';
    return;
else
    error('Incorrect task type specified (should be RRST) - check all required files are present for all participants');
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE THE TASK ACCURACY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calculate accuracy
metrics.accuracy = nanmean(behaviour.trials.correct);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE SENSITIVITY METRICS - Using Weibull PF, and Weber Contrast
% Values for both pressure and resistance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calculate sensitivity
metrics.sensitivity = [];

% Replace zeros with NaN in the weber contrast arrays to avoid taking the
% log of 0
physiology.trials.webers_contrast.pressure(physiology.trials.webers_contrast.pressure == 0) = NaN;
physiology.trials.webers_contrast.resistance(physiology.trials.webers_contrast.resistance == 0) = NaN;

% Log transform and avereage pressure and resistance
metrics.sensitivity.meanPressure = nanmean(log10(physiology.trials.webers_contrast.pressure));
metrics.sensitivity.meanResistance = nanmean(log10(physiology.trials.webers_contrast.resistance));

% Calculate average number of steps (intensity)
metrics.sensitivity.intensity = nanmean(behaviour.trials.intensity);

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
metrics.sensitivity.stimulusLevelsPressure = unique(roundedPressure); % extract all unique rounded pressure values

% Predefine nCorrectP and nIncorrectP length based on binIndices
metrics.sensitivity.nCorrectPressure = zeros(size(metrics.sensitivity.stimulusLevelsPressure));
metrics.sensitivity.nIncorrectPressure = zeros(size(metrics.sensitivity.stimulusLevelsPressure));

% Iterate through each bin in binIndices
for i = 1:length(metrics.sensitivity.stimulusLevelsPressure) 
    level = metrics.sensitivity.stimulusLevelsPressure(i);

     % Filter correct trials based on the current level and non-NaN
     % pressure
      correct_trials = behaviour.trials.correct == 1 & ~isnan(roundedPressure);
      metrics.sensitivity.nCorrectPressure(i) = sum(correct_trials & (roundedPressure == level));
    
     % Filter incorrect trials based on the current level and non-NaN
     % pressure
      incorrect_trials = behaviour.trials.correct == 0 & ~isnan(roundedPressure);
      metrics.sensitivity.nIncorrectPressure(i) = sum(incorrect_trials & (roundedPressure == level));

end

% Remove NaN Values e.g., those rows corresponding to trials with pressure outside of expected pressure levels
nanRows = isnan(metrics.sensitivity.stimulusLevelsPressure);
metrics.sensitivity.stimulusLevelsPressure(nanRows) = []; % Remove NaN values from binIndices/stimulus input levels for PF
metrics.sensitivity.nCorrectPressure(nanRows) = []; % Remove rows corresponding NaN values in binIndices from nCorrectPressure/number of correct trials per stimulus input level
metrics.sensitivity.nIncorrectPressure(nanRows) = []; % Remove rows corresponding NaN values in binIndices from nInorrectPressure/number of incorrect trials per stimulus input leve

% FitWeibAlphTAFC for Pressure Weber Contrast Value
[metrics.sensitivity.pressureAlpha , metrics.sensitivity.pressureSlope , metrics.sensitivity.pressureThresh92] = FitWeibAlphTAFC(metrics.sensitivity.stimulusLevelsPressure, metrics.sensitivity.nCorrectPressure, metrics.sensitivity.nIncorrectPressure,[], slopeEst);

% calculated total number of trials at each stimulus level
metrics.sensitivity.nTotalPressure = metrics.sensitivity.nCorrectPressure + metrics.sensitivity.nIncorrectPressure


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE THE METACOGNITIVE BIAS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calculate metacognitive bias/sensibility
% Round confidence to closest 10, in alignment with discrete confidence
% scale granularity in VPT
confidence = round(behaviour.trials.confidence, -1);

% Calculate Mean confidence
metrics.confidence = nanmean(confidence);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE THE METACOGNITIVE PERFORMANCE/INSIGHT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calculate metacognitive performance/otherwise known as insight (area under the type2ROC curve)
correct = behaviour.trials.correct;
% confidence = round(behaviour.trials.confidence, -1); defined above.

% Remove trials with NaN values for confidence from both confidence and
% correct indexes
nanIndices = isnan(correct) | isnan(confidence);
confidence(nanIndices) = [];
correct(nanIndices) = [];

Nratings = 101;
a = Nratings+1;
for c = 1:Nratings
        H2(a-1) = length(find(confidence == c & correct)) + 0.5;
        FA2(a-1) = length(find(confidence == c & ~correct)) + 0.5;
        a = a-1;
end
H2 = H2./sum(H2);
FA2 = FA2./sum(FA2);
cum_H2 = [0 cumsum(H2)];
cum_FA2 = [0 cumsum(FA2)];
a=1;
for c = 1:Nratings
        k(a) = (cum_H2(c+1) - cum_FA2(c))^2 - (cum_H2(c) - cum_FA2(c+1))^2;
        a = a+1;
end
metrics.metaPerformance = 0.5 + 0.25*sum(k);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT THE METACOGNITIVE PERFORMANCE/INSIGHT RESULTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plot the area under the Type2ROC curve
figure
plot(cum_FA2, cum_H2, 'ko-', 'linewidth', 1.5, 'markersize', 12);
hold on
ylabel('TYPE2 P(CORRECT)');
xlabel('TYPE2 P(INCORRECT)');
title(sprintf('PARTICIPANT %s: type2ROC = %.2f', options.PPID, metrics.metaPerformance));
set(gca, 'XLim', [0 1], 'YLim', [0 1], 'FontSize', 16);
line([0 1],[0 1],'linestyle','--','color','k','HandleVisibility','off');
axis square
print(fullfile(options.paths.figureFolder, ['figure_autype2ROC_', options.PPID, '_', behaviour.type]), '-dtiff');
close


end