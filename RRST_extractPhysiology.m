%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% JRSNZ RRST ANALYSIS: EXTRACT PHYSIOLOGY %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
% Ella McLeod
% Created: 07/07/2024
% -------------------------------------------------------------------------
% TO RUN:   physiology  = RRST_extractPhysiology(options, behaviour)
% INPUTS:   options     = PPID-specific matrix output from RRST_setOptions
%           behaviour   = Structure with task and response metrics for the
%                         specific task type (RRST)
% OUTPUTS:  physiology  = Structure with preprocessed physiology
% -------------------------------------------------------------------------
% DESCRIPTION:
% This script extracts the physiology data related to the Respiratory Resistance Sensitivity Task.
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

function physiology = RRST_extractPhysiology(options, behaviour)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD THE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load the raw data according to pre/post task type, if no post files exist
% assign 'skip'
if strcmp(behaviour.type, 'RRST')
    physiology.type = 'RRST';
    raw = load(options.fileNames.RRST.physio);
elseif strcmp(behaviour.type, 'skip') 
    physiology.type = 'skip';
    return;
else
    error('Incorrect task type specified (should be RRST)');
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SEPARATE CHANNEL DATA 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
% Pull out each of the channels
physiology.raw.names = {'InspPressure', 'Flow', 'FlowSmoothed', 'Triggers', 'MaxInsp'};
    for a = 1:length(raw.datastart)
        physiology.raw.data(:,a) = raw.data(raw.datastart(a,1):raw.dataend(a,1));
    end

% Check and adjust for multiple blocks
if size(raw.datastart,2) > 1
   for b = 2:size(raw.datastart,2)
       for a = 1:length(raw.datastart)
           dataExtra(:,a) = raw.data(raw.datastart(a,b):raw.dataend(a,b));
       end
       physiology.raw.data = [physiology.raw.data; dataExtra];
       clear dataExtra;
   end
end

% Binarise the trigger channel
physiology.raw.data(:,4) = physiology.raw.data(:,4) > 2;

% Convert the pressure channel from mm Hg to cm H2O
physiology.raw.data(:,1) = physiology.raw.data(:,1) .* 1.35951;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIND THE TRIAL INDICES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate the gradient of the triggers
trigSlope = gradient(physiology.raw.data(:,4));
% Find where the gradient slopes up
[pks, physiology.raw.trialIndices] = findpeaks(trigSlope);


% Check and adjust for multiple blocks
if size(raw.datastart,2) > 1
   for b = 2:size(raw.datastart,2)
       vals = find(raw.com(:,2) == b);
       physiology.raw.trialIndices(vals) = raw.com(vals,3) + (raw.dataend(1,1) * (b - 1));
   end
end

% Check for any repeated trials and remove trial indices
if any(behaviour.raw.Results.trialRepeats) == 1
   idxDelete = (find(behaviour.raw.Results.trialRepeats ~= 0)) * 2; % Two breaths in each trial
   for a = 1:length(idxDelete)
       physiology.raw.trialIndices(idxDelete(a):(idxDelete(a)+1)) = [];
   end
   % Check that trial index sum now = 200 for RRST
   if length(physiology.raw.trialIndices) == 200
   else
      disp(['WARNING: TRIAL INDEX LENGTH NOT 100 FOR PPID ' num2str(options.PPID) behaviour.type ' --> PLEASE CHECK!']);
   end
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIND THE TRIAL-WISE PHYSIOLOGY MEASURES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find the physiology values at each trial breath
for a = 1:length(physiology.raw.trialIndices)
    if a < length(physiology.raw.trialIndices)
       breathIdx = find((physiology.raw.data(physiology.raw.trialIndices(a):physiology.raw.trialIndices(a+1),5) == 1), 1) + physiology.raw.trialIndices(a);
    elseif a == length(physiology.raw.trialIndices)
       breathIdx = find((physiology.raw.data(physiology.raw.trialIndices(a):end,5) == 1), 1) + physiology.raw.trialIndices(a);
    end
    if ~isempty(breathIdx)
       physiology.trials.total.flow(a,1) = abs(physiology.raw.data(breathIdx,3));
       physiology.trials.total.pressure(a,1) = abs(physiology.raw.data(breathIdx,1) - physiology.raw.data(physiology.raw.trialIndices(a),1));
       physiology.trials.total.resistance(a,1) = physiology.trials.total.pressure(a) / physiology.trials.total.flow(a);
    else
    physiology.trials.total.pressure(a,1) = NaN;
    physiology.trials.total.flow(a,1) = NaN;
    physiology.trials.total.resistance(a,1) = NaN;
    end
end

% Find the physiology values between trial breaths
oddNums = 1:2:length(physiology.raw.trialIndices);
evenNums = 2:2:length(physiology.raw.trialIndices);
physiology.trials.diffs.pressure = abs(physiology.trials.total.pressure(evenNums) - physiology.trials.total.pressure(oddNums));
physiology.trials.diffs.flow = abs(physiology.trials.total.flow(evenNums) - physiology.trials.total.flow(oddNums));
physiology.trials.diffs.resistance = abs(physiology.trials.total.resistance(evenNums) - physiology.trials.total.resistance(oddNums));

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CREATE TRIAL WISE COMPARISON PAIRS FOR WEBER CONTRAST FOR RESISTANCE AND
% PRESSURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Pressure Values for Trial Breath Pairs
physiology.trials.comp.pressure = [physiology.trials.total.pressure(1:2:end-1),physiology.trials.total.pressure(2:2:end)];
% Resistance Values for Trial Breath Pairs
physiology.trials.comp.resistance = [physiology.trials.total.resistance(1:2:end-1),physiology.trials.total.resistance(2:2:end)];

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE WEBER CONTRAST VALUE FOR RESISTANCE AND PRESSURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Weber Contrast Values for Pressure
% Initialize a vector to store the Weber contrast values
physiology.trials.webers_contrast.pressure = zeros(size(physiology.trials.diffs.pressure));
% Iterate through rows
for i = 1:size(physiology.trials.webers_contrast.pressure, 1)
    % Calculate the Weber contrast for the current row
    physiology.trials.webers_contrast.pressure(i, :) = physiology.trials.diffs.pressure(i, :)/(min(physiology.trials.comp.pressure(i, :))); 
end
physiology.trials.webers_contrast.pressure = round(physiology.trials.webers_contrast.pressure, 2); % round all weber contrast pressure values to 2dp

%Weber Contrast Values for Resistance
% Initialize a vector to store the Weber contrast values
physiology.trials.webers_contrast.resistance = zeros(size(physiology.trials.diffs.resistance));
% Iterate through rows
for i = 1:size(physiology.trials.webers_contrast.resistance, 1)
    % Calculate the Weber contrast for the current row
    physiology.trials.webers_contrast.resistance(i, :) = physiology.trials.diffs.resistance(i, :)/(min(physiology.trials.comp.resistance(i, :))); 
end
physiology.trials.webers_contrast.resistance = round(physiology.trials.webers_contrast.resistance, 2); % round all weber contrast resistance values to 2 dp
 

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK AND REMOVE OUTLIERS - Based on Pressure Weber contrast values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Compute the measure of scale 'Sn', from Rousseeuw & Croux (1993) for
% outlier detection based on weber contrast pressure values

[Sn, x_j] = RousseeuwCrouxSn(physiology.trials.webers_contrast.pressure);

% Identify outlying Weber Contrast Pressure values - median distance (x_j) is more than 3 times the scale estimator (Sn). 
physiology.trials.webers_contrast.outliersP = find(x_j/Sn > 3);

if sum(physiology.trials.webers_contrast.outliersP > 0)
    physiology.trials.webers_contrast.pressure(physiology.trials.webers_contrast.outliersP) = NaN;
    physiology.trials.webers_contrast.resistance(physiology.trials.webers_contrast.outliersP) = NaN;
    physiology.trials.diffs.pressure(physiology.trials.webers_contrast.outliersP) = NaN;
    physiology.trials.diffs.flow(physiology.trials.webers_contrast.outliersP) = NaN;
    physiology.trials.diffs.resistance(physiology.trials.webers_contrast.outliersP) = NaN;
end


end