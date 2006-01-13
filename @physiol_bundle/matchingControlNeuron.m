function crit_db = matchingControlNeuron(a_bundle, neuron_id, props)

% matchingControlNeuron - Creates a criterion database for matching the neuron at traceset_index.
%
% Usage:
% crit_db = matchingControlNeuron(a_bundle, neuron_id, props)
%
% Description:
%   Copies selected test values from row as the first row into the 
% criterion db. Adds a second row for the STD of each column in the db.
%
%   Parameters:
%	a_bundle: A physiol_bundle object.
%	neuron_id: A NeuronId of the neuron to match.
%	props: A structure with any optional properties.
%		
%   Returns:
%	crit_db: A tests_db with two rows for values and STDs.
%
%   Example:
%	Matches gpd0421c from cip_traces_all_axoclamp.txt:
%	>> crit_db = matchingControlNeuron(pbundle, 33)
%
% See also: rankMatching, tests_db, tests2cols
%
% $Id$
% Author: Cengiz Gunay <cgunay@emory.edu>, 2005/12/21

if ~ exist('props')
  props = struct;
end

%# Get control TracesetIndex using NeuronId
t_idx = ...
    a_bundle.joined_control_db(a_bundle.joined_control_db(:, 'NeuronId') == neuron_id, ...
			       'TracesetIndex').data;
%# Delegate to TracesetIndex version
crit_db = matchingRow(a_bundle, t_idx, props);
