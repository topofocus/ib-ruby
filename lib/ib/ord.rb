# By requiring this file, we make all IB:Models database-backed ActiveRecord subclasses

require 'active-orient'

module IB
  module ORD 
    include ActiveOrient::Init

    # 
    def self.logger= logger
      ActiveOrient::Base.logger = logger 
      ActiveOrient::OrientDB.logger = logger 
    end

    # establishes a connection to the Database and returns the Connection-Object (an ActiveOrient::OrientDB.instance)
    def self.connect config={}

      c = { :server => 'localhost',
	    :port   => 2480,
	    :protocol => 'http',
	    :user    => 'hctw',
	    :password => 'hc',
	    :database => 'tws'
	       }.merge config.presence || {}
      ActiveOrient.default_server= { user: c[:user], password: c[:password] ,
				     server: c[:server], port: c[:port]  }
      ActiveOrient.database = c[:database]
      logger =  Logger.new '/dev/stdout'
      if ActiveOrient::Base.logger.nil? 
	ActiveOrient::Base.logger =  logger 
	ActiveOrient::OrientDB.logger = logger 
	IB::Gateway.logger = logger
      end
      ActiveOrient::Init.define_namespace { IB } 
      project_root = File.expand_path('../..', __FILE__)

      ActiveOrient::Model.model_dir =  "#{project_root}/models"
      ActiveOrient::OrientDB.new  preallocate: true  # connect via http-rest

    end
    def self.root
            project_root = File.expand_path('../..', __FILE__)

    end

  end # module DB
end


