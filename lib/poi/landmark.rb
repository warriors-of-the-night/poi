require 'httparty'
class_files = %w( landmark/meituan   landmark/baidu_waimai 
                  landmark/dianping  landmark/elong_flight
                  landmark/train     landmark/metro 
                  landmark/scene     landmark/university
                  landmark/consulate landmark/embassy)
class_files.each { |file| require_relative file }
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
          :university   => University,
          :consulate    => Consulate,
          :embassy      => Embassy,
          :hospital     => POI::Hospital,
        } 
        @index        =  0
        @redis        =  Redis.new(:host=>"127.0.0.1", :port=>6379)
        @key          =  web_site
        @counter      =  0
        @pipe         =  Queue.new
        @geocoder     =  Baidumap::Request::Geocoder.new(Keys[@index])
        @crawler      =  @cp[@key.to_sym].new
        @landmarks    =  Db::BasePoiLandmark
        @elong_cities =  Db::BaseElongHotelCity
      end 

      def producer
        Thread.new {
          city_list   = @crawler.city_list 
            start     = get_rd(@key)
            city_list.drop(start).each do |city|
            city_cn     = city[:city_cn]
            @elong_city = @elong_cities.find_by(NameShort: city_cn)
            pois        = @crawler.landmarks(city)
            pois.each do |name, city_info|
              puts "Fetching pois: #{name}'s location, type: #{city_info[:cata]}, city: #{city_info[:city_cn]}"
              begin
                addrs = location(name, city_cn)
                redo if addrs.nil?
                @pipe << {
                  :name          => name,
                  :elong_city_id => @elong_city.nil? ? '0000' : @elong_city[:Code],
                }.merge(city_info).merge(addrs)
                puts "\e[32mFinished!\e[0m"
              rescue=>e
                warn "#{e}\n#{e.backtrace.join("\n")}"
                next
              end
            end
            @counter+=1
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
            warn "#{e}\n#{e.backtrace.join("\n")}"
            exit
          end
        }
      end

      def work
        begin 
          @pduer  = producer
          @writer = consumer
          @pduer.join
          @writer.join
        rescue=>e
          set_rd(@key,@counter)
          exit
        end
        set_rd(@key)
        abort( "Congratulation! All things Finished.")
      end 

      def location(name, city)
        addr_dtls = {:lng=>nil,:lat=>nil,:address=>nil,:province=>nil}
        geo_crd   = @geocoder.encode(name, city).result

        if geo_crd.nil?
          @geocoder = chg_api_key  # change baidumap api keys if quotas runs out
          return
        elsif !geo_crd.empty?
          lng_lat   = geo_crd['location']
          geo_dtls  = @geocoder.decode(lng_lat['lat'],lng_lat['lng']).result

          if check_city(geo_dtls, city)
            addr_dtls = {
              :lng      => lng_lat['lng'],
              :lat      => lng_lat['lat'],
              :city_cn  => geo_dtls['addressComponent']['city'].gsub(/市$/,''),
              :address  => geo_dtls['formatted_address'],
              :province => geo_dtls['addressComponent']['province'],
            }
          end
        end
        @elong_city = @elong_cities.find_by(NameShort: addr_dtls[:city_cn]) unless city
        addr_dtls
      end
       
      def chg_api_key
        @index+=1
        raise "No more keys remains." if @index>=Keys.length
        @geocoder = Baidumap::Request::Geocoder.new(Keys[@index])
      end

      def check_city(geo_dtls, city)
        addr  = geo_dtls['addressComponent']
        [addr['city'], addr['district']].any? { |ad| city.nil? or ad.include?(city.to_s) }
      end

      def get_rd(key, init_value=0)
        value = @redis.get(key)
        value.nil? ? init_value : value.to_i
      end

      def set_rd(key,value=0)
        @redis.set(key,value)
      end

    end
  end
end
