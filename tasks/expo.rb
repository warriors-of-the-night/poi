namespace :poi do 
  task :update_expos do
    # get expo list
    queue = Queue.new
    expos = POI::Expo.get_expos()

    # fetch each info of each expo
    thread_num = 5
    workers = (0..thread_num).map do 
      # start a new thread
      Thread.new do
        begin 
          while expo = expos.pop()
            raise "Works finished" if expo == nil
            # sleep for 1 second
            sleep( 0.1 )
            begin
                queue.push( POI::Expo.get_info(expo) ) 
            rescue => e
              puts "error loading page:" + work[:page]
            end
          end
        rescue ThreadError
        end
      end 
    end # works.map

    # single thread writing
    writer = Thread.new do
      # sleep for 1s
      sleep( 1 )
      begin
        while queue.length > 0
                    p queue.length 

          begin
            ::Db::BaseGeneralExpo.using(:master).new( queue.pop ).save
          rescue => e
            p "error writting data" + e.to_s
          end
          sleep( 1/(queue.length+1) )
        end
      rescue => e
      end
    end
    # hold main thread 
    workers.map(&:join); 
    writer.join
  end

  task :update_expo_centers do
    # get expo center id list
    center_ids = POI::ExpoCenter.get_center_ids()
    queue = Queue.new

    # fetch info of each expo center
    thread_num = 5
    workers = (0..thread_num).map do 
      # start a new thread
      Thread.new do
        begin 
          while center_id = center_ids.pop()
            raise "Works finished" if center_id == nil
            # sleep for 0.1s
            sleep( 0.1 )
            begin
              queue.push( POI::ExpoCenter.get_info( work ))
            rescue => e
              puts "Errors encoutered when loading Expo Center : #{center_id}"
              puts e
            end
          end
        rescue ThreadError
        end
      end 
    end # works.map

    # single thread writing
    writer = Thread.new do
      # sleep for 1s
      sleep( 1 )
      begin
        while queue.length > 0
          p queue.length 
          begin
            ::Db::BaseGeneralExpoCenter.using(:master).new( queue.pop ).save
          rescue => e
            p "error writting data" + e.to_s
          end
          sleep( 1/(queue.length+1) )
        end
      rescue => e
      end
    end
    # hold main thread 
    workers.map(&:join); 
  end

end