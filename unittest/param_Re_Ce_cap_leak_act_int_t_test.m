function param_Re_Ce_cap_leak_act_int_t_test(ifplot)
  
% param_Re_Ce_cap_leak_act_int_t_test - Unit test.
%
% Usage:
%   param_Re_Ce_cap_leak_act_int_t_test(ifplot)
%
% Parameters:
%   ifplot: If 1, produce plots.
%
% Returns:
%
% Description:  
%   Uses the xunit framework by Steve Eddins downloaded from Mathworks
% File Exchange.
%
% See also: xunit
%
% $Id: param_Re_Ce_cap_leak_act_int_t_test.m 168 2010-10-04 19:02:23Z cengiz $
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2011/06/07

ifplot = defaultValue('ifplot', 0);
  
% compare the two implementations
capleakReCe_old_f = ...
    param_Re_Ce_cap_leak_int_t(...
      struct('Re', 28, 'Ce', 2e-4, 'gL', 3.2e-3, ... % Ce=2e-4 OR 4e-3
             'EL', -88, 'Cm', .018, 'delay', 0, 'offset', 0), ... % EL=-70
      ['cap, leak, Re and Ce']);

capleakReCe_new_f = ...
    param_Re_Ce_cap_leak_act_int_t(...
      struct('Re', 28, 'Ce', 2e-4, 'gL', 3.2e-3, ... % Ce=2e-4 OR 4e-3
             'EL', -88, 'Cm', .018, 'delay', 0, 'offset', 0), ... % EL=-70
      ['cap, leak, Re and Ce']);


% make a perfect voltage clamp data (could have used makeIdealClampV)
pre_v = -70;
pulse_v = -90:10:-50;
post_v = -70;
dt = 0.025; % [ms]
pre_t = round(10/dt) + 1; % +1 for neuron
pulse_t = round(100/dt);
post_t = round(10/dt);

a_p_clamp = ...
    voltage_clamp([ repmat(0, pre_t + pulse_t + post_t, length(pulse_v))], ...
                  [ repmat(pre_v, pre_t, length(pulse_v)); ...
                    repmat(pulse_v, pulse_t, 1); ...
                    repmat(post_v, post_t, length(pulse_v)) ], ...
                  dt*1e-3, 1e-9, 1e-3, 'Ideal voltage clamp');

% simulate
sim_old_vc = ...
    simModel(a_p_clamp, capleakReCe_old_f, struct('levels', 1:5));
sim_new_vc = ...
    simModel(a_p_clamp, capleakReCe_new_f, struct('levels', 1:5));

if ifplot
  plotFigure(plot_superpose({...
    plot_abstract(sim_old_vc, '', struct('onlyPlot', 'i', 'label', 'old Re')), ...
    plot_abstract(sim_new_vc, '', struct('onlyPlot', 'i', 'label', 'new Re'))}));
end

% init & steady tests
assertElementsAlmostEqual(sim_old_vc.i.data, ...
                          sim_new_vc.i.data, 'absolute', 1e-2);

% load neuron files
tr = ...
    trace('../../voltage-clamp/nrn/Ic_dt_0.025000ms_dy_1e-9nA_vclamp_-70_to_-90_mV.bin', ...
          0.025e-3,  1e-9, 'neuron sim Ic', ...
          struct('file_type', 'neuron', ...
                 'unit_y', 'A'));

if ifplot
  plotFigure(plot_superpose({...
    plot_abstract(tr, '', struct('label', 'Neuron sim', 'ColorOrder', [0 0 1; 1 0 0])), ...
    plot_abstract(setLevels(sim_new_vc, 1), '', struct('onlyPlot', 'i', ...
                                                    'label', 'new Re'))}));
end

if ifplot
  diff_tr = ...
      tr - get(setLevels(sim_new_vc, 1), 'i');
  plotFigure(plot_abstract(diff_tr, '', struct('label', 'diff')));
end

% init & steady tests
skip_dt = 3/dt; % skip settlement artifact at beginning
assertElementsAlmostEqual(tr.data(skip_dt:end), ...
                          sim_new_vc.i.data(skip_dt:end, 1), 'absolute', 1e-1);

