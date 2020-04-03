require 'sequel'
require 'singleton'
require 'app-config'
require 'app-logger'

##
# Основной смысл надстройки -- красиво начать.
# Остальное Sequel и сам умеет.
# Модуль создаёт глобальную переменную Db
# Предполагается использование глобальной Cfg для настроек

module App
  class Database
    include Singleton
    attr_reader :db

    ##
    # Ищем секцию настроек Cfg.db
    def initialize
      raise ArgumentError.new("Cfg not found!") if ! defined?( ::Cfg ) || ! Cfg.db || Cfg.db.empty?
      if (! defined? @db ) || ( @db.nil? ) || ( ! @db ) || ( ! @db.test_connection )
        Log.info{ "БД #{ Cfg.db.database }." }
        Sequel.extension :pg_array, :pg_inet, :pg_json, :pg_json_ops, :pg_array, :pg_array_ops, :pg_row, :pg_hstore, :pg_json_ops
        Sequel::Model.raise_on_save_failure = false
        Sequel::Model.plugin :validation_helpers
        Sequel::Database.extension :pg_inet, :pg_json, :pg_array, :pg_range, :pg_row, :pg_enum
        counter = Cfg.app.tmout.database_start
        begin
          @db = Sequel.connect Cfg.db.to_hash
        rescue Sequel::DatabaseConnectionError => e
          Log.error{"Шо-то с базой: #{ ( e.message.dup ).force_encoding('UTF-8') }"}
          ( counter -= 1 ) > 0 ? ( sleep(1); retry ) : raise
        end
        Sequel::Model.db = @db
        @db.tables.each{ |t| @db.reset_primary_key_sequence t } # Настоящие герои всегда идут в обход
        @db.freeze if Cfg.env == :production
        Kernel.const_set 'Db', @db
      end
      return @db
    end

  end
end
