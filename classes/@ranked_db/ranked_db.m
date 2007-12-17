function a_ranked_db = ranked_db(data, col_names, orig_db, crit_db, id, props)

% ranked_db - A database of distance values generated by ranking rows of orig_db with the criterion in crit_db.
%
% Usage:
% a_ranked_db = ranked_db(data, col_names, orig_db, crit_db, id, props)
%
% Description:
%   This is a subclass of tests_db. It should contain a Distance column. A
% more general ranked db class may be needed later. Use the rankMatching method
% to get an instance of this class.
%
%   Parameters:
%	data: Database contents.
%	col_names: The column names.
%	orig_db: DB whose rows are ranked.
%	crit_db: The criterion DB used for generating the ranking scores.
%	id: An identifying string.
%	props: A structure with any optional properties.
%	  tolerateNaNs: If 0, rows with any NaN values are skipped (default=1).
%		
%   Returns a structure object with the following fields:
%	tests_db, orig_db, crit_db, props.
%
% General operations on ranked_db objects:
%   ranked_db		- Construct a new ranked_db object.
%   displayRows		- Overloaded to provide individual distances for each column.
%   joinedOriginal	- Joins the Distance column with the original DB.
%
% Additional methods:
%	See methods('ranked_db')
%
% See also: tests_db, tests_db/rankMatching, tests_db/matchingRow
%
% $Id$
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2004/12/21

% Copyright (c) 2007 Cengiz Gunay <cengique@users.sf.net>.
% This work is licensed under the Academic Free License ("AFL")
% v. 3.0. To view a copy of this license, please look at the COPYING
% file distributed with this software or visit
% http://opensource.org/licenses/afl-3.0.php.

if nargin == 0 % Called with no params
   a_ranked_db.orig_db = tests_db;
   a_ranked_db.crit_db = tests_db;
   a_ranked_db = class(a_ranked_db, 'ranked_db', tests_db);
 elseif isa(data, 'ranked_db') % copy constructor?
   a_ranked_db = data;
 else % Create a new object

   if ~ exist('props')
     props = struct([]);
   end

   a_ranked_db.orig_db = orig_db;
   a_ranked_db.crit_db = crit_db;

   a_ranked_db = class(a_ranked_db, 'ranked_db', ...
		       tests_db(data, col_names, {}, id, props));
end

