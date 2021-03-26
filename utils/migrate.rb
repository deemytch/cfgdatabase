#!/usr/bin/env ruby
# encoding: utf-8

require 'bundler/setup'
require 'fileutils'
require 'pathname'
require 'bunny'
require 'logger'
require 'yaml'
require 'optparse'
require 'thor'
require 'monkey-hash'
require 'app-config'
require 'app-logger'
require 'sequel'
require 'pg'
require 'app-database'

App::Config.init( approot: Pathname.new( Dir.pwd ).expand_path )
App::Logger.new
App::Database.init if Cfg.db?
Sequel.extension :migration

# тупой способ определения запуска в корне проекта
launchdir = Dir.pwd
if launchdir != Cfg.root || ! File.exist?( "#{ Cfg.root }/Gemfile" )
  puts "\n\tВнимание! Следует запускать migrate.rb в корне проекта.\n\n"
  raise "\n\tВнимание! Следует запускать migrate.rb в корне проекта.\n\n"
end

class Dbtask < Thor
  package_name 'db'
  desc 'init', 'Создать папки и записать нулевую миграцию'
  def init
    mydir       = Pathname( __dir__ ).expand_path.to_s
    migrations  = Pathname( "#{ Cfg.root }/db/migrations" ).expand_path.to_s
    Log.info{"Создаю папку #{ migrations }"}
    FileUtils.mkdir_p migrations
    list = Dir[ "#{ mydir }/migrations/*rb" ]
    Log.info{"Копирую файл#{ list.count == 1 ? '' : 'ы' } с миграциями:\n#{ list.join("\n") }"}
    FileUtils.cp list, "#{ migrations }/"
  end

  desc "g class_name", "Создать файл миграции в db/migrations"
  def g(class_name)
    tstamp = Time.now.strftime "%Y%m%d%H%M%S"
    fname = ''
    if Dir[ "#{ Cfg.root }/db/migrations/#{ tstamp }_*.rb" ].any?
      counter = 0
      while Dir[ "#{ Cfg.root }/db/migrations/#{ tstamp }#{ '%02d' % counter }_*.rb" ].any? do
        counter += 1
      end
      fname = "#{ Cfg.root }/db/migrations/#{ tstamp }_#{ '%02d' % counter }_#{ class_name }.rb"
    else
      fname = "#{ Cfg.root }/db/migrations/#{ tstamp }_#{ class_name }.rb"
    end
    Log.info{ "Создаю файлик миграции #{ fname }" }
    File.open( fname, 'w' ) do |f|
      f.write <<~EFILE
      Sequel.migration do
        up do
          create_table :#{ class_name } do
            primary_key :id, type: :Bignum

            column :created_at, DateTime, null: false, index: true, default: Sequel.lit("now()")
            column :updated_at, DateTime, null: false, index: true, default: Sequel.lit("now()")
          end
          run <<~EUP
            DO $$
            BEGIN
              --triggers
              IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = '#{ class_name }_update_timestamp') THEN
                CREATE TRIGGER #{ class_name }_update_timestamp
                  BEFORE INSERT OR UPDATE ON #{ class_name }
                  FOR EACH ROW EXECUTE PROCEDURE update_timestamp();
              END IF;
            END $$;
          EUP
        end
        down { run 'DROP TABLE #{ class_name } CASCADE' }
      end
      EFILE
    end
  end

  desc "m", "Мигрировать миграции, можно добавить имя файла"
  def m(point = nil)
    point = point_from_filename(point) || nil
    Log.warn{ "Мигрирую базу #{ point }" }
    if point
      Sequel::Migrator.run(Db, "db/migrations", target: point )
    else
      Sequel::Migrator.run(Db, "db/migrations" )
    end
    v
  end

  desc "r", "Откатить базу в ноль, либо к указанному файлу"
  def r(point = '0')
    point = point_from_filename(point) || 0
    Log.warn{ "Откатываю базу #{ point }" }
    if point
      Sequel::Migrator.run(Db, "db/migrations", :target => point )
    else
      Sequel::Migrator.run(Db, "db/migrations" )
    end
    v
  end

  desc "v" , "Напечатать текущую версию в базе"
  def v
    version =
    if Db.tables.include?(:schema_migrations)
      (f = Db[:schema_migrations].all).any? ? f.last[:filename] : 'пусто'
    else
      'пусто'
    end
    puts "Последняя миграция: #{ version }"
  end

  desc "create", "Создать базу"
  def create
    rootdb = superdb
    Log.warn{ "Создаю пользователя: #{ Cfg.db.user } и базу: #{ Cfg.db.database }." }
    begin
      rootdb["CREATE USER #{ Cfg.db.user  } WITH LOGIN PASSWORD '#{ Cfg.db.password }'"].all
    rescue Exception => e
      Log.info{ e.message }
    end
    begin
      rootdb["CREATE DATABASE #{ Cfg.db.database } OWNER #{ Cfg.db.user  }"].all
    rescue Exception => e
      Log.info{ e.message }
    end
  end

  desc "scratch", 'Удалить базу, загрузить все миграции заново'
  def scratch(db = nil)
    db = superdb
    Log.debug{"Отключение от текущей базы"}
    Db.disconnect
    unless db.test_connection
      Log.warn{"Не смог подключиться к базе для махинаций. #{ superuser.inspect }"}
      exit 255
    end
    Log.warn{ "Удаляю базу #{ Cfg.db.database }" }
    begin
      db << "DROP DATABASE #{ Cfg.db.database }"
    rescue Exception => e
      Log.error e.message
    end
    create
    m
  end

  no_commands do
    # подключается к базе с правами админа
    # жёстко закодировано, что админ базы 'postgres' без пароля, и схема 'public'
    def superdb
      if ! @rootdb || ! @rootdb.test_connection
        superuser = Marshal.load(Marshal.dump( Cfg.db ))
        superuser[:adapter]  = 'postgres'
        superuser[:user]     = 'postgres'
        superuser[:database] = 'postgres'
        superuser.delete :password
        Log.debug{"Попытка административного подключения #{ superuser.inspect }"}
        @rootdb = Sequel.connect( superuser )
      end
      @rootdb
    end

    def point_from_filename(n)
      Log.debug{"Поиск миграции по куску имени: '#{ n }'."}
      return nil unless n
      unless n =~ /^\d+/
        Pathname.new( Dir["#{ Cfg.root }/db/migrations/*#{ n }*.rb"].sort.last ).basename.to_s[/(\d+)/, 1].to_i
      else
        n[/^(\d+)/, 1].to_i
      end
    end

  end

end

Dbtask.start
