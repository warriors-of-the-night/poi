namespace :poi do
  
  @Thread_num = 5
  
  task :zhuna do
    
    cityQueue = Queue.new
    attractionQueue = Queue.new
    
    app = POI::Zhuna.new
    
    citys = app.city_in_homepage()
    citys.each do |city|
      cityQueue.push(city)
    end
    (1..@Thread_num).each do
      thread = Thread.new {
        until cityQueue.empty?
          city = cityQueue.pop
          begin
            attractions = app.attraction_in_city(city)
            attractions.each do |attraction|
              attractionQueue.push(attraction)
            end
          rescue =>e
            puts e
          end
        end
      }
      thread.run
    end
    

    while true
      if attractionQueue.empty?
        if Thread.list.size == 1
          break
        end
      else
        attraction = attractionQueue.pop
        
      end
    end
 
  end
end
