function res = integrate(a_sol, x, props)

% integrate - Integrate all variables of a system and return a matrix of [time, vars, columns].
%
% Usage:
%   res = integrate(a_sol, x, props)
%
% Parameters:
%   a_sol: A param_func object.
%   props: A structure with any optional properties.
%     time: Array of time points where functions should be integrated
%           (default=for all points in x)
%		
% Returns:
%   res: A structure array with the array of variable solutions.
%
% Description:
%
% Example:
%   >> res = integrate(a_sol)
%
% See also: dt, add, setVals, solver_int, deriv_func, param_func
%
% $Id: integrate.m 88 2010-04-08 17:41:24Z cengiz $
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2010/06/10

% Copyright (c) 2009-2010 Cengiz Gunay <cengique@users.sf.net>.
% This work is licensed under the Academic Free License ("AFL")
% v. 3.0. To view a copy of this license, please look at the COPYING
% file distributed with this software or visit
% http://opensource.org/licenses/afl-3.0.php.

props = defaultValue('props', struct);

num_vars = length(fieldnames(a_sol.vars));
dfdt_init = repmat(NaN, num_vars, 1);
dfdtHs = struct2cell(a_sol.dfdtHs);

% by default integrate for all values in x
time = getFieldDefault(props, 'time', (0:(size(x, 1) - 1))*a_sol.dt);

% integrate each column separately
num_columns = size(x, 2);
res = repmat(NaN, [length(time), num_vars, num_columns]);
for column_num = 1:num_columns
  % initialize
  a_sol_tmp = a_sol;
  v_col = x(:, column_num);
  [t_tmp, result] = ...
      ode15s(@(t,vars) deriv_all(t, vars), ...
             time, cell2mat(struct2cell(a_sol.vars)'));
  res(:, :, column_num) = result;
end

function dfdt = deriv_all(t, vars)
  a_sol_tmp = setVals(a_sol_tmp, vars);
  dfdt = dfdt_init;
  for var_num = 1:num_vars
    dfdt(var_num) = ...
        feval(dfdtHs{var_num}, ...
              struct('t', t, 's', a_sol_tmp, 'v', v_col, 'dt', a_sol.dt));
  end
  end

end