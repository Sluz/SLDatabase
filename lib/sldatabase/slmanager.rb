
require 'singleton'
require 'thread'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
# Ruby:
# :postgresql => gem 'pg', platform: :ruby
# :orientdb   => gem 'jorientdb', platform: :ruby
# 
# JRuby:
# :postgresql => gem 'jruby_pg', platform: :jruby  
# :orientdb   => gem 'jorientdb', platform: :jruby
#
module SLDatabase
    class SLManager
        include Singleton
    
        attr_accessor :clients
        attr_accessor :configuration
        
        class << self
            attr_accessor :mode
            attr_accessor :database_default
            
            # => :DEFAULT : disconnect client on push 
            def mode_default; 0; end
            # => :PRELOADED : don't disconnect client on push and connect on initialisation \see :config_json or :config_yml
            def mode_preloaded; 100; end
            # => :KEEP_LOADED : don't disconnect client on push    
            def mode_keep_loaded; 200; end
      
            alias_method :db, :instance
        end
    
        def initialize
            self.class.mode = self.class.mode_default if self.class.mode.nil?
            self.clients = {}
        end
    
        def pop_connection(database = self.class.database_default)
            connections = Thread.current[:tsclientdb]
            if connections.nil?
                Thread.current[:tsclientdb] = {}
            end
            clt = Thread.current[:tsclientdb][database] ||= clients[database].pop
            clt.connect
            clt
        end
    
        alias_method :get,  :pop_connection
        alias_method :pop,  :pop_connection
        alias_method :open, :pop_connection

        def push_connection(database = self.class.database_default)
            connections = Thread.current[:tsclientdb][database]
            unless connections.nil?
                Thread.current[:tsclientdb].delete(database)
                if self.class.mode == self.class.mode_default
                    connections.disconnect
                end
                clients[database].push connections
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
                    if self.class.mode == self.class.mode_default
                        value.disconnect
                    end
                    clients[key].push value
                end
                Thread.current[:tsclientdb] = nil
            end
        end
    
        alias_method :close_all, :all_close

        #\brief before to use you need to have in your Gems yaml 
        def config_yml(filename, mode = :production)
            if configuration.nil?
                require 'yaml'
                if filename.is_a? String
                    json_hash = YAML::load(File.open(filename))
                elsif filename.is_a? File
                    json_hash = YAML::load(filename)
                else
                    raise ConfigurationError.new :file
                end
                config_hash json_hash, mode
            else
                raise ConfigurationError, "Multiple configuration"
            end
        end
    
        #\brief before to use you need to have in your Gems multi_json
        def config_json(filename, mode = :production)
            if configuration.nil?
                require 'multi_json'
                if filename.is_a? String
                    json_hash = MultiJson.load(File.open(filename), :symbolize_keys => true)
                elsif filename.is_a? File
                    json_hash = MultiJson.load(filename)
                else
                    raise ConfigurationError.new :file
                end
                config_hash json_hash, mode
            else
                raise ConfigurationError.new :multiple
            end
        end
        
        def config_hash(json_hash, mode= :production)
            self.configuration = json_hash[mode]
            generate_clients
        end
    
        #
        # create a new client for each adapter supported :
        # => postgresql
        # => orientdb
        #
        def client config
            case config[:adapter].to_sym
            when :postgresql
                if (RUBY_PLATFORM === "java")
                    require 'sldatabase/postgresql/jtspostgresql'
                    clt = JSLPostgresql.new config
                else
                    require 'sldatabase/postgresql/slpostgresql'
                    clt = SLPostgresql.new config
                end
            when :orientdb
#                if (RUBY_PLATFORM === "java")
#                  require 'sldatabase/orientdb/jtsorientdb'
#                  clt = JSLOrientdb.new config
#                else
#                  require 'sldatabase/orientdb/slorientdb'
#                  clt = SLOrientdb.new config
#                end
#                require 'sldatabase/orientdb/slorientdbbinary'
#                clt = SLOrientdbBinary.new config 

                require 'sldatabase/orientdb/slorientdb'
                clt = SLOrientdb.new config 
            else
                raise MissingAdapterError, "Adapter #{ config[:adapter] } are not supported"
            end
      
            if (self.class.mode == self.class.mode_preloaded)
                clt.connect
            end
      
            clt
        end
    
        private
    
        def qclients config
            qclient = Queue.new 
            if config[:pool].nil?
                qclient.push(client config)
            else
                (1..config[:pool]).each do 
                    qclient.push(client config)
                end
            end
            qclient
        end

        def generate_clients
            unless configuration.nil?
                if (configuration.is_a? Hash)
                    configuration.each do |keys, config|
            
                        if (self.class.database_default.nil?)
                            self.class.database_default = keys.to_sym
                        end
            
                        if (config[:database].nil?)
                            config[:database] = keys
                        end
                        clients[keys.to_sym] = qclients config
                    end
            
                elsif (configuration.is_a? Array)
                    configuration.each do |config |
                        if (self.class.database_default.nil?)
                            self.class.database_default = config[:database].to_sym
                        end
                        clients[ config[:database].to_sym ] = qclients config
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