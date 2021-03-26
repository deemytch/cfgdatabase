Gem::Specification.new do |lib|
  lib.name          = 'cfgdatabase'
  lib.version       = '1.2.5'
  lib.date          = '2021-03-26'
  lib.summary       = 'Удобная загрузка настроек Sequel и миграции для PostgreSQL.'
  lib.files         = Dir[ 'lib/*.rb', 'utils/migrations/*' ]
  lib.require_paths = %w[ lib ]
  lib.author        = 'deemytch'
  lib.email         = 'aspamkiller@yandex.ru'
  lib.license       = 'GPL-2.0'
  lib.homepage      = 'https://github.com/deemytch/cfgdatabase'
  lib.bindir        = 'utils'
  lib.executables   = %w[ migrate.rb ]

  lib.add_runtime_dependency 'sequel'
  lib.add_runtime_dependency 'monkey-hash'
  lib.add_runtime_dependency 'cfgstore'
  lib.add_runtime_dependency 'pg'
end
