namespace :poi do
  desc "update venues' info"
  task :update_venues do 
   # todo: dynamic call
    num_of_page = ::POI::Venue.max_page_num

    thread_num = 10
    queue = Queue.new
    works = num_of_page

    workers = (0..thread_num).map do 
      # start a new thread
      Thread.new do
        begin 
          while true
            # each thread deal with one page
            page_i = works
            works -= 1 
            raise "Works finished" if works < 0
            # sleep for 0.1 second
            sleep( 0.1 )

            begin # parse schools in one page and store into database
              venues = Venue.venues_in_page( page_i )
              venues.each do | venue |
                queue.push( Venue.get_info( venue ) )
              end 
            rescue => e
              puts "error encountered when processing page:" + page_i.to_s
            end
          end
        rescue ThreadError
        end
      end 
    end # works.map

    # writer thread
    writer = Thread.new do
      # wait for workers
      sleep( thread_num*0.2 + 3 )
      while true
        begin
          # shading use :master to write
          ::Db::BaseGeneralVenue.new( queue.pop ).save.using(:master)
          # adaptive wrting rate
          sleep( 1.0/(queue.length+1) )
        rescue => e
          # todo: add error handling
        end
      end
    end

    # hold main thread 
    workers.map(&:join); 
    writer.join
  end
  
end