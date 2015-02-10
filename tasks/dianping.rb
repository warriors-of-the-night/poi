namespace :poi do
#
# === Example
#   rake poi:dianping
#
  desc "download the place of interests of the whole country in dianping.com"
  task :dianping do 
    pipeline = Queue.new
    crawler = POI::Dianping.new
    # Redis to record the interruption
    redis = Redis.new(:host => "127.0.0.1", :port => 6379)
    city_id = redis.get('city_stuck').nil? ? 1 : redis.get('city_stuck').to_i

    # Producer thread
    producer = Thread.new(city_id, pipeline, redis) do
        crawler.producer(city_id, pipeline, redis)
    end
    #Consumer thread
    consumer = Thread.new(pipeline) do
      crawler.consumer(pipeline)
    end
    # Wait for child threads
    producer.join
    consumer.join
  end
end