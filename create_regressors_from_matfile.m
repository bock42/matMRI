function create_regressors_from_matfile(matFile,outDir,wrapAround)

% Creates .txt files in the FSL 3-colium format of releveant regressors
%   from .mat file generated from our experimental scripts
%   (OLFlickerSensitivity).
%
%   Usage:
%   create_regressors_from_matfile(matFile,outDir,wrapAround)
%
%   Input:
%   matFile = full path and filename of .mat file
%   outDir = path to output directory (e.g. fullfile(session_dir,'Stimuli'));
%   wrapAround = 1 to remove the wrap around block, 0 otherwise
%
%   2/22/16   ms, gf      Written.
%   Updates by Andrew S Bock Feb 2016
%   3/1/16 wrap-around update gf
%   Wrap Around fix by Andrew S Bock Mar 2016

%% Load the data, create output directory
load(matFile);
% Output prefix
[~, fileName] = fileparts(matFile);
NSegments = length(params.responseStruct.events);
% Make a 'covariates' folder
covDir = fullfile(outDir,fileName);
if ~exist(covDir,'dir');
    mkdir(covDir);
end
%% Iterate over the segments and count analyze accuracy
attentionTaskFlag   = zeros(1,NSegments);
responseDetection   = zeros(1,NSegments);
hit                 = zeros(1,NSegments);
miss                = zeros(1,NSegments);
falseAlarm          = zeros(1,NSegments);
for i = 1:NSegments
    % Attentional 'blinks'
    if params.responseStruct.events(i).attentionTask.segmentFlag
        attentionTaskFlag(i) = 1;
    end
    % Subject key press responses
    if ~isempty(params.responseStruct.events(i).buffer)
        responseDetection(i) = 1;
    end
    % Hits
    if (attentionTaskFlag(i) == 1) && (responseDetection(i) == 1)
        hit(i) = 1;
    end
    % Misses
    if (attentionTaskFlag(i) == 1) && (responseDetection(i) == 0)
        miss(i) = 1;
    end
    % False Alarms
    if (attentionTaskFlag(i) == 0) && (responseDetection(i) == 1)
        falseAlarm(i) = 1;
    end
end
% Display performance
fprintf('*** Subject %s - hit rate: %.3f (%g/%g) / false alarm: %.3f (%g/%g)\n', ...
    exp.subject, sum(hit)/sum(attentionTaskFlag), sum(hit), sum(attentionTaskFlag), ...
    sum(falseAlarm)/(NSegments-sum(attentionTaskFlag)), sum(falseAlarm), ...
    (NSegments-sum(attentionTaskFlag)));
% Save performance text file
fid = fopen(fullfile(covDir, [fileName '-performance.txt']), 'w');
fprintf(fid,'error type,pct,N,total\n');
fprintf(fid,'hit rate,%.3f,%g,%g\n', ...
    sum(hit)/sum(attentionTaskFlag), ...
    sum(hit),sum(attentionTaskFlag));
fprintf(fid,'false alarm rate,%.3f,%g,%g\n', ...
    sum(falseAlarm)/(NSegments-sum(attentionTaskFlag)), ...
    sum(falseAlarm),(NSegments-sum(attentionTaskFlag)));
fclose(fid);
%% Get the frequencies presented
theFreqs = params.theFrequenciesHz;

%% Iterate over the frequencies to produce text files
for f = 1:length(theFreqs)
    % Get the 'all', 'valid', and 'invalid' trials
    allTrials       = params.theFrequencyIndices == f;
    validTrials     = params.theFrequencyIndices == f & ~miss;
    invalidTrials   = params.theFrequencyIndices == f & miss;
    % Construct the 'all' covariate
    startTrials = [params.responseStruct.events(allTrials).tTrialStart] ...
        - params.responseStruct.tBlockStart;
    endTrials = [params.responseStruct.events(allTrials).tTrialEnd] ...
        - params.responseStruct.tBlockStart;
    allCov = [startTrials' (endTrials-startTrials)' ones(size(startTrials'))];
    if isempty(allCov)
        allCov = [0 0 0];
    end
    fprintf('>>> Saving out to %s ...', ...
        [fileName '-cov_' num2str(theFreqs(f)) 'Hz_all.txt']);
    dlmwrite(fullfile(covDir, ...
        [fileName '-cov_' num2str(theFreqs(f)) 'Hz_all.txt']), allCov, '\t');
    fprintf('done.\n');
    % Construct the 'valid' covariate
    startTrials = [params.responseStruct.events(validTrials).tTrialStart] ...
        - params.responseStruct.tBlockStart;
    endTrials = [params.responseStruct.events(validTrials).tTrialEnd] ...
        - params.responseStruct.tBlockStart;
    validCov = [startTrials' (endTrials-startTrials)' ones(size(startTrials'))];
    if isempty(validCov)
        validCov = [0 0 0];
    end
    fprintf('>>> Saving out to %s ...', ...
        [fileName '-cov_' num2str(theFreqs(f)) 'Hz_valid.txt']);
    dlmwrite(fullfile(covDir, ...
        [fileName '-cov_' num2str(theFreqs(f)) 'Hz_valid.txt']), validCov, '\t');
    fprintf('done.\n');
    % Construct the 'invalid' covariate
    startTrials = [params.responseStruct.events(invalidTrials).tTrialStart] ...
        - params.responseStruct.tBlockStart;
    endTrials = [params.responseStruct.events(invalidTrials).tTrialEnd] ...
        - params.responseStruct.tBlockStart;
    invalidCov = [startTrials' (endTrials-startTrials)' ones(size(startTrials'))];
    if isempty(invalidCov)
        invalidCov = [0 0 0];
    end
    fprintf('>>> Saving out to %s ...', ...
        [fileName '-cov_' num2str(theFreqs(f)) 'Hz_invalid.txt']);
    dlmwrite(fullfile(covDir, ...
        [fileName '-cov_' num2str(theFreqs(f)) 'Hz_invalid.txt']), invalidCov, '\t');
    fprintf('done.\n');
end
%% Make the attentional blink covariate
attCov = [0 0 0];
ct = 0;
for i = 1:NSegments
    if attentionTaskFlag(i)
        ct = ct+1;
        startBlink = params.responseStruct.events(i).t(...
            params.responseStruct.events(i).attentionTask.T == 1) - ...
            params.responseStruct.tBlockStart;
        endBlink = params.responseStruct.events(i).t(...
            params.responseStruct.events(i).attentionTask.T == -1) - ...
            params.responseStruct.tBlockStart;
        attCov(ct,1) = startBlink;
        attCov(ct,2) = endBlink - startBlink;
        attCov(ct,3) = 1;
    end
end
dlmwrite(fullfile(covDir, [fileName '-cov_attentionTask.txt']), attCov, '\t');
%% Save wrap around as separate covariate
if wrapAround
    % The first presented frequency is the wrap around
    wrap_freq = theFreqs(params.theFrequencyIndices(1));
    %remove wrap-around block from 'all' covariate
    oldAll = load(fullfile(covDir,[fileName '-cov_' num2str(wrap_freq) 'Hz_all.txt']));
    dlmwrite(fullfile(covDir, ...
        [fileName '-cov_' num2str(wrap_freq) 'Hz_all.txt']), oldAll(2:end,:), '\t');
    dlmwrite(fullfile(covDir, ...
        [fileName '-cov_' num2str(wrap_freq) 'Hz_wrapAround.txt']), oldAll(1,:), '\t');
    %remove wrap-around block from 'valid' covariate
    oldValid = load(fullfile(covDir,[fileName '-cov_' num2str(wrap_freq) 'Hz_valid.txt']));
    if ismember(oldValid(1,:),oldAll(1,:),'rows');
        dlmwrite(fullfile(covDir, ...
            [fileName '-cov_' num2str(wrap_freq) 'Hz_valid.txt']), oldValid(2:end,:), '\t');
    end
    %remove wrap-around block from 'invalid' covariate
    oldInvalid = load(fullfile(covDir,[fileName '-cov_' num2str(wrap_freq) 'Hz_invalid.txt']));
    if ismember(oldInvalid(1,:),oldAll(1,:),'rows');
        dlmwrite(fullfile(covDir, ...
            [fileName '-cov_' num2str(wrap_freq) 'Hz_invalid.txt']), oldInvalid(2:end,:), '\t');
    end
    disp('Wrap around block saved as covariate');
end