function a_p = plotSimCurrent(a_vc, f_I_v, props)

% plotSimCurrent - Simulate voltage clamp current on a model channel and superpose on data.
%
% Usage:
% a_p = plotSimCurrent(a_vc, f_I_v, props)
%
% Parameters:
%   a_vc: A voltage_clamp object.
%   f_I_v: param_func object representing the model channel. 
%   props: A structure with any optional properties.
%     delay: If given, use as voltage clamp delay [ms].
%     levels: Only plot these voltage level indices.
%		
% Returns:
%   a_p: A plot_abstract object.
%
% Description:
%
% Example:
% >> plotFigure(plotSimCurrent(a_vc))
%
% See also: param_I_v, param_func, plot_abstract
%
% $Id: plotSimCurrent.m 1174 2009-03-31 03:14:21Z cengiz $
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2010/03/29

% TODO: 

if ~ exist('props', 'var')
  props = struct;
end

dt = get(a_vc, 'dt');

data_i = get(a_vc.i, 'data');
data_v = get(a_vc.v, 'data');
cell_name = get(a_vc, 'id');
time = (0:(size(data_i, 1)-1))*dt;

% choose the range
range_step_1 = ...
    max(1, (a_vc.time_steps(1) - round(10 / dt))) : ...
    min(size(data_v, 1), (a_vc.time_steps(2) + round(10 / dt)));

if isfield(props, 'delay')
  v_delay = props.delay; % ms, for space clamp error delay
else
  v_delay = 0; 
end

% select which levels to plot
if isfield(props, 'levels')
  % only few (faster)
  v_step_idx = v_step_idx(props.levels);
else
  v_step_idx = 1:length(a_vc.v_steps);
end

% integrate current for each voltage step
Isim = ...
    f(f_I_v, { data_v(max(1, range_step_1 - round(v_delay/dt)), ...
                      v_step_idx ), dt});
    
% nicely plot current and voltage trace in separate axes  
line_colors = lines(length(a_vc.v_steps)); %hsv(length(v_steps));

% stacked plot
a_p = ...
  plot_stack({...
    plot_abstract({time, data_i}, {'time [ms]', 'I_{data} [nA]'}, ...
                  'data', {}, 'plot', struct('ColorOrder', line_colors)), ...
    plot_abstract({time(range_step_1), Isim}, {'time [ms]', 'I_{sim} [nA]'}, ...
                  'model', {}, 'plot', struct('ColorOrder', line_colors)), ...
    plot_abstract({time, data_v}, {'time [ms]', 'V_m [mV]'}, ...
                  'all currents', {}, 'plot', struct('ColorOrder', line_colors))}, ...
             [min(time(range_step_1)) max(time(range_step_1)) NaN NaN], ...
             'y', [ cell_name ], ...
             struct('titlesPos', 'none', 'xLabelsPos', 'bottom', ...
                    'fixedSize', [4 4], 'noTitle', 1));
  
end
