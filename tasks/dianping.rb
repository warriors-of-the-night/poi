namespace :poi do
#
# === Example
#   rake poi:dianping
#
  desc "download the place of interests of the whole country in dianping.com"
  task :dianping do 
    timer = Time.now 
    pipeline = Queue.new
    city_num  = POI::Dianping.cities.size

    # Redis to record the interruption
    redis = Redis.new(:host => "127.0.0.1", :port => 6379)
    city_id = redis.get('city_stuck').nil? ? 1 : redis.get('city_stuck').to_i

   # log msg
    def log(msg)
      log_file = File.open("dianping.log", "a+")
      log_file.syswrite(msg)
      log_file.close
    end

    # Start a new thread
    producer = Thread.new do
        until city_id > city_num do
          # Sleep for 2 second
          sleep(2)
          limiter = 0
          begin
            pois = POI::Dianping.pois(city_id)
            pois.each do |poi|
              pipeline.push(poi)
            end
            puts "Processing city_id: #{city_id} finished!"

          # Exception handler
          rescue =>e
            limiter+=1
            retry if limiter<3
            p e
            warn "\e[31mError encountered when processing city_id: #{city_id}\e[0m"
            case e
              when ArgumentError
                msg = %Q(#{Time.now} http://www.dianping.com/shopall/#{city_id}/0" #{e} \n)
                log(msg)
                city_num+=1
              when Errno
                next
              when OpenURI::HTTPError
                redis.set('city_stuck', city_id)
                msg = %Q(#{Time.now}  #{e} finished: #{city_id} , unfinished: #{ city_num-city_id }, Timeleft: #{(Time.now-timer)*city_id/city_num}\n)
                log(msg)
                exit
              else
                exit
            end
          end
          city_id+=1
        end
      redis.set('city_stuck', 1)
      abort "\e[32m Works finished!\e[0m"
    end

    #Consumer thread
    consumer = Thread.new do
      # Wait for producer
      sleep(2)
      while true
        begin
          item = pipeline.pop
          existed_item = Db::DianpingPoi.find_by(center_id: item[:center_id], city_id: item[:city_id], name: item[:name])
          existed_item.nil? ? Db::DianpingPoi.new(item).save : existed_item.update(item)
          # adaptive wrting rate
          sleep(1.0/(pipeline.length+1))
        rescue => e
          p e
         log(%Q(#{Time.now}  #{e}\n))
        end
      end
    end

    # Wait for child threads
    producer.join
    consumer.join
  end
end