require 'redis'
namespace :poi do
# Arguments: type_en[center, metro, landmark, other]
#
# === Example
#
#   rake poi:dianping_pois['center']
#
  desc "download the place of interests of the whole country in dianping.com"
  task :dianping_pois,[:type_en] do |t, args|
    timer = Time.now
    # The mapping hash
    mapping = { 'center' => '商区', 'metro' => '地铁沿线',
                'landmark' => '地标', 'other' =>'分类' }
    poi = mapping[args[:type_en]]
    selector = "//h2[text()="+"'#{poi}']/.."
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
            business_center = POI::Dianping.centers(city_id, args[:type_en], selector)
            business_center.each do |center|
              pipeline.push(center)
            end
            puts "Processing city_id: #{city_id} finished!"

          # Exception handler
          rescue =>e
            limiter+=1
            retry if limiter<3
            p e
            puts "\e[31mError encountered when processing city_id: #{city_id}\e[0m"
            case e
              when ArgumentError
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
          existed_item = Db::Dianping_poi.find_by(center_id: item[:center_id], city_id: item[:city_id])
          existed_item.nil? ? Db::Dianping_poi.new(item).save : existed_item.update(item)
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