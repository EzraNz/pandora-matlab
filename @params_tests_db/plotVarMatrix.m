function a_plot_stack = plotVarMatrix(a_db, p_stats)

% plotVarMatrix - Create a stack of parameter-test variation plots organized in a matrix.
%
% Usage:
% a_plot_stack = plotVarMatrix(a_db, p_stats)
%
% Description:
%   Skips the 'FileIndex' test.
%
%   Parameters:
%	a_db: A tests_db object.
%	p_stats: Cell array of invariant parameter databases.
%		
%   Returns:
%	a_plot_stack: A plot_stack with the plots organized in matrix form
%
% See also: params_tests_profile, plotVar
%
% $Id$
% Author: Cengiz Gunay <cgunay@emory.edu>, 2004/10/17

num_params = a_db.num_params;
num_tests = size(a_db, 2) - num_params - 1; %# Except the file indices

%# TODO: Row stacks with fixed y-axis bounds?
plot_rows = cell(1, num_tests);
for test_num=1:num_tests

  plots = cell(1, num_params);  
  for param_num=1:num_params
    a_stats_db = p_stats{param_num};
    plots{param_num} = plotVar(p_stats{param_num}, 1, test_num + 1, ...
			       struct('rotateYLabel', 60));
  end
  if test_num == 1
    props = struct('titlesPos', 'none', ...
		   'yLabelsPos', 'left');
  else
    props = struct('titlesPos', 'none', ...
		   'yLabelsPos', 'left', ...
		   'xLabelsPos', 'none', ...
		   'xTicksPos', 'none');
  end

  plot_rows{test_num} = plot_stack(plots, [], 'x', '', props);
end

a_plot_stack = plot_stack(plot_rows, [], 'y', '', ...
			  struct('titlesPos', 'none', ...
				 'xLabelsPos', 'bottom', ...
				 'xTicksPos', 'bottom'));
