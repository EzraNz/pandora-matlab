function a_hist_db = histogram_db(col_name, bins, hist_results, id, props)

% histogram_db - A database of histogram values generated for 
%		a column of another database.
%
% Usage:
% a_hist_db = histogram_db(col_name, bins, hist_results, id, props)
%
% Description:
%   This is a subclass of tests_db. Allows generating a histogram plot, etc.
%
%   Parameters:
%	col_name: The column name of the histogrammed value.
%	bins: The values for which the histogram values are calculated.
%	hist_results: A column vector of histogram values.
%	id: An identifying string.
%	props: A structure with any optional properties.
%		
%   Returns a structure object with the following fields:
%	tests_db, props.
%
% General operations on histogram_db objects:
%   histogram_db		- Construct a new histogram_db object.
%   plot_abstract		- Create a simple plot object
%   plotPages			- Create a multiplot from pages of histograms.
%   plot			- Plot this histogram alone in a figure.
%
% Additional methods:
%	See methods('histogram_db')
%
% See also: tests_db, plot_simple, tests_db/histogram
%
% $Id$
% Author: Cengiz Gunay <cgunay@emory.edu>, 2004/09/20

if nargin == 0 %# Called with no params
   a_hist_db.props = struct([]);
   a_hist_db = class(a_hist_db, 'histogram_db', tests_db);
 elseif isa(col_name, 'histogram_db') %# copy constructor?
   a_hist_db = col_name;
 else

   if ~ exist('props')
     props = struct([]);
   end

   %# Add a column for bin numbers
   test_results = [bins, hist_results];
   col_names = { col_name, 'histVal' };

   a_hist_db.props = props;

   a_hist_db = class(a_hist_db, 'histogram_db', ...
		     tests_db(test_results, col_names, {}, id, props));
end

