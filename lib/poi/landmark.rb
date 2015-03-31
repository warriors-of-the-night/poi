require 'httparty'
require_relative 'landmark/meituan'
require_relative 'landmark/baidu_waimai'
require_relative 'landmark/dianping'
require_relative 'landmark/elong_flight'
require_relative 'landmark/train'
require_relative 'landmark/metro'
require_relative 'landmark/scene'
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
        @cp           = {
          :meituan      => MeiTuan,
          :baidu_waimai => BaiduWaimai,
          :dianping     => DianPing,
          :elong_flight => ElongFlight,
          :train        => Train,
          :metro        => Metro,
          :scene        => Scene,
        } 
        @index        =  0
        @pipe         =  Queue.new
        @geocoder     =  Baidumap::Request::Geocoder.new(Keys[@index])
        @crawler      =  @cp[web_site.to_sym].new
        @landmarks    =  Db::BasePoiLandmark
        @elong_cities =  Db::BaseElongHotelCity
      end 

      def producer
        Thread.new {
          city_list = @crawler.city_list
          city_list.each do |city|
            elong_city = @elong_cities.find_by(NameShort: city[:city_cn])
            pois       = @crawler.landmarks(city)
            pois.each do |name, city_info|
              puts "Fetching pois: #{name}'s location, type: #{city_info[:cata]}, city: #{city_info[:city_cn]}"
              begin
                addrs = location(name, city_info)
                redo if addrs.nil?
                @pipe << {
                  :name          => name,
                  :elong_city_id => elong_city.nil? ? '0000' : elong_city[:Code],
                }.merge(city_info).merge(addrs)
                puts "\e[32mFinished!\e[0m"
              rescue=>e
                warn e
                warn e.backtrace
                next
              end
            end
          end
        }
      end

      def consumer 
        Thread.new {
          begin
          while @pduer.status or @pipe.length>0 do 
            row     =  @pipe.pop
            existed = @landmarks.find_by(name: row[:name],city_cn: row[:city_cn],source_domain: row[:source_domain])
            existed.nil? ? @landmarks.new(row).save : existed.update(row)
            sleep(1/(@pipe.length+1))
          end
          rescue=>e
            warn e
            warn e.backtrace
          end
        }
      end

      def work
        @pduer  = producer
        @writer = consumer
        @pduer.join
        @writer.join
        abort( "Congratulation! All things Finished.")
      end 

      def check_city(geo_dtls, city)
        addr  = geo_dtls['addressComponent']
        [addr['city'], addr['district']].any? {|ad| ad.include?(city) }
      end

      def location(name, city)
        addr_dtls = {:lng=>nil,:lat=>nil,:address=>nil,:province=>nil}
        geo_crd   = @geocoder.encode(name, city[:city_cn]).result

        if geo_crd.nil?
          @geocoder = change_key  # change_key if quotas runs out
          return nil  
        elsif !geo_crd.empty?
          lng_lat   = geo_crd['location']
          geo_dtls  = @geocoder.decode(lng_lat['lat'],lng_lat['lng']).result

          if check_city(geo_dtls,city[:city_cn])
            addr_dtls = {
              :lng      => lng_lat['lng'],
              :lat      => lng_lat['lat'],
              :address  => geo_dtls['formatted_address'],
              :province => geo_dtls['addressComponent']['province'],
            }
          end
        end
        addr_dtls
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
