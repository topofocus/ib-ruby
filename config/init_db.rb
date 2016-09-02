# Execute with 
#  ActiveOrient::OrientSetup.init_database
#
module ActiveOrient
  module OrientSetup
    def self.init_database
      (logger= ActiveOrient::Base.logger).progname= 'OrientSetup#InitDatabase'
      contracts =  DB.class_hierarchy base_class: 'contract'
      edges = DB.class_hierarchy base_class: 'E'
      logger.info{ " preallocated-database-classes: #{DB.database_classes.join(" , ")} " }

      delete_class = -> (c,d) do 
	the_class = ActiveOrient::Model.orientdb_class( name: c, superclass: d)
	logger.info{  "The Class: "+the_class.to_s }
	the_class.delete_class
      end
      
      logger.info{ "  Deleting Class and Classdefinitions" }
      contracts.each{|v| delete_class[ v, :contract ]}
      delete_class[ :contract, :V ] if defined?(IB::Contract)
      delete_class[ :contract_detail, ActiveOrient::Model ] if defined?(IB::ContractDetail)
      delete_class[ :account, ActiveOrient::Model ] if defined?(IB::Account)
      delete_class[ :bar, ActiveOrient::Model ] if defined?(IB::Bar)
      edges.each{|e| delete_class[ e, :E ] }

      logger.info{ "  Creating Classes " }
  DB.create_classes 'E', 'V'
  #E.ref_name = 'E'
  #V.ref_name = 'V'
      #ActiveOrient::Init.vertex_and_egde_class
      DB.create_vertex_class :contract		      # --> TimeBase
      contract_classes = DB.create_classes( :stock, :option, :future, :forex,  :bag){ :contract }
      IB::Contract.create_property :con_id, type: :integer
      IB::Contract.create_index 'contract_idx', on: :con_id

      DB.create_class :contract_detail
      IB::Contract.create_property :contract_detail , type: :link, linked_class: :contract_detail
      
      DB.create_class :bar
      IB::Bar.create_property :contract, type: :link, linked_class: :contract
      IB::Bar.create_property( :time, type: 'datetime')
      IB::Bar.create_index 'time_ind', :on => [ :time, :contract ]

      DB.create_class :account
      IB::Account.create_property( :account, type: :string ){ :unique }



      ## this puts an uniqe index on child-classes
      #time_base_classes.each{|y| y.create_index :value }
      
      # modified naming-convention in  model/e.rb
      #edges = ORD.create_edge_class :time_of, :day_of	     # --> TIME_OF, :DAY_OF
#      edges.each &:uniq_index

      DB.database_classes  # return_value
    end
  end
end
# to_do:  define validations
#  hour_class   = r.create_vertex_class "Hour", properties: {value_string: {type: :string}, value: {type: :integer}}
#  hour_class.alter_property property: "value", attribute: "MIN", alteration: 0
#  hour_class.alter_property property: "value", attribute: "MAX", alteration: 23
#
#  day_class    = r.create_vertex_class "Day", properties: {value_string: {type: :string}, value: {type: :integer}}
#  day_class.alter_property property: "value", attribute: "MIN", alteration: 1
#  day_class.alter_property property: "value", attribute: "MAX", alteration: 31
#
#  month_class  = r.create_vertex_class "Month", properties: {value_string: {type: :string}, value: {type: :integer}}
#  month_class.alter_property property: "value", attribute: "MIN", alteration: 1
#  month_class.alter_property property: "value", attribute: "MAX", alteration: 12
#

#  timeof_class = r.create_edge_class "TIMEOF"
