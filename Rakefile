# DEPENDENCIES
require "bundler/gem_tasks"
require './lib/poi'
require 'db'
require 'thread'
require 'baidumap'
require 'redis'
# shading

# TASKS
require './tasks/school'
require './tasks/expo'
require './tasks/venue'
require './tasks/baidumap'
require './tasks/dianping'
require './tasks/hospital'
require './tasks/encyclopedia'
namespace :poi do
	desc " crawl landmarks data from website"
		task :landmark do 
			POI::LandMark.work(ENV[:cp])
		end
end

