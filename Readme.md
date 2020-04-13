# App::Database

Удобная загрузка настроек и настройка базы Sequel.

Настройки базы берутся из переменной `Cfg.db`

Настройщик умеет подождать `Cfg.tmout.database_start` секунд при старте, если база не отзывается. Например всё грузится одновременно и постгрес ещё не успел.

## Готовый кот

    require 'app-config'
    require 'app-logger'
    require 'app-database'

    App::Config.init approot: Pathname( __FILE__ ).dirname # Тут должен быть путь к корню проекта
    App::Logger.new
    App::Database.instance if defined?( Cfg.db )

### Содержимое хэша Cfg.db

Подробности смотрите в документации Sequel https://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-General+connection+options

Образец настроек YAML:

    app:
      id: my-prog # look at it `ps ax|grep my-prog`
      tmout:
        database_start: 60 # in seconds, time to wait the database server to start
    db:
      adapter: postgres
      user: datapultem
      password: my-database-password
      database: my-database-name
      host: 127.0.0.1
      port: 5432
      search_path: public
