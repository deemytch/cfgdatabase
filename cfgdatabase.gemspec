Gem::Specification.new do |lib|
  lib.name          = 'cfgdatabase'
  lib.version       = '1.0.10'
  lib.date          = '2020-02-18'
  lib.summary       = 'Удобная загрузка настроек Sequel.'
  lib.files         = Dir[ 'lib/*.rb' ]
  lib.require_paths = %w[ lib ]
  lib.author        = 'deemytch'
  lib.email         = 'aspamkiller@yandex.ru'
  lib.license       = 'GPL-2.0'
  lib.homepage      = 'https://gitlab.sudo.su/amqp-lib/cfgdatabase'
  lib.add_runtime_dependency 'sequel'
  lib.add_runtime_dependency 'monkey-hash'
  lib.add_runtime_dependency 'cfgstore'
end
