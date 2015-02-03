namespace :poi do
#
# === Example
#   rake poi:hospital
#
  desc "download the hospitals of the whole country "
  task :hospital do 
    
    pipeline = Queue.new
    hospital = POI::Hospital.new

    # Redis to record the interruption
    redis = Redis.new(:host => "127.0.0.1", :port => 6379)
    city_id = redis.get('hospital_stuck').nil? ? 0 : redis.get('hospital_stuck').to_i

    # producer thread
    producer = Thread.new(city_id, pipeline,redis) do
      hospital.producer(city_id, pipeline, redis)
    end

    #Consumer thread
    consumer = Thread.new(pipeline) do
      hospital.consumer(pipeline)
    end

    # Wait for child threads
    producer.join
    consumer.join
  end
end