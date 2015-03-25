# DEPENDENCIES
require "bundler/gem_tasks"
require './lib/poi'
require 'thread'
require 'redis'
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
			POI::LandMark.work(ENV['cp'], ENV['ak']='uPpVFGTNR9ke9GHxswi4OeHg')
		end 
end

