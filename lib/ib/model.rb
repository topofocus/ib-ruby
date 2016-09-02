require 'ib/base_properties'
require 'ib/base'

module IB
  # IB Models can be either lightweight (tableless) or database-backed.
  # require 'ib/db' - to make all IB models database-backed
  Model =  if IB.db_backed? 
	     ActiveRecord::Base 
	   elsif IB.orient?
	     ActiveOrient::Base 
	   else
	     IB::Base
	   end
end
