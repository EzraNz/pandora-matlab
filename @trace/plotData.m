function a_plot = plotData(t, title_str)

% plotData - Plots a trace.
%
% Usage: 
% a_plot = plotData(t, title_str)
%
% Description:
%   Parameters:
%	t: A trace object.
%
%   Returns:
%	a_plot: A plot_abstract object that can be visualized.
%	title_str: (Optional) String to append to plot title.
%
% See also: trace, plot_abstract
%
% $Id$
% Author: Cengiz Gunay <cgunay@emory.edu>, 2004/11/17

if ~ exist('title_str')
  title_str = '';
end

time = (1:length(t.data)) * t.dt * 1e3; %# in ms

if isfield(t.props, 'y_label')
  ylabel = t.props.y_label;
else
  ylabel = 'voltage [mV]';
end

%# If input is an array, then return array of plots
num_dbs = length(t);
if num_dbs > 1 
  %# Create array of plots
  [a_plot(1:num_dbs)] = deal(plot_abstract);
  for plot_num = 1:num_dbs
    a_plot(plot_num) = plotData(t(plot_num), title_str);
  end
  return;
end

%# Remove all '_' characters, because they interfere with TeX interpretation

if isfield(t.props, 'quiet') 
  the_title = title_str;
else
  class_name = strrep(class(t), '_', ' ');
  the_title = [ sprintf('%s: %s', class_name, t.id) title_str ];
end

a_plot = plot_abstract({time, t.dy * t.data * 1e3}, ...
		       {'time [ms]', ylabel}, ...
		       the_title, ...
		       {t.id});
