# DEPENDENCIES
require "bundler/gem_tasks"
require 'poi'
require 'thread'
require 'redis'
require 'time'
# shading

# TASKS
require './tasks/school'
require './tasks/expo'
require './tasks/venue'
require './tasks/baidumap'
require './tasks/hospital'
require './tasks/encyclopedia'
namespace :poi do
  desc " Fetch landmarks data from web,For example: rake poi:landmark cp=meituan"
		task :landmark do 
      Dir.mkdir 'log' unless Dir.exists? 'log'
      worker = POI::LandMark::Worker.new(ENV['cp'])
      worker.work
		end 
end

