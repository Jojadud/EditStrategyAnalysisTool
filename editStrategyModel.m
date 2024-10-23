function [T, CER, KSPC] = editStrategyModel(charInsTimeMean,charDelTimeMean,wordSubTimeMean,pError,pNotice,pWordFix,pWordSuggest,delStrategy,reps)

filename = 'stimulus_phrases.txt';
text = fileread(filename);
lines = splitlines(text);

% Take first 500
lines = lines(1:500);
lines = repmat(lines,reps,1);
reps = size(lines,1);

T = zeros(reps,1);
CER = zeros(reps,1);
KSPC = zeros(reps,1);

for iRep = 1:reps
    timing = 0;
    ksCount = 0;
    unfixErrCount = 0;
    wordErrCount = 0;
    
    stimulus = strsplit(lines{iRep},'\t');
    tTarget = stimulus{2};
    
    for iC = 1:length(tTarget)
        
        errorSample = unifrnd(0,1);
        error = false;
        notice = false;
        wordError = false;
        
        if (tTarget(iC) == ' ' || tTarget(iC) == '.' || tTarget(iC) == '?' || tTarget(iC) == '!')
            if (wordErrCount > 0)
                wordFixSample = unifrnd(0,1);
                if wordFixSample > pWordFix
                    wordError = true;
                else
                    % Word was fixed
                    wordErrCount = 0;
                end
            end
        else
            if errorSample < pError
                error = true;
                wordErrCount = wordErrCount + 1;
            end
        end
                
        if (error || wordError)
            noticeSample = unifrnd(0,1);
            if noticeSample < pNotice
                notice = true;
            end
        end
        
        % Original insertion
        timing = timing + normrnd(charInsTimeMean,1);
        ksCount = ksCount + 1;
        
        if (delStrategy)
            if (error && notice)
                % Deletion
                timing = timing + normrnd(charDelTimeMean,1);
                
                % Second insertion
                timing = timing + normrnd(charInsTimeMean,1);
                
                ksCount = ksCount + 2;
            elseif (error && ~notice)
                unfixErrCount = unfixErrCount + 1;
            end
        else
            
            if (wordError && notice)
                
                wordSuggestSample = unifrnd(0,1);
                if wordSuggestSample < pWordSuggest
                    timing = timing + normrnd(wordSubTimeMean,1);                
                    ksCount = ksCount + 1;
                else
                    % Take time to look for word sub
                    timing = timing + normrnd(wordSubTimeMean,1);                
                    ksCount = ksCount + 1;
                    
                    % Take time to remove error chars manuall
                    for iE = 1:wordErrCount                        
                        
                        % Deletion
                        timing = timing + normrnd(charDelTimeMean,1);

                        % Second insertion
                        timing = timing + normrnd(charInsTimeMean,1);

                        ksCount = ksCount + 2;
                    end
                end                
                
            elseif (error && ~notice)
                unfixErrCount = unfixErrCount + wordErrCount;
                wordErrCount = 0;
            end
        end
        
    end
    
    T(iRep) = timing;
    CER(iRep) = unfixErrCount / length(tTarget) * 100;
    KSPC(iRep) = ksCount / length(tTarget);
end

end

