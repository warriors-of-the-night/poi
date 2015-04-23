namespace :poi do
#
# === Example
#   rake poi:encyclopedia
#
  desc "download the encyclopedia of the landmarks "
  task :encyclopedia do 
    Dir.mkdir 'log' unless Dir.exists? 'log'
    encyclopedia = POI::Encyclopedia.new
    encyclopedia.work
  end
end
