function [f_capleak sub_vc] = ...
      scale_sub_cap_leak(a_vc, title_str, props)

% scale_sub_cap_leak - Scale capacitance and leak artifacts to subtract them.
%
% Usage:
% [f_capleak sub_vc] = scale_sub_cap_leak(a_vc, props)
%
% Parameters:
%   a_vc: Full path to a_vc.
%   props: A structure with any optional properties.
%     capLeakModel: Model object to fit (default obtained from
%     param_cap_leak_int_t). Can choose object obtained from another
%     function such as: param_Rs_cap_leak_int_t, param_cap_leak_2comp_int_t.
%     fitRange: Start and end times of range to apply the optimization [ms].
%     fitRangeRel: Start and end times of range relative to first voltage
%     		   step [ms]. Specify any other voltage step as the first element.
%     fitLevels: Indices of voltage/current levels to use from clamp
%     		 data. If empty, not fit is done.
%     dispParams: If non-zero, display params every once this many iterations.
%     dispPlot: If non-zero, update a plot of the fit at end of this many iterations.
%     saveData: If 1, save subtracted data into a new text file (default=0).
%     quiet: If 1, do not include cell name on title.
%     period: Limit the subtraction to this period of a_vc.
% 
% Returns:
%   f_capleak: Updated function with fitted parameters
%   sub_vc: voltage_clamp object with passive-subtracted I trace.
%
% Description:
%
% Example:
% % set up a function with passive electrode and membrane parameters
% >> capleakReCe_f = ...
%    param_Re_Ce_cap_leak_int_t(...
%      struct('Re', 47, 'Ce', 12, 'gL', .56, ...
%             'EL', -67, 'Cm', 270, 'delay', 0.21), ...
%                         ['cap, leak, Re and Ce']);
% % load ABF file and use above function to fit selected voltage steps
% >> [capleakReCe_f sub_cap_leak_vc ] = ...
%    scale_sub_cap_leak(...
%      abf2voltage_clamp('calcium.abf'), '', ...
%      struct('capLeakModel', capleakReCe_f, ...
%             'fitRangeRel', [-.2 165], 'fitLevels', 1:5, ...
%             'optimset', struct('Display', 'iter')));
%
% See also: param_I_v, param_func
%
% $Id$
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2010/01/17

% TODO: 
% - process 2nd step and write a 2nd data file for prepulse step
% - prepare a doc_multi from this. Find a way to label figures but print later.
% - also plot IClCa m_infty curve?
% - have option to show no plots, to create database of params
% - extract fitting to a separate function that returns the optimized _f

props = defaultValue('props', struct);
title_str = defaultValue('title_str', '');

dt = get(a_vc, 'dt') * 1e3;             % convert to ms
cell_name = get(a_vc, 'id');

time = (0:(size(a_vc.v.data, 1) - 1)) * dt;

% select the initial part before v-dep currents get activated
range_rel = getFieldDefault(props, 'fitRangeRel', [-.2, +1]); % [ms]

if length(range_rel) > 2
  step_num = range_rel(1);
  range_rel = range_rel(2:end);
else
  step_num = 1;
end
range_maxima = ...
    getFieldDefault(props, 'fitRange', ...
                           [a_vc.time_steps(step_num) + ...
                    floor(range_rel / dt + .49)]);
range_cap_resp = round(range_maxima(1)):round(range_maxima(2));

% use all voltage levels by default
use_levels = getFieldDefault(props, 'fitLevels', 1:size(a_vc.v.data, 2));

% func
if ~ isfield(props, 'capLeakModel')
  f_capleak = ...
      param_cap_leak_int_t(...
        struct('gL', 0.7, 'EL', -75, 'Cm', .2, 'delay', 0.1), ...
        ['cap leak']);
else
  f_capleak = props.capLeakModel;
end

extra_text = ...
    [ '; fit ' get(f_capleak, 'id') ' to [' ...
      sprintf('%.2f ', range_maxima * dt) ']' ...
      '; levels: [' sprintf('%d ', use_levels) '], ' ...
      getParamsString(f_capleak) ];

if isfield(props, 'quiet')
  all_title = properTeXLabel(title_str);
else
  all_title = ...
      properTeXLabel([ cell_name ': Raw data' extra_text title_str ]);
end

if isfield(props, 'dispParams')
  props = ...
      mergeStructsRecursive(...
        props, ...
        struct('optimset', optimset('OutputFcn', @disp_out)));
end

if isfield(props, 'dispPlot') && props.dispPlot > 0
  props = ...
      mergeStructsRecursive(...
        props, ...
        struct('optimset', optimset('OutputFcn', @plot_out)));      
end

% need to run optimset at least once to get all the fields
props = ...
    mergeStructsRecursive(props, struct('optimset', optimset));      


  line_colors = lines(length(use_levels)); %hsv(length(v_steps));

  function stop = disp_out(x, optimValues, state)
    if mod(optimValues.iteration, props.dispParams) == 0 && ...
          strcmp(state, 'iter')
      disp(displayParams(setParams(f_capleak, x, struct('onlySelect', 1)), ...
                         struct('lastParams', getParams(f_capleak), ...
                                'onlySelect', 1)));
    end
    stop = false;
  end

  fig_props = struct;
  
  function stop = plot_out(p, optimValues, state)
    if mod(optimValues.iteration, props.dispPlot) == 0  && ...
          strcmp(state, 'iter')
      f_capleak = setParams(f_capleak, p, struct('onlySelect', 1));
      Im = f(f_capleak, struct('v', a_vc.v.data(range_cap_resp, use_levels), 'dt', dt));
      fig_handle = ...
          plotFigure(...
            plot_stack({...
              plot_superpose({...
                plot_abstract({time(range_cap_resp), ...
                          a_vc.i.data(range_cap_resp, use_levels)}, ...
                              {'time [ms]', 'I [nA]'}, ...
                              'fitted currents', {}, 'plot', ...
                              struct('ColorOrder', line_colors, ...
                                     'noLegends', 1)), ...
                plot_abstract({time(range_cap_resp), Im}, ...
                              {'time [ms]', 'I [nA]'}, ...
                              'est. I_{cap+leak}', {}, 'plot', ...
                              struct('plotProps', struct('LineWidth', 2), ...
                                     'ColorOrder', line_colors))}, ...
                             {}, '', struct('noCombine', 1)), ...
              plot_abstract({time(range_cap_resp), ...
                          a_vc.v.data(range_cap_resp, use_levels)}, {'time [ms]', 'V_m [mV]'}, ...
                            'all currents', {}, 'plot', struct)}, ...
                       [min(range_cap_resp) * dt, max(range_cap_resp) * dt NaN NaN], ...
                       'y', all_title, ...
                       struct('titlesPos', 'none', 'xLabelsPos', 'bottom', ...
                              'fixedSize', [4 3], 'noTitle', 1)), '', ...
            fig_props);
      fig_props = mergeStructs(struct('figureHandle', fig_handle), fig_props);
    end
    stop = false;
  end

  % list of voltage steps for labeling
  v_steps = a_vc.v_steps(2, :);
  v_legend = ...
      cellfun(@(x)([ sprintf('%.0f', x) ' mV']), num2cell(v_steps'), ...
              'UniformOutput', false);

  params = getParamsStruct(f_capleak);

if ~ isempty(use_levels)
  disp('Fitting...');
  %select_params = {'Ri', 'Cm', 'delay'}
  %select_params = {'gL', 'EL'}
  %f_capleak = setProp(f_capleak, 'selectParams', select_params); 

  % optimize
  f_capleak = ...
      optimize(f_capleak, ...
               struct('v', a_vc.v.data(range_cap_resp, use_levels), 'dt', dt), ...
               a_vc.i.data(range_cap_resp, use_levels), ...
               props);

  % recreate title text with new parameters
  extra_text = ...
    [ '; fit ' get(f_capleak, 'id') ' to [' ...
      sprintf('%.2f ', range_maxima * dt) ']' ...
      '; levels: [' sprintf('%d ', use_levels) '], ' ...
      getParamsString(f_capleak) ];

  if isfield(props, 'quiet')
    all_title = properTeXLabel(title_str);
  else
    all_title = ...
        properTeXLabel([ cell_name ': Raw data' extra_text title_str ]);
  end

  % show all parameters
  params = getParamsStruct(f_capleak)

  Im = f(f_capleak, struct('v', a_vc.v.data(range_cap_resp, use_levels), 'dt', dt));

  % nicely plot current and voltage trace in separate axes only for
  % part fitted

plotFigure(...
  plot_stack({...
    plot_superpose({...
        plot_abstract({time(range_cap_resp), ...
                    a_vc.i.data(range_cap_resp, use_levels)}, ...
                      {'time [ms]', 'I [nA]'}, ...
                      'fitted currents', {}, 'plot', ...
                      struct('ColorOrder', line_colors, ...
                             'noLegends', 1)), ...
        plot_abstract({time(range_cap_resp), Im}, ...
                      {'time [ms]', 'I [nA]'}, ...
                      'est. I_{cap+leak}', {}, 'plot', ...
                      struct('plotProps', struct('LineWidth', 2), ...
                             'ColorOrder', line_colors))}, ...
                     {}, '', struct('noCombine', 1)), ...
    plot_abstract({time(range_cap_resp), ...
                   a_vc.v.data(range_cap_resp, use_levels)}, {'time [ms]', 'V_m [mV]'}, ...
                  'all currents', {}, 'plot', struct)}, ...
             [min(range_cap_resp) * dt, max(range_cap_resp) * dt NaN NaN], ...
             'y', all_title, ...
             struct('titlesPos', 'none', 'xLabelsPos', 'bottom', ...
                    'fixedSize', [4 3], 'noTitle', 1)));

end

  line_colors = lines(length(v_steps)); %hsv(length(v_steps));

  % choose the range
  period_range = getFieldDefault(props, 'period', periodWhole(a_vc));
% $$$   period_range = period(round(a_vc.time_steps(1) - 10 / dt), ...
% $$$                         round(a_vc.time_steps(2) + 30 / dt));

  % restrict the a_vc to given range to prepare for subtraction
  [a_range_vc period_range] = ...
      withinPeriod(a_vc, period_range, struct('useAvailable', 1)); 

  range_steps = array(period_range);

  model_vc = simModel(a_range_vc, f_capleak);
  
  % subtract the cap+leak part from current
  sub_vc = a_range_vc - model_vc;
  
  % HACK: choose between Re and Vm_Re
  Re = getFieldDefault(params, 'Re', getFieldDefault(params, 'Vm_Re', NaN));
  
  % Recalculate voltage traces based on series resistance.
  % There is a problem because additional currents will still affect the
  % voltage, although it is good to keep to see the membrane voltage?
  % TODO: shift back the delay in the current trace?
  sub_vc.v = sub_vc.v - model_vc.i * Re;
  
  if isfield(props, 'quiet')
    all_title = properTeXLabel(title_str);
  else
    all_title = ...
        properTeXLabel([ cell_name ': Sim + sub data' extra_text title_str ]);
  end

  % superpose over data  
  plotFigure(...
    plot_stack({...
      plot_superpose({...
        plot_abstract({time, a_vc.i.data}, {'time [ms]', 'I_{data}&I_{sim} [nA]'}, ...
                      'data', v_legend, 'plot', ...
                      struct('ColorOrder', line_colors)), ...
        plot_abstract({time(range_steps), model_vc.i.data}, ...
                      {'time [ms]', 'I [nA]'}, ...
                      'est. I_{cap+leak}', {}, 'plot', ...
                      struct('plotProps', struct('LineWidth', 2), ...
                             'ColorOrder', line_colors))}, ...
                     {}, '', struct('noCombine', 1)), ...
      plot_abstract({time(range_steps), sub_vc.i.data}, ...
                    {'time [ms]', 'I_{error} [nA]'}, ...
                    'data - I_{cap+leak}', {}, 'plot', ...
                    struct('ColorOrder', line_colors, ...
                           'plotProps', struct('LineWidth', 1)))}, ...
               [min(range_steps) * dt, max(range_steps) * dt NaN NaN], ...
               'y', all_title, ...
               struct('titlesPos', 'none', 'xLabelsPos', 'bottom', ...
                      'fixedSize', [4 3], 'noTitle', 1, ...
                      'relativeSizes', [3 1])));

if isfield(props, 'saveData')
  saveDataTxt(sub_vc);
end

end
