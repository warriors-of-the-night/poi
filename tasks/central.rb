require 'redis'
namespace :poi do
  desc "download the place of interests of the whole country in dianping.com"
  task :dianping_pois,[:type_en] do |t, args| 
    mapping = {'center' => '商区', 'metro' => '地铁沿线', 
                'landmark' => '地标', 'other' =>'其他' }
    poi = mapping[args[:type_en]]
    selector = "//h2[text()="+"'#{poi}']/.."
    pipeline = Queue.new
    city_num  = POI::Dianping.cities.size
   # Redis to record the interruption
    redis = Redis.new(:host => "127.0.1.1", :port => 6379)
    counter = redis.get('city_stuck').to_i
    # start a new thread
    producer = Thread.new do
        until counter > city_num do
          # Sleep for 2 second
          sleep(2)
          limiter = 0 
          begin 
            business_center = POI::Dianping.centers(counter, args[:type_en], selector)
            business_center.each do |center|
              pipeline.push(center)
            end 
            puts "Processing city_id: #{counter} finished!"

          # Exception handler
          rescue =>e
            limiter+=1
            retry if limiter<3
            p e 
            puts "Error encountered when processing city_id: #{counter}" 
            case e
              when ArgumentError
                city_num+=1
              when Errno
                next
              when OpenURI::HTTPError
                redis.set('city_stuck', counter)
                exit  
              else
                exit
            end
          end
          counter+=1
        end
      redis.set('city_stuck', 1)
      exit
    end 

    #consumer thread
    consumer = Thread.new do
      # wait for producer
      sleep(2)
      while true
        begin
          item = pipeline.pop
          existed_item = Db::Dianping_poi.find_by(center_id: item[:center_id])
          existed_item.nil? ? Db::Dianping_poi.new(item).save : existed_item.update(item)
          # adaptive wrting rate
          sleep(1.0/(pipeline.length+1))
        rescue => e
          p e
          # TODO: add error handling
        end
      end
    end

    # Wait for child threads
    producer.join
    consumer.join
  end
end