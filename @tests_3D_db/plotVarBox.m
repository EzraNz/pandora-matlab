function a_plot = plotVarBox(a_db, test1, test2, notch, sym, vert, whis, props)

% plotVarBox - Generates a boxplot of the variation between two tests.
%
% Usage:
% a_plot = plotVarBox(a_db, test1, test2, notch, sym, vert, whis, props)
%
% Description:
%   It is assumed that each page of the db contains a different parameter value.
%
%   Parameters:
%	a_db: A tests_3D_db object.
%	test1: Test column for the x-axis, only mean values are used.
%	test2: Test column for the y-axis, used for boxplot.
%	notch, sym, vert, whis: See boxplot, defaults = (1, '+', 1, 1.5).
%	props: Optional properties to be passed to plot_abstract.
%		
%   Returns:
%	a_plot: A plot_abstract object or one of its subclasses.
%
% See also: boxplot, plot_abstract
%
% $Id$
% Author: Cengiz Gunay <cgunay@emory.edu>, 2004/11/10

if ~ exist('props')
  props = struct([]);
end

if ~ exist('notch')
   notch = 1;
end

if ~ exist('sym')
  sym = '+';
end

if ~ exist('vert')
  vert = 1;
end

if ~ exist('whis')
  whis = 1.5;
end

col1 = tests2cols(a_db, test1);
col2 = tests2cols(a_db, test2);

%# Setup lookup tables
col_names = fieldnames(get(a_db, 'col_idx'));
data = get(a_db, 'data');

%# remove the column dimension from in-between
%# (squeeze me macaroni)
col1data = squeeze(data(:, col1, :)); %# Grouping variable
col2data = squeeze(data(:, col2, :));

%# Flatten into a single dimension, since boxplot can still distinguish by looking
%# at distinct values of the grouping variable
%# (see "help reshape the world")
bicoldata = [reshape(col1data, prod(size(col1data)), 1), ...
	     reshape(col2data, prod(size(col2data)), 1)];

%# Remove rows with any NaN values since they will disrupt the statistics
bicoldata = bicoldata(~any(isnan(bicoldata), 2), :);

col1name = col_names{col1};
col2name = col_names{col2};

a_plot = plot_abstract({bicoldata(:, 2), bicoldata(:, 1), ...
			notch, sym, vert, whis, struct('nooutliers', 1)}, ...
		       {col1name, col2name}, ...
		       ['Variations in ' get(a_db, 'id') ], {}, 'boxplotp', props);
