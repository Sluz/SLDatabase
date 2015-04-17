
require 'singleton'

#
# \author Cyril Bourgès <cyril@tapastreet.com>
#
module SLDatabase
  class SLManager
    include Singleton
    
    attr_accessor :configured
    attr_accessor :databases
    attr_accessor :database_default
  
    def initialize
      self.databases = {}
      self.configured = false
    end
    
    def pop_connection(database = database_default)
      pool = self.databases[database]
      raise SLDatabaseError.new(:unknow) if pool.nil?
      pool.acquire
    end
        
    def push_connection(database = database_default)
      pool = self.databases[database]
      raise SLDatabaseError.new(:unknow) if pool.nil?
      pool.close
    end
    
    # \brief close (push) all connection get(pop)
    def all_close
      self.databases.each do |_, pool|
        pool.close
      end
    end
    alias_method :close_all, :all_close

    def load_configuration filename_or_hash, mode = :production
      #--- Generate hash of server option
      if filename_or_hash.is_a? Hash
        config_hash filename_or_hash, mode
      else
        if filename_or_hash.is_a? String 
          extname = File.extname(filename_or_hash) 
        elsif filename_or_hash.is_a? File 
          extname = File.extname(filename_or_hash.path) 
        end
            
        unless extname.nil?
          if extname === ".json"
            config_json filename_or_hash, mode
          elsif extname === ".yml"
            config_yml filename_or_hash, mode
          else
            raise ConfigurationError.new :format
          end
        else
          raise ConfigurationError.new :file
        end
      end
    end
    
    #
    # Create a new PoolManager for each adapter supported :
    # => postgresql
    # => orientdb
    #
    def create_pool config
      case config[:adapter].to_sym
      when :postgresql
        require 'sldatabase/postgresql/slpostgresqlpool'
        clt = SLPostgresqlPool.new config
      when :orientdb
        require 'sldatabase/orientdb/slorientdbpool'
        clt = SLOrientdblPool.new config 
      else
        raise MissingAdapterError, "Adapter #{ config[:adapter] } are not supported"
      end
    end
    
    private

    #\brief before to use you need to have in your Gems yaml 
    def config_yml filename, mode
      require 'yaml'
      if filename.is_a? String
        json_hash = YAML::load(File.open(filename))
      elsif filename.is_a? File
        json_hash = YAML::load(filename)
      else
        raise ConfigurationError.new :file
      end
      config_hash json_hash, mode
    end
    
    #\brief before to use you need to have in your Gems multi_json
    def config_json filename, mode
      require 'multi_json'
      if filename.is_a? String
        json_hash = MultiJson.load(File.open(filename), :symbolize_keys => true)
      elsif filename.is_a? File
        json_hash = MultiJson.load(filename)
      else
        raise ConfigurationError.new :file
      end
      config_hash json_hash, mode
    end
        
    def config_hash json_hash, mode
      raise ConfigurationError.new :multiple if configured
      mode ||= :production
      generate_pools json_hash[mode]
      self.configured = true
    end

    def generate_pools configuration
      unless configuration.nil?
        if (configuration.is_a? Hash)
          configuration.each do |keys, config|
            self.database_default ||= keys.to_sym 
            config[:database] ||= keys
            
            databases[keys.to_sym] = create_pool config
          end
        elsif (configuration.is_a? Array)
          configuration.each do |config |
            self.database_default ||= config[:database].to_sym
          
            databases[ config[:database].to_sym ] = create_pool config
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