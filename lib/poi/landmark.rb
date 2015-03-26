require 'httparty'
require_relative 'landmark/meituan'
require_relative 'landmark/baidu_waimai'
require_relative 'landmark/dianping'
module Db
  class BasePoiLandmark < ActiveRecord::Base

  end
  class BaseElongHotelCity < ActiveRecord::Base

  end
end
module POI
  module LandMark
    class Worker
      Keys = %w(nML7mZ3xMUkAPjz3KAWQCq3j B76dd0064529522a1a9bedadbfaf48f6 57e45E513cb63ccc69895779634be327  
                aQx1gGYrQGqIrUAozPHlUDAC ZfGRFj1029I1lkZrTSPFbCIW  E3m8XYAayQY0Z0Rm32zaNZmq SWnBEi8yt4klHKPHFzi5Xuvm  
                A5KusGlYIoejSBgLpgIO4ypH GG4XEskQdLZTT4ADvOjYcDmV PH5XOjTkT20Yx7YNtjczLyE3 ITRp7wngpB1aulNFgoryaRGG
                uZIOFIRWBLptE04mHwNrMcAj N4BeVM6t7LTjjbDXHbDMMZkx Tlyg0gekTuqpUH6bMPLcsth9 2Rei7o9gbdqRLSGXeMHj5DNX
                L7oWwVgcqzz9ZTGsfwlftI0o)

      def initialize(web_site)
        @index    = 0
        @geocoder = Baidumap::Request::Geocoder.new(Keys[@index])
        @cp       = {
          :meituan      => MeiTuan,
          :baidu_waimai => BaiduWaimai,
          :dianping     => DianPing,
        } 
        @crawler  = @cp[web_site.to_sym].new
      end 

      def producer
        Thread.new {
          city_list = @crawler.city_list
          city_list.each do |city|
            elong_city = Db::BaseElongHotelCity.find_by(NameShort: city[:city_cn])
            @crawler.landmarks(city).each do |name, city_info|
              begin
                geo_coordinate = @geocoder.encode(name, city_info[:city_cn]).result

                if geo_coordinate.nil?
                  @geocoder = change_key  # change_key if quota runs out
                  redo   
                elsif geo_coordinate.empty?
                  lng_lat, geo_details = {}, {'addressComponent'=>{}}
                else
                  lng_lat     = geo_coordinate['location']
                  geo_details = @geocoder.decode(lng_lat['lat'],lng_lat['lng']).result
                end

                @pipe<<{
                  :name          => name,
                  :elong_city_id => elong_city.nil? ? '0' : elong_city[:Code],
                  :lng           => lng_lat['lng'],
                  :lat           => lng_lat['lat'],
                  :province      => geo_details['addressComponent']['province'],
                  :address       => geo_details['formatted_address'],
                }.merge(city_info)
                puts "\e[32m #{name}"
              rescue=>e
                warn e
                puts geo_coordinate
                next
              end
            end
          end
        }
      end

      def consumer 
        Thread.new {
          while @pduer.status or @pipe.length>0 do 
            row     =  @pipe.pop
            existed = Db::BasePoiLandmark.find_by(name: row[:name], city_cn: row[:city_cn], source_domain: row[:source_domain])
            existed.nil? ? Db::BasePoiLandmark.new(row).save : existed.update(row)
            sleep(1/(@pipe.length+1))
          end
        }
      end

      def work
        @pipe   = Queue.new
        @pduer  = producer
        @writer = consumer
        @pduer.join
        @writer.join
        abort( "Finished!")
      end 

      # Change key
      def change_key
        @index+=1
        raise "No more keys remains." if @index>=Keys.length
        @geocoder = Baidumap::Request::Geocoder.new(Keys[@index])
      end
    end
  end
end
