# -*- coding:utf-8 -*-
require 'active_record'
require 'yaml'
require './lib/poi'


namespace :poi do
  config = YAML::load( File.open('db_config.yaml') )
  ActiveRecord::Base.establish_connection( config )

  # Tables 
  class ElementarySchool < ActiveRecord::Base
  end
  class MiddleSchool < ActiveRecord::Base
  end
  class HighSchol < ActiveRecord::Base
  end
  class Venue < ActiveRecord::Base
  end

  # crawl elementary schools
  task :crawl_elementary_schools do 
    num_of_page = ::Schools::Elementary.get_max_page_num()

    thread_num = 5
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
            sleep( 0.1.second )

            begin # parse schools in one page and store into database
              urls = ::Schools::Elementary.urls_in_page( page_i )
              urls.each do | url |
                school = ::Schools::Elementary.get_info()
                ElementarySchool.new(school).save
              end 
            rescue => e
              puts "error encountered when processing page:" + page_i.to_s
            end
          end
        rescue ThreadError
        end
      end 
    end # works.map
    # hold main thread 
    workers.map(&:join); 
  end

  # crawl middle schools
  task :crawl_middle_schools do 
    num_of_page = ::School::Middle.get_max_page_num()

    thread_num = 5
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
            sleep( 0.1.second )

            begin # parse schools in one page and store into database
              urls = ::School::Middle.urls_in_page( page_i )
              urls.each do | url |
                school = ::School::Middle.get_info()
                MiddleSchool.new(school).save
              end 
            rescue => e
              puts "error encountered when processing page:" + page_i.to_s
            end
          end
        rescue ThreadError
        end
      end 
    end # works.map
    # hold main thread 
    workers.map(&:join); 
  end

  # crawl high schools
  task :crawl_high_schools do 
    num_of_page = ::School::High.get_max_page_num()

    thread_num = 5
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
            sleep( 0.1.second )

            begin # parse schools in one page and store into database
              urls = ::School::High.urls_in_page( page_i )
              urls.each do | url |
                school = ::School::High.get_info()
                HighSchool.new(school).save
              end 
            rescue => e
              puts "error encountered when processing page:" + page_i.to_s
            end
          end
        rescue ThreadError
        end
      end 
    end # works.map
    # hold main thread 
    workers.map(&:join); 
  end

  # crawl middle schools
  task :crawl_venues do 

  end

end