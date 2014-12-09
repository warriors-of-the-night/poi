namespace :poi do

  # crawl elementary schools
  task :update_elementary_schools do 
    update_school(::Db::BaseElementarySchool, 'Elementary')
  end

  # crawl middle schools
  task :update_middle_schools do 
    update_school(::Db::BaseMiddleSchool, 'Middle')
  end

  # crawl high schools
  task :update_high_schools do 
    update_school(::Db::BaseHighSchool, 'High')
  end
  
  def call( type )
    eval "::POI::School::#{type}"
  end

  def update_school( base, type )
    # todo: dynamic call
    num_of_page = call(type).get_max_page_num()

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
              urls = call(type).urls_in_page( page_i )
              urls.each do | url |
                queue.push( call(type).get_info( url ))
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
          base.new( queue.pop ).save.using(:master)     
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