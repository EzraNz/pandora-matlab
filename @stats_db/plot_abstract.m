function a_plot = plot_abstract(a_stats_db, props)

% plot_abstract - Generates an error bar representation for each of the columns
%	in this db. Looks for 'min', 'max', and 'std' labels in the row_idx
%	for drawing the errorbars.
%
% Usage:
% a_plot = plot_abstract(a_stats_db)
%
% Description:
%   Generates a plot_simple object from this histogram.
%
%   Parameters:
%	a_stats_db: A histogram_db object.
%	command: Plot command (Optional, default='bar')
%		
%   Returns:
%	a_plot: A object of plot_abstract or one of its subclasses.
%
% See also: plot_abstract, plot_simple
%
% $Id$
% Author: Cengiz Gunay <cgunay@emory.edu>, 2004/10/08

if ~ exist('command')
  command = 'bar';
end

if ~ exist('props')
  props = struct([]);
end

%# Setup lookup tables
col_names = fieldnames(get(a_stats_db, 'col_idx'));
data = get(a_stats_db, 'data');
row_idx = get(a_stats_db, 'row_idx');

if isfield(row_idx, 'min')
  lows = data(row_idx.min,:) - data(1,:);
elseif isfield(row_idx, 'std')
  lows = -data(row_idx.std,:);  
  highs = data(row_idx.std,:);
elseif isfield(row_idx, 'se')
  lows = -data(row_idx.se,:);  
  highs = data(row_idx.se,:);
end

if isfield(row_idx, 'max')
  highs = data(row_idx.max,:) - data(1,:);
end

if isfield(a_stats_db.props, 'axis_limits')
  axis_limits = a_stats_db.props.axis_limits;
else
  axis_limits = [];
end

a_plot = plot_errorbars(data(1,:), lows, highs, ...
		       col_names, get(a_stats_db, 'id'), axis_limits, ...
		       mergeStructs(props, a_stats_db.props));
