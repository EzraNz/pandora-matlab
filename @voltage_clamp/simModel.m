function model_vc = simModel(a_vc, f_I_v, props)

% simModel - Simulate model channel current using voltage clamp.
%
% Usage:
% model_vc = simModel(a_vc, f_I_v, props)
%
% Parameters:
%   a_vc: A voltage_clamp object.
%   f_I_v: param_func object representing the model channel. 
%   props: A structure with any optional properties.
%     delay: If given, use as voltage clamp delay [ms].
%     levels: Only simulate these voltage level indices.
%		
% Returns:
%   model_vc: A voltage_clamp object with simulated current data and
%   	      the original voltage data.
%
% Description:
%   Often the delay is already included in the model, which is better
% because sub-dt precision can be achieved using interpolation.
%
% Example:
% >> I_Ca = param_I_v([1 1 .0077 58], m_Ca, h_Ca, 'I_{Ca}', ...
%              struct('paramRanges', ...
%                     [1 4; 0 1; 0 1e3; 100 200]'))
% >> model_vc = simModel(a_vc, I_Ca)
%
% See also: param_I_v, param_func, plot_abstract
%
% $Id$
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2010/03/29

% TODO: 

if ~ exist('props', 'var')
  props = struct;
end

% select which levels to simulate
if isfield(props, 'levels')
  % only few (faster)
  a_vc = setLevels(a_vc, props.levels);
end

dt = get(a_vc, 'dt');

data_v = get(a_vc.v, 'data');
cell_name = get(a_vc, 'id');
time = (0:(size(data_v, 1)-1))*dt;

% choose the range
period_range = ...
    period((a_vc.time_steps(1) - round(10 / dt)), ...
           (a_vc.time_steps(2) + round(10 / dt)));

% set and update the period
[a_vc period_range] = ...
    withinPeriod(a_vc, period_range, struct('useAvailable', 1));

range_steps = array(period_range);

if isfield(props, 'delay')
  v_delay = props.delay; % ms, for space clamp error delay
else
  v_delay = 0; 
end
    
% model data in vc
model_vc = a_vc;

% integrate current for selected voltage steps
model_vc.i = ...
    set(model_vc.i, 'data', ...
                    f(f_I_v, { data_v(max(1, range_steps - round(v_delay/dt)), ...
                                      : ), dt}));
% set a name
model_vc = set(model_vc, 'id', [ 'sim ' get(f_I_v, 'id') ]);

% recalculate values of step steady-state currents
[time_steps, v_steps, i_steps] = ...
    findSteps(model_vc.v.data, model_vc.i.data, get(model_vc, 'dt'), props);

model_vc.i_steps = i_steps;
