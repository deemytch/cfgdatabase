require 'app-config'
require 'app-logger'
require_relative '../lib/app-database'

RSpec.describe App::Database do
  it 'умеет подключаться' do
    App::Config.init approot: Pathname( __dir__ )
    App::Logger.new
    expect{ App::Database.init }.not_to raise_error
    expect( defined?( Db )).to be_truthy
    expect( Db.test_connection ).to be_truthy
  end

  it 'умеет не подключаться' do
    expect{ App::Database.init }.not_to raise_error
    expect( defined?( Db )).to be_truthy
    expect( Db.test_connection ).to be_truthy
  end

  it 'умеет заново подключаться' do
    Kernel.send :remove_const, 'Db'
    expect( defined? Db ).to be_falsy
    expect{ App::Database.init }.not_to raise_error
    expect( defined?( Db )).to be_truthy
    expect( Db.test_connection ).to be_truthy
  end

  it 'умеет отключаться' do
    expect{ App::Database.remove }.not_to raise_error
    expect( defined? Db ).to be_falsy
  end
end
