Gem::Specification.new do |lib|
  lib.name          = 'cfgdatabase'
  lib.version       = '1.2.4'
  lib.date          = '2021-02-10'
  lib.summary       = 'Удобная загрузка настроек Sequel.'
  lib.files         = Dir[ 'lib/*.rb' ]
  lib.require_paths = %w[ lib ]
  lib.author        = 'deemytch'
  lib.email         = 'aspamkiller@yandex.ru'
  lib.license       = 'GPL-2.0'
  lib.homepage      = 'https://github.com/deemytch/cfgdatabase'
  lib.add_runtime_dependency 'sequel'
  lib.add_runtime_dependency 'monkey-hash'
  lib.add_runtime_dependency 'cfgstore'
  lib.add_runtime_dependency 'pg'
end
