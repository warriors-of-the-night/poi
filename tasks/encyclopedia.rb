namespace :poi do
#
# === Example
#   rake poi:encyclopedia
#
  desc "download the encyclopedia of the landmarks "
  task :encyclopedia do 
      encyclopedia = POI::Encyclopedia.new
      encyclopedia.process
  end
end