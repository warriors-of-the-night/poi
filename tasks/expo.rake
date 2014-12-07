namespace :poi do 


  task :crawl_expos do
    # get expo list
    exhibitions = Expo.get_expos()
    processed_work = []
    # fetch each info of each expo
    thread_num = 5
    works = exhibitions

    workers = (0..thread_num).map do 
      # start a new thread
      Thread.new do
        begin 
          while work = works.pop()
            raise "Works finished" if work == nil
            # sleep for 1 second
            sleep( 1.second )
            begin
              if !processed_work.include?(work)
                processed_work << work
                p "update details of:" + work[:name].force_encoding('utf-8')
                info = Expo.get_expo_info(work) 
                BaseGeneralExpo.new( info ).save
              end
            rescue => e
              puts "error loading page:" + work[:page]
            end
          end
        rescue ThreadError
        end
      end 
    end # works.map
    # hold main thread 
    workers.map(&:join); 
  end

  task :crawl_expo_centers do
    # get expo center id list
    center_ids = ExpoCenter.get_expo_center_ids()
    
    # fetch info of each expo center
    thread_num = 5
    works = center_ids
    # Avoid duplicated work
    processed_work = []
    workers = (0..thread_num).map do 
      # start a new thread
      Thread.new do
        begin 
          while work = works.pop()
            raise "Works finished" if work == nil
            # sleep for 1 second
            sleep( 1.second )
            begin
              # Avoid duplicated work
              if !processed_work.include?(work) #&& !BaseGeneralExpoCenter.find_by_id(work.to_i)
                processed_work << work 
                p "update details of center. ID : " + work
                info = ExpoCenter.get_expo_center_info(work) 
                BaseGeneralExpoCenter.new( info ).save
              end
            rescue => e
              puts "Errors encoutered when loading Expo Center : #{work}"
              puts e
            end
          end
        rescue ThreadError
        end
      end 
    end # works.map
    # hold main thread 
    workers.map(&:join); 
  end

end