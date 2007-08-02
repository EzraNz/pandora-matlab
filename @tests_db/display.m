function s = display(t)

% Generic object display method.
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2004/08/04

%# Handle differently if an array of DBs
if length(t) > 1
  disp(t);
  return;
end

disp(sprintf('%s, %s', class(t), t.id));
%#struct(t) not needed
disp([ num2str(dbsize(t, 1)) ' rows in database with ' ...
      num2str(dbsize(t, 2)) ' columns, and ' ...
      num2str(dbsize(t, 3)) ' pages.']);
disp('Column names:');
colnames = fieldnames(t.col_idx);
colnums = num2cell(1:length(colnames));
format long
numnamecell = { colnums{:}; colnames{:} };
disp(numnamecell');
format short
row_names = fieldnames(t.row_idx);
if ~ isempty(row_names)
  disp('Row names:');
  disp(row_names);
end
disp(['Optional properties of ' class(t) ':']);
struct(t.props)
