
require 'singleton'
require 'thread'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
# Ruby:
# :postgresql => gem 'pg', platform: :ruby
# :orientdb   => gem 'orientdb4r', platform: :ruby
# 
# JRuby:
# :postgresql => gem 'jruby_pg', platform: :jruby  
# :orientdb   => gem 'orientdb', platform: :jruby
#
module TSDatabase
    class TSManager
        include Singleton
    
        class << self
            def database_default; @@database_default; end
            def default; 0; end
            def preloaded; 100; end
            def keep_loaded; 200; end
      
            # \param mode could be
            # => :DEFAULT : disconnect client on push 
            # => :PRELOADED : don't disconnect client on push and connect on initialisation \see :config_json or :config_yml
            # => :KEEP_LOADED : don't disconnect client on push    
            def set_mode(mode);@@mode = mode; end
      
            alias_method :db, :instance
        end
    
        @@mode = TSManager.default
        @@database_default = nil
    
        def initialize
            @clients = {}
            @dbconfig = nil
        end
    
        def pop_connection(database = @@database_default)
            connections = Thread.current[:tsclientdb]
            if (connections.nil?)
                Thread.current[:tsclientdb]={}
            end
            clt = Thread.current[:tsclientdb][database] ||= @clients[database].pop
            clt.connect
            clt
        end
    
        alias_method :get,  :pop_connection
        alias_method :pop,  :pop_connection
        alias_method :open, :pop_connection

        def push_connection(database = @@database_default)
            connections = Thread.current[:tsclientdb][database]
            unless (connections.nil?)
                Thread.current[:tsclientdb].delete(database)
                if (@@mode==TSManager.default)
                    connections.disconnect
                end
                @clients[database].push connections
            end
        end
    
        alias_method :free,  :push_connection
        alias_method :push,  :push_connection
        alias_method :close, :push_connection
    
        # \brief close (push) all connection get(pop)
        def all_close
            connections = Thread.current[:tsclientdb]
            unless (connections.nil?)
                connections.each do |key, value|
                    if (@@mode==TSManager.default)
                        value.disconnect
                    end
                    @clients[key].push value
                end
                Thread.current[:tsclientdb] = nil
            end
        end
    
        alias_method :close_all, :all_close

        #\brief before to use you need to have in your Gems yaml 
        def config_yml(filename, mode="production")
            if (@dbconfig.nil?)
                require 'yaml'
                yaml_hash= YAML::load(File.open(filename))
                @dbconfig = yaml_hash[mode]
                generate_clients 
            else
                raise ConfigurationError, "Multiple configuration"
            end
        end
    
        #\brief before to use you need to have in your Gems multi_json
        def config_json(filename, mode="production")
            if (@dbconfig.nil?)
                require "multi_json"
                json_hash= MultiJson.load(File.open(filename))
                @dbconfig = json_hash=[mode]
                generate_clients
            else
                raise ConfigurationError, "Multiple configuration"
            end
        end
    
        #
        # create a new client for each adapter supported :
        # => postgresql
        # => orientdb
        #
        def client config
            case config["adapter"].to_sym
            when :postgresql
                if (RUBY_PLATFORM === "java")
                    require 'tsdatabase/postgresql/jtspostgresql'
                    clt = JTSPostgresql.new config
                else
                    require 'tsdatabase/postgresql/tspostgresql'
                    clt = TSPostgresql.new config
                end
            when :orientdb
                #        if (RUBY_PLATFORM === "java")
                #          require 'tsdatabase/orientdb/jtsorientdb'
                #          clt = JTSOrientdb.new config
                #        else
                #          require 'tsdatabase/orientdb/tsorientdb'
                #          clt = TSOrientdb.new config
                #        end
                require 'tsdatabase/orientdb/tsorientdbbinary'
                clt = TSOrientdbBinary.new config 
            else
                raise MissingAdapterError, "Adapter #{ config["adapter"] } are not supported"
            end
      
            if (@@mode == TSManager.preloaded)
                clt.connect
            end
      
            clt
        end
    
        private
    
        def qclients config
            qclient = Queue.new 
            if config["pool"].nil?
                qclient.push(client config)
            else
                (1..config["pool"]).each do 
                    qclient.push(client config)
                end
            end
            qclient
        end

        def generate_clients
            unless @dbconfig.nil?
                case
            
                when (@dbconfig.is_a? Hash)
                    @dbconfig.each do |keys, config|
            
                        if (@@database_default.nil?)
                            @@database_default = keys.to_sym
                        end
            
                        if (config["database"].nil?)
                            config["database"] = keys
                        end
                        @clients[keys.to_sym] = qclients config
                    end
            
                when (@dbconfig.is_a? Array)
                    @dbconfig.each do |config |
                        if (@@database_default.nil?)
                            @@database_default = config["database"].to_sym
                        end
                        @clients[config["database"].to_sym] = qclients config
                    end
            
                else
                    raise ConfigurationError, "Wrong datas"
                end
            else
                raise ConfigurationError, "No configuration file setting"
            end
        end
    end
end