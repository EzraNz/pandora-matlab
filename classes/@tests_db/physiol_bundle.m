function a_pbundle = physiol_bundle(phys_dball, phys_dataset, props)
  
% physiol_bundle - Create a physiol_bundle from a raw physiology database.
%
% Usage:
% a_pbundle = physiol_bundle(phys_dball, phys_dataset, props)
%
% Description:
%   Removes small bias currents, calculates input resistance by averaging
% negative CIP traces, averages multiple traces with similar treatments,
% selects certain CIP levels collapses its rows to create a
% one-neuron-per-pow database. It includes post-DB calculated columns
% such as rate ratios between spont and recovery periods.
%
% Parameters:
%   phys_dball: A raw database obtained by loading traces from the tracesets.
%   phys_dataset: Dataset object passed to physiol_bundle.
%   props: Optional parameters.
%	weedCols: Cell array of parameter columns to be weed-out before averaging rows
%		that are same w.r.t other parameters.
%		(default={'pulseOn', 'pulseOff', 'traceEnd', 'pAbias', 'ItemIndex'}).
%	drugCols: Cell array of drug names that need to be zero for the
%		control db (default={'TTX', 'Apamin', 'EBIO', 'XE991', 'Cadmium', 'drug_4AP'}).
%       CIPList: row array specifying the CIP levels to choose (eliminate the
%       	others), default is an empty array, which means to choose all.
% 	biasLimit: Limit in pA, biases larger +/- than which will be
% 		eliminated. (default=30)
%
% Returns:
%	phys_joined_db: Final one row per cip and neuron db.
%	phys_joined_control_db: Rows where all drug treatments are zero.
%	phys_db: Original db only with parameter and including the weedCols.
%
% See also: physiol_bundle, params_tests_db
%
% $Id$
% Author: Cengiz Gunay <cgunay@emory.edu>, 2007/12/21
% Modified: Li Su, added various new props and fixes, 2008/03

% Copyright (c) 2007 Cengiz Gunay <cengique@users.sf.net>.
% This work is licensed under the Academic Free License ("AFL")
% v. 3.0. To view a copy of this license, please look at the COPYING
% file distributed with this software or visit
% http://opensource.org/licenses/afl-3.0.php.

  vs = warning('query', 'verbose');
  verbose = strcmp(vs.state, 'on');

  if ~ exist('props','var')
    props = struct;
  end

  if verbose
    disp(['Start with DB of ' num2str(dbsize(phys_dball, 1)) ' rows.' ]);
  end
  
% Weed out any traces with |bias| > 30 pA
if isfield(props, 'biasLimit')
  bias_limit = props.biasLimit;
else
  bias_limit = 30;
end
phys_db = phys_dball(phys_dball(:, 'pAbias') > -bias_limit & phys_dball(:, 'pAbias') < bias_limit, :);

  if verbose
    disp(['Eliminated large biases, left with DB of ' num2str(dbsize(phys_db, 1)) ' rows.' ]);
  end

  % remove unnecessary params before averaging 
  if isfield(props, 'weedCols')
    weed_cols = props.weedCols;
  else
    weed_cols = {'pulseOn', 'pulseOff', 'traceEnd', 'pAbias', 'ItemIndex'};
  end
  phys_db = ...
      delColumns(phys_db, weed_cols);

    if verbose
      disp(['Eliminated ' num2str(length(weed_cols)) ... 
            ' param columns that do not contribute to identifying ' ...
            'traces, left with DB of ' num2str(dbsize(phys_db, 2)) ...
           ' columns.' ]);
    end

    % Add some new measures
    phys_db = addPostDBColumns(phys_db);
    
    if verbose
      disp(['Added new post-measure columns, now has with DB of ' ...
           num2str(dbsize(phys_db, 2)) ...
           ' columns.' ]);
    end

    % Use CIP levels -20 to -60 for averaging input resistance and membrane
    %time constants. Average across pAcip, so remove it, too.
    phys_inputres_mean_db = ...
        meanDuplicateParams(delColumns(phys_db(...
          phys_db(:, 'pAcip') > -100 & ...
          phys_db(:, 'pAcip') <= -20, :), ...
                                       {'pAcip'}));


    if verbose
      disp(['Averaging traces with -20 to -100 pA CIP for finding input ' ...
            'resistance ended up with intermediary DB of ' ...
           num2str(dbsize(phys_inputres_mean_db, 1)) ...
           ' rows and ' num2str(dbsize(phys_inputres_mean_db, 2)) ...
           ' columns.' ]);
    end

    % Choose some CIPs
  CIPList = getfuzzyfield(props, 'CIPList');
  if ~isempty(CIPList)
    phys_db = ...
        phys_db(anyRows(phys_db(:, 'pAcip'), ...
                                   CIPList(:)), :);
  end

  if verbose
    disp(['Eliminated unwanted CIPs, left with DB of ' num2str(dbsize(phys_db, 1)) ' rows.' ]);
  end

    % Average traces with same CIP levels
    phys_db = meanDuplicateParams(phys_db);

    if verbose
      disp(['Averaging traces with same CIP levels reduced main DB to ' ...
           num2str(dbsize(phys_db, 1)) ...
           ' rows.' ]);
    end

    % Merge measures from multiple CIP levels into one row for each neuron
    spont_spike_tests  = ...
        {'SpontSpikeAmplitudeMean', ...
         'SpontSpikeAmplitudeMode', ...
         'SpontSpikeAmplitudeSTD', ...
         'SpontSpikeBaseWidthMean', ...
         'SpontSpikeBaseWidthMode', ...
         'SpontSpikeBaseWidthSTD', ...
         'SpontSpikeFallTimeMean', ...
         'SpontSpikeFallTimeMode', ...
         'SpontSpikeFallTimeSTD', ...
         'SpontSpikeHalfWidthMean', ...
         'SpontSpikeHalfWidthMode', ...
         'SpontSpikeHalfWidthSTD', ...
         'SpontSpikeFixVWidthMean', ...
         'SpontSpikeFixVWidthMode', ...
         'SpontSpikeFixVWidthSTD', ...
         'SpontSpikeInitVmBySlopeMean', ...
         'SpontSpikeInitVmBySlopeMode', ...
         'SpontSpikeInitVmBySlopeSTD', ...
         'SpontSpikeInitVmMean', ...
         'SpontSpikeInitVmMode', ...
         'SpontSpikeInitVmSTD', ...
         'SpontSpikeMaxAHPMean', ...
         'SpontSpikeMaxAHPMode', ...
         'SpontSpikeMaxAHPSTD', ...
         'SpontSpikeMaxVmSlopeMean', ...
         'SpontSpikeMaxVmSlopeMode', ...
         'SpontSpikeMaxVmSlopeSTD', ...
         'SpontSpikeMinTimeMean', ...
         'SpontSpikeMinTimeMode', ...
         'SpontSpikeMinTimeSTD', ...
         'SpontSpikeRiseTimeMean', ...
         'SpontSpikeRiseTimeMode', ...
         'SpontSpikeRiseTimeSTD'};
    
    pulse_spike_tests  = ...
        {'PulseSpikeAmplitudeMean', ...
         'PulseSpikeAmplitudeMode', ...
         'PulseSpikeAmplitudeSTD', ...
         'PulseSpikeBaseWidthMean', ...
         'PulseSpikeBaseWidthMode', ...
         'PulseSpikeBaseWidthSTD', ...
         'PulseSpikeFallTimeMean', ...
         'PulseSpikeFallTimeMode', ...
         'PulseSpikeFallTimeSTD', ...
         'PulseSpikeHalfWidthMean', ...
         'PulseSpikeHalfWidthMode', ...
         'PulseSpikeHalfWidthSTD', ...
         'PulseSpikeFixVWidthMean', ...
         'PulseSpikeFixVWidthMode', ...
         'PulseSpikeFixVWidthSTD', ...     
         'PulseSpikeInitVmBySlopeMean', ...
         'PulseSpikeInitVmBySlopeMode', ...
         'PulseSpikeInitVmBySlopeSTD', ...
         'PulseSpikeInitVmMean', ...
         'PulseSpikeInitVmMode', ...
         'PulseSpikeInitVmSTD', ...
         'PulseSpikeMaxAHPMean', ...
         'PulseSpikeMaxAHPMode', ...
         'PulseSpikeMaxAHPSTD', ...
         'PulseSpikeMaxVmSlopeMean', ...
         'PulseSpikeMaxVmSlopeMode', ...
         'PulseSpikeMaxVmSlopeSTD', ...
         'PulseSpikeMinTimeMean', ...
         'PulseSpikeMinTimeMode', ...
         'PulseSpikeMinTimeSTD', ...
         'PulseSpikeRiseTimeMean', ...
         'PulseSpikeRiseTimeMode', ...
         'PulseSpikeRiseTimeSTD'};

    recov_spike_tests  = ...
        {'RecovSpikeAmplitudeMean', ...
         'RecovSpikeAmplitudeMode', ...
         'RecovSpikeAmplitudeSTD', ...
         'RecovSpikeBaseWidthMean', ...
         'RecovSpikeBaseWidthMode', ...
         'RecovSpikeBaseWidthSTD', ...
         'RecovSpikeFallTimeMean', ...
         'RecovSpikeFallTimeMode', ...
         'RecovSpikeFallTimeSTD', ...
         'RecovSpikeHalfWidthMean', ...
         'RecovSpikeHalfWidthMode', ...
         'RecovSpikeHalfWidthSTD', ...
         'RecovSpikeFixVWidthMean', ...
         'RecovSpikeFixVWidthMode', ...
         'RecovSpikeFixVWidthSTD', ...     
         'RecovSpikeInitVmBySlopeMean', ...
         'RecovSpikeInitVmBySlopeMode', ...
         'RecovSpikeInitVmBySlopeSTD', ...
         'RecovSpikeInitVmMean', ...
         'RecovSpikeInitVmMode', ...
         'RecovSpikeInitVmSTD', ...
         'RecovSpikeMaxAHPMean', ...
         'RecovSpikeMaxAHPMode', ...
         'RecovSpikeMaxAHPSTD', ...
         'RecovSpikeMaxVmSlopeMean', ...
         'RecovSpikeMaxVmSlopeMode', ...
         'RecovSpikeMaxVmSlopeSTD', ...
         'RecovSpikeMinTimeMean', ...
         'RecovSpikeMinTimeMode', ...
         'RecovSpikeMinTimeSTD', ...
         'RecovSpikeRiseTimeMean', ...
         'RecovSpikeRiseTimeMode', ...
         'RecovSpikeRiseTimeSTD'};

    ini_spont_tests = ...
        {'IniSpontISICV', ...
         'IniSpontPotAvg', ...
         'IniSpontSpikeRate', ...
         'IniSpontSpikeRateISI'};

    pulse_rate_tests = ...
        {'PulseISICV', ...
         'PulseSFA', ...
         'PulseSFARatio', ...
         'PulseIni100msISICV', ...
         'PulseIni100msRest1SpikeRate', ...
         'PulseIni100msRest2SpikeRate', ...
         'PulseIni100msRest1SpikeRateISI', ...
         'PulseIni100msRest2SpikeRateISI', ...
         'PulseIni100msSpikeRate', ...
         'PulseIni100msSpikeRateISI', ...
         'PulsePotAvg', ...
         'PulseSpikeAmpDecayTau', ...
         'PulseSpikeAmpDecayDelta', ...
         'PulseSpontAmpRatio'};

    pulse_hyper_pot_tests = ...
        {'PulsePotMin', ...
         'PulsePotMinTime', ...
         'PulsePotSag', ...
         'PulsePotSagDivMin', ...
         'PulsePotTau'};

    recov_rate_tests = ...
        {'RecIniSpontPotRatio', ...
         'RecIniSpontRateRatio', ...
         'IniRecISIRatio', ...
         'RecSpont1SpikeRate', ...
         'RecSpont2SpikeRate', ...
         'RecSpont1SpikeRateISI', ...
         'RecSpont2SpikeRateISI', ...
         'RecSpontFirstISI', ...
         'RecSpontFirstSpikeTime', ...
         'RecSpontISICV', ...
         'RecSpontPotAvg'};

% spike tests: [ 0:5 9:11 15:17 21:35 42:44 ]

% Common for 40, 100, 200pA
depol_pulse_tests = ...
    { pulse_rate_tests{:}, recov_rate_tests{:}, pulse_spike_tests{:}};

% prepare to use by mergeMultipleCIPsInOne
merge_args = {...
  {'_H100pA', {'IniSpontSpikeRateISI', pulse_rate_tests{:}, pulse_hyper_pot_tests{:}, recov_rate_tests{:}, recov_spike_tests{:}}, ...
   '_0pA', { ini_spont_tests{:}, spont_spike_tests{:}}, ...
   '_D40pA', depol_pulse_tests, ...
   '_D100pA', {depol_pulse_tests{:}, recov_spike_tests{:}}, ...
   '_D200pA', depol_pulse_tests}, 'RowIndex_0pA', ...
  struct('cipLevels', [-100 0 40 100 200])};

% remove input resistance cips and excessive columns before merging CIPs
% TODO: keep NumDuplicates? [no, messes up merging process]
phys_2_join_db = ...
    delColumns(phys_db(phys_db(:, 'pAcip', 1) <= -100 | ...
                            phys_db(:, 'pAcip', 1) >= 0, :, :), ...
               {'NumDuplicates', 'RowIndex'});

% get the main values (TODO: merge pages using concat and swapRowsPages)
if dbsize(phys_2_join_db,1)==0 % by Li Su, if it's an empty db.
    phys_joined_db = params_tests_db;
    phys_joined_added_db = phys_joined_db;
    phys_joined_control_db = phys_joined_db;
else
    phys_joined_db = ...
        mergeMultipleCIPsInOne(phys_2_join_db(:, :, 1), merge_args{:});

    % get the STDs
    phys_joined_std_db = ...
        mergeMultipleCIPsInOne(phys_2_join_db(:, :, 2), merge_args{:});

    if verbose
      disp(['Merged multiple CIPs into one row, ended up with DB of ' ...
               num2str(dbsize(phys_joined_db, 1)) ...
               ' rows.' ]);
    end

    % {'_H100pA', [5:14 19:24 (119 + spike_tests) 165], '_0pA', [1:3 (27 + spike_tests) 165], '_D40pA', [5:11 19:24 (73 + spike_tests) 165], '_D100pA', [5:11 14:16 19:24 (73 + spike_tests) (119 + spike_tests) 165], '_D200pA', [5:11 19:24 (73 + spike_tests) 165]}

    num_params = get(phys_joined_db, 'num_params');
    [existing_rows existing_rows_idx] = ...
        anyRows(phys_joined_db(:, 1:num_params), ...
                phys_inputres_mean_db(:, 1:num_params, 1));

    % Copy the existing rows from inputres db back to joined db
    try 
      phys_joined_added_db1 = ...
          addColumns(onlyRowsTests(phys_joined_db, existing_rows, ':'), ...
                     {'InputResGOhm_HpA', 'InputCappF_HpA', ...
                      'PulsePotTau_HpA'}, ...
                     get(onlyRowsTests(phys_inputres_mean_db, ...
                                       existing_rows_idx(existing_rows), ...
                                       {'InputResGOhm', 'InputCappF', ...
                          'PulsePotTau'}, 1), 'data'));
    catch 
      warning([ 'Failed adding input res results back into joined db. ' ...
                ' Existing rows = ' num2str(sum(existing_rows)) '. ' ]);
      phys_joined_db
      phys_inputres_mean_db
      rethrow(lasterror);
    end

    if verbose
      disp(['Merged ' num2str(dbsize(phys_joined_added_db1, 1)) ' rows from ' ...
            'input resistance DB back into the one-neuron-per-row DB.' ]);
    end

    % Fill-in NaN for the non-existing rows
    phys_joined_added_db2 = ...
        addColumns(onlyRowsTests(phys_joined_db, ~existing_rows, ':'), ...
               {'InputResGOhm_HpA', 'InputCappF_HpA', ...
            'PulsePotTau_HpA'}, ...
               repmat(NaN, length(find(~existing_rows)), 3));

    % Combine all
    phys_joined_added_db = [phys_joined_added_db1; phys_joined_added_db2];
    clear phys_joined_added_db1 phys_joined_added_db2

    % Get control DB
    if isfield(props, 'drugCols')
      drug_cols = props.drugCols;
    else
      drug_cols = {'TTX', 'Apamin', 'EBIO', 'XE991', 'Cadmium', 'drug_4AP'};
    end
    phys_joined_control_db = ...
        phys_joined_added_db(onlyRowsTests(phys_joined_added_db, ':', drug_cols) == ...
                             zeros(1, length(drug_cols)), :);

    if verbose
      disp(['Found control DB of ' ...
           num2str(dbsize(phys_joined_control_db, 1)) ...
           ' rows.' ]);
    end

    phys_joined_control_db = ...
        set(phys_joined_control_db, 'id', [phys_joined_control_db.id ' (control cells)']);
end

% all parameters kept here to access original traceset items
phys_db = phys_dball(:, { 1:get(phys_dball, 'num_params'), 'ItemIndex'});

% create the bundle
a_pbundle = ...
    physiol_bundle({phys_dataset, phys_db, phys_joined_added_db}, struct('controlDB', phys_joined_control_db));
