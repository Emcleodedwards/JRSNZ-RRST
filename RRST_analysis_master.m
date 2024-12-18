%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% JRSNZ RRST ANALYSIS: MASTER SCRIPT %%%%%%%%%
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
% This script runs the analysis for the physiological and perceptual 
% data related to the Respiratory Resistance Sensitivity Task. 
% The data was collected as part of study conducted at the University of
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
% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET THE OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Specify the PPIDs to analyse
% Enter in all the PPIDs for analyses here:
RRST.options.PPIDs = {'0002', '0002', '0003', '0004', '0005', '0006', '0007', '0008', '0009', '0010', '0011', '0012', '0013', '0014', '0015'};
% Set the options
for a = 1:length(RRST.options.PPIDs)
    RRST.options.setup{a} = RRST_setOptions(RRST.options.PPIDs{a});
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXTRACT THE EXPERIMENTAL AND BEHAVIOURAL MEASURES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Extract the experimental and behavioural measures for pre and post tasks
for a = 1:length(RRST.options.PPIDs)
   % Check if files exist, if files are not found set type to 'skip'
    if ~exist(RRST.options.setup{a}.fileNames.RRST.beh, 'file') || ...
       ~exist(RRST.options.setup{a}.fileNames.RRST.physio, 'file')
        RRST.data{a}.behaviour = RRST_extractBehaviour(RRST.options.setup{a}, 'skip');
    else
        RRST.data{a}.behaviour = RRST_extractBehaviour(RRST.options.setup{a}, 'RRST');
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXTRACT THE PHYSIOLOGY MEASURES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Extract the physiology measures for RRST task (when multiple PPID)
for a = 1:length(RRST.options.PPIDs)
       RRST.data{a}.physiology = RRST_extractPhysiology(RRST.options.setup{a}, RRST.data{a}.behaviour);
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ESTIMATE SENSITIVITY PSYCHOMETRIC FUNCTION - Individual PF Maximum
% Likelihood
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Estimate the Psychometric function parameters for sensitivity
for a = 1:length(RRST.options.PPIDs)
    RRST.data{a}.PFmetrics = RRST_estPF(RRST.options.setup{a}, RRST.data{a}.behaviour, RRST.data{a}.physiology);
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ESTIMATE SENSITIVITY PSYCHOMETRIC FUNCTION - Group Mean Bayesian Pre/one
% Session
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
allThresholds = [];
allSlopes = [];
allStimulusLevels = [];
allResponses = [];
allnPresented = [];

  for a = 1:length(RRST.options.PPIDs)
      % Access session sensitivity data
        Data = RRST.data{a}.PFmetrics;
        % Calculate Threshold and Slope
            threshEst   = Data.pressureAlpha;
            slopeEst    = Data.pressureSlope;

            PF          = @PAL_Weibull;
            gamma       = 0.5;
            lambda      = 0.03;

         % Collect stimuli, responses, and presented trials
            stimuli     = Data.stimulusLevelsPressure;
            responses   = Data.nCorrectPressure;
            nPresented  = Data.nTotalPressure;
            
            % Collect data for grand mean fit
            allThresholds     = [allThresholds; threshEst];
            allSlopes         = [allSlopes; slopeEst];
            allStimulusLevels = [allStimulusLevels; stimuli];
            allResponses      = [allResponses; responses];
            allnPresented     = [allnPresented; nPresented];
    end

% Mean pmf
PF          = @PAL_Weibull;
gamma       = 0.5;
lambda      = 0.03;
grain       = 50;

% Search grid set to same as Nikolova et al., 2022
sgrid.alpha  = linspace(PF([6 2 0 0],.1,'inverse'),PF([6 2 0 0],.9999,'inverse'),grain);
sgrid.beta   = linspace(log10(1),log10(16),grain);
sgrid.gamma  = gamma;
sgrid.lambda = lambda;

stimuli    = allStimulusLevels;
responses   = allResponses;
nPresented  = allnPresented;

maxStim1     = max(allStimulusLevels);

% bayesian fit of PMF
[SL, NP, OON] = PAL_PFML_GroupTrialsbyX(stimuli',responses',nPresented');
[paramsValues, ~] = PAL_PFBA_Fit(SL, NP, ...
    OON, sgrid, PF);

threshEst   = paramsValues(1,1);
slopeEst    = 10.^(paramsValues(1,2)); % Estimate slope for session one

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE THE INTEROCEPTIVE SUMMARY MEASURES - using Slope
% Estimate from Bayesian Grand Mean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calculate the accuracy, sensitivity, metacognitive bias and metacognitive
% performance summary measures in each task
for a = 1:length(RRST.options.PPIDs)
    RRST.data{a}.metrics = RRST_calcMetrics(RRST.options.setup{a}, RRST.data{a}.behaviour, RRST.data{a}.physiology, slopeEst);
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot grand mean PF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define plotting variables
saveplots   = 0;
lineWidth   = 1;
fontName    = 'Helvetica';
fontSize    = 18;%24;
scatterMarkerSize   = 40;

   % colours
    cb = [0.1059 0.2824 0.4784; 0.4784 0.6588 0.7686; 0.6 0.2 0.8; 0.1 0.8 0.3; 0.9 0.7 0.1; 0.4 0.1 0.6; 0.3 0.7 0.9; 0.6 0.6 0.6];
        

cl(1,:) = cb(1,:);     % dark blue IO  
cl(2,:) = cb(2,:);     % light blue IO  
cl(3,:) = cb(8,:);     % gray

%% Set up figure
% Create figure & format
fig_position    = [200,200,346,346];
f3  = figure('Position', fig_position);
title([sprintf('Group Psychometric Function Fit')],'fontsize',fontSize+2,'FontWeight','Normal');
set(gcf,'color','w');
axis([0 10 0.5 1]);
xticks([1, 3, 5, 7, 9]);
xticklabels({'1', '3', '5', '7', '9'});
xlabel([sprintf('Stimulus Levels')]); %weber contrast value pressures
ylabel('p(correct)');
set(gca,'fontsize',fontSize,'FontName',fontName)
grid on
hold on

% Loop through participants, plot individual PF using ML

  for a = 1:length(RRST.options.PPIDs)
      % Access pre-session sensitivity data
        Data = RRST.data{a}.metrics.sensitivity;
        % Calculate Threshold and Slope
            threshEst   = Data.pressureAlpha;
            slopeEst    = slopeEst;

            PF          = @PAL_Weibull;
            gamma       = 0.5;
            lambda      = 0.03;

         % Collect stimuli, responses, and presented trials
            stimuli     = Data.stimulusLevelsPressure;
            responses   = Data.nCorrectPressure;
            nPresented  = Data.nTotalPressure;
    
            % Plot
            plot([0:.01:max(stimuli)+1], PF([threshEst slopeEst gamma lambda],0:.01:max(stimuli)+1),'Color',cl(3,:),'linewidth',lineWidth/2,'HandleVisibility','off')
  end

% Plot PF Grand Mean using Bayeisan
% Add reference line for threshold level of 75% correct
y1 = PF([threshEst slopeEst gamma lambda],0:.01:max(stimuli)+5);        % Psychometric function fit
y2 = 0.75 * ones(size(y1));                                             % Threshold level                
x1 = [0:.01:max(stimuli)+5];                                            
[xInt,yInt] = intersections(x1,y1,x1,y2);

% Add a vertical line to indicate the threshold
plot([0 xInt],[yInt yInt],'--','Color',cl(2,:),'linewidth',lineWidth*2)
plot([xInt xInt],[0 .75],'--','Color',cl(2,:),'linewidth',lineWidth*2)

% Plot PMF
plot([0:.01:max(stimuli)+5], PF([threshEst slopeEst gamma lambda],0:.01:max(stimuli)+5),'Color',cl(1,:),'linewidth',lineWidth*4)

% Add marker at threshold and text, '[Threshold:  num2str(round(xInt))]'
plot(xInt,.75,'wo','markerfacecolor',cl(2,:),'markersize', 14)
threshLabel     = ['\alpha: ', num2str(xInt)];
text(4.2,.785,threshLabel,'FontSize',fontSize,'FontName',fontName)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIGURE PROPORTION OF CONFIDENCE BINS HISTOGRAM BY ACCURACY SESSION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize variables
nRatings = 5; % Assuming 5 confidence rating bins
confidenceData = [];
accuracyData = [];
C_prop_mean = zeros(1, nRatings);
I_prop_mean = zeros(1, nRatings);

% Loop through participants
for a = 1:length(RRST.options.PPIDs)
    % Access confidence and accuracy data
    confidence = RRST.data{1, a}.behaviour.trials.confidence;
    accuracy = RRST.data{1, a}.behaviour.trials.correct;

    % Collect accuracy and confidence for all participants data 
    confidenceData     = [confidenceData; confidence];
    accuracyData       = [accuracyData; accuracy];
end

% Define confidence rating bins 
confidenceBins = linspace(0, 100, nRatings+1);

% Calculate proportions for each confidence rating bin
for i = 1:nRatings
    % Indices of trials falling into this confidence rating bin
    binIndices = confidenceData >= confidenceBins(i) & confidenceData < confidenceBins(i+1);
    
    % Calculate proportions of correct and incorrect responses
    totalTrials = sum(binIndices);
    if totalTrials > 0
        correctTrials = sum(accuracyData(binIndices & ~isnan(accuracyData)));
        C_prop_mean(i) = correctTrials / totalTrials;
        I_prop_mean(i) = 1 - C_prop_mean(i);
        
    end
end

% Plot
fig_position = [200, 200, 400, 400]; % square
f4 = figure('Position', fig_position);
title([sprintf('Proportion of Binned Confidence Ratings \n by Accuracy RRST')], 'fontsize', 18, 'FontWeight', 'Normal');
set(gcf, 'color', 'w');
hold on;

% Width of each bar
barWidth = 0.5;
% X-coordinate for the center of each group of bars
x = 1:nRatings;

% Plot stacked bars
b = bar(x, [C_prop_mean; I_prop_mean]', 'stacked', 'EdgeColor', 'none');

% Set face colors for each bar
b(1).FaceColor = [0.1059 0.2824 0.4784]; % Color for correct bars
b(1).FaceAlpha = 0.9 % Set transparency for Correct Bars
b(2).FaceColor = [0.4784 0.6588 0.7686]; % Color for incorrect bars
b(2).FaceAlpha = 0.75 % Set transparency for incorrect bars

% Edit figure properties
axis([0.5 nRatings+1.5 0 1]);
xticks(1:nRatings);
xticklabels({'0-20', '20-40', '40-60', '60-80', '80-100'});
xlabel('Confidence Rating (%)');
ylabel('Proportion of Confidence Bin');
legend({'Correct', 'Incorrect'}, 'FontSize', 14, 'Location', 'northeastoutside');
legend boxoff;
set(gca, 'fontsize', 18);
set(gca, 'Layer', 'top');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIGURE PROPORTION OF CONFIDENCE RATINGS HISTOGRAM BY ACCURACY SESSION ONE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize variables
nRatings = 5; % Assuming 5 confidence rating bins
confidenceData = [];
accuracyData = [];
C_prop_mean = zeros(1, nRatings);
I_prop_mean = zeros(1, nRatings);
C_SEM = zeros(1, nRatings);
I_SEM = zeros(1, nRatings);

% Loop through participants
for a = 1:length(RRST.options.PPIDs)
    % Access confidence and accuracy data
    confidence = RRST.data{1, a}.behaviour.trials.confidence;
    accuracy = RRST.data{1, a}.behaviour.trials.correct;

    % Collect accuracy and confidence for all participants data 
    confidenceData     = [confidenceData; confidence];
    accuracyData       = [accuracyData; accuracy];
end

% Count Accuracy Correct and Incorrect
countIncorrect = sum(accuracyData == false);
countCorrect = sum(accuracyData == true);

% Define confidence rating bins 
confidenceBins = linspace(0, 100, nRatings+1);

% Calculate proportions for each confidence rating bin
for i = 1:nRatings
    % Indices of trials falling into this confidence rating bin
    binIndices = confidenceData >= confidenceBins(i) & confidenceData < confidenceBins(i+1);
    
    % Calculate proportions of correct and incorrect responses
    totalTrials = sum(binIndices);
    if totalTrials > 0
        correctTrials = sum(accuracyData(binIndices & ~isnan(accuracyData)));
        incorrectTrials = sum(accuracyData(binIndices & ~isnan(accuracyData)) == false);
        C_prop_mean(i) = correctTrials / countCorrect;
        I_prop_mean(i) = incorrectTrials / countIncorrect;
        
        % Calculate standard error of the mean (SEM)
        % Assuming binomial distribution for correct/incorrect responses
        C_SEM(i) = sqrt(C_prop_mean(i) * (1 - C_prop_mean(i)) / countCorrect);
        I_SEM(i) = sqrt(I_prop_mean(i) * (1 - I_prop_mean(i)) / countIncorrect);
    end
end

% Plot
fig_position = [200, 200, 400, 400]; % square
f4 = figure('Position', fig_position);
title([sprintf('Proportion of Confidence Ratings by Accuracy \n RRST')], 'fontsize', 18, 'FontWeight', 'Normal');
set(gcf, 'color', 'w');
hold on;

% Width of each bar
barWidth = 0.5;

% X-coordinate for the center of each group of bars
x = 1:nRatings;

% Plot bars for correct responses
bar(x, C_prop_mean, barWidth, 'EdgeColor', [1 1 1], 'FaceColor', cl(1,:), 'FaceAlpha', 0.80);
% Plot bars for incorrect responses next to correct bars
bar(x + barWidth, I_prop_mean, barWidth, 'EdgeColor', [1 1 1], 'FaceColor', cl(2,:), 'FaceAlpha', 0.75);

% Plot error bars for correct responses
for i = 1:nRatings
    errorbar(x(i), C_prop_mean(i), C_SEM(i), 'Color', 'black', 'LineWidth', 1);
end

% Plot error bars for incorrect responses
for i = 1:nRatings
    errorbar(x(i) + barWidth, I_prop_mean(i), I_SEM(i), 'Color', 'black', 'LineWidth', 1);
end

% Edit figure properties
axis([0.5 nRatings+1.5 0 0.5]);
xticks(1:nRatings + barWidth/2);
xticklabels({'0-20', '20-40', '40-60', '60-80', '80-100'});
xlabel('Confidence Rating (%)');
ylabel('Proportion');
legend({'Correct', 'Incorrect'}, 'FontSize', 14, 'Location', 'northwest');
legend boxoff;
set(gca, 'fontsize', 18);
set(gca, 'Layer', 'top');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE GRAND MEAN INSIGHT AND PLOT - SESSION 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Round confidence data to 0 dp
confidenceData = round(confidenceData, -1);

% Remove trials with NaN values for confidence from both confidence and
% correct indexes
nanIndices = isnan(accuracyData) | isnan(confidenceData);
confidenceData(nanIndices) = [];
accuracyData(nanIndices) = [];


Nratings = 101;
a = Nratings+1;
for c = 1:Nratings
        H2(a-1) = length(find(confidenceData == c & accuracyData)) + 0.5;
        FA2(a-1) = length(find(confidenceData == c & ~accuracyData)) + 0.5;
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


% Plot the area under the Type2ROC curve with the specified style
fig_position    = [200,200,400,400];        % square
f8  = figure('Position', fig_position);
title('Type 2 ROC Curve RRST', 'fontsize', fontSize+2, 'FontWeight', 'Normal');
set(gcf, 'color', 'w'); 
hold on;

plot(cum_FA2, cum_H2, 'o-', 'Color', cl(1,:), 'MarkerSize', 10, 'LineWidth', lineWidth+1, 'MarkerEdgeColor', [1 1 1], 'MarkerFaceColor', [1 1 1]);
hold on;
scatter(cum_FA2, cum_H2, scatterMarkerSize*3, 'MarkerEdgeColor', cl(2,:), 'MarkerFaceColor', cl(2,:), 'MarkerFaceAlpha', .5);
h4 = refline(1);
h4.Color = cl(3,:);
h4.LineStyle = '--';
h4.LineWidth = lineWidth;
h4.HandleVisibility = 'off';

set(gca, 'fontsize', fontSize, 'FontName', fontName);
xticks([0,.5, 1]);
yticks([.5, 1]);
ylabel('Type 2 p(correct)');
xlabel('Type 2 p(incorrect)');


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE PREPROCESSED DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save(RRST.options.setup{1}.fileNames.saveNames.matMatrix, 'RRST');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Export mean intensity, resistance, and presssure; and slope (held value)
% and threshold PF estimates from weber contrast pressure values to sheet 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pull out all summary resistance and pressure measures for RRST
for a = 1:length(RRST.options.PPIDs)
    % Summary Intensity
    RRST.summary.intensity(1,a) = RRST.data{a}.metrics.sensitivity.intensity; % Intensity = average number of steps 
    % Summary resistance values for pre session 
    RRST.summary.resistance(1,a) = RRST.data{a}.metrics.sensitivity.meanResistance;
    % Summary pressure values for pre session
    RRST.summary.pressure(1,a) = RRST.data{a}.metrics.sensitivity.meanPressure;
    RRST.summary.pressureSlope(1,a) = slopeEst;
    RRST.summary.pressureThresh(1,a) = RRST.data{a}.metrics.sensitivity.pressureAlpha;
end

% Export to spreadsheet
T = table(RRST.options.PPIDs', RRST.summary.intensity', RRST.summary.resistance',...
    RRST.summary.pressure', RRST.summary.pressureSlope', RRST.summary.pressureThresh',...
    'VariableNames', {'PPID', 'Intensity', 'MeanResist',...
    'MeanPressure', 'PressureSlope', 'PressureThresh'});
writetable(T, RRST.options.setup{1}.fileNames.saveNames.excel, 'Sheet', 2);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Export interoceptive dimensions measured (sensitivity 
% (based on log transformed weber contrast pressure values), metacognitive
% bias/confidence, and metacognitive performance (insight); and
% anxiety/depression
% scores - to sheet 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Pull out all additional summary interoceptive measures for RRST

for a = 1:length(RRST.options.PPIDs)
    % Summary accuracy values for pre session
    RRST.summary.accuracy(1,a) = RRST.data{a}.metrics.accuracy; 
    % Summary pressure sensitivity values for pre session
    RRST.summary.pressureSlope(1,a) = slopeEst;
    RRST.summary.pressureThresh(1,a) = RRST.data{a}.metrics.sensitivity.pressureAlpha;
    % Summary confidence values for pre session
    RRST.summary.confidence(1,a) = RRST.data{a}.metrics.confidence;
    % Summary metacognitive values for pre session
    RRST.summary.metaPerformance(1,a) = RRST.data{a}.metrics.metaPerformance;
     
end

% Export to spreadsheet
T = table(RRST.options.PPIDs', RRST.summary.accuracy', RRST.summary.pressureSlope',RRST.summary.pressureThresh',...
    RRST.summary.confidence', RRST.summary.metaPerformance',...
    'VariableNames', {'PPID','Accuracy', 'Slope', 'Threshold', 'Confidence', 'MetaPerf'});

writetable(T, RRST.options.setup{1}.fileNames.saveNames.excel, 'Sheet', 1);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE FULL DATA MATRIX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save(RRST.options.setup{1}.fileNames.saveNames.matMatrix, 'RRST');
