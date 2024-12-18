%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% JRSNZ RRST ANALYSIS: EXTRACT BEHAVIOUR %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
% Ella McLeod
% Created: 07/07/2024
% -------------------------------------------------------------------------
% TO RUN:   behaviour   = RRST_extractBehaviour(options, type)
% INPUTS:   options     = PPID-specific matrix output from RRST_setOptions
%           type        = 'RRST'
% OUTPUTS:  behaviour   = Structure with task and response metrics
% -------------------------------------------------------------------------
% DESCRIPTION:
% This script extracts the task and behavioural data related to the
% Respiratory Resistance Sensitivity Task. The data was collected as part of a 
% study conducted at the University of Otago, within the Department of 
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

function behaviour = RRST_extractBehaviour(options, type)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD AND SORT THE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create empty behaviour structure to store data
behaviour = struct();

% Load and sort data depending on type (pre/post session), if type = 'skip'
% assign 'skip'
if strcmp(type, 'RRST')
    behaviour.type = 'RRST';
    behaviour.raw = load(options.fileNames.RRST.beh);
    behaviour.trials.intensity = behaviour.raw.Results.Stim;
    behaviour.trials.interval = behaviour.raw.Results.SignalInterval;
    behaviour.trials.response = behaviour.raw.Results.SignalInterval;
    behaviour.trials.correct = behaviour.raw.Results.Resp;
    behaviour.trials.confidence = behaviour.raw.Results.ConfResp;
    behaviour.pmFit.threshold = behaviour.raw.stair.PM.threshold;
    behaviour.pmFit.slope = behaviour.raw.stair.PM.slope;
elseif strcmp(type, 'skip')
    behaviour.type = 'skip';
    return;
else
    error('Incorrect task type specified (should be RRST)');
end


end