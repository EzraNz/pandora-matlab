function a_doc_multi = ...
      reportCompareModelToPhysiolNeuron(m_bundle, trial_num, p_bundle, traceset_index, props)

% reportCompareModelToPhysiolNeuron - Generates a report by comparing given model neuron to given physiol neuron.
%
% Usage:
% a_doc_multi = reportCompareModelToPhysiolNeuron(m_bundle, trial_num, p_bundle, 
%						  traceset_index, props)
%
% Description:
%   Generates a report document with:
%	- Figure displaying raw traces of the physiol neuron compared with the model neuron
%	- Figure comparing f-I curves of the two neurons.
%	- Figure comparing spont and pulse spike shapes of the two neurons.
%
% Parameters:
%	m_bundle, p_bundle: dataset_db_bundle objects of the model and physiology neurons.
%	trial_num: Trial number of desired model neuron in m_bundle.
%	traceset_index: TracesetIndex of desired neuron in p_bundle.
%	props: A structure with any optional properties.
%	  horizRow: If defined, create a row-figure with all plots.
%	  numPhysTraces: Number of physiology traces to show in plot (>=1).
%
% Returns:
%	a_doc_multi: A doc_multi object that can be printed as a PS or PDF file.
%
% Example:
% >> printTeXFile(reportCompareModelToPhysiolNeuron(mbundle, 2222, pbundle, 34), 'a.tex')
%
% See also: doc_multi, doc_generate, doc_generate/printTeXFile
%
% $Id$
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2006/01/24

% Copyright (c) 2007 Cengiz Gunay <cengique@users.sf.net>.
% This work is licensed under the Academic Free License ("AFL")
% v. 3.0. To view a copy of this license, please look at the COPYING
% file distributed with this software or visit
% http://opensource.org/licenses/afl-3.0.php.

% TODO: add a prop (clearPageAtEnd: If given, a page break is inserted at end of document.)

if ~ exist('props')
  props = struct([]);
end

% Get raw data traces from bundles
phys_trace_d100 = ctFromRows(p_bundle, traceset_index, 100);
phys_trace_h100 = ctFromRows(p_bundle, traceset_index, -100);
phys_trace_id = ...
    properTeXLabel([ get(getItem(p_bundle.dataset, traceset_index), 'id') ...
		    '(s' num2str(traceset_index) ')']);

% If specified, only include desired number of the available phys. traces
% Mostly to allow showing only one trace, to avoid cluttered displays.
if isfield(props, 'numPhysTraces')
  phys_trace_d100 = ...
      phys_trace_d100(1:max(1, min(length(phys_trace_d100), props.numPhysTraces)));
  phys_trace_h100 = ...
      phys_trace_h100(1:max(1, min(length(phys_trace_h100), props.numPhysTraces)));
end

phys_db_row = p_bundle.joined_db(p_bundle.joined_db(:, 'TracesetIndex') == traceset_index, :);
phys_db_id = properTeXLabel(p_bundle.joined_db.id);

model_trace_d100 = ctFromRows(m_bundle, trial_num, 100);
model_trace_h100 = ctFromRows(m_bundle, trial_num, -100);
model_trace_id = [ get(get(m_bundle, 'db'), 'id') '(t' num2str(trial_num) ')' ];
mj_db = get(m_bundle, 'joined_db');
model_db_row = mj_db(mj_db(:, 'trial') == trial_num, :);
model_db_id = properTeXLabel(mj_db.id);

a_d100_plot = ...
    superposePlots([plotData(model_trace_d100), ...
		    plotData(phys_trace_d100)], {}, '+100 pA CIP');

a_h100_plot = ...
    superposePlots([plotData(model_trace_h100), ...
		    plotData(phys_trace_h100)], {}, '-100 pA CIP');

% Make a full figure with raw data traces
if isfield(props, 'horizRow')
  orientation = 'x';
  % remove legends
  a_d100_plot.legend = {};
  a_h100_plot.legend = {};
else
  orientation = 'y';
end
short_caption = ['Comparing raw traces of ' model_trace_id ' with ' phys_trace_id '.' ];
caption = [ short_caption ...
	   ' All available raw traces from the physiology neuron are shown.' ];
plot_title = '';

trace_doc = ...
    doc_plot(plot_stack([a_d100_plot, a_h100_plot], ...
			[0 3000 -150 80], orientation, plot_title, ...
			struct('xLabelsPos', 'bottom', 'yLabelsPos', 'left', ...
			       'yTicksPos', 'left')), ... % , 'titlesPos', 'none'
	     caption, short_caption, ...
	     struct('floatType', 'figure', 'center', 1, ...
		    'height', '.8\textheight', 'shortCaption', short_caption), ...
	     'raw trace figure', struct('orient', 'tall'));

% spike shape comparisons 
short_caption = [ 'Comparing spike shapes of ' model_trace_id ' to ' phys_trace_id '.' ];
caption = [ short_caption ];
plot_title = '';

phys_spont_sshape = get2ndSpike(phys_trace_d100(1), @periodIniSpont);
phys_pulse_sshape = get2ndSpike(phys_trace_d100(1), @periodPulse);

model_spont_sshape = get2ndSpike(model_trace_d100, @periodIniSpont);
model_pulse_sshape = get2ndSpike(model_trace_d100, @periodPulse);

sshape_doc = ...
    doc_plot(plot_stack([superposePlots([plotData(model_spont_sshape, 'model'), ...
					 plotData(phys_spont_sshape, 'phys.')], ...
					{}, '2nd spont. spike'), ...
			 superposePlots([plotData(model_pulse_sshape, 'model'), ...
					 plotData(phys_pulse_sshape, 'phys.')], ...
					{}, '2nd pulse spike')], [0 50 -100 80], 'x', ...
			plot_title, ...
			struct('yLabelsPos', 'left', 'yTicksPos', 'left')), ...
	     caption, ['compare spike shapes of ' phys_trace_id ' with ' model_trace_id ...
		       ' from ' model_db_id ], ...
	     struct('floatType', 'figure', 'center', 1, ...
		    'width', '.9\textwidth', 'shortCaption', short_caption), ...
	     'spike shape comparison', struct);

% fI curves
short_caption = [ 'Comparing f-I curves of ' model_trace_id ' with ' phys_trace_id '.' ];
caption = [ short_caption ];
if isfield(props, 'horizRow')
  sup_props = struct('noLegends', 1);
else
  sup_props = struct;
end

fIcurve_doc = ...
      doc_plot(plotComparefICurve(m_bundle, trial_num, p_bundle, traceset_index, ...
				  struct('shortCaption', short_caption, ...
					 'plotToStats', 1, 'captionToStats', ...
					 'phys. avg.', 'quiet', 1)), ...
	       caption, short_caption, ...
	       struct('floatType', 'figure', 'center', 1, ...
		      'width', '.7\textwidth', 'shortCaption', short_caption), ...
	       'frequency-current curve', struct);

% time vs. freq plot for +/- 100 pA CIP
phys_spikes_d100 = spikes(phys_trace_d100(1));
phys_spikes_h100 = spikes(phys_trace_h100(1));
model_spikes_d100 = spikes(model_trace_d100);
model_spikes_h100 = spikes(model_trace_h100);

short_caption = [ 'Comparing firing rate profiles of ' model_trace_id ' with ' phys_trace_id '.' ];
caption = [ short_caption ];
freq_profile_doc = ...
    doc_plot(plot_stack([superposePlots([plotFreqVsTime(model_spikes_d100, 'model'), ...
					 plotFreqVsTime(phys_spikes_d100, 'phys.')], ...
					{}, '+100 pA', '', ...
					mergeStructs(sup_props, ...
						     struct('quiet', 1))), ...
			 superposePlots([plotFreqVsTime(model_spikes_h100, 'model'), ...
					 plotFreqVsTime(phys_spikes_h100, 'phys.')], ...
					{}, '-100 pA', '', ...
					mergeStructs(sup_props, ...
						     struct('quiet', 1)))], ...
			[0 3000 0 100], 'x', '', ...
			struct('yLabelsPos', 'left', 'yTicksPos', 'left')), ...
	     caption, ['compare firing rate profiles of ' phys_trace_id ' with ' ...
		       model_trace_id ' from ' model_db_id ], ...
	     struct('floatType', 'figure', 'center', 1, ...
		    'width', '.7\textwidth', 'shortCaption', short_caption), ...
	     'freq-time curve', struct);

% Compose the pieces together into larger document
if isfield(props, 'horizRow')
  plot_title = [ 'compare model ' model_trace_id ' to neuron ' phys_trace_id ];
  a_doc_multi = ...
      doc_plot(plot_stack({trace_doc.plot, freq_profile_doc.plot, ...
			   fIcurve_doc.plot, ...
			   sshape_doc.plot}, [], 'x', plot_title, ...
			  struct('PaperPosition', [0 0 12 3])), ...
	       caption, ['compare ' phys_trace_id ' with ' ...
			 model_trace_id ' from ' model_db_id ], ...
	       struct('floatType', 'figure', 'center', 1, ...
		      'width', '.7\textwidth', 'shortCaption', short_caption), ...
	       plot_title, struct);
else
  a_doc_multi = ...
      doc_multi({trace_doc, sshape_doc, fIcurve_doc, freq_profile_doc}, ...
		[ 'model ' model_trace_id ' to phys. neuron ' phys_trace_id ' comparison report']);
end

end

function sshape = get2ndSpike(ct, period_func)
  spks = spikes(ct);
  num_spikes = ...
      length(get(withinPeriod(spks, feval(period_func, ct)), 'times'));
  if  num_spikes > 0
    sshape = setProp(getSpike(ct, spks, min(num_spikes, 2)), 'quiet', 1);
  else
    sshape = spike_shape;
  end
end
