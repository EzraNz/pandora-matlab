function params_row = getItemParams(dataset, index, a_profile)

% getItemParams - Get the parameter values of a dataset item.
%
% Usage:
% params_row = getItemParams(dataset, index)
%
% Description:
%
%   Parameters:
%	dataset: A params_tests_dataset.
%	index: Index of item in dataset.
%		
%   Returns:
%	params_row: Parameter values in the same order of paramNames
%
% See also: itemResultsRow, params_tests_dataset, paramNames, testNames
%
% $Id$
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2004/12/03

props = get(dataset, 'props');

filename = getItem(dataset, index);
fullname = fullfile(dataset.path, filename);

names_vals = parseGenesisFilename(fullname);

if isfield(props, 'num_params')
  num_params = props.num_params;
else
  num_params = size(names_vals, 1);
end

if isfield(props, 'param_rows')
  %# Take parameter values from the specified parameter file,
  %# in addition to the ones specified on data filenames.

  if ~ isfield(props, 'param_trial_name')
    props.param_trial_name = 'trial';
  end
  str_index = strmatch(props.param_trial_name, names_vals{1:num_params, 1});

  if length(str_index) < 1
    error(['Parameter lookup from rows is requested, but cannot find ' ...
	   'the "' props.param_trial_name '" parameter in the data filename ' fullname ]);
  end
  
  trial_num = names_vals{str_index, 2};

  %# Skip the "trial" value from the rows file
  str_index = strmatch(props.param_trial_name, props.param_names);

  trues = true(1, length(props.param_names));

  if ~ isempty(str_index)
    %# If found, ignore the parameter "trial" from the list of parameters 
    %# coming from the param rows file
    trues(str_index) = false;
  end

  add_param_vals = props.param_rows(trial_num, trues);
else
  add_param_vals = [];
end

%# Convert params to row vector
params_row = [ add_param_vals, names_vals{1:num_params, 2} ];

