require 'openssl'
require 'sequel'

module TestHelper
  def truncate_tables(lsd=nil) # [(:except | :only ) = (tables list)]
    all_tables = Db.tables
    return if all_tables.empty?
    tbl = (if lsd.class == Hash
              if lsd.key?(:except) then all_tables - lsd[:except];
              elsif lsd.key?(:only) then all_tables = lsd[:only]; end
            else
              all_tables
            end) - [:schema_migrations]
    # Log.debug{ "Стираю содержимое таблиц #{ tbl.inspect }"}
    tbl.each{|t| Db[t].truncate(cascade: true) }
    # Log.debug{ "После стирания: #{ tbl.collect{|t| { t => Db[t].count } }.inspect }"}
  end

  def gen_rsa_keys
    privkey = OpenSSL::PKey::RSA.generate 4096
    pubkey  = privkey.public_key
    [ privkey.to_s, pubkey.to_s ]
  end

  def app_init
    require 'app-config';
    require 'app-logger';
    require 'app-database';

    App::Config.init approot: Pathname( __FILE__ ).dirname.parent;
    App::Logger.new;
    App::Database.instance if defined?( Cfg.db );
  end

  module_function :truncate_tables, :gen_rsa_keys, :app_init
end
