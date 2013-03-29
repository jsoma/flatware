require 'sinatra'
require 'data_mapper'
require 'open-uri'
require 'fog'

namespace :bundler do
  task :setup do
    require 'rubygems'
    require 'bundler/setup'
  end
end

task :environment, [:env] => 'bundler:setup' do |cmd, args|
  ENV["RACK_ENV"] = args[:env] || "development"
  require './app'
end

namespace :flatware do
  task :process => :environment do
    spreadsheet = Spreadsheet.all.each(&:write_content)
  end
end