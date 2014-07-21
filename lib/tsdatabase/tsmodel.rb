#  Tapastreet ltd 
#  All right reserved 
#
# \author Cyril Bourgès <cyril@tapastreet.com>
#

require "tsdatabase"
#
# TODO 
# - Thinking about dependency destroy like for a user model has_many :user_devices, :dependent => :destroy
#
module TSDatabase
  class InvalidError< TSDatabaseError; end
  
  class TSModel
    @@validates = {}
    @@links = {}
   
    class << self

      def database
        @database ||= TSManager.default
      end
      
      def database= name
        @database = name 
      end
      
      def create record_datas
        obj = self.new record_datas
        obj.save
      end
    end
    
    attr_accessor :datas
    
    def initialize record_datas
      if (record_datas.is_a? Hash)
        self.datas = record_datas
        self.datas.keys.each do |key|
          self.class.send(:define_method, key.to_s) do
            self.datas[key]
          end
        end
      else
        nila
      end
    end
    
    def find(query, *option)
      query_block do |conn|
        conn.find_by_query(query, *option)
      end
    end
    
    def find_by_id(record_id)
      query_block do |conn|
        conn.find_by_id(record_id)
      end
    end
    
    def save 
      error = nil
      @@validates.each do |key, value|
        e = value.call(datas[key])
        unless e.nil?
          # checking whether e is a boolean
          if !!e == e 
            unless e
              if (error.nil?); error={};end
              error[key] = e
            end
          else
            if (error.nil?); error={};end
            error[key] = e
          end  
        end
      end
      if (error.nil?)
        #todo save
        raise NotImplementedError, 'NotImplementedError To Do Save'
      else
        {:error=>error}
      end
    end
    
    def [] key, *args
      unless args.empty?
        if args.include? :expand
          return expand key
        end
      end
      datas[key]
    end
    
    def []= key, value
      unless (datas.key? key)
        self.class.send(:define_method, key.to_s) do
          self.datas[key]
        end
      end
      datas[key] = value
    end
    
    def to_hash option=nil
      if option == :expand
        datas
      elsif option == :pointer
        datas
      else
        datas.to_h
      end
    end
    
    def query_block database=self.database,  &block
      begin
        is_from_thread = true
        conn = Thread.current[:tsclientdb][database]
        if (conn.nil?)
          is_from_thread = false
          conn = TSManager.db.pop(database)
        end
        yield(conn)
      ensure
        unless is_from_thread
          TSManager.db.push(database)
        end
      end
    end
    
    def self.expand key
      info = @@links[key]
      unless info.nil?
        db = info[:database]
        if (db.nil?)
          db = self.database
        end
        query_block db do |conn|
          if (info[:table].nil?)
            @@links[key][:expand] = conn.find_by_id(datas[key])
          else
            @@links[key][:expand] = conn.find_by_id(datas[key], info[:table])
          end
        end
      else
        datas[key]
      end
    end
    
    def self.has_link key, from, option ={}
      
      if from.is_a? String
        rfrom = {:table => from, :database=>self.database }
      elsif from.is_a? Hash
        rfrom = {}
        
        if (from[:table])
          rfrom[:table] = from[:table]
        else
          raise InvalidError, "Wrong, we need :table => \"myTable\" and you give #{from.inspect}"
        end
        
        if (from[:database])
          rfrom[:database] = from[:database]
        else
          rfrom[:database] = self.database
        end
      else
        raise InvalidError, "It's not a String or Hash"
      end
      
      @@links[key] = option.merge rfrom
    end
    
    def self.validates key, &block
      @@validates[key] = block
    end
  end
end
